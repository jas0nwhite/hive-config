classdef Aggregator
    %AGGREGATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
    end
    
    properties (Access = protected)
        treatment
        cfg
    end
    
    %
    % API
    %
    methods
        
        function this = Aggregator(cfg)
            this.treatment = cfg;
            this.cfg = cfg.training;
        end
        
        
        function this = process(this)
            nSets = numel(this.cfg.sourceCatalog);
            cloud = cell(nSets, 1);
            
            for setIx = 1:nSets
                nSources = this.cfg.getSize(this.cfg.sourceCatalog, setIx);
                
                cloud{setIx} = cell(nSources, 1);
                path = this.cfg.getSetValue(this.cfg.resultPathList, setIx);
                
                fprintf('\n***\n*** Aggregating training set %d (%d sources) in %s\n***\n\n',...
                    setIx, nSources, path);
                
                for sourceIx = 1:nSources
                    cloud{setIx}{sourceIx} = this.processSource(setIx, sourceIx, path);
                end
            end
            
            nRecordings = sum(cellfun(@(set) sum(cellfun(@(src) numel(src), set)), cloud));
            
            sourceId = nan(nRecordings, 1);
            setIx = nan(nRecordings, 1);
            sourceIx = nan(nRecordings, 1);
            stepIx = nan(nRecordings, 1);
            labels = nan(nRecordings, Chem.count);
            characterization = nan(nRecordings, 2);
            clusterIx = nan(nRecordings, 1);
            nVgramsRetained = nan(nRecordings, 1);
            nVgramsRejected = nan(nRecordings, 1);
            nVgramClusters = nan(nRecordings, 1);
            
            entryIx = 0;
            
            for x = 1:length(cloud)
                for y = 1:length(cloud{x})
                    for z = 1:length(cloud{x}{y})
                        entryIx = entryIx + 1;
                        
                        c = cloud{x}{y}(z);
                        
                        sourceId(entryIx) = c.id;
                        setIx(entryIx) = c.setIx;
                        sourceIx(entryIx) = c.sourceIx;
                        stepIx(entryIx) = c.stepIx;
                        labels(entryIx, :) = c.labels(:);
                        characterization(entryIx, :) = c.characterization;
                        clusterIx(entryIx) = c.clusterIx;
                        nVgramsRetained(entryIx) = c.nVgramsRetained;
                        nVgramsRejected(entryIx) = c.nVgramsRejected;
                        nVgramClusters(entryIx) = c.nVgramClusters;
                    end
                end
            end

            parent = fileparts(this.cfg.indexCloudFile);
            
            if ~exist(parent, 'dir')
                mkdir(parent)
            end
            
            save(this.cfg.indexCloudFile, 'sourceId', 'setIx', 'sourceIx', 'stepIx', 'labels', 'characterization',...
                'clusterIx', 'nVgramsRetained', 'nVgramsRejected', 'nVgramClusters');
        end
        
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
        
        function c = processSource(this, setIx, sourceIx, path)
            [id, name, ~] = this.cfg.getSourceInfo(setIx, sourceIx);
            
            fprintf('    dataset %03d: %s... ', id, name);
            t = tic;
            
            indir = fullfile(path, name);
            labelFile = fullfile(indir, this.cfg.labelFile);
            charFile = fullfile(indir, this.cfg.characterizationFile);
            indexFile = fullfile(indir, this.cfg.clusterIndexFile);
            
            outfile = this.cfg.indexCloudFile;
            outdir = strsplit(outfile, filesep);
            outdir = outdir{end - 1};
            
            if ~exist(outdir, 'dir')
                mkdir(outdir);
            end
            
            % load data
            load(labelFile);
            load(charFile);
            load(indexFile);
            
            nSteps = length(vgramChar); %#ok<USENS>
            fprintf('%d steps...', nSteps);
            
            c = repmat(struct('id', id), nSteps, 1);
            
            
            for stepIx = 1:nSteps
                c(stepIx).setIx = setIx;
                c(stepIx).sourceIx = sourceIx;
                c(stepIx).stepIx = stepIx;
                c(stepIx).labels = median(labels{stepIx}); %#ok<USENS>
                c(stepIx).characterization = median(vgramChar{stepIx});
                c(stepIx).clusterIx = datasetCluster.clustIx(stepIx);
                c(stepIx).nVgramsRetained = numel(stepClusters{stepIx}.clusteredIx); %#ok<USENS>
                c(stepIx).nVgramsRejected = numel(stepClusters{stepIx}.noiseIx);
                c(stepIx).nVgramClusters = numel(unique(stepClusters{stepIx}.clustIx(stepClusters{stepIx}.clustIx > 0)));
            end
            
            fprintf(' %0.3fs\n', toc(t));
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
            
            clusterFile = fullfile(outPath, name, this.indexFile);
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

