classdef Importer < hive.proc.invitro.ImporterBase
    %IMPORTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
    end
    
    %
    % API
    %
    methods
        
        function this = Importer(cfg)
            this.treatment = cfg;
            this.cfg = cfg.training;
            this.actionLabel = 'Importing training';
            this.labels = readtable(this.cfg.labelCatalogFile);
        end
        
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Access = protected)
        
    end
    
end

