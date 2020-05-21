classdef KneeCharacterizer < hive.proc.invitro.CharacterizerBase
    %CHARACTERIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        
    end
    
    %
    % API
    %
    methods
        function this = KneeCharacterizer(cfg)
            this.treatment = cfg;
            this.cfg = cfg.testing;
            this.actionLabel = 'Characterizing testing';
            this.characterizer = @hive.proc.analyze.findTriangleKnee;
        end
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Access = protected)
        function c = processStep(this, vgrams)
            nVgrams = size(vgrams, 2);
            
            c = nan(nVgrams, 2);
            
            for vgramIx = 1:nVgrams
                [x, y] = this.characterizer(vgrams(:, vgramIx));
                c(vgramIx, :) = [x, y];
            end
        end
    end
    
end

