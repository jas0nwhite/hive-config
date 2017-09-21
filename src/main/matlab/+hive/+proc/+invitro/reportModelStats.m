function [ report ] = reportModelStats( cfg )
%REPORTMODELSTATS Summary of this function goes here
%   Detailed explanation goes here
    
    nDatasets = cfg.training.getSize(cfg.training.datasetCatalog);
    columns = {'datasetId', 'treatment', 'chem', 'probe', 'alpha', 'lambda_min', 'cv_rmse', 'n', 'rmse', 'snr', 'snr_apparent'};
    nColumns = numel(columns);
    reportData = cell(0, nColumns);
    
    for dsIx = 1:nDatasets
        [setId, sourceId] = cfg.training.getSourceIxByDatasetId(dsIx);
        [datasetId, name, ~] = cfg.training.getSourceInfo(setId, sourceId);
        info = cfg.training.infoCatalog{setId}{sourceId, 2};
        [~, treatment, ~] = fileparts(cfg.testing.getSetValue(cfg.testing.resultPathList, setId));
        
        resultDir = fullfile(cfg.testing.getSetValue(cfg.testing.resultPathList, setId), name);
        cvStatsFile = fullfile(resultDir, 'cv-stats.mat');
        cvModelFile = fullfile(resultDir, 'cv-model.mat');
        
        cvModel = load(cvModelFile);
        cvStats = load(cvStatsFile);
        
        for chemIx = 1:numel(cvStats.chems)
            chem = cvStats.chems{chemIx};
            if ~isempty(info.probeName)
                probe = info.probeName;
            else
                probe = info.acqDate;
            end
            alpha = cvModel.CVerr.alpha;
            lambda_min = cvModel.CVerr.lambda_min;
            cv_rmse = sqrt(cvModel.CVerr.cvm(cvModel.CVerr.lambda == lambda_min));
            n = sum(cvStats.forChem(chemIx).n);
            rmse = cvStats.fullRmse(chemIx);
            snr = cvStats.fullSnr(chemIx);
            snr_apparent = cvStats.fullSnre(chemIx);
            
            reportData(end + 1, :) = {
                datasetId, treatment, chem, probe, alpha, lambda_min, cv_rmse, n, rmse, snr, snr_apparent
                }; %#ok<AGROW>
        end
    end

    report = cell2table(reportData, 'VariableNames', columns);
end

