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
        fprintf('    SKIP\n\n');
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
    results.analytes = Chem.names;
    results.rmse = nan(nSources, nSources, Chem.count);
    results.snr = nan(nSources, nSources, Chem.count);
    results.n = nan(nSources, nSources, 1);
    results.sd = nan(nSources, nSources, Chem.count);
    results.lmAlpha = nan(nSources, nSources, Chem.count);
    results.lmBeta = nan(nSources, nSources, Chem.count);
    results.lmRsquared = nan(nSources, nSources, Chem.count);
    results.lmRmse = nan(nSources, nSources, Chem.count);
    
    for sourceId = 1:nSources
        [~, resIx, srcIx] = intersect(results.analytes, sourceResults{sourceId}.analytes);
        
        results.rmse(sourceId, :, resIx)       = sourceResults{sourceId}.rmse(:, srcIx);
        results.snr(sourceId, :, resIx)        = sourceResults{sourceId}.snr(:, srcIx);
        results.n(sourceId, :)                 = sourceResults{sourceId}.n(:);
        results.sd(sourceId, :, resIx)         = sourceResults{sourceId}.sd(:, srcIx);
        results.lmAlpha(sourceId, :, resIx)    = sourceResults{sourceId}.lmAlpha(:, srcIx);
        results.lmBeta(sourceId, :, resIx)     = sourceResults{sourceId}.lmBeta(:, srcIx);
        results.lmRsquared(sourceId, :, resIx) = sourceResults{sourceId}.lmRsquared(:, srcIx);
        results.lmRmse(sourceId, :, resIx)     = sourceResults{sourceId}.lmRmse(:, srcIx);
    end
    
    % save results
    save(cvPermuteFile, '-struct', 'results');
    hive.util.appendDatasetInfo(cvPermuteFile, [], [], setId, [], this.treatment.name);

    fprintf('\n');
end

