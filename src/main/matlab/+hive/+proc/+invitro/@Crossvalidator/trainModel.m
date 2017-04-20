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
    
    % DETERMINE ALPHA RANGE
    switch this.treatment.alphaSelectId
        case 0
            alphaRange = 1.0; % LASSO
        case 1
            alphaRange = 0.0:0.1:1.0; % find best alpha
        otherwise
            error('unhandled alphaSelectId %03d', cfg.alphaSelectId);
    end
    
    % TRAIN
    CVerr = hive.proc.train.trainModelForAlpha(...
        training.voltammograms, training.labels, alphaRange, this.trainingDebug); %#ok<NASGU>
    
    save(cvModelFile, 'CVerr');
    hive.util.appendDatasetInfo(cvModelFile, name, id, setId, sourceId, this.treatment.name);
    
    fprintf('    %03d: DONE (%.3fs)\n', id, toc(t));
end