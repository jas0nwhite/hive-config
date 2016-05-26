classdef Indexer < hive.proc.invitro.IndexerBase
    %INDEXER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
    end
    
    %
    % API
    %
    methods
        
        function this = Indexer(cfg)
            this.treatment = cfg;
            this.cfg = cfg.training;
            this.actionLabel = 'Indexing training';
            this.epsilon = [0.20, 5];
            this.minPoints = 2/3;
        end
        
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Access = protected)
        
    end
    
    
end

