function [coreIx, noiseIx, borderIx, clustIx] = characterizeAll(catalog, epsPct, minPoints)

    nDatasets = sum(cellfun(@(c) length(c), catalog.datasetCatalog));
    coreIx = cell(nDatasets, 1);
    noiseIx = cell(nDatasets, 1);
    borderIx = cell(nDatasets, 1);
    clustIx = cell(nDatasets, 1);
    
    s = hgexport('readstyle', 'jpw-fig');
    s.Format = 'pdf';
    s.Height = 11;
    figs = fullfile('testing', 'figs');
    
    if ~exist(figs, 'dir')
        mkdir(figs)
    end
    
    for datasetIx = 1:nDatasets
        if nargin == 3
            [coreIx{datasetIx}, noiseIx{datasetIx}, borderIx{datasetIx}, clustIx{datasetIx}] = ...
                characterizeDataset(catalog, datasetIx, epsPct, minPoints);
        else
            [coreIx{datasetIx}, noiseIx{datasetIx}, borderIx{datasetIx}, clustIx{datasetIx}] = ...
                characterizeDataset(catalog, datasetIx, epsPct);
        end
        
        drawnow;
        hgexport(gcf, fullfile('testing', 'figs', sprintf('characterization-%03d.pdf', datasetIx)), s);
        close;
    end

    system(sprintf([
        'find %s -type f -name "characterization-*.pdf" -print0 |',...
        'xargs -0 /opt/local/bin/join-pdf -o %s'], figs, fullfile(figs, 'characterization.pdf')));
end