classdef (Abstract) ProcessorBase < hive.util.Logging
    %PROCESSORBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        treatment
        cfg
        actionLabel = 'Processing'
        overwrite = false;
        doParfor = true;
        nodeId = 1;
        nodeCount = 1;
        x_cpuCount
    end
    
    %
    % PUBLIC API
    %
    methods
        
        function this = withOverwrite(this, setting)
            if nargin == 1
                setting = true;
            end
            
            this.overwrite = setting;
        end
        
        function this = inParallel(this, setting)
            if nargin == 1
                setting = true;
            end
            
            this.doParfor = setting;
        end
        
        function this = forNodeSpec( this, aNodeId, aNodeCount )
            this.nodeId = aNodeId;
            this.nodeCount = aNodeCount;
        end
        
        function this = process(this)
            if this.doParfor
                p = gcp();
                this.x_cpuCount = p.NumWorkers;
            else
                this.x_cpuCount = 0; % force parfor loops to run in workspace
            end
            
            nSets = size(this.cfg.sourceCatalog);
            
            for setIx = 1:nSets
                this.processSet(setIx)
            end
        end
        
   end
    
    %
    % INTERNAL API
    %
    methods (Access = protected)
        
        function [processList, fullList] = getDatasetIdsToProcess(this, setIx)
            fullList = vertcat(this.cfg.sourceCatalog{setIx}{:, 1});
            nodeIds = mod(fullList, this.nodeCount);
            processList = fullList(nodeIds == this.nodeId);
        end
        
        function processSet(this, setIx)
            % perform modulo-based dataset selection
            [datasetIdsToProcess, allDatasetIds] = this.getDatasetIdsToProcess(setIx);

            % convert from datasetIds to sourceIxs (within set)
            [setIxsToProcess, sourceIxsToProcess] = this.cfg.getSourceIxByDatasetId(datasetIdsToProcess);            
            assert(numel(setIxsToProcess) ~= 1 || setIxsToProcess == setIx);
            
            if iscell(sourceIxsToProcess)
                sourceIxsToProcess = cell2mat(sourceIxsToProcess);
            end
            
            this.displayProcessSetHeader(setIx, numel(sourceIxsToProcess), numel(allDatasetIds));
            
            if numel(datasetIdsToProcess) == 0
                return
            end
            
            args = this.getArgsForProcessSource(setIx);
            
            parfor (ix = 1:numel(sourceIxsToProcess), this.getNumWorkers())
                sourceIx = sourceIxsToProcess(ix);
                this.processSource(setIx, sourceIx, args{:}) %#ok<PFBNS>
            end
        end
        
        function argv = getArgsForProcessSource(~, ~)
            argv = {};
        end
        
        function displayProcessSetHeader(this, setIx, nSources, nTotalSources)
            fprintf('\n***\n*** NODE %d: %s set %d (%d / %d sources)\n***\n\n', ...
                this.nodeId, this.actionLabel, setIx, nSources, nTotalSources);
        end
        
        function numWorkers = getNumWorkers(this)
            % override for more complex processors
            numWorkers = this.x_cpuCount;
        end
            
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Abstract, Access = protected)
       
        processSource(this, setIx, sourceIx, varargin)
        
    end
    
end

