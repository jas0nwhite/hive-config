function datasets = summarizeProbeHistory(ivCfg, setIx, parallel)
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
    %SUMMARIZEPROBEHISTORY Summary of this function goes here
    %   Detailed explanation goes here
    
    % output path for figs and data
    outPath = ivCfg.getSetValue(ivCfg.resultPathList, setIx);
    
    % root directory for finding vgram and metadata files
    dataRoot = ivCfg.resultPathList{setIx};
    
    % find the datasets for this specific probe
    probeDatasets = datasets(datasets.probeName == probe, :);
    nRows = size(probeDatasets, 1);
    
    
    %
    % ADD TIMESTAMPS TO DATASETS
    %
    dsTimes = nan(nRows, 1);
    
    for rowIx = 1:nRows
        ds = probeDatasets(rowIx, :);
        
        [~, name, ~] = ivCfg.getSourceInfo(ds.dsIx);
        
        metaFile = fullfile(dataRoot, name, ivCfg.metaFile);
        load(metaFile, 'headers');
        
        dsTimes(rowIx) = min(cellfun(@(h) h.abfTimestamp, headers));
    end
    
    % this will properly sort datasets acquired on the same day
    probeDatasets = sortrows(...
        addvars(probeDatasets, dsTimes, 'NewVariableNames', {'acqStart'}),...
        {'acqDate', 'acqStart'});
    
    
    %
    % PLOT PUSHES FOR EACH DATASET
    %
    push = 0;
    dsLastPush = nan(nRows, 1);

    fig = figure;
    hold on;
    
    for rowIx = 1:nRows
        ds = probeDatasets(rowIx, :);
        
        [~, name, ~] = ivCfg.getSourceInfo(ds.dsIx);
        
        vgramFile = fullfile(dataRoot, name, ivCfg.vgramFile);
        load(vgramFile, 'voltammograms');
        
        nPush = numel(voltammograms);
        x = push + (1:nPush)';
        y = cellfun(@(v) mean(rms(v, 1)), voltammograms);
        e = cellfun(@(v) std(rms(v, 1)), voltammograms);
        
        errorbar(x, y, e, '.');
        
        dsLastPush(rowIx) = push + nPush;
        push = push + nPush;
    end
    
    %
    % PLOT DATASET MARKERS
    %
    for ix = 1:numel(dsLastPush)
        xline(dsLastPush(ix), ':k', num2str(ix),...
            'LabelHorizontalAlignment', 'left', ...
            'LabelOrientation', 'horizontal');
    end
    
    %
    % DECORATE
    %
    protocol = strrep(unique(probeDatasets.protocol), '_', ' @ ');
    title(sprintf(...
        '%s  |  %s  |  %d datasets  |  %d recordings', ...
        probe, protocol, nRows, push));
    axis tight;
    ylim([0, 2000]);
    hold off;
    
    %
    % SAVE
    %
    figFile = fullfile(outPath, sprintf('%s-history.pdf', probe));
    
    % format figure
    fig.PaperPositionMode = 'manual';
    orient(fig, 'landscape');
    drawnow();
    hive.util.FigureStyle(fig)...
        .withScaledFontSize(1.5)...
        .withMinimumFontSize(8)...
        .withScaledLineWidth(1.25)...
        .withScaledMarkerSize(2)...
        .withMinimumLineWidth(1.5)...
        .withFontName('Helvetica')...
        .apply();
    drawnow();
    
    print(fig, figFile, '-dpdf');
    close(fig);
    
    fprintf('%s\n', probe);
end

