function [coreIx, noiseIx, borderIx, clustIx] = clusterProbes( catalog, probeList, minPoints, epsX, epsY )
%CLUSTERPROBES Summary of this function goes here
%   Detailed explanation goes here

    nProbes = length(probeList);
    
    coreIx = cell(nProbes, 1);
    noiseIx = cell(nProbes, 1);
    borderIx = cell(nProbes, 1);
    clustIx = cell(nProbes, 1);
    
    labels = readtable(catalog.labelCatalogFile, 'Delimiter', ',');
    [g, datasets] = findgroups(labels.datasetId);
    probes = splitapply(@unique, labels.probe, g);
    
    s = hgexport('readstyle', 'jpw-fig');
    s.Format = 'pdf';
    s.Height = 11;
    figs = fullfile('testing', 'figs');
    
    if ~exist(figs, 'dir')
        mkdir(figs)
    end
    
    parfor ix = 1:nProbes
        t = tic;
        fprintf('*** probe %03d/%03d... ', ix, nProbes);
        
        probe = probeList{ix};
        datasetList = unique(datasets(strcmp(probes, probe))); %#ok<PFBNS>
        
        if (numel(datasetList) > 1)
            
            [coreIx{ix}, noiseIx{ix}, borderIx{ix}, clustIx{ix}] =...
                clusterDatasets(catalog, datasetList, minPoints, epsX, epsY, strrep(probe, '_', '-'));
            
            hgexport(gcf, fullfile('testing', 'figs', sprintf('probe-cluster-%03d.pdf', ix)), s);
            close;
            
        end
        
        fprintf('DONE (%.3f sec)\n', toc(t));
    end
    
    system(sprintf([
        'find %s -maxdepth 1 -type f -name "probe-cluster-*.pdf" -print0 |',...
        'xargs -0 /opt/local/bin/join-pdf -o %s'], figs, fullfile(figs, 'probe-cluster.pdf')));
    
    system(sprintf(...
        'find %s -maxdepth 1 -type f -name "probe-cluster-*.pdf" -delete',...
        figs));
end

