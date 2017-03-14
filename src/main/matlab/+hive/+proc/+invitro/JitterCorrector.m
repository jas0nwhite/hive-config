classdef JitterCorrector
    %JITTERCORRECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        examWindow = 1:10
        maxLag = 3
    end
    
    %
    % API
    %
    methods
        function this = withExamWindow(this, range)
            this.examWindow = range;
        end
        
        function this = withMaxLag(this, lag)
            this.maxLag = lag;
        end
        
        function lags = getLags(this, voltammograms)
            nVgrams = size(voltammograms, 2);            
            medianVgram = median(voltammograms, 2);
            
            lags = nan(nVgrams, 1);
            
            for i = 1:nVgrams
                lags(i) = this.getOffset(medianVgram, voltammograms(:, i));
            end
        end
        
        function offset = getOffset(this, x, y)
            nSteps = 2 * this.maxLag + 1;
            winSize = length(this.examWindow);
            distances = nan(nSteps, 1);
            
            xStart = 1;
            yStart = 1 + this.maxLag;
            
            for step = 1:nSteps
                xEnd = xStart + winSize - 1;
                yEnd = yStart + winSize - 1;
                xx = x(xStart:xEnd);
                yy = y(yStart:yEnd);
                
                distances(step) = sum((xx - yy).^2);
                
                if (yStart > 1)
                    yStart = yStart - 1;
                else
                    xStart = xStart + 1;
                end
            end
            
            [~, step] = min(distances);
            
            offset = (step - 1) - this.maxLag;
        end
            
    end
    
end

