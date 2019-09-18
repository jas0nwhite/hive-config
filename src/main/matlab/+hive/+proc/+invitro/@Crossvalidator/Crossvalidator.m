classdef Crossvalidator < hive.proc.ProcessorBase
    %CROSSVALIDATEMIXTURES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        testCfg
        trainingPct
        muMin
        muMax
        trainingDebug = false
        removeJitter = true
        processSets = true
        processSources = true
        holdOutMedianLabels = false
        preprocessor
        labelProcessor
    end
    
    %
    % API
    %
    methods
        
        function this = Crossvalidator(cfg)
            this.treatment = cfg;
            this.cfg = cfg.training;
            this.testCfg = cfg.testing;
            this.actionLabel = 'Cross-validating';
            this.preprocessor = hive.proc.train.DataPreprocessor(cfg);
            this.labelProcessor = hive.proc.model.LabelTransformer.forTrainingStyle(this.treatment.trainingStyleId);
            
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
                
        function this = withTrainingDebug(this, setting)
            if nargin == 1
                this.trainingDebug = true;
            else
                this.trainingDebug = setting;
            end
        end
        
        function this = withJitterRemoval(this, setting)
            if nargin == 1
                this.removeJitter = true;
            else
                this.removeJitter = setting;
            end
        end
        
        function this = forSourcesOnly(this)
            this.processSources = true;
            this.processSets = false;
        end
        
        function this = forSetsOnly(this)
            this.processSources = false;
            this.processSets = true;
        end
        
        function this = withMedianLabelHoldout(this, setting)
            if nargin == 1
                this.holdOutMedianLabels = true;
            else
                this.holdOutMedianLabels = setting;
            end
        end
        
        function this = process(this)
            % set up
            if this.doParfor
                p = gcp();
                this.x_cpuCount = p.NumWorkers;
            else
                this.x_cpuCount = 0; % force parfor loops to run in workspace
            end
            
            % perform modulo-based dataset selection
            nFull = this.cfg.getSize(this.cfg.datasetCatalog);
            fullList = 1:nFull;
            nodeIds = mod(fullList, this.nodeCount);
            processList = fullList(nodeIds == this.nodeId);
            nDatasets = numel(processList);
            
            if nDatasets == 0
                fprintf('*** NODE %d: NO DATASETS\n\n', this.nodeId);
                return
            end
            
            %
            % ASSEMBLE TRAINING AND TESTING DATA
            %
            if this.processSources
                g = tic;
                
                fprintf('*** NODE %d: ASSEMBLING %d DATASETS...\n\n', this.nodeId, nDatasets);
                
                parfor (ix = 1:nDatasets, this.getNumWorkers())
                    this.buildDataset(processList(ix)); %#ok<PFBNS>
                end
                
                fprintf('\n*** DONE (%.3fs)\n\n\n', toc(g));
            else
                fprintf('*** NODE %d: SKIP ASSEMBLE DATASETS (forSetsOnly)\n\n', this.nodeId);
            end
            
            
            %
            % TRAIN
            %
            if this.processSources
                g = tic;
                
                % here, trainModel() uses parfor, so we can't
                fprintf('*** NODE %d: TRAINING %d MODELS...\n\n', this.nodeId, nDatasets);
                
                for ix = 1:nDatasets
                    this.trainModel(processList(ix));
                end
                
                fprintf('\n*** DONE (%.3fs)\n\n\n', toc(g));
            else
                fprintf('*** NODE %d: SKIP TRAIN MODELS (forSetsOnly)\n\n', this.nodeId);
            end
            
            
            %
            % TEST
            %
            if this.processSources
                g = tic;
                
                fprintf('*** NODE %d: TESTING %d DATASETS...\n\n', this.nodeId, nDatasets);
                
                parfor (ix = 1:nDatasets, this.getNumWorkers())
                    this.generatePredictions(processList(ix)); %#ok<PFBNS>
                end
                
                fprintf('\n*** DONE (%.3fs)\n\n\n', toc(g));
            else
                fprintf('*** NODE %d: SKIP TEST DATASETS (forSetsOnly)\n\n', this.nodeId);
            end
            
            
            %
            % ANALYZE
            %
            if this.processSources
                g = tic;
                
                fprintf('*** NODE %d: ANALYZING %d DATASETS...\n\n', this.nodeId, nDatasets);
                
                parfor (ix = 1:nDatasets, this.getNumWorkers())
                    this.analyzeDataset(processList(ix)); %#ok<PFBNS>
                end
                
                fprintf('\n*** DONE (%.3fs)\n\n\n', toc(g));
            else
                fprintf('*** NODE %d: SKIP ANALYZE DATASETS (forSetsOnly)\n\n', this.nodeId);
            end
            
            
            %
            % EVALUATE MODELS
            %            
            if this.processSets
                g = tic;
                
                nSets = size(this.cfg.sourceCatalog, 1);
                
                fprintf('*** NODE %d: CROSS-EVALUATING %d SETS...\n\n', this.nodeId, nSets);
                
                for setId = 1:nSets
                    this.evaluateAllModels(setId);
                end
                
                fprintf('\n*** DONE (%.3fs)\n\n\n', toc(g));
            else
                fprintf('*** NODE %d: SKIP CROSS-EVALUATE SETS (forSourcesOnly)\n\n', this.nodeId);
            end
            
            
        end
    end
    
    %
    % API (external files)
    %
    methods
        
        buildDataset(this, ix)
        
        trainModel(this, ix)
        
        generatePredictions(this, ix)
        
        analyzeDataset(this, ix)
        
        summarize(this)
        
        evalutateAllModels(this, setId)
        
        results = evaluateModels(this, setId, sourceId)
        
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Access = protected)
        function this = processSource(this, ~, ~)
        end
    end
    
end

