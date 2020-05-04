function V = correctUnderflowClipping(V, dim, posthresh, negthresh)
    %CORRECTUNDERFLOWCLIPPING Summary of this function goes here
    %   Detailed explanation goes here

    % default values
    if nargin < 4
        negthresh = -3800;
    end
    
    if nargin < 3
        posthresh = 3800;
    end
    
    if nargin < 2
        dim = 1;
    end
    
    % check arguments
    validateattributes(V, {'double'}, {'2d'}, 1);
    validateattributes(dim, {'double'}, {'scalar', 'positive', 'integer'}, 2);
    validateattributes(posthresh, {'double'}, {'scalar'}, 3);
    validateattributes(negthresh, {'double'}, {'scalar'}, 4);
    
    % use the diff to find underflow
    D = diff(V, 1, dim);
    
    % start of underflow is where diff is < negthresh
    S = find(D < negthresh);
    
    % end of underflow is where diff > posthresh
    E = find(D > posthresh);
    
    % check to see we have the same number of entries in S and E
    if numel(S) ~= numel(E)
        fprintf(' -- no undeflow correction (%d S, %d E) -- ', numel(S), numel(E));
        return
    end
    
    % since S and E are in terms of diff, we need to identify the sweep
    % number to adjust the positions in terms of V
    sweep = floor(S ./ size(D, dim));
    
    % start of correction is one sample after S + sweep correction
    S = S + 1 + sweep;
    
    % end of correction is sample S + sweep correction
    E = E + sweep;
    
    % perform correction
    for ix = 1:numel(sweep)
        V(S(ix):E(ix)) = 2000;
    end
end

