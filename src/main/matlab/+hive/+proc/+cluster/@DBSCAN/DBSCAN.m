classdef DBSCAN < hive.util.Logging
    %DBSCAN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        levels = []
        coreIx = []
        noiseIx = []
        clusteredIx = []
        borderIx = []
        clustIx = []
        normValues = []
        values = []
        minPoints = NaN
        epsilonVector = []
    end
    
    methods (Static)
        function s = cluster(values, minPoints, epsilonVector)
            s = hive.proc.cluster.DBSCAN();
            s.coreIx = [];
            s.noiseIx = [];
            s.borderIx = [];
            s.clustIx = [];
            s.normValues = [];
            s.values = values;
            s.minPoints = minPoints;
            s.epsilonVector = epsilonVector;
            
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
                s.minPoints = ceil(s.minPoints * nValues);
            end
            
            %
            % we need to normalize the data in terms of the given epsion
            % vector, since this DBSCAN implementation only supports a
            % 1-D epsilon
            %
            
            eps = 1;
            
            s.normValues = bsxfun(@rdivide, ...
                bsxfun(@minus, values, mean(values, 1)), ...
                epsilonVector);
            
            [s.clustIx, s.levels] = dbscan(s.normValues, eps, s.minPoints);
            
            s.coreIx = find(s.levels > 0);
            s.noiseIx = find(s.levels == -1);
            s.clusteredIx = find(s.levels ~= -1);
            s.borderIx = find(s.levels == -2);
        end
        
    end
    
    
    
    methods
        
        function plot2D(this, xlab, ylab, ax)
            if nargin < 4
                figure;
                ax = gca();
            end
            
            if nargin < 3
                ylab = sprintf('Y (\\epsilon_y = %0.2f)', this.epsilonVector(2));
            end
            
            if nargin < 2
                xlab = sprintf('X (\\epsilon_x = %0.2f)', this.epsilonVector(1));
            end
            
            data = this.values(:, 1:2);
            epsilon = this.epsilonVector(1:2);
            
            nClust = length(unique(this.clustIx(this.coreIx)));
            
            colors = colormap(ax, lines(nClust));
            hold(ax, 'on');
            
            if ~isempty(this.borderIx)
                plot(ax, data(this.borderIx, 1), data(this.borderIx, 2), 'oc', 'MarkerFaceColor', 'c', 'MarkerSize', 15);
            end
            
            theta = linspace(0, 2*pi, 100);
            cx = epsilon(1) * cos(theta);
            cy = epsilon(2) * -sin(theta); % -sin(theta) to make a clockwise contour
            
            if ~isempty(this.coreIx)
                
                for i = 1:nClust
                    patchIx = find(this.levels == i);
                    px = [];
                    py = [];
                    
                    for j = 1:length(patchIx)
                        ix = patchIx(j);
                        [px, py] = polybool('union', px, py, cx + data(ix, 1), cy + data(ix, 2));
                    end
                    
                    patch(px, py, colors(i, :), 'FaceAlpha', .1, 'EdgeColor', colors(i, :), 'Parent', ax);
                end
                
                for i = 1:nClust
                    plotIx = this.clustIx == i;
                    plot(ax, data(plotIx, 1), data(plotIx, 2), 'o', ...
                        'MarkerEdgeColor', colors(i, :), 'MarkerFaceColor', colors(i, :));
                end
                
            end
            
            if ~isempty(this.noiseIx)
                plot(ax, data(this.noiseIx, 1), data(this.noiseIx, 2), 'or');
            end
            
            if isempty(this.clusteredIx)
                x = mean(ax.XLim);
                y = mean(ax.YLim);
                plot(cx + x, cy + y, ':r');
            end
            
            title(ax, ...
                sprintf('epsilon = %0.2f x %0.2f, min cluster size = %d\nclusters: %d, retained: %d, rejected: %d', ...
                epsilon(1), epsilon(2), this.minPoints,...
                nClust, length(this.clusteredIx), length(this.noiseIx)));
            xlabel(ax, xlab);
            ylabel(ax, ylab);
            axis(ax, 'tight');
            
            hold(ax, 'off');
            
        end
    end
    
end
