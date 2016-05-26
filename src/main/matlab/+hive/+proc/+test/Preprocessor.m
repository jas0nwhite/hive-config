classdef Preprocessor < hive.proc.PreprocessorBase
    %PREPROCESSOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
    end
    
    %
    % API
    %
    methods
        
        function this = Preprocessor(cfg)
            this.treatment = cfg;
            this.cfg = cfg.testing;
            this.actionLabel = 'Preprocessing testing';
            this.labels = readtable(this.cfg.labelCatalogFile);
        end
        
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Access = protected)
        
    end
    
end

