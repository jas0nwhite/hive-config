function generatePredictions(this, dsIx)
    t = tic;
    
    % LOAD DATA
    [setId, sourceId] = this.cfg.getSourceIxByDatasetId(dsIx);
    [id, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
    
    resultDir = fullfile(this.testCfg.getSetValue(this.testCfg.resultPathList, setId), name);
    cvTestFile = fullfile(resultDir, 'cv-testing.mat');
    cvModelFile = fullfile(resultDir, 'cv-model.mat');
    cvPredFile = fullfile(resultDir, 'cv-predictions.mat');
    
    if ~this.overwrite && exist(cvPredFile, 'file')
        fprintf('    %03d: SKIP (%.3fs)\n', id, toc(t));
        return
    end
    
    testing = load(cvTestFile);
    load(cvModelFile); %#ok<LOAD>
    
    % DETERMINE PREPROCESSING FUNCTION
    preprocFn = this.preprocessor.getPreprocessFn();
    
    % testing data
    x = preprocFn(testing.voltammograms', 2);
    labels = testing.labels;
    
    % generate predictions
    predictions = cvglmnetPredict(CVerr, x, 'lambda_min');
    chemical = testing.chemical;
    
    save(cvPredFile, 'predictions', 'labels', 'chemical');
    hive.util.appendDatasetInfo(cvPredFile, name, id, setId, sourceId, this.treatment.name);
    
    fprintf('    %03d: DONE (%.3fs)\n', id, toc(t));
end