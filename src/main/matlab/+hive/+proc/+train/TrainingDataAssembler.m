classdef TrainingDataAssembler < hive.proc.ProcessorBase
    %TRAININGDATAASSEMBLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
    end
    
    properties (Access = protected)
        nNeighbors
        muSpecList
        cloud
        muRangeList
    end
    
    %
    % API
    %
    methods
        
        function this = TrainingDataAssembler(cfg)
            this.treatment = cfg;
            this.cfg = cfg.testing;
            this.actionLabel = 'Assembling training dataset for testing';
            this.cloud = load(this.treatment.training.indexCloudFile);
            
            % defaults
            this.nNeighbors = 3;
            this.muSpecList = repmat([-Inf, Inf, NaN], Chem.count, 1);
            this.muRangeList = this.calculateBins();
        end
        
        function this = withNearest(this, setting)
            this.nNeighbors = setting;
        end
        
        function this = withMuSpec(this, chem, muMin, muMax, binSize)
            if (nargin < 5)
                binSize = NaN;
            end
            
            this.muSpecList(chem.ix, :) = [muMin, muMax, binSize];
            this.muRangeList = this.calculateBins();
        end
        
        function this = histogram(this)
            
            figure;
            
            for chemIx = 1:Chem.count
                muList = this.muRangeList{chemIx};
                
                binStart = cellfun(@(m) m.minMu, muList);
                binEnd = cellfun(@(m) m.maxMu, muList);
                binTicks = round(cellfun(@(m) mean([m.minMu, m.maxMu]), muList), 1);
                
                edges = sort(unique(union(binStart, binEnd)));
                edges(edges == .0001) = 25;
                
                f = subplot(Chem.count, 1, chemIx);
                histogram(this.cloud.labels, edges);
                
                title(Chem.get(chemIx).name);
                xlabel('µ');
                f.XTick = binTicks;
                ylabel('steps');
                f.YScale = 'log';
                xlim([min(edges), max(edges)]);
            end
            
            s = hgexport('readstyle', 'Default');
            s.Width = 8.5;
            s.Height = 11;
            s.ScaledFontSize = 'auto';
            s.ScaledLineWidth = 'auto';
            s.Format = 'pdf';
            
            hgexport(gcf, fullfile(this.treatment.muHome, 'traininghistogram.pdf'), s);
            close;
            
        end
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Access = protected)
        
        function argv = getArgsForProcessSource(this, setIx)
            argv = {
                this.cfg.getSetValue(this.cfg.resultPathList, setIx);
                };
        end
        
        function displayProcessSetHeader(this, setIx, nSources)
            path = this.cfg.getSetValue(this.cfg.resultPathList, setIx);
            
            fprintf('\n***\n*** %s set %d (%d sources) in %s\n***\n\n',...
                this.actionLabel, setIx, nSources, path);
        end
        
        function processSource(this, setIx, sourceIx, path)
            [id, name, ~] = this.cfg.getSourceInfo(setIx, sourceIx);
            
            fprintf('    dataset %03d: %s:', id, name);
            t = tic;
            
            outFile = fullfile(path, name, this.cfg.trainingDataFile);
            
            if (this.overwrite || ~exist(outFile, 'file'))
                
                [trainingDatasetIx, neighbors, distances] = this.findNeighbors(path, name);
                
                [voltammograms, labels, chemicals] = this.gatherTrainingData(trainingDatasetIx);
                
                save(outFile,...
                    'neighbors', 'distances', 'trainingDatasetIx',...
                    'voltammograms', 'labels', 'chemicals');
                
                fprintf(' DONE. (%.3fs)\n', toc(t));
            else
                fprintf(' SKIP. (%.3fs)\n', toc(t));
            end
        end
        
        function [voltammograms, labels, chemicals] = gatherTrainingData(this, trainingDatasetIx)
            training = this.treatment.training;
            nDatasets = length(trainingDatasetIx);
            
            voltammograms = cell(nDatasets, 1);
            labels = cell(nDatasets, 1);
            chemicals = cell(1, Chem.count);
            
            for chemIx = 1:Chem.count
                chemicals{chemIx} = Chem.get(chemIx).name;
            end
            
            for ix = 1:nDatasets
                tsIx = trainingDatasetIx(ix);
                
                setIx = this.cloud.setIx(tsIx);
                sourceIx = this.cloud.sourceIx(tsIx);
                stepIx = this.cloud.stepIx(tsIx);
                
                [id, name, ~] = training.getSourceInfo(setIx, sourceIx);
                path = training.getSetValue(training.resultPathList, setIx);
                
                vData = load(fullfile(path, name, training.vgramFile));
                lData = load(fullfile(path, name, training.labelFile));
                
                if (~isequal(chemicals, lData.chemicals))
                    this.error('analyteMismatch', 'analyte mismatch in dataset %d: %s', id, name);
                end
                
                voltammograms{ix} = vData.voltammograms{stepIx};
                labels{ix} = lData.labels{stepIx};
            end
            
            % resize for consistency
            voltammograms = horzcat(voltammograms{:});
            labels = vertcat(labels{:});
            labels = labels';
            chemicals = chemicals';
        end
        
        function [trainingDatasetIx, neighbors, distances] = findNeighbors(this, path, name)
            neighbors = cell(Chem.count, 1);
            distances = cell(Chem.count, 1);
            
            % get the median characterization of the target
            load(fullfile(path, name, this.cfg.characterizationFile));
            medianVgramChar = median(cell2mat(vgramChar), 1);
            
            % find the distance between each characterization in the cloud and the target median
            distanceFromTarget = arrayfun(...
                @(r) norm(this.cloud.characterization(r, :) - medianVgramChar), ...
                1:size(this.cloud.characterization, 1));
            
            % list of all Chem indices
            allChems = 1:Chem.count;
            
            for chemIx = 1:Chem.count
                ranges = this.muRangeList{chemIx};
                nRanges = length(ranges);
                
                neighbors{chemIx} = nan(nRanges, this.nNeighbors);
                distances{chemIx} = nan(nRanges, this.nNeighbors);
                
                % find labels for target analyte
                chemLabels = this.cloud.labels(:, chemIx);
                
                % find labels where the other analytes are neutral [MONO-ANALYTE]
                otherChems = allChems;
                otherChems(chemIx) = [];
                neutralTF = cell2mat(...
                    arrayfun(...
                    @(chem) round(this.cloud.labels(:, chem), 1) == Chem.get(chem).neutral, ...
                    otherChems, 'UniformOutput', false));
                neutralTF = prod(neutralTF, 2); % aka AND
                
                for rangeIx = 1:length(ranges)
                    range = ranges{rangeIx};
                    
                    % find lables where analyte concentration is in range
                    inRangeTF = chemLabels >= range.minMu & chemLabels <= range.maxMu;
                    
                    % find datasets where target analyte is in range and
                    % others are neutral
                    targetIx = find(inRangeTF & neutralTF);
                    [tDist, tDistIx] = sort(distanceFromTarget(targetIx));
                    
                    % find the nearest neighbors
                    neighbors{chemIx}(rangeIx, :) = targetIx(tDistIx(1:this.nNeighbors));
                    distances{chemIx}(rangeIx, :) = tDist(1:this.nNeighbors);
                end
                
            end
            
            nTrainingDatasets = sum(cellfun(@(c) numel(c), neighbors));
            trainingDatasetIx = unique(reshape(vertcat(neighbors{:}), nTrainingDatasets, 1));
        end
        
        function muRangeList = calculateBins(this)
            muRangeList = cell(Chem.count, 1);
            fudge = 0.0001;
            
            for chemIx = 1:Chem.count
                labs = this.cloud.labels(:, chemIx);
                muMin = this.muSpecList(chemIx, 1);
                muMax = this.muSpecList(chemIx, 2);
                binSize = this.muSpecList(chemIx, 3);
                
                if (isinf(muMin))
                    muMin = min(labs);
                end
                
                if (isinf(muMax))
                    muMax = max(labs);
                end
                
                if (isnan(binSize))
                    % create a bin for each concentration
                    labs = labs(labs >= muMin & labs <= muMax);
                    binCenter = unique(labs);
                    binStart = binCenter - fudge;
                    binEnd = binCenter + fudge;
                else
                    % create bins
                    binStart = muMin:binSize:(muMax - binSize);
                    binEnd = (muMin + binSize):binSize:muMax;
                    
                    % exclude lower bound to prevent overlap
                    binStart = binStart + fudge;
                    
                    % special case: if muMin is zero, include it in its own bin
                    if (muMin == 0)
                        binStart = [0, binStart]; %#ok<AGROW>
                        binEnd = [0, binEnd]; %#ok<AGROW>
                    end
                end
                
                nBins = length(binStart);
                muRangeList{chemIx} = cell(nBins, 1);
                
                for binIx = 1:nBins
                    muRangeList{chemIx}{binIx} = hive.cfg.MuRangeUniform(binStart(binIx), binEnd(binIx));
                end
            end
        end
    end
    
end

