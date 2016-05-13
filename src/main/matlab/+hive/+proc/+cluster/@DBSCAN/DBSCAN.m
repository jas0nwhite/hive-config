classdef DBSCAN < hive.util.Logging
    %DBSCAN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function [coreIx, noiseIx, borderIx, clustIx] = cluster(values, minPoints, epsilonVector)
            
            coreIx = [];
            noiseIx = [];
            borderIx = [];
            clustIx = [];
            
            [nValues, nDims] = size(values);
            
            % if there are no values to cluster, we're done
            if (nValues == 0)
                return
            end
            
            % if there are no dimensions, we're done
            if (nDims == 0)
                return
            end
            
            % the length of the epsilon vector must equal the number of dimensions
            if (length(epsilonVector) ~= nDims)
                warning('values(%dx%d) / epsilonVector(%d) mismatch', size(values), length(epsilonVector));
                return
            end
            
            % negative or zero minpoints is not allowed
            if (minPoints <= 0)
                warning('minPoints must be positive and non-zero');
                return
            end
            
            % if minPoints < 1, assume it's a percentage
            if (minPoints < 1)
                minPoints = ceil(minPoints * nValues);
            end
            
            %
            % we need to normalize the data in order to support multiple
            % dimensions
            %
            
            % find the mean of each dimension
            valueMeans = nan(nDims, 1);
            
            for dimIx = 1:nDims
                valueMeans(dimIx) = mean(values, dimIx);
            end
            
            %%
            %% STOPPED HERE
            %%
            
            eps = 1;
            
            normX = (x - mean(x)) / epsX;
            normY = (y - mean(y)) / epsY;
            
            normXY = horzcat(normX, normY);
            
            [clustIx, lc] = dbscan(normXY, eps, minPoints);
            
            coreIx = find(lc > 0);
            noiseIx = find(lc == -1);
            borderIx = find(lc == -2);
            clusteredIx = sort(union(coreIx, borderIx));
            nClust = length(unique(clustIx(coreIx)));
            
            scanMat = cell2mat(values);
            
            samplesPerSecond = unique(sampleFreq);
            samplesPerMs = samplesPerSecond / 1e3; % milliseconds
            samplesPerUs = samplesPerSecond / 1e6; % microseconds
            
            time = sampleIx{1} ./ samplesPerMs;
            index2ms = @(s) ((s - 1) / samplesPerMs) + time(1);
            index2us = @(s) index2ms(s) * 1e3; %#ok<NASGU>
            
            
            norm2ms = @(v) (v * epsX) / samplesPerMs; %#ok<NASGU>
            norm2us = @(v) (v * epsX) / samplesPerUs;
            norm2current = @(v) v * epsY;
            epsXus = norm2us(1);
        end
        
    end
    
end
