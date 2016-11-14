function [ voltammograms, labels, chemicals ] = gatherCVTesting( cfg )
%GATHERCVTESTING Summary of this function goes here
%   Detailed explanation goes here
    %%
    nSets = size(cfg.training.sourceCatalog, 1);
    
    voltammograms = cell(nSets, 1);
    labels = cell(nSets, 1);
    chemicals = cell(nSets, 1);
    
    %%
    for setIx = 1:nSets
        %%
        nDatasets = size(cfg.training.sourceCatalog{setIx}, 1);
        modelPath = cfg.testing.resultPathList{setIx};
        
        voltammograms{setIx} = cell(nDatasets, 1);
        labels{setIx} = cell(nDatasets, 1);
        chemicals{setIx} = cell(nDatasets, 1);
        
        %%
        for sourceIx = 1:nDatasets
            %%
            [~, name, ~] = cfg.training.getSourceInfo(setIx, sourceIx);
            
            testingFile = fullfile(modelPath, name, 'cv-testing.mat');
            data = load(testingFile);
            
            voltammograms{setIx, sourceIx} = data.voltammograms;
            labels{setIx, sourceIx} = data.labels;
            chemicals{setIx, sourceIx} = data.chemical;
            
        end
        
    end

end

