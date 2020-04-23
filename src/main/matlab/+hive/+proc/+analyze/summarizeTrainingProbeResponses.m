function datasets = summarizeTrainingProbeResponses(cfg, setIx)
    %SUMMARIZEPROBERESPONSES Summarizes current responses by probe for the
    %given training set
    %   Detailed explanation goes here
    
    %S = hgexport('readstyle', 'jpw-fig');
    %S.Format = 'eps';
    %S.Height = 8.5;
    %S.Width = 11;
    
    outPath = cfg.training.getSetValue(cfg.training.resultPathList, setIx);
    [~, setName, ~] = fileparts(outPath);
    
    % get the array of dataset indices for this set
    dsIx = arrayfun(@(s) s, vertcat(cfg.training.infoCatalog{setIx}{:, 1}));
    
    % get the array of InvitroDataset objects for this set
    s = arrayfun(@(s) s, vertcat(cfg.training.infoCatalog{setIx}{:, 2}));
    
    % convert the array of objects into a table by coercing each object
    % into a structure
    w = warning('off', 'MATLAB:structOnObject');
    datasets = struct2table(arrayfun(@struct, s));
    warning(w);
    
    % convert column types
    vn = datasets.Properties.VariableNames;
    datasets = varfun(@string, datasets);
    datasets.Properties.VariableNames = vn;
    datasets.acqDate = datetime(datasets.acqDate, 'InputFormat', 'yyyy-MM-dd');
    
    % add index
    datasets.dsIx = dsIx;
    
    % sort it nicely for processing
    datasets = sortrows(datasets, {'probeName', 'acqDate', 'dsIx'});
    
    % get some general data
    cfg.training.summaryFile
    
    % get list of probes participating in this set
    probeList = unique(datasets.probeName);
    
    %
    % process each probe
    %
    for probe = probeList'
        fprintf('*** %s\n', probe);
        
        probeDatasets = datasets(datasets.probeName == probe, :);
        meanResponse = nan(size(probeDatasets, 1), 1000);
        stdResponse = nan(size(meanResponse));
        
        % get the summary from each dataset
        for rowIx = 1:size(probeDatasets, 1)
            ds = probeDatasets(rowIx, :);
            fprintf('    %03d (%s)\n', ds.dsIx, datestr(ds.acqDate, 'yyyy-mm-dd'));
            
            [~, sourceIx] = cfg.training.getSourceIxByDatasetId(ds.dsIx);
            [~, dsName, ~] = cfg.training.getSourceInfo(setIx, sourceIx);
            
            summaryFile = fullfile(outPath, dsName, cfg.training.summaryFile);
            
            summary = load(summaryFile);
            meanResponse(rowIx, :) = summary.grand.mean';
            stdResponse(rowIx, :) = summary.grand.std';
        end
        
        %
        % PLOT
        %
        nLines = size(meanResponse, 1);
        fig = figure;
        hold on;
        colors = jet(nLines);
        
        % plot current response ± sd
        for ix = 1:nLines
            x = (1:1000)';
            y = meanResponse(ix, :)';
            e = stdResponse(ix, :)';
            c = colors(ix, :);
            
            px = [x; flipud(x)];
            py = [y + e; flipud(y - e)];
            
            patch(px, py, c, 'FaceAlpha', .1, 'EdgeColor', 'none');
            line(x, y, 'Color', c, 'LineWidth', 1.5);
        end
        
        % decorate
        xlabel('sample');
        ylabel('current, mean ± sd (nA)');
        ylim([-2050, 2050]);
        title(sprintf('%s  |  %s', setName, probe));
        colormap(jet(nLines));
        hc = colorbar('Ticks', (1:nLines)' / nLines - 1/(2*nLines), 'TickLabels', num2str((1:nLines)', '%02d'));
        hc.Label.String = 'dataset';
        
        %
        % SAVE
        %
        figFile = fullfile(outPath, sprintf('%s.pdf', probe));
        fprintf('    ==> %s\n', figFile);
        %hgexport(fig, figFile, S);
        fig.PaperPositionMode = 'manual';
        orient(fig, 'landscape');
        drawnow();
        hive.util.FigureStyle(fig)...
            .withScaledFontSize(1.5)...
            .withMinimumFontSize(8)...
            .withScaledLineWidth(1.25)...
            .withMinimumLineWidth(1.5)...
            .withFontName('Helvetica')...
            .apply();
        drawnow();
        print(fig, figFile, '-dpdf');
        close(fig);
    end
end

