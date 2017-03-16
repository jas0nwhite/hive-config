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
    
    % do the training
    switch this.treatment.alphaSelectId
        case 0
            alpha = 1.0; % LASSO
        case 1
            alpha = 0.0:0.1:1.0; % find best alpha
        otherwise
            error('unhandled alphaSelectId %03d', cfg.alphaSelectId);
    end
    
    CVerr = this.trainModelForAlpha(training, alpha); %#ok<NASGU>
    
    save(cvModelFile, 'CVerr');
    
    fprintf('    %03d: DONE (%.3fs)\n', id, toc(t));
end