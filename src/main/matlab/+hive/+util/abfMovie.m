function abfMovie(abfFile, movieFile, varargin)
%ABFMOVIE Summary of this function goes here
%   Detailed explanation goes here
    
    assertLogical = @(x) islogical(x) && isscalar(x);
    assertPosNum = @(x) isnumeric(x) && isscalar(x) && (x > 0);

    p = inputParser;
    addRequired(p, 'abfFile');
    addRequired(p, 'movieFile');
    addParameter(p, 'channel', 'FSCV_1');
    addParameter(p, 'seconds', 30, assertPosNum);
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
        error('Movie file %s already exists. Use overwrite = true to overwrite', cfg.movieFile);
    end
    
    [d, si, ~] = hive.convert.AbfToMat.abfload(cfg.abfFile, 'channels', {cfg.channel});
    
    % DIM: samples x sweeps
    abf = squeeze(d);
    nSamples = size(abf, 1);
    
    %
    % sweep timeline
    %
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
    thickness = alpha;
    
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
        plot(abf(:, ss(1)), 'LineWidth', 1.5, 'Color', 'black');
        
        xlim([0, nSamples - 1]);
        ylim([-2500, 2500]);
        xlabel('sample');
        ylabel('current (nA)');
        
        title(sprintf('time: %04.1fs  |  frame %04d  |  sweep %04d', t, f, max(ss)));
        drawnow;
        F(f) = getframe(gcf);
        
        clf;
    end
    fprintf('done.\n');
    
    fprintf('*** encoding video...')
    open(video);
    writeVideo(video, F);
    close(video);
    fprintf('DONE\n');

end

