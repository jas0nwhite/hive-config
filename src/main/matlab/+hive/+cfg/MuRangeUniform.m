classdef MuRangeUniform < hive.cfg.MuRange
    %MURANGEUNIFORM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        minMu = NaN
        maxMu = NaN
    end
    
    methods (Access = protected)
        
    end
    
    methods
        function this = MuRangeUniform(minMu, maxMu)
            this.minMu = minMu;
            this.maxMu = maxMu;
        end
        
        function ix = findCandidates(this, pop)
            ix = find(pop >= this.minMu & pop <= this.maxMu);
        end
        
        function ix = sampleIx(this, pop, k)
            % find the population index in the range
            popIx = this.findCandidates(pop);
            
            % sample the index without replacement
            % ix = randsample(popIx, k, false);
            ix = datasample(popIx, k, 'Replace', false);
        end
        
        function n = popSize(this, pop)
            n = length(this.findCandidates(pop));
        end
    end    
end

