function analyzeDataset(this, dsIx)
    t = tic;
    
    % LOAD DATA
    [setId, sourceId] = this.cfg.getSourceIxByDatasetId(dsIx);
    [id, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
    
    importDir = fullfile(this.cfg.getSetValue(this.cfg.importPathList, setId), name);
    metadataFile = fullfile(importDir, this.cfg.metaFile);
    
    resultDir = fullfile(this.testCfg.getSetValue(this.testCfg.resultPathList, setId), name);
    cvStatsFile = fullfile(resultDir, 'cv-stats.mat');
    cvTrainFile = fullfile(resultDir, 'cv-training.mat');
    cvTestFile = fullfile(resultDir, 'cv-testing.mat');
    cvPredFile = fullfile(resultDir, 'cv-predictions.mat');
    
    if ~this.overwrite && exist(cvStatsFile, 'file')
        fprintf('    %03d: SKIP (%.3fs)\n', id, toc(t));
        return
    end
    
    cv = load(cvPredFile);
    testing = load(cvTestFile, 'ix');
    training = load(cvTrainFile);
    metadata = load(metadataFile);
    
    
    % stats
    labels = unique(cv.labels, 'rows', 'stable');
    
    nSteps = size(testing.ix, 1);
    nChems = size(cv.labels, 2);
    
    predRmse = nan(nSteps, nChems);
    predSnr = nan(nSteps, nChems);
    predSnre = nan(nSteps, nChems);
    
    for ix = 1:nSteps
        signal = cv.predictions(ix, :);
        truth = cv.labels(ix, :);
        noise = signal - truth;
        estimate = mean(signal);
        noiseEst = bsxfun(@minus, signal, estimate);
        
        predRmse(ix, :) = arrayfun(@(i) rms(noise(:, i)), 1:size(noise, 2));
        predSnr(ix, :) = arrayfun(@(i) snr(signal(:, i), noise(:, i)), 1:size(signal, 2));
        predSnre(ix, :) = arrayfun(@(i) snr(signal(:, i), noiseEst(:, i)), 1:size(signal, 2));
    end
    
    fSample = round(metadata.sampleFreq(1), 0);
    fSweep = round(metadata.sweepFreq(1), 0);
    
    plotT = (testing.ix - 1) / metadata.sweepFreq(1);
    
    % plot
    info = this.cfg.infoCatalog{setId}{sourceId, 2};
    probe = info.probeName;
    
    
    if (~isempty(regexp(info.protocol, '_uncorrelated_', 'once')))
        vpsString = 'random burst';
    else
        voltage = 2;
        sampleIx = this.cfg.getSetValue(this.cfg.vgramWindowList, setId);
        sampleRange = round(max(sampleIx) - min(sampleIx), -3);
        seconds = sampleRange / fSample;
        vps = round(voltage * 2 / seconds);
        vpsString = sprintf('%dV/s', vps);
    end
    
    if (~isempty(regexp(resultDir, '-shuffled', 'once')))
        vpsString = sprintf('%s (shuffled)', vpsString);
    end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%
    %%% PLOT
    %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure;
    
    nChem = numel(training.chemical);
    rows = 3;
    cols = nChem * 2;
    
    for chemIx = 1:nChem
        chem = Chem.get(training.chemical{chemIx});
        
        switch chem
            case Chem.pH
                units = '';
            otherwise
                units = sprintf(' (%s)', chem.units);
        end
        
        muLabel = [chem.label units];
        
        colors = lines(8);
        labColor = colors(2, :);
        colors = colors([1 4 7 8], :);
        
        col = 2 * (chemIx - 1) + 1;
        nextRow = cols;
        
        subplot(rows, cols, [col, col + 1, nextRow + col, nextRow + col + 1])
        hold on;
        title(chem.label);
        xlabel('samples');
        ylabel(muLabel);
        
        plot(plotT(:), cv.predictions(:, chemIx), '.', 'Color', colors(chemIx, :), 'MarkerSize', 10);
        for ix = 1:nSteps
            stepX = [min(plotT(ix, :)), max(plotT(ix, :))];
            stepY = [labels(ix, chemIx), labels(ix, chemIx)];
            plot(stepX, stepY, 'Color', labColor);
        end
        
        axis tight;
        xl = xlim();
        yl = [this.muMin, this.muMax];
        xtwix = diff(xl) / 20;
        ytwix = diff(yl) / 20;
        
        legend({'predicted'; 'actual'}, 'Location', 'best');
        
        barX = (0:14) + 15*xtwix;
        barY = repmat(yl(1) - 2*ytwix, size(barX)); % + 2*ytwix;
        plot(barX, barY, 'k', 'LineWidth', 2);
        
        text(mean(barX), min(barY) + ytwix, '15s', 'HorizontalAlignment', 'Center', 'FontSize', 10);
        
        set(gca,'xtick',[]);
        xlim(xl + [-xtwix, +xtwix]);
        ylim(yl + [-3*ytwix, +2*ytwix]);
        axis manual;
    end
    
    
    desat = @(c) hsv2rgb(rgb2hsv(c) .* [1.0 0.3 1.2]);
    
    
    %
    % RMSE
    %
    subplot(rows, cols, (rows - 1) * cols + (1:(cols/2)));
    hold on;
    % title(sprintf('RMSE = %0.1f %s', fullRmse, chem.units));
    title('RMSE');
    xlabel(muLabel);
    ylabel(['RMSE' units]);
    
    grid on;
    xl = [this.muMin, this.muMax];
    yl = [0, max(predRmse(:))];
    xtwix = diff(xl) / 20;
    ytwix = diff(yl) / 20;
    xlim(xl + [-xtwix, +xtwix]);
    ylim(yl + [-2*ytwix, +2*ytwix]);
    axis manual;
    
    for chemIx = 1:nChem
        fullSignal = cv.predictions(:, chemIx);
        fullTruth = cv.labels(:, chemIx);
        fullNoise = fullSignal - fullTruth;
        fullRmse = rms(fullNoise);
        
        plot(xlim(), [fullRmse fullRmse], '--', 'Color', desat(colors(chemIx, :)));
    end
    
    for chemIx = 1:nChem
        y = predRmse(:, chemIx);
        x = labels(:, chemIx);
        
        plot(x, y, '.', 'MarkerSize', 25, 'Color', colors(chemIx, :));
    end
    
    
    %
    % SNR
    %
    subplot(rows, cols, (rows - 1) * cols + ((cols/2 + 1):cols));
    hold on;
    % title(sprintf('SNR = %0.1f dB', fullSnr));
    title('SNR');
    xlabel(muLabel);
    ylabel('SNR (dB)');
    
    
    grid on;
    xl = [this.muMin, this.muMax];
    yl = [0, max(predSnr(:))];
    xtwix = diff(xl) / 20;
    ytwix = diff(yl) / 20;
    xlim(xl + [-xtwix, +xtwix]);
    ylim(yl + [-2*ytwix, +2*ytwix]);
    axis manual;
    
    for chemIx = 1:nChem
        fullSignal = cv.predictions(:, chemIx);
        fullTruth = cv.labels(:, chemIx);
        fullNoise = fullSignal - fullTruth;
        fullSnr = snr(fullSignal, fullNoise);
        
        plot(xlim(), [fullSnr fullSnr], '--', 'Color', desat(colors(chemIx, :)));
    end
    
    for chemIx = 1:nChem
        x = labels(:, chemIx);
        y = predSnr(:, chemIx);
        
        plot(x(x > 0), y(x > 0), '.', 'MarkerSize', 25, 'Color', colors(chemIx, :));
    end
    
    
    
    
    
    suptitle(sprintf('probe %s  |  %s @ %dHz\n\\fontsize{8}%s  |  dataset %03d  |  set %02d  |  source %03d',...
        strrep(regexprep(probe, '[_]+', '_'), '_', '\_'), vpsString, fSweep,...
        strrep(info.protocol, '_', '\_'), dsIx, setId, sourceId));
    
    savefig(gcf, fullfile(resultDir, 'cv-plot.fig'));
    
    s = hgexport('readstyle', 'png-4MP');
    s.Format = 'png';
    s.Height = 9;
    s.Width = 12;
    s.Resolution = 200;
    hgexport(gcf, fullfile(resultDir, 'cv-plot.png'), s);
    
    s.Format = 'eps';
    hgexport(gcf, fullfile(resultDir, 'cv-plot.eps'), s);
    
    close;
    
    save(cvStatsFile, 'labels', 'predRmse', 'predSnr', 'predSnre');
    
    fprintf('    %03d: DONE (%.3fs)\n', id, toc(t));
end