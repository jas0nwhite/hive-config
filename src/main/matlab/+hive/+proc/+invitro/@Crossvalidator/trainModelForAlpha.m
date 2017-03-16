function CVerr = trainModelForAlpha(this, training, alphaRange)
%TRAINMODELFORALPHA Summary of this function goes here
%   Detailed explanation goes here

    % determine if training should be monomial or multinomial
    nAnalytes = size(training.labels, 2);
    
    % cross validated glmnet options
    if nAnalytes == 1
        family = 'gaussian';
    else
        family = 'mgaussian';
    end
    
    % training data
    % training data supplied in ?training.voltammograms? variable
    % 1st dimension is observations, 2nd dimension is variables
    X = diff(training.voltammograms', 1, 2); %#ok<UDIM> % first differential along second dimension
    
    % training labels
    % training labels supplied in ?training.labels? variable
    % 1st dimension is observations, 2nd dimension is analyte concentrations
    Y = training.labels';
    
    % cross-validation folds
    rng(032272);
    nfolds = [];
    foldid = randsample(...
        1:10,...
        size(Y, 2),...
        true);
    
    % train for each alpha in the range
    nAlpha = numel(alphaRange);
    
    CVerrList = cell(nAlpha, 1);
    
    for alphaIx = 1:nAlpha
        alpha = alphaRange(alphaIx);
        
        % cross validated glmnet options
        options.alpha = alpha;
        type = 'mse';
        parallel = ~this.trainingDebug; % if true (=1), then will run in parallel mode
        keep = 0;
        grouped = 1;
        
        % this could take a long time, so try it out first with a small amount of data
        CVerrList{alphaIx} = cvglmnet(X, Y, family, options, type, nfolds, foldid, parallel, keep, grouped);
        CVerrList{alphaIx}.alpha = alpha;
    end
    
    % find the mean squared cross-validated error value for each fit
    mse = cellfun(@(C) C.cvm(C.lambda == C.lambda_min), CVerrList);
    
    % find which alphaIx minimizes MSE
    [~, bestIx] = min(mse);
    
    % winner winner chicken dinner
    CVerr = CVerrList{bestIx};
end

