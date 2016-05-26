classdef (Abstract) SummarizerBase < hive.proc.ProcessorBase
    %SUMMARIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
    end
    
    %
    % API
    %
    methods
        
        function this = plot(this)
            nSets = length(this.cfg.sourceCatalog);
            
            s = hgexport('readstyle', 'Default');
            s.format = 'pdf';
            s.Width = 8.5;
            s.Height = 8.5;
            s.FontMode = 'scaled';
            s.LineMode = 'scaled';
            
            for setIx = 1:nSets
                nSources = this.cfg.getSize(this.cfg.sourceCatalog, setIx);
                outPath = this.cfg.resultPathList{setIx};
                
                fprintf('\n***\n*** Plotting set %d from %s\n***\n\n', setIx, outPath);
                
                parfor sourceIx = 1:nSources
                    [id, name, ~] = this.cfg.getSourceInfo(setIx, sourceIx); %#ok<PFBNS>
                    
                    fprintf('    dataset %03d: %s... ', id, name);
                    t = tic;
                    
                    summaryFile = fullfile(outPath, name, 'summary.mat');
                    metadataFile = fullfile(outPath, name, this.cfg.metaFile);
                    labelFile = fullfile(outPath, name, this.cfg.labelFile);
                    
                    summary = load(summaryFile);
                    metadata = load(metadataFile, 'sampleIx');
                    labs = load(labelFile);
                    
                    x = median(cell2mat(metadata.sampleIx));
                    y = cell2mat(summary.steps.median');
                    labels = cell2mat(labs.labels);
                    
                    muCounts = arrayfun(@(i) numel(unique(labels(:, i))), 1:size(labels, 2));
                    chemIx = find(muCounts > 1);
                    
                    if (numel(chemIx) > 1)
                        % mixture
                        continue;
                    end
                    
                    nSteps = size(y, 2);
                    mu = arrayfun(@(ix) labs.labels{ix}(1, chemIx), 1:nSteps);
                    muList = sort(unique(mu));
                    nMus = numel(muList);
                    
                    ticks = linspace(min(muList), max(muList), 5);
                    tickLabels = arrayfun(@(n) num2str(n), ticks, 'uniformOutput', false);
                    
                    chem = Chem.get(chemIx);
                    
                    colorbarLabel = ''; %#ok<NASGU>
                    switch chem
                        case Chem.pH
                            colorbarLabel = 'pH';
                        otherwise
                            colorbarLabel = sprintf('[%s] (%s)', chem.label, chem.units);
                    end
                    
                    figure;
                    hold all;
                    colors = parula(nMus);
                    colormap(colors);
                    
                    
                    for ix = 1:nSteps
                        colorIx = muList == mu(ix);
                        plot(x, y(:, ix), 'Color', colors(colorIx, :));
                    end
                    
                    title(sprintf('%03d: %s', id, name), 'interpreter', 'none');
                    xlabel('sample #');
                    ylabel('current (nA)');
                    axis tight;
                    ylim([-2100 2100]);
                    c = colorbar('Ticks', (ticks - min(ticks)) / (max(ticks) - min(ticks)), 'TickLabels', tickLabels);
                    c.Label.String = colorbarLabel;
                    hgexport(gcf, fullfile(this.cfg.resultPathList{setIx}, name, 'mono-steps.pdf'), s);
                    close;
                    
                    fprintf(' %0.3fs\n', toc(t));
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
                this.cfg.getSetValue(this.cfg.resultPathList, setIx)
                };
        end
        
        function displayProcessSetHeader(this, setIx, nSources)
            path = this.cfg.getSetValue(this.cfg.resultPathList, setIx);
            
            fprintf('\n***\n*** %s set %d (%d sources) from %s\n***\n\n',...
                this.actionLabel, setIx, nSources, path);
        end
        
        function processSource(this, setIx, sourceIx, path)
            [id, name, ~] = this.cfg.getSourceInfo(setIx, sourceIx);
            
            outDir = fullfile(path, name);
            vgramFile = fullfile(outDir, this.cfg.vgramFile);
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
            
            fprintf('%s (%0.3fs)\n', char(status), toc(t));
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

