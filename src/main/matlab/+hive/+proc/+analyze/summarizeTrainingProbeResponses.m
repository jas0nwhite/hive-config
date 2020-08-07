function datasets = summarizeProbeResponses(ivCfg, setIx, parallel)
    %SUMMARIZEPROBERESPONSES Summarizes current responses by probe for the
    %given training set
    %   Detailed explanation goes here
    
    % get a table of InvitroDataset values for this set
    datasets = ivCfg.getDatasetTable(setIx);
    
    % get list of probes participating in this set
    probeList = unique(datasets.probeName);
    
    %
    % process each probe
    %
    if parallel
        parfor probeIx = 1:numel(probeList)
            probe = probeList(probeIx);
            plotProbe(ivCfg, setIx, datasets, probe);
        end
    else 
        for probe = probeList'
            plotProbe(ivCfg, setIx, datasets, probe);
        end
    end
    
end

function plotProbe(ivCfg, setIx, datasets, probe)
    % output path for figs and data
    outPath = ivCfg.getSetValue(ivCfg.resultPathList, setIx);
    
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
        
        [~, sourceIx] = ivCfg.getSourceIxByDatasetId(ds.dsIx);
        [~, dsName, ~] = ivCfg.getSourceInfo(setIx, sourceIx);
        
        summaryFile = fullfile(outPath, dsName, ivCfg.summaryFile);
        
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

