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
            this.cfg = cfg.testing;
            this.actionLabel = 'Importing testing';
            this.labels = readtable(this.cfg.labelCatalogFile);
        end
        
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Access = protected)
        
    end
    
end

