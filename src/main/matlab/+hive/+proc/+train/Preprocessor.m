classdef Preprocessor
    %PREPROCESSOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        cfg
        labels
        overwrite = false
    end
    
    %
    % API
    %
    methods
        
        function this = Preprocessor(cfg)
            this.cfg = cfg;
            this.labels = readtable(this.cfg.training.labelCatalogFile);
            gcp();
        end
        
        function this = withOverwrite(this, setting)
            if nargin == 1
                setting = true;
            end
            
            this.overwrite = setting;
        end
        
        function this = process(this)
            nSets = size(this.cfg.training.sourceCatalog);
            
            for setIx = 1:nSets
                this.processSet(setIx)
            end
        end
        
    end
    
    %
    % internal API
    %
    methods (Access = protected)
        
        function processSet(this, setIx)
            nSources = size(this.cfg.training.sourceCatalog{setIx}, 1);
            
            tcfg = this.cfg.training;
            
            vgramWin = tcfg.getSetValue(tcfg.vgramWindowList, setIx);
            timeWin = tcfg.getSetValue(tcfg.timeWindowList, setIx);
            outPath = tcfg.getSetValue(tcfg.resultPathList, setIx);
            
            fprintf('\n***\n*** Processing set %d into %s\n***\n\n', setIx, outPath);
            
            for sourceIx = 1:nSources
                this.processSource(setIx, sourceIx, outPath, vgramWin, timeWin)
            end
        end
        
        function processSource(this, setIx, sourceIx, outPath, vgramWin, timeWin)
            tcfg = this.cfg.training;
            [id, name, ~] = tcfg.getSourceInfo(setIx, sourceIx);
            
            % find chemcial labels and names
            abfIx = this.labels.datasetId == id;
            chemIx = (1:Chem.count) + 2;
            abfLabels = table2array(this.labels(abfIx, chemIx));
            abfChemNames = arrayfun(@(ix) Chem.get(ix).name, 1:Chem.count, 'UniformOutput', false);
            
            abfFiles = this.labels.file(abfIx);            
            outDir = fullfile(outPath, name);
            
            if ~ exist(outDir, 'dir')
                mkdir(outDir);
            end
            
            vgramFile = fullfile(outDir, tcfg.vgramFile);
            metaFile = fullfile(outDir, 'abfMetadata.mat');
            
            fprintf('    dataset %03d (%d files): %s... ', id, length(abfFiles), name);
            t = tic;
            
            status = hive.convert.AbfToMat(abfFiles, vgramFile, metaFile, vgramWin, timeWin)...
                .withOverwrite(this.overwrite)...
                .withLabels(abfLabels, abfChemNames)...
                .convert;
            
            fprintf('%s (%.3fms)\n', char(status), toc(t)/1e-3);
        end
        
    end
    
end

