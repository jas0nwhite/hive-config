function abfMovie(abfFile, movieFile, varargin)
%ABFMOVIE Summary of this function goes here
%   Detailed explanation goes here
    close all;
    
    assertLogical = @(x) islogical(x) && isscalar(x);
    assertPosNum = @(x) isnumeric(x) && isscalar(x) && (x > 0);
    
    p = inputParser;
    addRequired(p, 'abfFile');
    addRequired(p, 'movieFile');
    addParameter(p, 'channel', 'FSCV_1');
    addParameter(p, 'seconds', 30, assertPosNum);
    addParameter(p, 'truncate', 0, @isnumeric);
    addParameter(p, 'process', 'none', @(x) any(validatestring(x, {'none', 'raw', 'fft', 'diff', 'medfilt'})));
    addParameter(p, 'overwrite', false, assertLogical);
    addParameter(p, 'fps', 30, assertPosNum);
    addParameter(p, 'format', 'MPEG-4');
    addParameter(p, 'quality', 90, @(x) assertPosNum(x) && (x <= 100));
    addParameter(p, 'zoompct', 100, @(x) assertPosNum(x) && (x <= 100));
    
    
    parse(p, abfFile, movieFile, varargin{:});
    
    cfg = p.Results;
    
    if ~exist(cfg.abfFile, 'file')
        error('ABF file %s does not exist.', cfg.abfFile);
    end
    
    if exist(movieFile, 'file') && ~cfg.overwrite
        doMovie = false;
    else
        doMovie = true;
    end
    
    [d, f, x] = fileparts(movieFile);
    spectrumFile = fullfile(d, [f '-spec' x]);
    pgramFile = fullfile(d, [f '-pgram.png']);
    
    if exist(spectrumFile, 'file') && ~cfg.overwrite
        doSpectrum = false;
    else
        doSpectrum = true;
    end
    
    if exist(pgramFile, 'file') && ~cfg.overwrite
        doPgram = false;
    else
        doPgram = true;
    end
    
    if ~(doPgram || doSpectrum || doMovie)
        fprintf('    SKIP. [%s][%s][%s]\n\n', movieFile, spectrumFile, pgramFile);
    end
    
    [~, abfFileName, ~] = fileparts(abfFile);
    abfFileName = strrep(abfFileName, '_', '-');
    
    fprintf('*** converting %s...', abfFileName);
    [d, si, ~] = hive.convert.AbfToMat.abfload(cfg.abfFile, 'channels', {cfg.channel});
    fprintf(' done.\n');
    
    if isempty(d)
        error('    no data read from channel %s', cfg.channel);
    end
    
    % DIM: samples x sweeps
    samplewise = 1;
    sweepwise = 2;
    abf = squeeze(d);
    
    %
    % truncate if requested
    %
    if cfg.truncate > 0
        fprintf('*** truncating at ±%.1f...', cfg.truncate);
        abf(abs(abf) > cfg.truncate) = -cfg.truncate;
        fprintf(' done.\n');
        ymax = 1.05 * cfg.truncate;
        ymin = -1.05 * cfg.truncate;
    else
        ymax = 2100;
        ymin = -2100;
    end
    
    %
    % process if requested
    %
    switch cfg.process
        case 'fft'
            fprintf('*** computing fft...');
            
            abf = hive.proc.model.log_P1_fft(abf, samplewise);
            
            yrange = range(abf, 'all');
            ymax = max(abf, [], 'all') + 0.05 * yrange;
            ymin = min(abf, [], 'all') - 0.05 * yrange;
            fprintf(' done.\n');
        case 'diff'
            fprintf('*** computing diff...');
            
            abf = hive.proc.model.first_diff(abf, samplewise);
            
            yrange = range(abf, 'all');
            ymax = max(abf, [], 'all') + 0.05 * yrange;
            ymin = min(abf, [], 'all') - 0.05 * yrange;
            fprintf(' done.\n');
        case 'medfilt'
            order = 25;
            fprintf('*** median filtering (n = %d)...', order);
            
            abf = medfilt1(abf, order, [], sweepwise, 'omitnan', 'truncate');
            
            ymax = 2100;
            ymin = -2100;
            fprintf(' done.\n');
    end
    
    %
    % sweep timeline
    %
    nSamples = size(abf, samplewise);
    nSweeps = size(abf, sweepwise);
    tSample = si / 1e6; % seconds
    tSweep = tSample * nSamples;
    sweeps = 1:floor(cfg.seconds / tSweep);
    sampleWindow = 1:(floor(cfg.zoompct / 100 * nSamples));
    
    %
    % handle file smaller than requested numer of seconds
    %
    if numel(sweeps) > nSweeps
        sweeps = 1:nSweeps;
        cfg.seconds = nSweeps * tSweep;
    end
    
    sweepT = (sweeps - 1) * tSweep + tSweep;
    sps = floor(1 / tSweep);
    fs = 1/tSample;
    
    %
    % frame timeline
    %
    tFrame = 1 / cfg.fps;
    frames = 1:floor(cfg.seconds * cfg.fps);
    frameT = (frames - 1) * tFrame + tFrame;
    nFrames = numel(frames);
    
    %
    % waveform
    %
    fprintf('*** building waveform frames...');
    if doMovie
        video = VideoWriter(cfg.movieFile, cfg.format);
        video.FrameRate = cfg.fps;
        video.Quality = cfg.quality;
        
        alpha = fliplr(exp(0.1 * (1:(sps + 1)))/exp(0.1 * (sps + 1)));
        thickness = 2 * alpha;
        
        F(nFrames) = struct('cdata',[],'colormap',[]);
        
        parfor f = frames
            t = frameT(f);
            ss = fliplr(sweeps((sweepT <= t) & (sweepT > t - 1))); %#ok<PFBNS>
            
            
            hold on;
            for s = 2:numel(ss)
                hl = plot(abf(sampleWindow, ss(s)), 'LineWidth', thickness(s)); %#ok<PFBNS>
                hl.Color = [0, 0, 1, alpha(s)]; %#ok<PFBNS>
            end
            
            if ~isempty(ss)
                plot(abf(sampleWindow, ss(1)), 'LineWidth', 3, 'Color', 'black');
            end
            
            xlim([0, numel(sampleWindow) - 1]);
            ylim([ymin, ymax]);
            xlabel('sample');
            ylabel('current (nA)');
            
            title({abfFileName; sprintf('time: %04.1fs  |  frame %04d  |  sweep %04d', t, f, max(ss))});
            set(gcf, ...
                'Position', [-120 1274 1280 720],...
                'Color', [1, 1, 1]...
                );
            drawnow;
            F(f) = getframe(gcf);
            
            clf;
        end
        fprintf(' done.\n');
        
        fprintf('*** encoding waveform video...')
        open(video);
        writeVideo(video, F);
        close(video);
        fprintf(' done.\n');
    else
        fprintf(' SKIP.\n');
    end
    
    
    %
    % spectrum
    %
    fprintf('*** building spectrum frames...');
    if doSpectrum
        wav = abf(:);
        
        nfft = 2048;
        noverlap = 2040;
        freqs = 0:.2:2400;
        spf = numel(wav)/nFrames;
        
        video = VideoWriter(spectrumFile, cfg.format);
        video.FrameRate = cfg.fps;
        video.Quality = cfg.quality;
        
        F(nFrames) = struct('cdata',[],'colormap',[]);
        
        parfor f = frames
            t = frameT(f);
            
            i0 = floor((f - 1) * spf) + 1;
            i1 = floor(f * spf);
            x = wav(i0:i1); %#ok<PFBNS>
            
            if numel(x) < nfft
                NFFT = nextpow2(floor(nfft/2));
                NOVERLAP = floor(.9 * nfft);
            else
                NFFT = nfft;
                NOVERLAP = noverlap;
            end
            
            spectrogram(x, NFFT, NOVERLAP, freqs, fs, 'yaxis');
            
            title({abfFileName; sprintf('time: %04.1fs  |  frame %04d', t, f)});
            set(gcf, ...
                'Position', [-120 1274 1280 720],...
                'Color', [1, 1, 1]...
                );
            drawnow;
            F(f) = getframe(gcf);
            
            clf;
        end
        fprintf(' done.\n');
        
        fprintf('*** encoding waveform video...')
        open(video);
        writeVideo(video, F);
        close(video);
        fprintf(' done.\n');
    else
        fprintf(' SKIP.\n');
    end
    
    if doPgram
        fprintf('*** plotting frequency response...')
        N = numel(abf);
        dF = fs/N;
        freqs = 0:dF:200;
        close all;
        periodogram(abf(:), rectwin(N), freqs, fs);
        title({abfFileName; 'Periodogram Power Spectral Density Estimate'});
        s = hgexport('readstyle', 'PNG-4MP');
        s.Format = 'png';
        s.Width = 8;
        s.Height = 4.5;
        hgexport(gcf, pgramFile, s);
        close all;
        fprintf(' done.\n');
    else
        fprintf(' SKIP.\n');
    end
    
    fprintf('\n\n*** DONE\n');
    

end

