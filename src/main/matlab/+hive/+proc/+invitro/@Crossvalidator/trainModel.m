function trainModel(this, dsIx)
    t = tic;
    
    % LOAD DATA
    [setId, sourceId] = this.cfg.getSourceIxByDatasetId(dsIx);
    [id, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
    
    resultDir = fullfile(this.testCfg.getSetValue(this.testCfg.resultPathList, setId), name);
    cvTrainFile = fullfile(resultDir, 'cv-training.mat');
    cvModelFile = fullfile(resultDir, 'cv-model.mat');
    
    if ~this.overwrite && exist(cvModelFile, 'file')
        fprintf('    %03d: SKIP (%.3fs)\n', id, toc(t));
        return
    end
    
    training = load(cvTrainFile);
    
    % cross validated glmnet options
    options.alpha = 1.0; % LASSO - to optimize, use 0:.1:1 in a loop
    family = 'mgaussian';
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