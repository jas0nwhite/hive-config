function clusterAndPlot(catalog, id)
%CLUSTERANDPLOT Summary of this function goes here
%   Detailed explanation goes here

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
    
    figure;
    subplot(2, 2, [1, 2]);
    s = hive.proc.cluster.DBSCAN.cluster(summaryValues, 3, eps1);
    s.plot2D('time (µs)', 'current (nA)', gca);
    xl = xlim;
    xlim([min(xl) - diff(xl)/2, max(xl) + diff(xl)/2]);
    
    subplot(2, 2, 3);
    
    s = hive.proc.cluster.DBSCAN.cluster(values, pts1, eps1);
    s.plot2D('time (µs)', 'current (nA)', gca);
    
    subplot(2, 2, 4);

    s = hive.proc.cluster.DBSCAN.cluster(values, pts2, eps2);
    s.plot2D('time (µs)', 'current (nA)', gca);


    suptitle(sprintf('dataset #%d: %s', id, strrep(name, '_', '-')));
end

