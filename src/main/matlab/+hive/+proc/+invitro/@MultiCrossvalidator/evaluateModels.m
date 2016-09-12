function [rmseMat, snrMat] = evaluateModels(this, setId, sourceId)
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
    
    rmseMat = nan(nTests, nAnalytes);
    snrMat = nan(nTests, nAnalytes);
    
    for testId = 1:nTests
        [~, testName, ~] = this.cfg.getSourceInfo(setId, testId);
        
        cvTestFile = fullfile(setDir, testName, 'cv-testing.mat');
        
        testing = load(cvTestFile);
        
        % testing data
        x = diff(testing.voltammograms', 1, 2); %#ok<UDIM>
        
        % generate predictions
        predictions = cvglmnetPredict(CVerr, x, 'lambda_min');
        
        % evaluate RMSE
        signal = predictions;
        truth = testing.labels;
        noise = signal - truth;
        
        rmseMat(testId, :) = arrayfun(@(i) rms(noise(:, i)), 1:size(noise, 2));
        snrMat(testId, :) = arrayfun(@(i) snr(signal(:, i), noise(:, i)), 1:size(signal, 2));
    end
    
    
    fprintf('    %03d: DONE (%.3fs)\n', sourceId, toc(t));

end

