function clusterIndex = clusterCVerrBetas( CVerrList )
%CLUSTERCVERRBETAS Summary of this function goes here
%   Detailed explanation goes here

    %% BUILD BETA MATRICES
    nSets = size(CVerrList, 1);
    
    for setIx = 1:nSets
        nSources = size(CVerrList(setIx, :), 2);
        
        peek = cvglmnetCoef(CVerrList{setIx, 1}, 'lambda_min');
        nAnalytes = size(peek, 2);
        nCoefs = size(peek{1}, 1);
        
        X = nan(nSources, nAnalytes * (nCoefs - 1));
        
        for sourceIx = 1:nSources
            c = cvglmnetCoef(CVerrList{setIx, sourceIx}, 'lambda_min');
            betas = arrayfun(@(i) c{i}(2:nCoefs), 1:nAnalytes, 'unif', false);
            X(sourceIx, :) = vertcat(betas{:});
        end
    end
    
    %% BUILD HIERARCHICHAL CLUSTER
    Y = pdist(X);
    Z = linkage(Y);
    figure;
    dendrogram(Z, nSources);

end

