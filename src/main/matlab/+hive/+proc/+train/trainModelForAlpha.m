function CVerr = trainModelForAlpha(voltammograms, labels, foldId, alphaRange, preprocFn, debug)
%TRAINMODELFORALPHA Summary of this function goes here
%   Detailed explanation goes here

    % check args
    narginchk(2, 6);
    
    % default alpha == LASSO
    if nargin < 4
        alphaRange = 1.0;
    end
    
    % default preprocess == diff
    if nargin < 5
        preprocFn = @(x) diff(x, 1, 1);
    end
    
    % default debug == false
    if nargin < 6
        debug = false;
    end
    
    
    % make sure dimensions are correct
    [nObvs, nAnalytes] = size(labels);    
    [nSamples, nSweeps] = size(voltammograms);
    
    if nObvs ~= nSweeps
        error('observation dimensions disagree: voltammograms[%d x %d], labels[%d x %d]', ...
            nObvs, nAnalytes, nSweeps, nSamples);
    end
    
    % create cv-folds if not passed in
    if nargin < 3
        % generate 10 randomly-selected folds
        rng(032272);
        nFolds = 10;
        foldId = randsample(...
            1:nFolds,...
            nObvs,...
            true);
    end
    
    nFolds = numel(unique(foldId));
    
    % choose family for glmnet fit
    if nAnalytes == 1
        family = 'gaussian';
    else
        family = 'mgaussian';
    end
    
    % prepare input matrix
    %  - dimensions: (glmnet) observations x variables
    X = preprocFn(voltammograms, 1)';
    
    % prepare response matrix
    %  - dimensions: (glmnet) observations x variables
    Y = labels;
    
    % train for each alpha in the range
    nAlpha = numel(alphaRange);
    
    CVerrList = cell(nAlpha, 1);
    
    for alphaIx = 1:nAlpha
        alpha = alphaRange(alphaIx);
        
        % cross validated glmnet options
        options.alpha = alpha;
        type = 'mse';
        parallel = ~debug; % if true (=1), then will run in parallel mode
        keep = false;
        grouped = true;
        
        % this could take a long time, so try it out first with a small amount of data
        CVerrList{alphaIx} = cvglmnet(X, Y, family, options, type, nFolds, foldId, parallel, keep, grouped);
        CVerrList{alphaIx}.alpha = alpha;
    end
    
    % find the mean squared cross-validated error value for each fit
    mse = cellfun(@(C) C.cvm(C.lambda == C.lambda_min), CVerrList);
    
    % find which alphaIx minimizes MSE
    [~, bestIx] = min(mse);
    
    % winner winner chicken dinner
    CVerr = CVerrList{bestIx};
end

