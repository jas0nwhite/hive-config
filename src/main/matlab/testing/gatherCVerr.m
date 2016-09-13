function [ CVerr, labels, chemicals, betas ] = gatherCVerr( cfg )
%GATHERCVERR Summary of this function goes here
%   Detailed explanation goes here
    %%
    nSets = size(cfg.training.sourceCatalog, 1);
    
    CVerr = cell(nSets, 1);
    labels = cell(nSets, 1);
    chemicals = cell(nSets, 1);
    betas = cell(nSets, 1);
    
    %%
    for setIx = 1:nSets
        %%
        nDatasets = size(cfg.training.sourceCatalog{setIx}, 1);
        modelPath = cfg.testing.resultPathList{setIx};
        
        CVerr{setIx} = cell(nDatasets, 1);
        labels{setIx} = cell(nDatasets, 1);
        chemicals{setIx} = cell(nDatasets, 1);
        betas{setIx} = cell(nDatasets, 2);
        
        %%
        for sourceIx = 1:nDatasets
            %%
            [~, name, ~] = cfg.training.getSourceInfo(setIx, sourceIx);
            
            modelFile = fullfile(modelPath, name, 'cv-model.mat');
            trainingFile = fullfile(modelPath, name, 'cv-training.mat');
            
            model = load(modelFile);
            CVerr{setIx, sourceIx} = model.CVerr;
            betas{setIx, sourceIx} = cvglmnetCoef(model.CVerr, 'lambda_min');
            
            info = load(trainingFile, 'labels', 'chemical');
            labels{setIx, sourceIx} = unique(info.labels, 'rows');
            chemicals{setIx, sourceIx} = info.chemical;
            
        end
        
    end

end

