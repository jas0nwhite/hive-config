function buildDataset(this, dsIx)
    t = tic;
    
    % LOAD DATA
    [setId, sourceId] = this.cfg.getSourceIxByDatasetId(dsIx);
    [id, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
    
    importDir = fullfile(this.cfg.getSetValue(this.cfg.importPathList, setId), name);
    labelFile = fullfile(importDir, this.cfg.labelFile);
    vgramFile = fullfile(importDir, this.cfg.vgramFile);
    
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
    
    % BUILD A MASTER INDEX
    nSteps = size(all.voltammograms, 1);
    
    all.index = cell(nSteps, 1);
    offset = 0;
    
    for ix = 1:nSteps
        all.sweepNumber{ix} = (1:size(all.labels{ix}, 1)) + offset;
        offset = max(all.sweepNumber{ix});
    end 
    
    % CLEAN JITTERED DATA IF NECESSARY
    jitterOutput = '';
    if isobject(this.jitterCorrector)
        all.voltammograms = arrayfun(@(s) this.jitterCorrector.removeJitter(all.voltammograms{s}), stepIx,...
            'UniformOutput', false);
        
        ixRemoved = arrayfun(@(s) isnan(all.voltammograms{s}(1, :)), stepIx, 'UniformOutput', false);
        nRemoved = sum(arrayfun(@(s) sum(ixRemoved{s}), stepIx));
        
        all.voltammograms = arrayfun(@(s) all.voltammograms{s}(:, ~ixRemoved{s}), stepIx', 'UniformOutput', false);
        all.labels = arrayfun(@(s) all.labels{s}(~ixRemoved{s}, :), stepIx', 'UniformOutput', false);
        all.sweepNumber = arrayfun(@(s) all.sweepNumber{s}(~ixRemoved{s}), stepIx', 'UniformOutput', false);
        
        jitterOutput = sprintf('[-%d jitter]', nRemoved);
    end
    
    clear dat;
    
    % FIND TARGET ANALYTES
    muVals = vertcat(all.labels{:});
    muCount = arrayfun(@(c) numel(unique(muVals(:, c))), 1:size(muVals, 2));
    chemIx = sort(find(muCount > 1));
    
    % BUILD TRAINING AND TESTING DATASETS
    vgrams = horzcat(all.voltammograms{:});
    
    offset = 0;
    testIx = cell(nSteps, 1);
    trainIx = cell(nSteps, 1);
    
    % sample each step uniformly
    for ix = 1:nSteps
        step = all.labels{ix};
        stepInMuRange = arrayfun(@(i) ...
            prod(step(i, chemIx) >= this.muMin & step(i, chemIx) <= this.muMax), 1:size(step, 1));
        stepValidIx = find(stepInMuRange);
        index = offset + stepValidIx;
        
        stepN = size(step, 1);
        stepValidN = numel(stepValidIx);
        
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
        
        rng(1972);
        trainIx{ix} = datasample(index, trainN, 'Replace', false);
        testIx{ix} = setdiff(index, trainIx{ix});
        
        offset = offset + stepN;
    end
    
    sweeps = horzcat(all.sweepNumber{:});
    
    ix = horzcat(testIx{:});
    test.n = numel(ix);
    test.voltammograms = vgrams(:, ix);
    test.labels = muVals(ix, chemIx);
    test.chemical = all.chemicals(chemIx);
    test.sweepNumber = sweeps(ix);
    
    offset = 0;
    test.ix = cell(nSteps, 1);
    for i = 1:nSteps
        test.ix{i} = (1:numel(testIx{i})) + offset;
        offset = max(test.ix{i});
    end
    test.ix = test.ix(arrayfun(@(c) ~isempty(c{:}), test.ix));
    
    save(cvTestFile, '-struct', 'test');
    
    ix = horzcat(trainIx{:});
    train.n = numel(ix);
    train.voltammograms = vgrams(:, ix);
    train.labels = muVals(ix, chemIx);
    train.chemical = all.chemicals(chemIx);
    train.sweepNumber = sweeps(ix);
    
    offset = 0;
    train.ix = cell(nSteps, 1);
    for i = 1:nSteps
        train.ix{i} = (1:numel(trainIx{i})) + offset;
        offset = max(train.ix{i});
    end
    test.ix = train.ix(arrayfun(@(c) ~isempty(c{:}), train.ix));
    
    save(cvTrainFile, '-struct', 'train');
    
    fprintf('    %03d: DONE (%.3fs) %s\n', id, toc(t), jitterOutput);
end