%
% usage can be found by typing ?doc cvglmnet? in Matlab
%

% start up parallel
gcp();

% loop over all targets
tcfg = cfg.testing;

nSets = length(tcfg.datasetCatalog);
nDatasets = tcfg.getSize(tcfg.datasetCatalog);

for setIx = 1:nSets
    nSources = length(tcfg.datasetCatalog{setIx});
    
    for sourceIx = 1:nSources
        [id, name , ~] = tcfg.getSourceInfo(setIx, sourceIx);
        
        fprintf('*** dataset %03d/%03d... ', id, nDatasets);
        
        %
        % TRAINING
        %
        % load data
        targetPath = tcfg.getSetValue(tcfg.resultPathList, setIx);
        targetDir = fullfile(targetPath, name);
        modelFile = fullfile(targetDir, 'CVerr.mat');
        
        if ~exist(modelFile, 'file')
            training = load(fullfile(targetDir, tcfg.trainingDataFile));
            
            % cross validated glmnet options
            options.alpha = 1.0; % LASSO - to optimize, use 0:.1:1 in a loop
            family = 'mgaussian';
            type = 'mse';
            nfolds = 10; % when finding best alpha, set this to []
            foldid = []; % when finding best alpha, set this to a precalculated list of fold ids
            parallel = 1; % if true (=1), then will run in parallel mode
            keep = 0;
            grouped = 1;
            
            % training data
            % training data supplied in ?training.voltammograms? variable
            % 1st dimension is observations, 2nd dimension is variables
            X = diff(training.voltammograms', 1, 2); % first differential along second dimension
            
            % training labels
            % training labels supplied in ?training.labels? variable
            % 1st dimension is observations, 2nd dimension is analyte concentrations
            Y = training.labels';
            
            % this could take a long time, so try it out first with a small amount of data
            t = tic;
            CVerr = cvglmnet(X, Y, family, options, type, nfolds, foldid, parallel, keep, grouped);
            fprintf('TRAINING COMPLETE (%.3fs)\n', toc(t));
            
            save(modelFile, 'CVerr');
        else
            load(modelFile);
            fprintf('TRAINING DATA LOADED\n');
        end
        
        
        %
        % TESTING
        %
        predictionFile = fullfile(targetDir, tcfg.predictionFile);
        
        if ~exist(predictionFile, 'file')
            % load data
            sourcePath = tcfg.getSetValue(tcfg.importPathList, setIx);
            sourceDir = fullfile(sourcePath, name);
            
            testing = load(fullfile(sourceDir, tcfg.labelFile));
            load(fullfile(sourceDir, tcfg.vgramFile));
            testing.voltammograms = voltammograms;
            clear voltammograms;
            
            % testing data
            x = diff(horzcat(testing.voltammograms{:})', 1, 2);
            labels = vertcat(testing.labels{:});
            
            % generate predictions
            predictions = cvglmnetPredict(CVerr, x, 'lambda_min');
            chemicals = testing.chemicals;
            
            save(predictionFile, 'predictions', 'labels', 'chemicals');
        else
            load(predictionFile);
        end
        
        
        % plot
        
        % find bad samples to ignore
        load(fullfile(targetDir, tcfg.clusterIndexFile));
        
        nSteps = length(stepClusters);
        nSamples = sum(cellfun(@(s) size(s.levels, 1), stepClusters));
        
        plotX = 1:nSamples;
        plotTf = true(nSamples, 1);
        offset = 0;
        
        for stepIx = 1:nSteps
            step = stepClusters{stepIx};
            
            nStepSamples = size(step.levels, 1);
            
            if (ismember(stepIx, datasetCluster.noiseIx))
                plotTf((offset + 1):(offset + nStepSamples)) = false;
            else
                plotTf(offset + step.noiseIx) = false;
            end
            
            offset = offset + nStepSamples;
        end
        
        
        figure;
        
        for chemIx = 1:Chem.count
            chem = Chem.get(chemIx);
            
            subplot(3, 1, chemIx);
            hold on;
            plot(plotX(plotTf), round(predictions(plotTf, chemIx), 4), '.');
            plot(plotX(plotTf), labels(plotTf, chemIx), '.');
            grid on;
            
            title(chem.name);
            xlabel('sample #');
            
            switch Chem.get(chemIx)
                case Chem.pH
                    ylab = 'pH';
                otherwise
                    ylab = sprintf('%s (%s)', chem.label, chem.units);
            end
            
            ylabel(ylab);
            
            axis tight;
            
            yMin = min(labels(plotTf, chem));
            yMax = max(labels(plotTf, chem));
            yRng = yMax - yMin;
            yPad = 0.25 * yRng;
            if (yMin ~= yMax)
                ylim([yMin - yPad, yMax + yPad]);
            end
        end
        
        suptitle(strrep(name, '_', '\_'));
        
        s = hgexport('readstyle', 'Default');
        s.Height = 11;
        s.Width = 8.5;
        s.ScaledFontSize = 'auto';
        s.ScaledLineWidth = 'auto';
        s.Format = 'pdf';
        
        hgexport(gcf, fullfile(targetDir, 'predictions.pdf'), s);
        
        close;
        
    end
    
end