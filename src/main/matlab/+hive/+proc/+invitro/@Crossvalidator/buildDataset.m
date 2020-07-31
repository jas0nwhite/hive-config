function buildDataset(this, dsIx)
    t = tic;
    
    % LOAD DATA
    [setId, sourceId] = this.cfg.getSourceIxByDatasetId(dsIx);
    [id, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
    
    importDir = fullfile(this.cfg.getSetValue(this.cfg.importPathList, setId), name);
    labelFile = fullfile(importDir, this.cfg.labelFile);
    vgramFile = fullfile(importDir, this.cfg.vgramFile);
    metaFile = fullfile(importDir, this.cfg.metaFile);
    
    resultDir = fullfile(this.testCfg.getSetValue(this.testCfg.resultPathList, setId), name);
    cvTestFile = fullfile(resultDir, 'cv-testing.mat');
    cvTrainFile = fullfile(resultDir, 'cv-training.mat');
    
    if ~this.overwrite && exist(cvTestFile, 'file') && exist(cvTrainFile, 'file')
        fprintf('    %03d: SKIP (%.3fs)\n', id, toc(t));
        return
    end
    
    if ~exist(resultDir, 'dir')
        mkdir(resultDir);
    end
    
    dat = load(labelFile);
    all.chemicals = dat.chemicals;
    
    combos = cellfun(@(c) unique(vertcat(c(:))), dat.labels, 'unif', false);
    nCombos = size(combos, 1);
    isDoubled = nCombos == 2 * size(unique(cell2mat(dat.labels), 'rows'), 1);
    
    if (isDoubled)
        % only use even numbered steps -- fast protocol only
        stepIx = 2:2:size(dat.labels, 1);
    else
        stepIx = 1:size(dat.labels, 1);
    end
    
    all.labels = dat.labels(stepIx);
    
    dat = load(vgramFile);
    all.voltammograms = dat.voltammograms(stepIx);
    
    clear dat;
    
    % BUILD A MASTER INDEX
    nSteps = size(all.voltammograms, 1);
    
    all.index = cell(nSteps, 1);
    offset = 0;
    
    for ix = 1:nSteps
        all.sweepNumber{ix} = (1:size(all.labels{ix}, 1)) + offset;
        offset = max(all.sweepNumber{ix});
    end 
    
    % REMOVE JITTERED SAMPLES IF REQUESTED
    if this.removeJitter
        metadata = load(metaFile);
        jitterIx = metadata.jitterIx(stepIx);
        
        nRemoved = 0;
        for ix = 1:nSteps
            ixToRemove = jitterIx{ix};
            nRemoved = nRemoved + length(ixToRemove);
            
            all.sweepNumber{ix}(ixToRemove) = [];
            all.labels{ix}(ixToRemove, :) = [];
            all.voltammograms{ix}(:, ixToRemove) = [];
        end
        
        extraOutput = sprintf('[-%d jitter]', nRemoved);
    else
        extraOutput = '';
    end
    
    % FIND TARGET ANALYTES
    muVals = vertcat(all.labels{:});
    muCount = arrayfun(@(c) numel(unique(muVals(:, c))), 1:size(muVals, 2));
    chemIx = sort(find(muCount > 1));
    
   % FIND MEAN LABELS IF NEEDED
    skipTrainingLabels = cell(1, max(chemIx));
    if this.holdOutMeanLabels == true
        for ix = chemIx
            % we need to find the mean deviance cM from the neutral
            % concentration cN to account for pH, which can vary around 
            % the neutral 7.4
            cU = unique(muVals(:, chemIx));
            if numel(cU) < 4
                skipTrainingLabels{1, ix} = NaN;
                continue;
            end
            c = Chem.get(ix);
            cN = c.neutral();
            cD = round(abs(cU - cN), 5);
            cM = extantMean(cD) + cN;
            skipTrainingLabels{1, ix} = cM;
        end
    end
            
    
    % BUILD TRAINING AND TESTING DATASETS
    vgrams = horzcat(all.voltammograms{:});
    
    offset = 0;
    testIx = cell(nSteps, 1);
    trainIx = cell(nSteps, 1);
    novel = false(nSteps, 1);
    testN = 25; % TODO: figure out a better way to limit testing?
    
    % sample each step uniformly
    rng(1972);

    for ix = 1:nSteps
        step = all.labels{ix};
        stepInMuRange = arrayfun(@(i) ...
            prod(step(i, chemIx) >= this.muMin & step(i, chemIx) <= this.muMax), 1:size(step, 1));
        stepValidIx = find(stepInMuRange);
        index = offset + stepValidIx;
        
        stepN = size(step, 1);
        stepValidN = numel(stepValidIx);
        
        stepLabels = unique(step, 'rows');
        skipTraining = any(arrayfun(@(c) any(round(skipTrainingLabels{:, c}, 5) == round(stepLabels(c), 5)), chemIx));
        
        if skipTraining
            trainN = 0;
            novel(ix) = true;
        else
            if (this.trainingPct >= 1)
                if (this.trainingPct >= stepValidN)
                    % leave some samples left for testing
                    trainN = round(stepValidN * .9);
                else
                    % use the specified number of samples
                    trainN = min(stepValidN, this.trainingPct);
                end
            else
                trainN = round(stepValidN * this.trainingPct);
            end
        end
        
        trainIx{ix} = datasample(index, trainN, 'Replace', false);
        
        nonTrainIx = setdiff(index, trainIx{ix});
        k = min(testN, numel(nonTrainIx));
        testIx{ix} = datasample(nonTrainIx, k, 'Replace', false);
        
        offset = offset + stepN;
    end
    
    sweeps = horzcat(all.sweepNumber{:});
    
    ix = horzcat(testIx{:});
    test.n = numel(ix);
    test.voltammograms = vgrams(:, ix);
    test.labels = muVals(ix, chemIx);
    test.chemical = all.chemicals(chemIx);
    test.sweepNumber = sweeps(ix);
    test.novel = novel;
    
    offset = 0;
    test.ix = cell(nSteps, 1);
    for i = 1:nSteps
        test.ix{i} = (1:numel(testIx{i})) + offset;
        if (~isempty(test.ix{i}))
            offset = max(test.ix{i});
        end
    end
    test.ix = test.ix(arrayfun(@(c) ~isempty(c{:}), test.ix));
    
    save(cvTestFile, '-struct', 'test');
    hive.util.appendDatasetInfo(cvTestFile, name, id, setId, sourceId, this.treatment.name);
    
    ix = horzcat(trainIx{:});
    train.n = numel(ix);
    train.voltammograms = vgrams(:, ix);
    train.labels = muVals(ix, chemIx);
    train.chemical = all.chemicals(chemIx);
    train.sweepNumber = sweeps(ix);
    train.novel = novel;
    
    offset = 0;
    train.ix = cell(nSteps, 1);
    for i = 1:nSteps
        if ~isempty(trainIx{i})
            train.ix{i} = (1:numel(trainIx{i})) + offset;
            offset = max(train.ix{i});
        else
            train.ix{i} = [];
        end
    end
    train.ix = train.ix(arrayfun(@(c) ~isempty(c{:}), train.ix));
    
    save(cvTrainFile, '-struct', 'train');
    hive.util.appendDatasetInfo(cvTrainFile, name, id, setId, sourceId, this.treatment.name);
    
    fprintf('    %03d: DONE (%.3fs) %s\n', id, toc(t), extraOutput);
end

function em = extantMean(x)
        X = mean(x, 1);
        [~, ix] = min(sum(abs(x - X), 2));
        em = x(ix, :);
end
    
    