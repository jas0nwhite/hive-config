function results = evaluateModels(this, setId, sourceId)
%EVALUATEMODELS Summary of this function goes here
%   Detailed explanation goes here

    t = tic;
    
    % LOAD MODEL
    [~, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
    
    setDir = this.testCfg.getSetValue(this.testCfg.resultPathList, setId);
    resultDir = fullfile(setDir, name);
    
    cvModelFile = fullfile(resultDir, 'cv-model.mat');
    
    load(cvModelFile);
    
    nAnalytes = size(CVerr.glmnet_fit.beta, 2);
    
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
        
        % testing data
        x = diff(testing.voltammograms', 1, 2); %#ok<UDIM>
        
        % generate predictions
        predictions = cvglmnetPredict(CVerr, x, 'lambda_min');
        
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
        for analyteIx = 1:nAnalytes
            lm = fitlm(testing.labels(:, analyteIx), predictions(:, analyteIx));
            c = lm.Coefficients;
            results.lmAlpha(testId, analyteIx) = c.Estimate(1);
            results.lmBeta(testId, analyteIx) = c.Estimate(2);
            results.lmRsquared(testId, analyteIx) = lm.Rsquared.Ordinary;
            results.lmRmse(testId, analyteIx) = lm.RMSE;
        end
        
        % evaluate RMSE and SNR
        signal = predictions;
        truth = testing.labels;
        noise = signal - truth;
        
        results.rmse(testId, :) = arrayfun(@(i) rms(noise(:, i)), 1:size(noise, 2));
        results.snr(testId, :) = arrayfun(@(i) snr(signal(:, i), noise(:, i)), 1:size(signal, 2));
    end
    
    fprintf('    %03d: DONE (%.3fs)\n', sourceId, toc(t));

end

