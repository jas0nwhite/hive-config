classdef JitterCorrector
    %JITTERCORRECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        examWindow = 1:10
        maxLag = 3
        jitterRemoveOffsets = [0 1]
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
        
        function this = withJitterRemoveOffsets(this, vec)
            this.jitterRemoveOffsets = vec;
        end
        
        function clean = removeJitter(this, voltammograms)
            nVgrams = size(voltammograms, 2);
            
            % find lags with respect to median voltammogram
            lags = this.getLags(voltammograms);
            
            % jittered voltammograms are those with non-zero lag
            ixJitter = find(lags ~= 0);
            
            % find voltammograms to remove by applying jitterRemoveOffsets
            ixToRemove = arrayfun(@(i) ixJitter + i, this.jitterRemoveOffsets, 'UniformOutput', false);
            ixToRemove = horzcat(ixToRemove{:});
            
            % keep array indices in bounds
            ixToRemove = ixToRemove(ixToRemove >= 1 & ixToRemove <= nVgrams);
            
            % return cleaned copy of voltammograms
            clean = voltammograms;
            clean(:, ixToRemove) = nan;
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
            % number of lags to test (one per step)
            nSteps = 2 * this.maxLag + 1;
            
            % comparison window
            winSize = length(this.examWindow);
            
            distances = nan(nSteps, 1);
            
            % starting indices (for -maxLag)
            xStart = 1;
            yStart = 1 + this.maxLag;
            
            for step = 1:nSteps
                % extract for comparison
                xEnd = xStart + winSize - 1;
                yEnd = yStart + winSize - 1;
                xx = x(xStart:xEnd);
                yy = y(yStart:yEnd);
                
                % calculate distance
                distances(step) = sum((xx - yy).^2);
                
                % modify offset for next iteration
                if (yStart > 1)
                    yStart = yStart - 1;
                else
                    xStart = xStart + 1;
                end
            end
            
            % the step that produces the minimum distance indicates the offset
            [~, step] = min(distances);
            
            offset = (step - 1) - this.maxLag;
        end
        
    end
    
end

