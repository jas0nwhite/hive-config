classdef Preprocessor
    %PREPROCESSOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        cfg
        labels
    end
    
    %
    % API
    %
    methods
        
        function this = Preprocessor(cfg)
            this.cfg = cfg;
            this.labels = readtable(this.cfg.training.labelCatalogFile);
        end
        
        function this = process(this)
            nSets = size(this.cfg.training.sourceCatalog);
            
            for setIx = 1:nSets
                nSources = size(this.cfg.training.sourceCatalog{setIx}, 1);
                
                for sourceIx = 1:nSources
                    this.processSource(setIx, sourceIx)
                end
            end
        end
        
        
        
    end
    
    %
    % internal API
    %
    methods (Access = protected)
        
        function processSource(this, setIx, sourceIx)
            
            
        end
        
    end
    
end

