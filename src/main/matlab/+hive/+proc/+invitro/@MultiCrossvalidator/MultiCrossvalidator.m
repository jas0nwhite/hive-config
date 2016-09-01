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
            nDatasets = this.cfg.getSize(this.cfg.datasetCatalog);
            
            g = tic;
            fprintf('*** ASSEMBLING %d DATASETS...\n\n', nDatasets);
            
            if this.doParfor
                parfor dsIx = 1:nDatasets
                    this.buildDataset(dsIx); %#ok<PFBNS>
                end
            else
                for dsIx = 1:nDatasets
                    this.buildDataset(dsIx);
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
                    this.generatePredictions(dsIx); %#ok<PFBNS>
                end
            else
                for dsIx = 1:nDatasets
                    this.generatePredictions(dsIx);
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
    end
    
    %
    % API (external files)
    %
    methods
        
        buildDataset(this, dsIx)
        
        trainModel(this, dsIx)
        
        generatePredictions(this, dsIx)
        
        analyzeDataset(this, dsIx)
        
        summarize(this)
            
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Access = protected)
        function this = processSource(this, ~, ~)
        end
    end
    
end

