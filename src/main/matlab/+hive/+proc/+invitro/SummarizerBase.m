classdef (Abstract) SummarizerBase < hive.proc.ProcessorBase
    %SUMMARIZERBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
    end
    
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
                inPath = this.cfg.importPathList{setIx};
                outPath = this.cfg.resultPathList{setIx};
                
                % perform modulo-based dataset selection
                [datasetIdsToProcess, allDatasetIds] = this.getDatasetIdsToProcess(setIx);
                
                % convert from datasetIds to sourceIxs (within set)
                [setIxsToProcess, sourceIxsToProcess] = this.cfg.getSourceIxByDatasetId(datasetIdsToProcess);
                assert(numel(setIxsToProcess) ~= 1 || setIxsToProcess == setIx);
                
                if iscell(sourceIxsToProcess)
                    sourceIxsToProcess = cell2mat(sourceIxsToProcess);
                end
                
                nSources = numel(sourceIxsToProcess);
                
                fprintf('\n***\n*** NODE %d: Plotting set %d (%d / %d sources) from %s\n***\n\n', ...
                    this.nodeId, setIx, nSources, numel(allDatasetIds), outPath);
                
                if nSources == 0
                    return
                end
                
                % for jobIx = 1:nSources
                parfor (jobIx = 1:nSources, this.getNumWorkers())
                    sourceIx = sourceIxsToProcess(jobIx);
                    
                    [id, name, ~] = this.cfg.getSourceInfo(setIx, sourceIx); %#ok<PFBNS>
                    
                    fprintf('    dataset %03d: %s... ', id, name);
                    t = tic;
                    
                    sumFile = fullfile(outPath, name, this.cfg.summaryFile);
                    metadataFile = fullfile(inPath, name, this.cfg.metaFile);
                    labelFile = fullfile(inPath, name, this.cfg.labelFile);
                    
                    summary = load(sumFile);
                    metadata = load(metadataFile, 'sampleIx');
                    labs = load(labelFile);
                    
                    x = median(cell2mat(metadata.sampleIx));
                    y = cell2mat(summary.steps.median');
                    labels = cell2mat(labs.labels);
                    
                    nSteps = size(y, 2);
                    
                    % plot all steps
                    plotFile = fullfile(outPath, name, 'all-steps.pdf');
                    figFile = fullfile(outPath, name, 'all-steps.fig');
                    
                    if (~this.overwrite && exist(plotFile, 'file'))
                        fprintf(' SKIP (all)');
                    else
                        plotTitle = sprintf('%03d  |  %s  |  all steps', id, name);
                        
                        colorbarLabel = 'step';
                        
                        this.plotSteps(x, y, 1:nSteps, 1:nSteps, plotTitle, colorbarLabel);
                        
                        savefig(gcf, figFile);
                        hgexport(gcf, plotFile, s);
                        close;
                    end
                    
                    % find the neutral ("zero") status of each label
                    nChem = size(labels, 2);
                    neutrals = cellfun(@(s) round(Chem.get(s).neutral, 1), labs.chemicals);
                    
                    for chemIx = 1:nChem
                        % find column index of other chemicals
                        otherIx = setdiff(1:nChem, chemIx);
                        
                        % find concentrations for each step
                        nSteps = size(y, 2);
                        stepMu = cell2mat(arrayfun(@(ix) labs.labels{ix}(1, :)', 1:nSteps, 'UniformOutput', false))';
                        
                        % find the steps for which the other chemicals are at a neutral concentration
                        neutralTF = cell2mat( ...
                            arrayfun( ...
                            @(chem) round(stepMu(:, chem), 1) == neutrals(chem),...
                            otherIx, 'UniformOutput', false));
                        neutralTF = prod(neutralTF, 2); % aka AND
                        
                        stepIx = find(neutralTF);
                        nSteps = length(stepIx);
                        mu = arrayfun(@(ix) labs.labels{stepIx(ix)}(1, chemIx), 1:nSteps);
                        
                        if all(round(mu, 1) == neutrals(chemIx))
                            continue;
                        end
                        
                        % see if we need to re-do this plot
                        chem = Chem.get(labs.chemicals{chemIx});
                        
                        plotFile = fullfile(outPath, name, sprintf('mono-steps-%s.pdf', chem.label));
                        figFile = fullfile(outPath, name, sprintf('mono-steps-%s.fig', chem.label));
                        
                        if (~this.overwrite && exist(plotFile, 'file'))
                            fprintf(' SKIP (%s)', chem.label);
                            continue;
                        end
                        
                        % muList = sort(unique(mu));
                        % nMus = numel(muList);
                        %
                        % ticks = linspace(min(muList), max(muList), 5);
                        % tickLabels = arrayfun(@(n) num2str(n), ticks, 'uniformOutput', false);
                        
                        plotTitle = sprintf('%03d  |  %s  |  %s', id, name, chem.label);
                        
                        colorbarLabel = ''; %#ok<NASGU>
                        switch chem
                            case Chem.pH
                                colorbarLabel = 'pH';
                            otherwise
                                colorbarLabel = sprintf('[%s] (%s)', chem.label, chem.units);
                        end
                        
                        % figure;
                        % hold all;
                        % colors = jet(nMus);
                        % colormap(colors);
                        %
                        %
                        % for ix = nSteps:-1:1
                        %     colorIx = muList == mu(ix);
                        %
                        %     xs = sort(x);
                        %     if (isequaln(x, xs) && max(diff(xs)) == 1)
                        %         plot(x, y(:, ix), 'Color', colors(colorIx, :));
                        %     else
                        %         plot(xs, y(:, ix), '.', 'Color', colors(colorIx, :));
                        %     end
                        % end
                        %
                        % title(plotTitle, 'interpreter', 'none');
                        % xlabel('sample #');
                        % ylabel('current (nA)');
                        % axis tight;
                        % ylim([-2100 2100]);
                        % c = colorbar(...
                        %     'Ticks', (ticks - min(ticks)) / (max(ticks) - min(ticks)),...
                        %     'TickLabels', tickLabels);
                        % c.Label.String = colorbarLabel;
                        % % set(gca, 'Color', [0.9, 0.9, 0.9]);
                        
                        this.plotSteps(x, y, stepIx, mu, plotTitle, colorbarLabel);
                        
                        savefig(gcf, figFile);
                        hgexport(gcf, plotFile, s);
                        close;
                        
                    end
                    
                    
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
                this.cfg.getSetValue(this.cfg.importPathList, setIx)
                this.cfg.getSetValue(this.cfg.resultPathList, setIx)
                };
        end
        
        function displayProcessSetHeader(this, setIx, nSources, nTotalSources)
            path = this.cfg.getSetValue(this.cfg.importPathList, setIx);
            
            fprintf('\n***\n*** NODE %d: %s set %d (%d / %d sources) from %s\n***\n\n',...
                this.nodeId, this.actionLabel, setIx, nSources, nTotalSources, path);
        end
        
        function processSource(this, setIx, sourceIx, inPath, outPath)
            [id, name, ~] = this.cfg.getSourceInfo(setIx, sourceIx);
            
            vgramFile = fullfile(inPath, name, this.cfg.vgramFile);
            outDir = fullfile(outPath, name);
            outFile = fullfile(outDir, this.cfg.summaryFile);
            
            fprintf('    dataset %03d: %s... ', id, name);
            t = tic;
            
            if this.overwrite || ~exist(outFile, 'file')
                
                [summary, status] = this.analyzeVgramFile(vgramFile);
                
                if status == hive.Status.Success
                    if (~exist(outDir, 'dir'))
                        mkdir(outDir)
                    end
                    
                    save(outFile, '-struct', 'summary');
                    hive.util.appendDatasetInfo(outFile, name, id, setIx, sourceIx, this.treatment.name);
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
        
        
        function plotSteps(~, x, y, stepIx, groups, plotTitle, colorbarLabel)
            nSteps = length(stepIx);
            
            groupList = sort(unique(groups));
            nGroups = numel(groupList);
            
            ticks = linspace(min(groupList), max(groupList), min(nGroups, 5));
            tickLabels = arrayfun(@(n) num2str(n), ticks, 'uniformOutput', false);
            
            if nGroups > 1
                % RAINBOW!
                ticksNorm = (ticks - min(ticks)) / (max(ticks) - min(ticks));
                colors = jet(nGroups);
            else
                % BLACK!
                ticksNorm = 0.5;
                colors = [0, 0 0];
            end
            
            figure;
            hold all;
            
            colormap(colors);
            
            for ix = nSteps:-1:1
                colorIx = groupList == groups(ix);
                
                xs = sort(x);
                if (isequaln(x, xs) && max(diff(xs)) == 1)
                    plot(x, y(:, ix), 'Color', colors(colorIx, :));
                else
                    plot(xs, y(:, ix), '.', 'Color', colors(colorIx, :));
                end
            end
            
            title(plotTitle, 'interpreter', 'none');
            xlabel('sample #');
            ylabel('current (nA)');
            axis tight;
            ylim([-2100 2100]);
            c = colorbar(...
                'Ticks', ticksNorm,...
                'TickLabels', tickLabels);
            c.Label.String = colorbarLabel;
        end
        
    end
    
end

