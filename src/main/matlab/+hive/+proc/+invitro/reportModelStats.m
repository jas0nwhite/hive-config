function [ report ] = reportModelStats( cfg )
%REPORTMODELSTATS Summary of this function goes here
%   Detailed explanation goes here
    %%
    nDatasets = cfg.training.getSize(cfg.training.datasetCatalog);
    columns = {'datasetId', 'treatment', 'chem', 'probe', 'alpha', 'lambda_min', 'cv_rmse', 'n', 'rmse', 'snr', 'snr_apparent'};
    nColumns = numel(columns);
    reportData = cell(nDatasets, nColumns);
    %%
    parfor dsIx = 1:nDatasets
        %%
        [setId, sourceId] = cfg.training.getSourceIxByDatasetId(dsIx); %#ok<PFBNS>
        [datasetId, name, ~] = cfg.training.getSourceInfo(setId, sourceId);
        info = cfg.training.infoCatalog{setId}{sourceId, 2};
        
        resultDir = fullfile(cfg.testing.getSetValue(cfg.testing.resultPathList, setId), name);
        cvStatsFile = fullfile(resultDir, 'cv-stats.mat');
        cvModelFile = fullfile(resultDir, 'cv-model.mat');
        
        cvModel = load(cvModelFile);
        cvStats = load(cvStatsFile);
        
        [~, treatment, ~] = fileparts(cfg.testing.getSetValue(cfg.testing.resultPathList, setId));
        chem = info.analyteClass;
        probe = info.probeName;
        alpha = cvModel.CVerr.alpha;
        lambda_min = cvModel.CVerr.lambda_min;
        cv_rmse = sqrt(cvModel.CVerr.cvm(cvModel.CVerr.lambda == lambda_min));
        n = sum(cvStats.n);        
        rmse = cvStats.fullRmse;
        snr = cvStats.fullSnr;
        snr_apparent = cvStats.fullSnre;
        
        reportData(dsIx, :) = {datasetId, treatment, chem, probe, alpha, lambda_min, cv_rmse, n, rmse, snr, snr_apparent};
    end

    report = cell2table(reportData, 'VariableNames', columns);
end

