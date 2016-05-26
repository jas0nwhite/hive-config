classdef (Abstract) ProcessorBase < hive.util.Logging
    %PROCESSORBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        treatment
        cfg
        actionLabel = 'Processing'
        overwrite = false;
        doParfor = true;
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
        
        function this = process(this)
            if this.doParfor
                gcp();
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
        
        function processSet(this, setIx)
            nSources = size(this.cfg.sourceCatalog{setIx}, 1);
            
            this.displayProcessSetHeader(setIx, nSources);
            
            args = this.getArgsForProcessSource(setIx);
            
            if this.doParfor
                parfor sourceIx = 1:nSources
                    this.processSource(setIx, sourceIx, args{:}) %#ok<PFBNS>
                end
            else
                for sourceIx = 1:nSources
                    this.processSource(setIx, sourceIx, args{:})
                end
            end
        end
        
        function argv = getArgsForProcessSource(~, ~)
            argv = {};
        end
        
        function displayProcessSetHeader(this, setIx, nSources)
            fprintf('\n***\n*** %s set %d (%d sources)\n***\n\n', this.actionLabel, setIx, nSources);
        end
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Abstract, Access = protected)
       
        processSource(this, setIx, sourceIx, varargin)
        
    end
    
end

