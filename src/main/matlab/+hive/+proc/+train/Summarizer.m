classdef Summarizer < hive.util.Logging
    %SUMMARIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        cfg
        overwrite = false
    end
    
    %
    % API
    %
    methods
        
        function this = Summarizer(cfg)
            this.cfg = cfg;
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
        
        function this = plot(this)
            tcfg = this.cfg.training;
            nSets = length(tcfg.sourceCatalog);
            
            for setIx = 1:nSets
                nSources = tcfg.getSize(tcfg.sourceCatalog, setIx);
                
                for sourceIx = 1:nSources
                    [id, name, ~] = tcfg.getSourceInfo(setIx, sourceIx);
                    
                    summaryFile = fullfile(tcfg.resultPathList{setIx}, name, 'summary.mat');
                    metadataFile = fullfile(tcfg.resultPathList{setIx}, name, tcfg.metaFile);
                    
                    summary = load(summaryFile);
                    metadata = load(metadataFile, 'sampleIx');
                    
                    x = median(cell2mat(metadata.sampleIx));
                    y = cell2mat(summary.steps.median');
                    
                    figure;
                    plot(x, y);
                    title(sprintf('%03d: %s', id, name), 'interpreter', 'none');
                    xlabel('sample #');
                    ylabel('current (nA)');
                    ylim([-2100 2100]);
                    drawnow;
                end
                
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
            
            path = tcfg.getSetValue(tcfg.resultPathList, setIx);
            
            fprintf('\n***\n*** Processing set %d from %s\n***\n\n', setIx, path);
            
            parfor sourceIx = 1:nSources
                this.processSource(setIx, sourceIx, path) %#ok<PFBNS>
            end
        end
        
        function processSource(this, setIx, sourceIx, path)
            tcfg = this.cfg.training;
            [id, name, ~] = tcfg.getSourceInfo(setIx, sourceIx);
            
            outDir = fullfile(path, name);
            vgramFile = fullfile(outDir, tcfg.vgramFile);
            outFile = fullfile(outDir, 'summary.mat');
            
            fprintf('    dataset %03d: %s... ', id, name);
            t = tic;
            
            if this.overwrite || ~exist(outFile, 'file')
                
                [summary, status] = this.analyzeVgramFile(vgramFile); %#ok<ASGLU>
                
                if status == hive.Status.Success
                    save(outFile, '-struct', 'summary');
                end
                
            else
                status = hive.Status.Skipped;
            end
            
            fprintf('%s (%.3fms)\n', char(status), toc(t)/1e-3);
        end
        
    end
    
    %
    % internal API
    %
    methods (Access = protected)
        
        function [summary, status] = analyzeVgramFile(this, vgramFile)
            if ~ this.checkFile(vgramFile, true)
                status = hive.Status.Failure;
                summary = struct;
                return;
            end
            
            vgrams = load(vgramFile);
            
            summary.steps.mean = cellfun(@(a) mean(a, 2), vgrams.voltammograms, 'uniformOutput', false);
            summary.steps.median = cellfun(@(a) median(a, 2), vgrams.voltammograms, 'uniformOutput', false);
            summary.steps.mode = cellfun(@(a) mode(a, 2), vgrams.voltammograms, 'uniformOutput', false);
            summary.steps.min = cellfun(@(a) min(a, [], 2), vgrams.voltammograms, 'uniformOutput', false);
            summary.steps.max = cellfun(@(a) max(a, [], 2), vgrams.voltammograms, 'uniformOutput', false);
            summary.steps.std = cellfun(@(a) std(a, 0, 2), vgrams.voltammograms, 'uniformOutput', false);
            summary.steps.var = cellfun(@(a) var(a, 0, 2), vgrams.voltammograms, 'uniformOutput', false);
            summary.steps.n = cellfun(@(a) size(a, 2), vgrams.voltammograms);
            
            grand = horzcat(vgrams.voltammograms{:});
            summary.grand.mean = mean(grand, 2);
            summary.grand.median = median(grand, 2);
            summary.grand.mode = mode(grand, 2);
            summary.grand.min = min(grand, [], 2);
            summary.grand.max = max(grand, [], 2);
            summary.grand.std = std(grand, 0, 2);
            summary.grand.var = var(grand, 0, 2);
            summary.grand.n = size(grand, 2);
            
            status = hive.Status.Success;
        end
        
    end
    
end

