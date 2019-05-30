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
    
    % DETERMINE CV FOLDS
    [nObvs, ~] = size(training.labels);
    
    switch this.treatment.trainingStyleId
        % case 9
        %     % generate folds by unique combinations of analytes
        %     combos = unique(training.labels, 'rows');
        %     nFolds = size(combos, 1);
        %     foldId = nan(nObvs, 1);
        % 
        %     for fold = 1:nFolds
        %         foldIx = ismember(training.labels, combos(fold, :), 'rows');
        %         foldId(foldIx) = fold;
        %     end
            
        otherwise
            % generate 10 randomly-selected folds
            rng(032272);
            nFolds = 10;
            foldId = randsample(...
                1:nFolds,...
                nObvs,...
                true);
    end
    
    % DETERMINE ALPHA RANGE
    switch this.treatment.alphaSelectId
        case 0
            alphaRange = 1.0; % LASSO
        case 1
            alphaRange = 0.0:0.1:1.0; % find best alpha
        otherwise
            error('unhandled alphaSelectId %03d', cfg.alphaSelectId);
    end
    
    % DETERMINE PREPROCESSING FUNCTION
    switch this.treatment.trainingStyleId
        case 9
            % use FFT
            preprocFn = @hive.proc.model.log_P1_fft;
            
        otherwise
            % use first derivative (difference)
            preprocFn = @hive.proc.model.first_diff;
    end
    
    % TRAIN
    CVerr = hive.proc.train.trainModelForAlpha(...
        training.voltammograms, training.labels, foldId, alphaRange, preprocFn, this.trainingDebug);
    
    save(cvModelFile, 'CVerr');
    hive.util.appendDatasetInfo(cvModelFile, name, id, setId, sourceId, this.treatment.name);
    
    fprintf('    %03d: %03d-fold-cv DONE (%.3fs)\n', id, nFolds, toc(t));
end