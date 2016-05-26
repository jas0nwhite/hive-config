classdef (Abstract) PreprocessorBase < hive.proc.ProcessorBase
    %PREPROCESSOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        labels
    end
    
    %
    % API
    %
    methods
        
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Access = protected)
        
        function argv = getArgsForProcessSource(this, setIx)
            argv = {
                this.cfg.getSetValue(this.cfg.resultPathList, setIx);
                this.cfg.getSetValue(this.cfg.vgramWindowList, setIx);
                this.cfg.getSetValue(this.cfg.timeWindowList, setIx);
                };
        end
        
        function displayProcessSetHeader(this, setIx, nSources)
            outPath = this.cfg.getSetValue(this.cfg.resultPathList, setIx);

            fprintf('\n***\n*** %s set %d (%d sources) into %s\n***\n\n',...
                this.actionLabel, setIx, nSources, outPath);
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
            
            status = hive.convert.AbfToMat(abfFiles, vgramFile, metaFile, vgramWin, timeWin)...
                .withOverwrite(this.overwrite)...
                .withLabels(abfLabels, abfChemNames, labelFile)...
                .convert;
            
            fprintf('%s (%.3fs)\n', char(status), toc(t));
        end
        
    end
    
end

