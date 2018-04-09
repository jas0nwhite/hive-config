function evaluateAllModels( this, setId )
%EVALUATEALLMODELS Summary of this function goes here
%   Detailed explanation goes here

    % set up
    nSources = size(this.cfg.sourceCatalog{setId}, 1);
    
    fprintf('*** CROSS-EVALUATING SET %d: %d SOURCES...\n\n', setId, nSources);
    
    % skip if nothing do to
    if nSources == 0
        return
    end
    
    % skip if necessary
    cvPermuteFile = fullfile(this.cfg.resultPathList{setId}, 'cv-permutation.mat');
    
    if ~this.overwrite && exist(cvPermuteFile, 'file')
        fprintf('    SKIP\n');
        return
    end
    
    % process all sources
    sourceResults = cell(nSources, 1);
    
    if this.doParfor
        parfor sourceId = 1:nSources
            sourceResults{sourceId} = this.evaluateModels(setId, sourceId); %#ok<PFBNS>
        end
    else
        for sourceId = 1:nSources
            sourceResults{sourceId} = this.evaluateModels(setId, sourceId);
        end
    end
    
    % collate
    results.rmse = nan(nSources, nSources, nAnalytes);
    results.snr = nan(nSources, nSources, nAnalytes);
    results.n = nan(nSources, nSources, 1);
    results.sd = nan(nSources, nSources, nAnalytes);
    results.lmAlpha = nan(nSources, nSources, nAnalytes);
    results.lmBeta = nan(nSources, nSources, nAnalytes);
    results.lmRsquared = nan(nSources, nSources, nAnalytes);
    results.lmRmse = nan(nSources, nSources, nAnalytes);
    
    for sourceId = 1:nSources
        results.rmse(sourceId, :, :)       = sourceResults{sourceId}.rmse(:, :);
        results.snr(sourceId, :, :)        = sourceResults{sourceId}.snr(:, :);
        results.n(sourceId, :)             = sourceResults{sourceId}.n(:);
        results.sd(sourceId, :, :)         = sourceResults{sourceId}.sd(:, :);
        results.lmAlpha(sourceId, :, :)    = sourceResults{sourceId}.lmAlpha(:, :);
        results.lmBeta(sourceId, :, :)     = sourceResults{sourceId}.lmBeta(:, :);
        results.lmRsquared(sourceId, :, :) = sourceResults{sourceId}.lmRsquared(:, :);
        results.lmRmse(sourceId, :, :)     = sourceResults{sourceId}.lmRmse(:, :);
    end
    
    % save results
    save(cvPermuteFile, '-struct', 'results');
    hive.util.appendDatasetInfo(cvPermuteFile, [], [], setId, [], this.treatment.name);

end

