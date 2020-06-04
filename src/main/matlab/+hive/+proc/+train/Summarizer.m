classdef Summarizer < hive.proc.invitro.SummarizerBase
    %SUMMARIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
    end
    
    %
    % API
    %
    methods
        
        function this = Summarizer(cfg)
            this.treatment = cfg;
            this.cfg = cfg.training;
            this.actionLabel = 'Summarizing training';
        end
        
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Access = protected)
        
    end
    
    %
    % OVERRIDES
    %
    methods
        
        function this = summarizeTrainingProbes(this)
            % summarize training probe responses
            nSets = length(this.cfg.sourceCatalog);
            
            for setIx = 1:nSets
                t = tic;
                fprintf('\n***\n*** NODE %d: Summarizing probes in set %d\n***\n\n', ...
                    this.nodeId, setIx);
                
                hive.proc.analyze.summarizeTrainingProbeResponses(this.treatment, setIx, this.doParfor);
                
                toc(t);
            end
            
        end
        
    end
    
end

