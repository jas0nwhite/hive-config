function validateLabelsForDataset(this, dsIx)
    t = tic;
    
    % LOAD DATA
    [setId, sourceId] = this.cfg.getSourceIxByDatasetId(dsIx);
    [id, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
    
    importDir = fullfile(this.cfg.getSetValue(this.cfg.importPathList, setId), name);
    metadataFile = fullfile(importDir, this.cfg.metaFile);
    
    resultDir = fullfile(this.testCfg.getSetValue(this.testCfg.resultPathList, setId), name);
    cvTrainFile = fullfile(resultDir, 'cv-training.mat');
    cvValidateFile = fullfile(resultDir, 'cv-validate.mat');
    
    if ~this.overwrite && exist(cvValidateFile, 'file')
        fprintf('    %03d: SKIP (%.3fs)\n', id, toc(t));
        return
    end
    
    training = load(cvTrainFile);
    metadata = load(metadataFile, 'sampleFreq', 'sweepFreq');
    
        
    % DETERMINE PREPROCESSING FUNCTION
    preprocFn = this.preprocessor.getPreprocessFn();
    
    
    % SET UP VALIDATION RUNS
    nSteps = numel(training.ix);
    trainSize = 20;
    
    IX = 1:nSteps;
    iteration = 1;
    iterationIx(iteration, :) = IX;
    
    for r = 1:nSteps
        for c = 1:(nSteps)
            if r == c
                continue
            end
            
            iteration = iteration + 1;
            ix = IX;
            ix(r) = [];
            iterationIx(iteration, :) = [ix(1:(c-1)), r, ix(c:end)];

        end
    end
    
    iterationIx = unique(iterationIx, 'stable', 'rows');
    nIterations = size(iterationIx, 1);
    
    
    % PROCESS LABELS AND VOLTAMMOGRAMS
    vgrams = preprocFn(training.voltammograms, 1)';
    labels = this.labelProcessor.apply(training.labels);
    
    
    % PREPARE STATIC TRAIN/TEST DATA
    trainIx = arrayfun(@(a) training.ix{a}(:, 1:trainSize), IX, 'UniformOutput', false);
    trainIx = horzcat(trainIx{:});
    testIx = arrayfun(@(a) training.ix{a}(:, (trainSize+1):end), IX, 'UniformOutput', false);
    testIx = horzcat(testIx{:});
    
    x0 = vgrams(trainIx, :);
    x1 = vgrams(testIx, :);
    
    
    % TRAIN / TEST ITERATIONS
    trainingIx = training.ix;
    iterationMse = nan(nIterations, 1);
    iterationMse_1se = nan(nIterations, 1);
    options.alpha = 1;
    if size(labels, 2) > 1
        family = 'mgaussian';
    else
        family = 'gaussian';
    end
    
    fprintf('    %03d: evaluate %d labels .... (%d permutations)\n', id, nSteps, nIterations);
    
    parfor i = 1:nIterations
        l = tic();
        
        ix = iterationIx(i, :);
        trainIx = arrayfun(@(a) trainingIx{a}(:, 1:trainSize), ix, 'UniformOutput', false); %#ok<PFBNS>
        trainIx = horzcat(trainIx{:});
        testIx = arrayfun(@(a) trainingIx{a}(:, (trainSize+1):end), ix, 'UniformOutput', false);
        testIx = horzcat(testIx{:});
        
        % train
        y0 = labels(trainIx, :); %#ok<PFBNS>
        fit = glmnet(x0, y0, family, options);
        
        % cross-validate
        y1 = labels(testIx, :);        
        Y1 = glmnetPredict(fit, x1);
        
        % cv error
        if strcmp(family, 'gaussian')
            cve = (y1 - Y1).^2;                     % nobs x nlabmda
        else
            cve = squeeze(sum((y1 - Y1).^2, 2));    % nobs x nlambda
        end
        
        cvm = mean(cve, 1);                         % 1 x nlambda
        cvsd = std(cve, [], 1);                     % 1 x nlambda
        
        % find lambda_min and lambda_1se
        lambda_min = max(fit.lambda(cvm <= min(cvm)));
        idmin = fit.lambda == lambda_min;
        semin = cvm(idmin) + cvsd(idmin);
        lambda_1se = max(fit.lambda(cvm <= semin));
        
        % return MSE at lambda_min and lambda_1se
        iterationMse(i) = cvm(fit.lambda == lambda_min);
        iterationMse_1se(i) = cvm(fit.lambda == lambda_1se);
        
        fprintf('    %03d:     permutation %d/%d (%.3fs)\n', id, i, nIterations, toc(l));
    end
    
    % get best values
    [minMSE, minIx] = min(iterationMse);
    [minMSE_1se, minIx_1se] = min(iterationMse_1se);
    
    
    % PLOT
    fig = figure('visible', 'off');
    hold on;
    
    h1 = plot(1:nIterations, sqrt(iterationMse_1se));
    h2 = plot(1:nIterations, sqrt(iterationMse));
    
    plot(minIx_1se, sqrt(minMSE_1se), 'bo');
    plot(minIx, sqrt(minMSE), 'ro');
    
    hl = refline(0, sqrt(minMSE_1se));
    hl.Color = 'blue';
    hl.LineStyle = ':';
    
    hl = refline(0, sqrt(minMSE));
    hl.Color = 'red';
    hl.LineStyle = ':';
    
    legend([h1, h2], {'\lambda_{1se}', '\lambda_{min}'}, 'Location', 'northeast');
    xlabel('permutation #');
    ylabel('cv rmse');
    
    hold off;
    
    % decorate
    fSample = round(metadata.sampleFreq(1), 0);
    fSweep = round(metadata.sweepFreq(1), 0);
    info = this.cfg.infoCatalog{setId}{sourceId, 2};
    sampleIx = this.cfg.getSetValue(this.cfg.vgramWindowList, setId);
    sampleRange = round(max(sampleIx) - min(sampleIx), -3);
    
    if isempty(info.probeName)
        probe = info.acqDate;
    else
        probe = info.probeName;
    end
    
    % use some (standard?) data to calculate the forcing function and probe names
    forcingFn = hive.util.calculateProtocolTitle(info.protocol, sampleRange, fSample);
    
    % indicate shuffled dataset where appropriate
    if (~isempty(regexp(resultDir, '-shuffled', 'once')))
        forcingFn = sprintf('%s (shuffled)', forcingFn);
    end
    
    subtitle = sprintf(...
        'probe %s  |  %s @ %dHz\n\\fontsize{8}%s  |  dataset %03d  |  set %02d  |  source %03d  |  ix: %d / %d  |  rmse: %.0f / %.0f',...
        strrep(regexprep(probe, '[_]+', '_'), '_', '\_'), forcingFn, fSweep,...
        strrep(info.protocol, '_', '\_'), dsIx, setId, sourceId,...
        minIx_1se, minIx, sqrt(minMSE_1se), sqrt(minMSE));
    
    suptitle(subtitle);

    % save figure
    s = hgexport('readstyle', 'PNG-4MP');
    s.Format = 'png';
    s.Height = 9;
    s.Width = 12;
    s.Resolution = 200;
    hgexport(fig, fullfile(resultDir, 'cv-validate.png'), s);
    
    close(fig);
    
    
    % SAVE DATA
    data.stepPermutations = iterationIx;
    data.lambda_min.rmse = sqrt(iterationMse);
    data.lambda_min.ix = minIx;
    data.lambda_min.steps = iterationIx(minIx);
    data.lambda_1se.rmse = sqrt(iterationMse_1se);
    data.lambda_1se.ix = minIx_1se;
    data.lambda_1se.steps = iterationIx(minIx_1se);
    
    save(cvValidateFile, '-struct', 'data');
    
    
    fprintf('    %03d: evaluate %d labels DONE (%.3fs)\n', id, nSteps, toc(t));
end
