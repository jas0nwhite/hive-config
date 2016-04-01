function [coreIx, noiseIx, borderIx, clustIx] = characterizeDataset(catalog, datasetIx, epsPct, minPoints)

    [setIx, sourceIx] = catalog.getSourceIxByDatasetId(datasetIx);
    [~, name, ~] = catalog.getSourceInfo(setIx, sourceIx);

    summaryFile = fullfile(catalog.getSetValue(catalog.resultPathList, setIx), name, 'summary.mat');
    metadataFile = fullfile(catalog.getSetValue(catalog.resultPathList, setIx), name, 'abfMetadata.mat');

    summary = load(summaryFile);
    metadata = load(metadataFile);

    scanList = summary.steps.median;
    reference = summary.grand.median;

    if (nargin == 3)
        minPoints = ceil(length(scanList) * 0.75);
    end

    c = characterize(scanList, reference);
    x = cellfun(@(s) s.knots(2), c.slm);
    y = cellfun(@(s) s.coef(2), c.slm);
    refX = c.refSlm.knots(2);
    refY = c.refSlm.coef(2);

    normX = x / refX;
    normY = y / refY;

    normXY = horzcat(normX, normY);
    [clustIx, lc] = dbscan(normXY, epsPct, minPoints);

    coreIx = find(lc > 0);
    noiseIx = find(lc == -1);
    borderIx = find(lc == -2);

    scanMat = cell2mat(scanList');
    time = metadata.sampleIx{1} ./ metadata.sampleFreq(1) * 1e3; % milliseconds

    figure;

    subplot(2, 1, 1);
    hold on;
    
    if ~isempty(coreIx)
        plot(normX(coreIx), normY(coreIx), 'ob', 'MarkerFaceColor', 'b');
    end

    if ~isempty(borderIx)
        plot(normX(borderIx), normY(borderIx), 'oc', 'MarkerFaceColor', 'c');
    end

    if ~isempty(noiseIx)
        plot(normX(noiseIx), normY(noiseIx), 'or');
    end
    
    theta = 0:pi/50:2*pi;
    circX = epsPct/2 * cos(theta) + 1;
    circY = epsPct/2 * sin(theta) + 1;
    plot(circX, circY, ':k');
    
    title('characterization');
    xlabel('knot location (% ref)');
    ylabel('knot coefficient (% ref)');
    
    hold off;



    subplot(2, 1, 2);
    hold on;

    plot([time(1) time(1)], [-500 1500], 'g:');
    plot([time(60) time(60)], [-500 1500], 'g:');

    if ~isempty(coreIx)
        plot(time, scanMat(:, coreIx), 'b');
    end

    if ~isempty(borderIx)
        plot(time, scanMat(:, borderIx), 'c');
    end

    if ~isempty(noiseIx)
        plot(time, scanMat(:, noiseIx), 'r');
    end

    plot(time, reference, 'k', 'LineWidth', 2);
    title('voltammograms');
    xlabel('time (ms)');
    ylabel('current (nA)');
    xlim([1, 12]);
    ylim([-2100, 2100]);

    suptitle(sprintf('dataset #%d: %s', datasetIx, strrep(name, '_', '-')));
end