classdef (Abstract) ImporterBase < hive.proc.ProcessorBase
    %IMPORTERBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        labels
        vgramChannel = 'FSCV_1'
        jitterCorrector = []
    end
    
    %
    % API
    %
    methods
        function this = withVgramChannel(this, channel)
            this.vgramChannel = channel;
        end
        
        function this = withJitterCorrector(this, object)
            this.jitterCorrector = object;
        end
        
        function this = purgeExcludedData(this)
            this.labels = this.labels(strcmpi(this.labels.exclude, 'false'), :);
        end
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Access = protected)
        
        function numWorkers = getNumWorkers(~)
            % override: to limit I/O on the working node, only run one
            % AbfToMat job at a time... it is parallelized, anyway
            numWorkers = 0;
        end
        
        function argv = getArgsForProcessSource(this, setIx)
            argv = {
                this.cfg.getSetValue(this.cfg.importPathList, setIx);
                this.cfg.getSetValue(this.cfg.vgramWindowList, setIx);
                this.cfg.getSetValue(this.cfg.timeWindowList, setIx);
                };
        end
        
        function displayProcessSetHeader(this, setIx, nSources, nTotalSources)
            outPath = this.cfg.getSetValue(this.cfg.importPathList, setIx);

            fprintf('\n***\n*** NODE %d: %s set %d (%d / %d sources) into %s\n***\n\n',...
                this.nodeId, this.actionLabel, setIx, nSources, nTotalSources, outPath);
        end
        
        function processSource(this, setIx, sourceIx, outPath, vgramWin, timeWin)
            [id, name, ~] = this.cfg.getSourceInfo(setIx, sourceIx);
            
            t = tic;
            
            % find chemcial labels and names
            abfIx = this.labels.datasetId == id;
            chemIx = (1:Chem.count) + 2;
            abfLabels = table2array(this.labels(abfIx, chemIx));
            abfChemNames = arrayfun(@(ix) Chem.get(ix).name, 1:Chem.count, 'UniformOutput', false);
            
            abfFiles = this.labels.file(abfIx);
            
            fprintf('    dataset %03d (%d files): %s... ', id, length(abfFiles), name);
            
            outDir = fullfile(outPath, name);
            
            if ~ exist(outDir, 'dir')
                mkdir(outDir);
            end
            
            vgramFile = fullfile(outDir, this.cfg.vgramFile);
            metaFile = fullfile(outDir, this.cfg.metaFile);
            labelFile = fullfile(outDir, this.cfg.labelFile);
            otherFile = fullfile(outDir, 'otherwaveforms.mat');
            
            status = hive.convert.AbfToMat(abfFiles, this.vgramChannel, vgramFile, metaFile, otherFile, vgramWin, timeWin)...
                .withOverwrite(this.overwrite)...
                .withLabels(abfLabels, abfChemNames, labelFile)...
                .withDatasetInfo(name, id, setIx, sourceIx, this.treatment.name)...
                .withJitterCorrector(this.jitterCorrector)...
                .inParallel(this.doParfor)...
                .convert;
            
            fprintf('%s (%.3fs)\n', char(status), toc(t));
        end
        
    end
    
end

