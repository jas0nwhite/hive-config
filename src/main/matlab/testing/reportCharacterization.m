function report = reportCharacterization(catalog, coreIxList, noiseIxList, borderIxList, clusterIxList)
    
    labels = readtable(catalog.labelCatalogFile);

    nDatasets = length(clusterIxList);
    
    report = cell(0);
    
    for datasetIx = 1:nDatasets
        
        coreIx = coreIxList{datasetIx};
        noiseIx = noiseIxList{datasetIx};
        borderIx = borderIxList{datasetIx};
        clusterIx = clusterIxList{datasetIx};
        dsLabels = labels(labels.datasetId == datasetIx, :);
        
        nSteps = length(clusterIx);        
        clusteredIx = sort([coreIx; borderIx]);
        
        % nClusters = length(unique(clusterIx(clusterIx > 0)));
        %
        % if (nClusters == 1 && isempty(noiseIx))
        %     fprintf('*** dataset %d has one cluster with no outliers\n', datasetIx);
        %     continue;
        % end
        
        borderTF = false(nSteps, 1);
        noiseTF = false(nSteps, 1);
        cluster = nan(nSteps, 1);
        
        borderTF(borderIx) = true;
        noiseTF(noiseIx) = true;
        cluster(clusteredIx) = clusterIx(clusteredIx);
        
        T2 = table(borderTF, noiseTF, cluster, 'VariableNames', {'border', 'noise', 'cluster'});
        T1 = dsLabels(:, 1:2);
        T3 = dsLabels(:, 3:end);
        
        report{length(report) + 1} = [T1, T2, T3];
    end

    report = vertcat(report{:});
end