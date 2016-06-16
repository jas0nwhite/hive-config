function crossvalidate(cfg, trainingPct, muMin, muMax)

    %
    % usage can be found by typing ?doc cvglmnet? in Matlab
    %

    % start up parallel
    gcp();

    %
    % ASSEMBLE TRAINING AND TESTING DATA
    %
    tcfg = cfg.training;    
    nDatasets = tcfg.getSize(tcfg.datasetCatalog);
    
    g = tic;
    fprintf('*** ASSEMBLING %d DATASETS...\n\n', nDatasets);
    
    parfor dsIx = 1:nDatasets
        buildDatasets(dsIx, cfg, trainingPct, muMin, muMax);
    end
    
    fprintf('\n*** DONE (%.3fs)\n\n\n', toc(g));
    
    
    %
    % TRAIN
    %
    g = tic;
    
    fprintf('*** TRAINING %d MODELS...\n\n', nDatasets);
    
    for dsIx = 1:nDatasets
        trainModel(dsIx, cfg);
    end
    
    fprintf('\n*** DONE (%.3fs)\n\n\n', toc(g));
    
    
    %
    % TEST
    %
    g = tic;
    
    fprintf('*** TESTING %d DATASETS...\n\n', nDatasets);
    
    parfor dsIx = 1:nDatasets
        generatePredicitons(dsIx, cfg);
    end
    
    fprintf('\n*** DONE (%.3fs)\n\n\n', toc(g));
    

    %
    % ANALYZE
    %
    g = tic;
    
    fprintf('*** ANALYZING %d DATASETS...\n\n', nDatasets);
    
    parfor dsIx = 1:nDatasets
        analyzeDataset(dsIx, cfg);
    end
    
    fprintf('\n*** DONE (%.3fs)\n\n\n', toc(g));
end








function buildDatasets(dsIx, cfg, trainingPct, muMin, muMax)
    t = tic;
    
    % LOAD DATA
    tcfg = cfg.training;
    
    [setId, sourceId] = tcfg.getSourceIxByDatasetId(dsIx);
    [id, name, ~] = tcfg.getSourceInfo(setId, sourceId);
    
    importDir = fullfile(tcfg.getSetValue(tcfg.importPathList, setId), name);
    labelFile = fullfile(importDir, tcfg.labelFile);
    vgramFile = fullfile(importDir, tcfg.vgramFile);
    
    resultDir = fullfile(cfg.testing.getSetValue(cfg.testing.resultPathList, setId), name);
    cvTestFile = fullfile(resultDir, 'cv-testing.mat');
    cvTrainFile = fullfile(resultDir, 'cv-training.mat');
    
    if exist(cvTestFile, 'file') && exist(cvTrainFile, 'file')
        fprintf('    %03d: SKIP (%.3fs)\n', id, toc(t));
        return
    end
    
    if ~exist(resultDir, 'dir')
        mkdir(resultDir);
    end
    
    dat = load(labelFile);
    all.chemicals = dat.chemicals;
    
    combos = cellfun(@(c) unique(vertcat(c(:))), dat.labels, 'unif', false);
    nCombos = size(combos, 1);
    isDoubled = nCombos == 2 * size(dat.labels, 1);
    
    if (isDoubled)
        % only use even numbered steps -- fast protocol only
        stepIx = 2:2:size(dat.labels, 1);
    else
        stepIx = 1:size(dat.labels, 1);
    end
    
    all.labels = dat.labels(stepIx);
    
    dat = load(vgramFile);
    all.voltammograms = dat.voltammograms(stepIx);
    
    clear dat;
    
    % FIND TARGET ANALYTE (MONO-ANALYTE ONLY)
    muVals = vertcat(all.labels{:});
    muCount = arrayfun(@(c) numel(unique(muVals(:, c))), 1:size(muVals, 2));
    chemIx = find(muCount > 1, 1, 'first');
    
    
    % BUILD TRAINING AND TESTING DATASETS
    vgrams = horzcat(all.voltammograms{:});
    
    offset = 0;
    nSteps = size(all.voltammograms, 1);
    testIx = cell(nSteps, 1);
    trainIx = cell(nSteps, 1);
    
    % sample each step uniformly
    for ix = 1:size(all.voltammograms, 1)
        step = all.labels{ix};
        stepValidIx = find(step(:, chemIx) >= muMin & step(:, chemIx) <= muMax);
        index = offset + stepValidIx;
        
        stepN = size(step, 1);
        stepValidN = numel(stepValidIx);
        
        if (trainingPct >= 1)
            if (trainingPct >= stepN)
                % leave some samples left for testing
                trainN = round(stepValidN * .9);
            else
                % use the specified number of samples
                trainN = min(stepValidN, trainingPct);
            end
        else
            trainN = round(stepValidN * trainingPct);
        end
        
        trainIx{ix} = datasample(index, trainN, 'Replace', false);
        testIx{ix} = setdiff(index, trainIx{ix});
        
        offset = offset + stepN;
    end
    
    test.ix = vertcat(testIx{:});
    test.n = numel(test.ix);
    test.voltammograms = vgrams(:, test.ix);
    test.labels = muVals(test.ix, chemIx);
    test.chemical = all.chemicals{chemIx};
    
    save(cvTestFile, '-struct', 'test');
    
    train.ix = vertcat(trainIx{:});
    train.n = numel(train.ix);
    train.voltammograms = vgrams(:, train.ix);
    train.labels = muVals(train.ix, chemIx);
    train.chemical = all.chemicals{chemIx};
    
    save(cvTrainFile, '-struct', 'train');
    
    fprintf('    %03d: DONE (%.3fs)\n', id, toc(t));
