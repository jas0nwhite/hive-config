function datasets = summarizeTrainingProbeResponses(cfg, setIx, parallel)
    %SUMMARIZEPROBERESPONSES Summarizes current responses by probe for the
    %given training set
    %   Detailed explanation goes here
    
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
    
    % get list of probes participating in this set
    probeList = unique(datasets.probeName);
    
    %
    % process each probe
    %
    if parallel
        parfor probeIx = 1:numel(probeList)
            probe = probeList(probeIx);
            plotProbe(cfg, setIx, datasets, probe);
        end
    else 
        for probe = probeList'
            plotProbe(cfg, setIx, datasets, probe);
        end
    end
    
    
end

function plotProbe(cfg, setIx, datasets, probe)
    % output path for figs and data
    outPath = cfg.training.getSetValue(cfg.training.resultPathList, setIx);
    
    % name of the set (for title)
    [~, setName, ~] = fileparts(outPath);
    
    % find the datasets for this specific probe
    probeDatasets = datasets(datasets.probeName == probe, :);
    
    % get the summary from each dataset
    acqDate = nan(size(probeDatasets, 1), 1);
    dsNote = cell(size(acqDate));
    meanResponse = nan(size(probeDatasets, 1), 1000);
    stdResponse = nan(size(meanResponse));
    
    for rowIx = 1:size(probeDatasets, 1)
        ds = probeDatasets(rowIx, :);
        
        [~, sourceIx] = cfg.training.getSourceIxByDatasetId(ds.dsIx);
        [~, dsName, ~] = cfg.training.getSourceInfo(setIx, sourceIx);
        
        
        summaryFile = fullfile(outPath, dsName, cfg.training.summaryFile);
        
        summary = load(summaryFile);
        acqDate(rowIx) = datenum(ds.acqDate);
        meanResponse(rowIx, :) = summary.grand.mean';
        stdResponse(rowIx, :) = summary.grand.std';
        
        % add note for mono-mix datasets
        dsParts = strsplit(dsName, '_');
        if any(ismember(dsParts, 'mix'))
            dsNote{rowIx} = ['/' dsParts{5}];
        else
            dsNote{rowIx} = '';
        end
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

    % colorbar ==> acquisition day
    tickLabs = arrayfun(...
        @(i) [num2str(acqDate(i) - acqDate(1), '%02d') dsNote{i}], ...
        1:nLines, 'UniformOutput', false);
    hc = colorbar(...
        'Ticks', (1:nLines)' / nLines - 1/(2*nLines),...
        'TickLabels', tickLabs,...
        'Direction', 'reverse');
    hc.Label.String = 'acquisition';
    
    %
    % SAVE
    %
    figFile = fullfile(outPath, sprintf('%s.pdf', probe));
    fprintf('%s\n', probe);
    
    % format figure
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

