classdef MuRangeNormal < hive.cfg.MuRange
    %MURANGENORMAL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mu = NaN;
        sigma = NaN;
    end
    
    methods
        function this = MuRangeNormal(mu, sigma)
            this.mu = mu;
            this.sigma = sigma;
        end
        
        function ix = sampleIx(this, pop, k)
            % find the weights
            w = normpdf(pop, this.mu, this.sigma);
            
            % find the population index (easy)
            popIx = 1:length(pop);
            
            % sample the index without replacement
            % ix = randsample(popIx, k, true, w);
            ix = datasample(popIx, k, 'Replace', false, 'Weights', w);
        end
    end 
end

