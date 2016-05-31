classdef (Abstract) MuRange
    %MURANGE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Abstract)
        sampleIx(this, pop, k)
    end
    
    methods
        function s = sample(this, pop, k)
            % get the index of the sample and return the values
            ix = this.sampleIx(pop, k);
            s = pop(ix);
        end
    end
    
end

