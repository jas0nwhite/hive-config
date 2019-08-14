function results = evaluateModels(this, setId, sourceId)
%EVALUATEMODELS Summary of this function goes here
%   Detailed explanation goes here

    t = tic;
    
    % LOAD MODEL
    [~, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
    
    setDir = this.testCfg.getSetValue(this.testCfg.resultPathList, setId);
    resultDir = fullfile(setDir, name);
    
    cvModelFile = fullfile(resultDir, 'cv-model.mat');
    cvStats = fullfile(resultDir, 'cv-stats.mat');
    
    load(cvModelFile, 'CVerr');
    load(cvStats, 'chems');
    
    nAnalytes = numel(chems);
    
    % PROCESS EACH TESTING SET
    nTests = size(this.cfg.sourceCatalog{setId}, 1);
    
    results.rmse = nan(nTests, nAnalytes);
    results.snr = nan(nTests, nAnalytes);
    results.n = nan(nTests, 1);
    results.sd = nan(nTests, nAnalytes);
    results.lmAlpha = nan(nTests, nAnalytes);
    results.lmBeta = nan(nTests, nAnalytes);
    results.lmRsquared = nan(nTests, nAnalytes);
    results.lmRmse = nan(nTests, nAnalytes);
    
    for testId = 1:nTests
        
        [~, testName, ~] = this.cfg.getSourceInfo(setId, testId);
        
        cvTestFile = fullfile(setDir, testName, 'cv-testing.mat');
        
        testing = load(cvTestFile);
        
        % before we go any further, check to see if this test was trained
        % for any of the analytes used in this dataset
        [~, resultAnalyteIx, testAnalyteIx] = intersect(chems, testing.chemical);
        
        if isempty(resultAnalyteIx) || isempty(testAnalyteIx)
            % there is no overlap... continue to next dataset
            continue;
        end
        
        % DETERMINE PREPROCESSING FUNCTION
        preprocFn = this.preprocessor.getPreprocessFn();
        
        % testing data
        x = preprocFn(testing.voltammograms', 2);
        
        % generate predictions
        switch this.treatment.trainingStyleId
            case 9
                lambdaSelect = 'lambda_1se';
            otherwise
                lambdaSelect = 'lambda_min';
        end
        
        predictions = cvglmnetPredict(CVerr, x, lambdaSelect);
        
        results.n(testId) = size(predictions, 1);
        
        % calculate standard deviation of mean-subtracted predctions,
        % step-wise
        [~, ~, stepNumber] = unique(testing.labels, 'rows');
        nSteps = max(stepNumber);
        
        meanSubtracted = [];
        
        for stepIx = 1:nSteps
            stepPredictions = predictions(stepNumber == stepIx, :);
            meanSubtracted = vertcat(meanSubtracted, ...
                bsxfun(@minus, stepPredictions, mean(stepPredictions, 1))); %#ok<AGROW>
        end
        
        results.sd(testId, :) = std(meanSubtracted);
        
        % find linear fit
        for ix = 1:numel(resultAnalyteIx)
            resIx = resultAnalyteIx(ix);
            tstIx = testAnalyteIx(ix);
            
            lm = fitlm(testing.labels(:, tstIx), predictions(:, resIx));
            c = lm.Coefficients;
            results.lmAlpha(testId, resIx) = c.Estimate(1);
            results.lmBeta(testId, resIx) = c.Estimate(2);
            results.lmRsquared(testId, resIx) = lm.Rsquared.Ordinary;
            results.lmRmse(testId, resIx) = lm.RMSE;
        end
        
        % evaluate RMSE and SNR
        signal = predictions(:, resultAnalyteIx);
        truth = testing.labels(:, testAnalyteIx);
        noise = signal - truth;
        
        results.rmse(testId, resultAnalyteIx) = arrayfun(@(i) rms(noise(:, i)), 1:size(noise, 2));
        results.snr(testId, resultAnalyteIx) = arrayfun(@(i) snr(signal(:, i), noise(:, i)), 1:size(signal, 2));
        
        % record analytes for proper assignment to grand results
        results.analytes = chems(resultAnalyteIx);
    end
    
    fprintf('    %03d: DONE (%.3fs)\n', sourceId, toc(t));

end