end



function trainModel(dsIx, cfg)
    t = tic;
    
    % LOAD DATA
    tcfg = cfg.training;
    
    [setId, sourceId] = tcfg.getSourceIxByDatasetId(dsIx);
    [id, name, ~] = tcfg.getSourceInfo(setId, sourceId);
    
    resultDir = fullfile(cfg.testing.getSetValue(cfg.testing.resultPathList, setId), name);
    cvTrainFile = fullfile(resultDir, 'cv-training.mat');
    cvModelFile = fullfile(resultDir, 'cv-model.mat');
    
    if exist(cvModelFile, 'file')
        fprintf('    %03d: SKIP (%.3fs)\n', id, toc(t));
        return
    end
    
    training = load(cvTrainFile);
    
    % cross validated glmnet options
    options.alpha = 1.0; % LASSO - to optimize, use 0:.1:1 in a loop
    family = 'gaussian';
    type = 'mse';
    nfolds = 10; % when finding best alpha, set this to []
    foldid = []; % when finding best alpha, set this to a precalculated list of fold ids
    parallel = 1; % if true (=1), then will run in parallel mode
    keep = 0;
    grouped = 1;
    
    % training data
    % training data supplied in ?training.voltammograms? variable
    % 1st dimension is observations, 2nd dimension is variables
    X = diff(training.voltammograms', 1, 2); %#ok<UDIM> % first differential along second dimension
    
    % training labels
    % training labels supplied in ?training.labels? variable
    % 1st dimension is observations, 2nd dimension is analyte concentrations
    Y = training.labels';
    
    % this could take a long time, so try it out first with a small amount of data
    CVerr = cvglmnet(X, Y, family, options, type, nfolds, foldid, parallel, keep, grouped); %#ok<NASGU>
    
    save(cvModelFile, 'CVerr');
    
    fprintf('    %03d: DONE (%.3fs)\n', id, toc(t));
end



function generatePredicitons(dsIx, cfg)
    t = tic;
    
    % LOAD DATA
    tcfg = cfg.training;
    
    [setId, sourceId] = tcfg.getSourceIxByDatasetId(dsIx);
    [id, name, ~] = tcfg.getSourceInfo(setId, sourceId);
    
    resultDir = fullfile(cfg.testing.getSetValue(cfg.testing.resultPathList, setId), name);
    cvTestFile = fullfile(resultDir, 'cv-testing.mat');
    cvModelFile = fullfile(resultDir, 'cv-model.mat');
    cvPredFile = fullfile(resultDir, 'cv-predictions.mat');
    
    if exist(cvPredFile, 'file')
        fprintf('    %03d: SKIP (%.3fs)\n', id, toc(t));
        return
    end
    
    testing = load(cvTestFile);
    load(cvModelFile);
    
    % testing data
    x = diff(testing.voltammograms', 1, 2); %#ok<UDIM> 
    labels = testing.labels; %#ok<NASGU>
    
    % generate predictions
    predictions = cvglmnetPredict(CVerr, x, 'lambda_min'); %#ok<NASGU>
    chemical = testing.chemical; %#ok<NASGU>
    
    save(cvPredFile, 'predictions', 'labels', 'chemical');
    
    fprintf('    %03d: DONE (%.3fs)\n', id, toc(t));
end


function analyzeDataset(dsIx, cfg)
    t = tic;
    
    % LOAD DATA
    tcfg = cfg.training;
    
    [setId, sourceId] = tcfg.getSourceIxByDatasetId(dsIx);
    [id, name, ~] = tcfg.getSourceInfo(setId, sourceId);
    
    importDir = fullfile(tcfg.getSetValue(tcfg.importPathList, setId), name);
    metadataFile = fullfile(importDir, tcfg.metaFile);
    
    resultDir = fullfile(cfg.testing.getSetValue(cfg.testing.resultPathList, setId), name);
    cvStatsFile = fullfile(resultDir, 'cv-stats.mat');
    cvTrainFile = fullfile(resultDir, 'cv-training.mat');
    cvTestFile = fullfile(resultDir, 'cv-testing.mat');
    cvPredFile = fullfile(resultDir, 'cv-predictions.mat');
    
    if exist(cvStatsFile, 'file')
        fprintf('    %03d: SKIP (%.3fs)\n', id, toc(t));
        return
    end
    
    cv = load(cvPredFile);
    testing = load(cvTestFile, 'ix');
    training = load(cvTrainFile);
    metadata = load(metadataFile);
    
    
    % stats
    labels = unique(cv.labels);
    nLabels = numel(labels);
    
    predRmse = nan(size(labels));
    predSnr = nan(size(labels));
    predSnre = nan(size(labels));
    
    for ix = 1:nLabels
        labIx = cv.labels == labels(ix);
        signal = cv.predictions(labIx);
        truth = cv.labels(labIx);
        noise = signal - truth;
        estimate = mean(signal);
        noiseEst = signal - estimate;
        
        predRmse(ix) = rms(noise);
        predSnr(ix) = snr(signal, noise);
        predSnre(ix) = snr(signal, noiseEst);
    end
    
    fSample = round(metadata.sampleFreq(1), 0);
    fSweep = round(metadata.sweepFreq(1), 0);
    
    plotT = (testing.ix - 1) / metadata.sweepFreq(1);
    
    chem = Chem.get(training.chemical);
    
    % plot
    info = tcfg.infoCatalog{setId}{sourceId, 2};
    probe = info.probeName;
    
    switch chem
        case Chem.pH
            units = '';
        otherwise
            units = sprintf(' (%s)', chem.units);
    end
    
    muLabel = [chem.label units];
    
    if (~isempty(regexp(info.protocol, '_uncorrelated_', 'once')))
        vpsString = 'uncorrelated';
    else
        voltage = 2;
        seconds = (diff(tcfg.getSetValue(tcfg.vgramWindowList, setId)) + 1) / fSample;
        vps = floor(voltage * 2 / seconds);
        vpsString = sprintf('%dV/s', vps);
    end
    
    pTitle = {
        sprintf('%s  |  %s  |  %s @ %dHz  |  %dkHz',...
        chem.label, strrep(probe, '_', '\_'), vpsString, fSweep, fSample * 1e-3)
        sprintf('monoanalyte  |  LASSO  |  n=%d', training.n)
        };
    
    
    
    figure;
    colors = lines(2);
    
    subplot(3, 2, 1:4)
    hold on;
    title(pTitle);
    xlabel('samples');
    ylabel(muLabel);
    
    plot(plotT, cv.predictions, '.', 'Color', colors(1, :), 'MarkerSize', 10);
    for ix = 1:nLabels
        labIx = find(cv.labels == labels(ix));
        stepX = [min(plotT(labIx)), max(plotT(labIx))];
        stepY = [labels(ix), labels(ix)];
        plot(stepX, stepY, 'Color', colors(2, :));
    end
    
    axis tight;
    xl = xlim();
    yl = [min(labels), max(labels)];
    xtwix = diff(xl) / 20;
    ytwix = diff(yl) / 20;
    
    legend({'predicted'; 'actual'}, 'Location', 'best');
    
    barX = (0:14) + 15*xtwix;
    barY = repmat(yl(1), size(barX)) + 2*ytwix;
    plot(barX, barY, 'k', 'LineWidth', 2);
    
    text(mean(barX), min(barY) + ytwix, '15s', 'HorizontalAlignment', 'Center', 'FontSize', 10);
    
    set(gca,'xtick',[]);
    xlim(xl + [-xtwix, +xtwix]);
    ylim(yl + [-2*ytwix, +2*ytwix]);
    axis manual;
    
    
    subplot(3, 2, 5);
    hold on;
    title('RMSE');
    xlabel(muLabel);
    ylabel(['RMSE' units]);
    
    if (chem ~= Chem.pH)
        plot([10; labels(2:end)], predRmse, '.', 'MarkerSize', 25);
        set(gca, 'XScale', 'log');
    else
        plot(labels, predRmse, '.', 'MarkerSize', 25);
    end
    
    grid on;
    axis manual;
    
    
    subplot(3, 2, 6);
    hold on;
    title('SNR');
    xlabel(muLabel);
    ylabel('SNR (dB)');
    
    plot(labels, predSnr, '.', 'MarkerSize', 25);
    %plot(labels, predSnre, '.', 'MarkerSize', 15);
    
    if (chem ~= Chem.pH)
        set(gca, 'XScale', 'log');
    end
    
    %legend({'actual'; 'apparent'}, 'Location', 'Northwest');
    grid on;
    axis manual;
    
    s = hgexport('readstyle', 'png-4MP');
    s.Format = 'png';
    
    savefig(gcf, fullfile(resultDir, 'cv-plot.fig'));
    hgexport(gcf, fullfile(resultDir, 'cv-plot.png'), s);
    close;
    %%
    save(cvStatsFile, 'predRmse', 'predSnr', 'predSnre');
    
    fprintf('    %03d: DONE (%.3fs)\n', id, toc(t));
end