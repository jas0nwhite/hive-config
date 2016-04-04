function [coreIx, noiseIx, borderIx, clustIx] = characterizeAll(catalog, epsPct, minPointsPct)

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
    
    argCount = nargin;
      
    parfor datasetIx = 1:nDatasets
        t = tic;
        fprintf('*** dataset %03d/%03d... ', datasetIx, nDatasets);
        
        if argCount == 3
            [coreIx{datasetIx}, noiseIx{datasetIx}, borderIx{datasetIx}, clustIx{datasetIx}] = ...
                characterizeDataset(catalog, datasetIx, epsPct, minPointsPct);
        else
            [coreIx{datasetIx}, noiseIx{datasetIx}, borderIx{datasetIx}, clustIx{datasetIx}] = ...
                characterizeDataset(catalog, datasetIx, epsPct);
        end
        
        hgexport(gcf, fullfile('testing', 'figs', sprintf('characterization-%03d.pdf', datasetIx)), s);
        close;
        
        fprintf('DONE (%.3f sec)\n', toc(t));
    end

    system(sprintf([
        'find %s -maxdepth 1 -type f -name "characterization-*.pdf" -print0 |',...
        'xargs -0 /opt/local/bin/join-pdf -o %s'], figs, fullfile(figs, 'characterization.pdf')));
    
    system(sprintf(...
        'find %s -maxdepth 1 -type f -name "characterization-*.pdf" -delete',...
        figs));
end