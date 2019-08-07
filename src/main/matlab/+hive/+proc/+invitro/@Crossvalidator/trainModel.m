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
    rng(032272);
    [nObvs, ~] = size(training.labels);
    nFolds = 10;
    
    switch this.treatment.trainingStyleId
        case 9
            % generate masks for unique combinations of analytes
            allCombos = unique(training.labels, 'rows');
            
            % ...but let's not use min and max
            comboIx = find(~all(allCombos == min(allCombos), 2) & ~all(allCombos == max(allCombos), 2));
            
            % ...and, let's set a maximum number of folds
            nCombos = min(numel(comboIx), nFolds);
            combos = allCombos(randsample(comboIx, nCombos, false), :);
            
            trainMask = zeros(nObvs, 1);
            
            for cIx = 1:nCombos
                foldIx = ismember(training.labels, combos(cIx, :), 'rows');
                trainMask(foldIx) = cIx;
            end
            fprintf('    %03d: %03d-fold-cv .... (%d/%d combos masked)\n', id, nFolds, nCombos, size(allCombos, 1));
            
        otherwise
            % generate 10 randomly-selected folds
            trainMask = [];
            fprintf('    %03d: %03d-fold-cv ....\n', id, nFolds);
    end
    

    foldId = randsample(...
        1:nFolds,...
        nObvs,...
        true);
    
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
    preprocFn = this.preprocessor.getPreprocessFn();
    
    % TRAIN
    CVerr = hive.proc.train.trainModelForAlpha(...
        training.voltammograms, training.labels, foldId, alphaRange, preprocFn, trainMask, this.trainingDebug);
    
    save(cvModelFile, 'CVerr');
    hive.util.appendDatasetInfo(cvModelFile, name, id, setId, sourceId, this.treatment.name);
    
    fprintf('    %03d: %03d-fold-cv DONE (%.3fs)\n', id, nFolds, toc(t));
end