classdef (Abstract) IndexerBase < hive.proc.ProcessorBase
    %INDEXERBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
    end
    
    properties (Access = protected)
        epsilon
        minPoints
    end
    
    %
    % API
    %
    methods
        function plot(this)
            nSets = length(this.cfg.sourceCatalog);
            
            for setIx = 1:nSets
                nSources = this.cfg.getSize(this.cfg.sourceCatalog, setIx);
                outPath = this.cfg.resultPathList{setIx};
                
                fprintf('\n***\n*** Plotting set %d from %s\n***\n\n', setIx, outPath);
                
                parfor sourceIx = 1:nSources
                    this.plotSource(setIx, sourceIx, outPath); %#ok<PFBNS>
                end
                
            end
            
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
            outPath = this.cfg.getSetValue(this.cfg.resultPathList, setIx);
            
            fprintf('\n***\n*** %s set %d (%d sources) in %s\n***\n\n',...
                this.actionLabel, setIx, nSources, outPath);
        end
        
        function processSource(this, setIx, sourceIx, path)
            [id, name, ~] = this.cfg.getSourceInfo(setIx, sourceIx);
            
            fprintf('    dataset %03d: %s... ', id, name);
            t = tic;
            
            directory = fullfile(path, name);
            infile = fullfile(directory, this.cfg.characterizationFile);
            outfile = fullfile(directory, this.cfg.clusterIndexFile);
            
            if this.overwrite || ~exist(outfile, 'file')
                load(infile);
                
                nSteps = length(vgramChar); %#ok<USENS>
                stepClusters = cell(nSteps, 1);
                medianChars = cell(nSteps, 1);
                
                fprintf('%d steps...', nSteps);
                
                for stepIx = 1:nSteps
                    i = hive.proc.cluster.DBSCAN.cluster(vgramChar{stepIx}, this.minPoints, this.epsilon);
                    stepClusters{stepIx} = i;
                    medianChars{stepIx} = median(vgramChar{stepIx}, 1);
                end
                
                medianChars = cell2mat(medianChars);
                
                datasetCluster = hive.proc.cluster.DBSCAN.cluster(...
                    medianChars, 3, 1.5 * this.epsilon); %#ok<NASGU>
                
                save(outfile, 'stepClusters', 'datasetCluster');
                hive.util.appendDatasetInfo(cvTestFile, name, id, setIx, sourceIx, this.treatment.name);
                
                fprintf(' %0.3fs\n', toc(t));
            else
                fprintf('SKIP.\n');
            end
        end
        
        function plotSource(this, setIx, sourceIx, outPath)
            [id, name, ~] = this.cfg.getSourceInfo(setIx, sourceIx);
            
            fprintf('    dataset %03d: %s... ', id, name);
            t = tic;
            
            s = hgexport('readstyle', 'Default');
            s.Format = 'pdf';
            s.Width = 8.5;
            s.Height = 11;
            s.FontMode = 'scaled';
            s.LineMode = 'scaled';
            
            stepFile = fullfile(outPath, name, 'cluster-steps.pdf');
            datasetFile = fullfile(outPath, name, 'cluster-dataset.pdf');
            
            if (~this.overwrite && exist(stepFile, 'file') && exist(datasetFile, 'file'))
                fprintf(' SKIP. %0.3fs\n', toc(t));
                return;
            end
            
            clusterFile = fullfile(outPath, name, this.cfg.clusterIndexFile);
            load(clusterFile);
            
            % plot dataset cluster
            datasetCluster.plot2D('time (ms)', 'current (nA)');
            suptitle(sprintf('%03d: %s', id, strrep(name, '_', '-')));            
            hgexport(gcf, datasetFile, s);
            close;
            
            % plot vgram clusters
            nSteps = length(stepClusters); %#ok<USENS>
            rows = ceil(sqrt(nSteps) * 11 / 8.5);
            cols = ceil(nSteps / rows);
            
            figure;
            hold on;
            
            for ix = 1:nSteps
                ax = subplot(rows, cols, ix);
                
                if (datasetCluster.clustIx(ix) == -1)
                    set(ax, 'Color', [0.9 0.9 0.9]);
                end
                
                stepClusters{ix}.plot2D('', '', ax);
                title(sprintf('%03d', ix));
            end
            
            s.FontSizeMin = 2;
            s.ScaledFontSize = 50;
            suptitle(sprintf('%03d: %s', id, strrep(name, '_', '-')));            
            hgexport(gcf, stepFile, s);
            close;
            
            fprintf(' %0.3fs\n', toc(t));
        end
        
    end
    
end




