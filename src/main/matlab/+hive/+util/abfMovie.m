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
    addParameter(p, 'process', 'none', @(x) any(validatestring(x, {'none', 'fft', 'diff', 'medfilt'})));
    addParameter(p, 'overwrite', false, assertLogical);
    addParameter(p, 'fps', 30, assertPosNum);
    addParameter(p, 'format', 'MPEG-4');
    addParameter(p, 'quality', 90, @(x) assertPosNum(x) && (x <= 100));
    

    parse(p, abfFile, movieFile, varargin{:});
    
    cfg = p.Results;
    
    if ~exist(cfg.abfFile, 'file')
        error('ABF file %s does not exist.', cfg.abfFile);
    end
    
    if exist(movieFile, 'file') && ~cfg.overwrite
        warning('Movie file %s already exists. Use overwrite = true to overwrite', cfg.movieFile);
        return
    end

    [~, abfFileName, ~] = fileparts(abfFile);
    abfFileName = strrep(abfFileName, '_', '-');
    
    fprintf('*** converting %s...', abfFileName);
    [d, si, ~] = hive.convert.AbfToMat.abfload(cfg.abfFile, 'channels', {cfg.channel});
    fprintf(' done.\n');
    
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
    nSamples = size(abf, 1);
    tSample = si / 1e6; % seconds
    tSweep = tSample * nSamples;
    sweeps = 1:floor(cfg.seconds / tSweep);
    sweepT = (sweeps - 1) * tSweep + tSweep;
    sps = floor(1 / tSweep);
    
    %
    % frame timeline
    %
    tFrame = 1 / cfg.fps;
    frames = 1:floor(cfg.seconds * cfg.fps);
    frameT = (frames - 1) * tFrame + tFrame;
    nFrames = numel(frames);
    
    video = VideoWriter(cfg.movieFile, cfg.format);
    video.FrameRate = cfg.fps;
    video.Quality = cfg.quality;
    
    
    alpha = fliplr(exp(0.1 * (1:(sps + 1)))/exp(0.1 * (sps + 1)));
    thickness = 2 * alpha;
    
    
    F(nFrames) = struct('cdata',[],'colormap',[]);
    
    fprintf('*** building frames...');
    parfor f = frames
        t = frameT(f);
        ss = fliplr(sweeps((sweepT <= t) & (sweepT > t - 1))); %#ok<PFBNS>
        
        
        hold on;
        for s = 2:numel(ss)
            hl = plot(abf(:, ss(s)), 'LineWidth', thickness(s)); %#ok<PFBNS>
            hl.Color = [0, 0, 1, alpha(s)]; %#ok<PFBNS>
        end
        plot(abf(:, ss(1)), 'LineWidth', 3, 'Color', 'black');
        
        xlim([0, nSamples - 1]);
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
    
    fprintf('*** encoding video...')
    open(video);
    writeVideo(video, F);
    close(video);
    fprintf('\n\n*** DONE\n');

end

