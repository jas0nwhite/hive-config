function evaluateAllModels( this, setId )
%EVALUATEALLMODELS Summary of this function goes here
%   Detailed explanation goes here

    % set up
    nSources = size(this.cfg.sourceCatalog{setId}, 1);
    
    fprintf('*** CROSS-EVALUATING SET %d: %d SOURCES...\n\n', setId, nSources);
    
    % skip if necessary
    cvPermuteFile = fullfile(this.cfg.resultPathList{setId}, 'cv-permutation.mat');
    
    if ~this.overwrite && exist(cvPermuteFile, 'file')
        fprintf('    SKIP\n');
        return
    end
    
    % peek at one source to find number of analytes
    [~, name, ~] = this.cfg.getSourceInfo(setId, 1);
    cvTestFile = fullfile(this.testCfg.getSetValue(this.testCfg.resultPathList, setId), name, 'cv-testing.mat');
    load(cvTestFile, 'chemical');
    nAnalytes = size(chemical, 2);
    
    % process all sources
    rmseMat = nan(nSources, nSources, nAnalytes);
    snrMat = nan(nSources, nSources, nAnalytes);
    
    if this.doParfor
        parfor sourceId = 1:nSources
            [rmseMat(sourceId, :, :), snrMat(sourceId, :, :)] = this.evaluateModels(setId, sourceId); %#ok<PFOUS,PFBNS>
        end
    else
        for sourceId = 1:nSources
            [rmseMat(sourceId, :, :), snrMat(sourceId, :, :)] = this.evaluateModels(setId, sourceId);
        end
    end
    
    % save results
    save(cvPermuteFile, 'rmseMat', 'snrMat');

end

