classdef MultiCrossvalidator < hive.proc.ProcessorBase
    %CROSSVALIDATEMIXTURES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        testCfg
        trainingPct
        muMin
        muMax
    end
    
    %
    % API
    %
    methods
        
        function this = MultiCrossvalidator(cfg)
            this.treatment = cfg;
            this.cfg = cfg.training;
            this.testCfg = cfg.testing;
            this.actionLabel = 'Cross-validating mixtures';
            
            % defaults
            this.trainingPct = .1;
            this.muMin = -Inf;
            this.muMax = Inf;
        end
        
        function this = withTrainingPercent(this, setting)
            this.trainingPct = setting;
        end
        
        function this = withMinimum(this, setting)
            this.muMin = setting;
        end
        
        function this = withMaximum(this, setting)
            this.muMax = setting;
        end
        
        function this = process(this)
            if this.doParfor
                gcp();
            end
            
            %
            % ASSEMBLE TRAINING AND TESTING DATA
            %
            this.cfg = this.treatment.training;
            nDatasets = this.cfg.getSize(this.cfg.datasetCatalog);
            
            g = tic;
            fprintf('*** ASSEMBLING %d DATASETS...\n\n', nDatasets);
            
            if this.doParfor
                parfor dsIx = 1:nDatasets
                    this.buildDatasets(dsIx); %#ok<PFBNS>
                end
            else
                for dsIx = 1:nDatasets
                    this.buildDatasets(dsIx);
                end
            end
            
            fprintf('\n*** DONE (%.3fs)\n\n\n', toc(g));
            
            
            %
            % TRAIN
            %
            g = tic;
            
            fprintf('*** TRAINING %d MODELS...\n\n', nDatasets);
            
            for dsIx = 1:nDatasets
                this.trainModel(dsIx);
            end
            
            fprintf('\n*** DONE (%.3fs)\n\n\n', toc(g));
            
            
            %
            % TEST
            %
            g = tic;
            
            fprintf('*** TESTING %d DATASETS...\n\n', nDatasets);
            
            if this.doParfor
                parfor dsIx = 1:nDatasets
                    this.generatePredicitons(dsIx); %#ok<PFBNS>
                end
            else
                for dsIx = 1:nDatasets
                    this.generatePredicitons(dsIx);
                end
            end
            
            fprintf('\n*** DONE (%.3fs)\n\n\n', toc(g));
            
            
            %
            % ANALYZE
            %
            g = tic;
            
            fprintf('*** ANALYZING %d DATASETS...\n\n', nDatasets);
            
            if this.doParfor
                parfor dsIx = 1:nDatasets
                    this.analyzeDataset(dsIx); %#ok<PFBNS>
                end
            else
                for dsIx = 1:nDatasets
                    this.analyzeDataset(dsIx);
                end
            end
            
            fprintf('\n*** DONE (%.3fs)\n\n\n', toc(g));
        end
        
        
        function buildDatasets(this, dsIx)
            t = tic;
            
            % LOAD DATA
            [setId, sourceId] = this.cfg.getSourceIxByDatasetId(dsIx);
            [id, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
            
            importDir = fullfile(this.cfg.getSetValue(this.cfg.importPathList, setId), name);
            labelFile = fullfile(importDir, this.cfg.labelFile);
            vgramFile = fullfile(importDir, this.cfg.vgramFile);
            
            resultDir = fullfile(this.testCfg.getSetValue(this.testCfg.resultPathList, setId), name);
            cvTestFile = fullfile(resultDir, 'cv-testing.mat');
            cvTrainFile = fullfile(resultDir, 'cv-training.mat');
            
            if ~this.overwrite && exist(cvTestFile, 'file') && exist(cvTrainFile, 'file')
                fprintf('    %03d: SKIP (%.3fs)\n', id, toc(t));
                return
            end
            
            if ~exist(resultDir, 'dir')
                mkdir(resultDir);
            end
            
            dat = load(labelFile);
            all.chemicals = dat.chemicals;
            
            combos = cellfun(@(c) unique(vertcat(c(:))), dat.labels, 'unif', false);
            nCombos = size(combos, 1);
            isDoubled = nCombos == 2 * size(unique(cell2mat(dat.labels), 'rows'), 1);
            
            if (isDoubled)
                % only use even numbered steps -- fast protocol only
                stepIx = 2:2:size(dat.labels, 1);
            else
                stepIx = 1:size(dat.labels, 1);
            end
            
            all.labels = dat.labels(stepIx);
            
            dat = load(vgramFile);
            all.voltammograms = dat.voltammograms(stepIx);
            
            clear dat;
            
            % FIND TARGET ANALYTES
            muVals = vertcat(all.labels{:});
            muCount = arrayfun(@(c) numel(unique(muVals(:, c))), 1:size(muVals, 2));
            chemIx = sort(find(muCount > 1));
            
            % BUILD TRAINING AND TESTING DATASETS
            vgrams = horzcat(all.voltammograms{:});
            
            offset = 0;
            nSteps = size(all.voltammograms, 1);
            testIx = cell(nSteps, 1);
            trainIx = cell(nSteps, 1);
            
            % sample each step uniformly
            for ix = 1:size(all.voltammograms, 1)
                step = all.labels{ix};
                stepInMuRange = arrayfun(@(i) ...
                    prod(step(i, chemIx) >= this.muMin & step(i, chemIx) <= this.muMax), 1:size(step, 1));
                stepValidIx = find(stepInMuRange);
                index = offset + stepValidIx;
                
                stepN = size(step, 1);
                stepValidN = numel(stepValidIx);
                
                if (this.trainingPct >= 1)
                    if (this.trainingPct >= stepN)
                        % leave some samples left for testing
                        trainN = round(stepValidN * .9);
                    else
                        % use the specified number of samples
                        trainN = min(stepValidN, this.trainingPct);
                    end
                else
                    trainN = round(stepValidN * this.trainingPct);
                end
                
                rng(1972);
                trainIx{ix} = datasample(index, trainN, 'Replace', false);
                testIx{ix} = setdiff(index, trainIx{ix});
                
                offset = offset + stepN;
            end
            
            test.ix = vertcat(testIx{:});
            test.n = numel(test.ix);
            test.voltammograms = vgrams(:, test.ix);
            test.labels = muVals(test.ix, chemIx);
            test.chemical = all.chemicals(chemIx);
            
            save(cvTestFile, '-struct', 'test');
            
            train.ix = vertcat(trainIx{:});
            train.n = numel(train.ix);
            train.voltammograms = vgrams(:, train.ix);
            train.labels = muVals(train.ix, chemIx);
            train.chemical = all.chemicals(chemIx);
            
            save(cvTrainFile, '-struct', 'train');
            
            fprintf('    %03d: DONE (%.3fs)\n', id, toc(t));
        end
        
        
        function trainModel(this, dsIx)
            t = tic;
            
            % LOAD DATA
            [setId, sourceId] = this.cfg.getSourceIxByDatasetId(dsIx);
            [id, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
            
            resultDir = fullfile(this.testCfg.getSetValue(this.testCfg.resultPathList, setId), name);
            cvTrainFile = fullfile(resultDir, 'cv-training.mat');
            cvModelFile = fullfile(resultDir, 'cv-model.mat');
            
            if ~this.overwrite && exist(cvModelFile, 'file')
                fprintf('    %03d: SKIP (%.3fs)\n', id, toc(t));
                return
            end
            
            training = load(cvTrainFile);
            
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
            X = diff(training.voltammograms', 1, 2); %#ok<UDIM> % first differential along second dimension
            
            % training labels
            % training labels supplied in ?training.labels? variable
            % 1st dimension is observations, 2nd dimension is analyte concentrations
            Y = training.labels';
            
            % this could take a long time, so try it out first with a small amount of data
            CVerr = cvglmnet(X, Y, family, options, type, nfolds, foldid, parallel, keep, grouped); %#ok<NASGU>
            
            save(cvModelFile, 'CVerr');
            
            fprintf('    %03d: DONE (%.3fs)\n', id, toc(t));
        end
        
        
        
        
        function generatePredicitons(this, dsIx)
            t = tic;
            
            % LOAD DATA
            [setId, sourceId] = this.cfg.getSourceIxByDatasetId(dsIx);
            [id, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
            
            resultDir = fullfile(this.testCfg.getSetValue(this.testCfg.resultPathList, setId), name);
            cvTestFile = fullfile(resultDir, 'cv-testing.mat');
            cvModelFile = fullfile(resultDir, 'cv-model.mat');
            cvPredFile = fullfile(resultDir, 'cv-predictions.mat');
            
            if ~this.overwrite && exist(cvPredFile, 'file')
                fprintf('    %03d: SKIP (%.3fs)\n', id, toc(t));
                return
            end
            
            testing = load(cvTestFile);
            load(cvModelFile);
            
            % testing data
            x = diff(testing.voltammograms', 1, 2); %#ok<UDIM>
            labels = testing.labels; %#ok<NASGU>
            
            % generate predictions
            predictions = cvglmnetPredict(CVerr, x, 'lambda_min'); %#ok<NASGU>
            chemical = testing.chemical; %#ok<NASGU>
            
            save(cvPredFile, 'predictions', 'labels', 'chemical');
            
            fprintf('    %03d: DONE (%.3fs)\n', id, toc(t));
        end
        
        
        
        
        function analyzeDataset(this, dsIx)
            t = tic;
            
            % LOAD DATA
            [setId, sourceId] = this.cfg.getSourceIxByDatasetId(dsIx);
            [id, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
            
            importDir = fullfile(this.cfg.getSetValue(this.cfg.importPathList, setId), name);
            metadataFile = fullfile(importDir, this.cfg.metaFile);
            
            resultDir = fullfile(this.testCfg.getSetValue(this.testCfg.resultPathList, setId), name);
            cvStatsFile = fullfile(resultDir, 'cv-stats.mat');
            cvTrainFile = fullfile(resultDir, 'cv-training.mat');
            cvTestFile = fullfile(resultDir, 'cv-testing.mat');
            cvPredFile = fullfile(resultDir, 'cv-predictions.mat');
            
            if ~this.overwrite && exist(cvStatsFile, 'file')
                fprintf('    %03d: SKIP (%.3fs)\n', id, toc(t));
                return
            end
            
            cv = load(cvPredFile);
            testing = load(cvTestFile, 'ix');
            training = load(cvTrainFile);
            metadata = load(metadataFile);
            
            
            % stats
            labels = unique(cv.labels, 'rows', 'stable');
            
            nSteps = size(testing.ix, 1);
            nChems = size(cv.labels, 2);
            
            predRmse = nan(nSteps, nChems);
            predSnr = nan(nSteps, nChems);
            predSnre = nan(nSteps, nChems);
            
            for ix = 1:nSteps
                signal = cv.predictions(ix, :);
                truth = cv.labels(ix, :);
                noise = signal - truth;
                estimate = mean(signal);
                noiseEst = bsxfun(@minus, signal, estimate);
                
                predRmse(ix, :) = arrayfun(@(i) rms(noise(:, i)), 1:size(noise, 2));
                predSnr(ix, :) = arrayfun(@(i) snr(signal(:, i), noise(:, i)), 1:size(signal, 2));
                predSnre(ix, :) = arrayfun(@(i) snr(signal(:, i), noiseEst(:, i)), 1:size(signal, 2));
            end
            
            fSample = round(metadata.sampleFreq(1), 0);
            fSweep = round(metadata.sweepFreq(1), 0);
            
            plotT = (testing.ix - 1) / metadata.sweepFreq(1);
            
            % plot
            info = this.cfg.infoCatalog{setId}{sourceId, 2};
            probe = info.probeName;
            
            
            if (~isempty(regexp(info.protocol, '_uncorrelated_', 'once')))
                vpsString = 'random burst';
            else
                voltage = 2;
                sampleIx = this.cfg.getSetValue(this.cfg.vgramWindowList, setId);
                sampleRange = round(max(sampleIx) - min(sampleIx), -3);
                seconds = sampleRange / fSample;
                vps = round(voltage * 2 / seconds);
                vpsString = sprintf('%dV/s', vps);
            end
            
            if (~isempty(regexp(resultDir, '-shuffled', 'once')))
                vpsString = sprintf('%s (shuffled)', vpsString);
            end
            
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%
            %%% PLOT
            %%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            figure;
            
            nChem = numel(training.chemical);
            rows = 3;
            cols = nChem * 2;
            
            for chemIx = 1:nChem
                chem = Chem.get(training.chemical{chemIx});
                
                switch chem
                    case Chem.pH
                        units = '';
                    otherwise
                        units = sprintf(' (%s)', chem.units);
                end
                
                muLabel = [chem.label units];
                
                colors = lines(8);
                labColor = colors(2, :);
                colors = colors([1 4 7 8], :);
                
                col = 2 * (chemIx - 1) + 1;
                nextRow = cols;
                
                subplot(rows, cols, [col, col + 1, nextRow + col, nextRow + col + 1])
                hold on;
                title(chem.label);
                xlabel('samples');
                ylabel(muLabel);
                
                plot(plotT(:), cv.predictions(:, chemIx), '.', 'Color', colors(chemIx, :), 'MarkerSize', 10);
                for ix = 1:nSteps
                    stepX = [min(plotT(ix, :)), max(plotT(ix, :))];
                    stepY = [labels(ix, chemIx), labels(ix, chemIx)];
                    plot(stepX, stepY, 'Color', labColor);
                end
                
                axis tight;
                xl = xlim();
                yl = [this.muMin, this.muMax];
                xtwix = diff(xl) / 20;
                ytwix = diff(yl) / 20;
                
                legend({'predicted'; 'actual'}, 'Location', 'best');
                
                barX = (0:14) + 15*xtwix;
                barY = repmat(yl(1) - 2*ytwix, size(barX)); % + 2*ytwix;
                plot(barX, barY, 'k', 'LineWidth', 2);
                
                text(mean(barX), min(barY) + ytwix, '15s', 'HorizontalAlignment', 'Center', 'FontSize', 10);
                
                set(gca,'xtick',[]);
                xlim(xl + [-xtwix, +xtwix]);
                ylim(yl + [-3*ytwix, +2*ytwix]);
                axis manual;
            end
            
            
            desat = @(c) hsv2rgb(rgb2hsv(c) .* [1.0 0.3 1.2]);
            
            
            %
            % RMSE
            %
            subplot(rows, cols, (rows - 1) * cols + (1:(cols/2)));
            hold on;
            % title(sprintf('RMSE = %0.1f %s', fullRmse, chem.units));
            title('RMSE');
            xlabel(muLabel);
            ylabel(['RMSE' units]);
            
            grid on;
            xl = [this.muMin, this.muMax];
            yl = [0, max(predRmse(:))];
            xtwix = diff(xl) / 20;
            ytwix = diff(yl) / 20;
            xlim(xl + [-xtwix, +xtwix]);
            ylim(yl + [-2*ytwix, +2*ytwix]);
            axis manual;
            
            for chemIx = 1:nChem
                fullSignal = cv.predictions(:, chemIx);
                fullTruth = cv.labels(:, chemIx);
                fullNoise = fullSignal - fullTruth;
                fullRmse = rms(fullNoise);
                
                plot(xlim(), [fullRmse fullRmse], '--', 'Color', desat(colors(chemIx, :)));
            end
            
            for chemIx = 1:nChem
                y = predRmse(:, chemIx);
                x = labels(:, chemIx);
                
                plot(x, y, '.', 'MarkerSize', 25, 'Color', colors(chemIx, :));
            end
            
            
            %
            % SNR
            %
            subplot(rows, cols, (rows - 1) * cols + ((cols/2 + 1):cols));
            hold on;
            % title(sprintf('SNR = %0.1f dB', fullSnr));
            title('SNR');
            xlabel(muLabel);
            ylabel('SNR (dB)');
            
            
            grid on;
            xl = [this.muMin, this.muMax];
            yl = [0, max(predSnr(:))];
            xtwix = diff(xl) / 20;
            ytwix = diff(yl) / 20;
            xlim(xl + [-xtwix, +xtwix]);
            ylim(yl + [-2*ytwix, +2*ytwix]);
            axis manual;
            
            for chemIx = 1:nChem
                fullSignal = cv.predictions(:, chemIx);
                fullTruth = cv.labels(:, chemIx);
                fullNoise = fullSignal - fullTruth;
                fullSnr = snr(fullSignal, fullNoise);
                
                plot(xlim(), [fullSnr fullSnr], '--', 'Color', desat(colors(chemIx, :)));
            end
            
            for chemIx = 1:nChem
                x = labels(:, chemIx);
                y = predSnr(:, chemIx);
                
                plot(x(x > 0), y(x > 0), '.', 'MarkerSize', 25, 'Color', colors(chemIx, :));
            end
            
            
            
            
            
            suptitle(sprintf('probe %s  |  %s @ %dHz\n\\fontsize{8}%s  |  dataset %03d  |  set %02d  |  source %03d',...
                strrep(regexprep(probe, '[_]+', '_'), '_', '\_'), vpsString, fSweep,...
                strrep(info.protocol, '_', '\_'), dsIx, setId, sourceId));
            
            savefig(gcf, fullfile(resultDir, 'cv-plot.fig'));
            
            s = hgexport('readstyle', 'png-4MP');
            s.Format = 'png';
            s.Height = 9;
            s.Width = 12;
            s.Resolution = 200;
            hgexport(gcf, fullfile(resultDir, 'cv-plot.png'), s);
            
            s.Format = 'eps';
            hgexport(gcf, fullfile(resultDir, 'cv-plot.eps'), s);
            
            close;
            
            save(cvStatsFile, 'labels', 'predRmse', 'predSnr', 'predSnre');
            
            fprintf('    %03d: DONE (%.3fs)\n', id, toc(t));
        end
        
        
        
        
        
        
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Access = protected)
        function this = processSource(this, ~, ~)
        end
    end
    
end

