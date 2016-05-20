function clusterAndPlot(catalog, id)
%CLUSTERANDPLOT Summary of this function goes here
%   Detailed explanation goes here

    if nargin < 2
        id = 1:sum(arrayfun(@(c) length(c{1}), catalog.sourceCatalog));
    end
    
    parfor ix = 1:numel(id)
        doClusterAndPlot(catalog, id(ix));
    end
end

function doClusterAndPlot(catalog, id)
    t = tic;
    [setIx, sourceIx] = catalog.getSourceIxByDatasetId(id);
    [~, name, ~] = catalog.getSourceInfo(setIx, sourceIx);
    
    dataDir = fullfile(catalog.resultPathList{setIx}, name);
    
    charFile = fullfile(dataDir, catalog.characterizationFile);
    
    
    ch = load(charFile);
    values = vertcat(ch.vgramChar{:});
    summaryValues = cell2mat(cellfun(@(v) median(v, 1), ch.vgramChar, 'UniformOutput', false));
    
    eps1 = [0.50, 25.0];
    pts1 = 450;
    
    eps2 = [0.15, 4];
    pts2 = 100;
    
    
    f = hgexport('readstyle', 'Default');
    f.format = 'pdf';
    f.Width = 8.5;
    f.Height = 11;
    % f.FontMode = 'scaled';
    % f.LineMode = 'scaled';
    
    fig = figure;
    subplot(2, 2, [1, 2]);
    cluster = hive.proc.cluster.DBSCAN.cluster(summaryValues, 3, eps1);
    cluster.plot2D('time (µs)', 'current (nA)', gca);
    xl = xlim;
    xlim([min(xl) - diff(xl)/2, max(xl) + diff(xl)/2]);
    
    subplot(2, 2, 3);
    
    cluster = hive.proc.cluster.DBSCAN.cluster(values, pts1, eps1);
    cluster.plot2D('time (µs)', 'current (nA)', gca);
    
    subplot(2, 2, 4);

    cluster = hive.proc.cluster.DBSCAN.cluster(values, pts2, eps2);
    cluster.plot2D('time (µs)', 'current (nA)', gca);


    suptitle(sprintf('dataset #%d: %s', id, strrep(name, '_', '-')));
    
    hgexport(fig, fullfile(dataDir, 'vgram-cluster.pdf'), f);
    close;
    
    fprintf('*** dataset %d %0.3fms\n', id, 1e3 * toc(t));

end

