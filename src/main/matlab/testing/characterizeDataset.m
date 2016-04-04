function [coreIx, noiseIx, borderIx, clustIx] = characterizeDataset(catalog, datasetIx, epsPct, minPoints)

    [setIx, sourceIx] = catalog.getSourceIxByDatasetId(datasetIx);
    [~, name, ~] = catalog.getSourceInfo(setIx, sourceIx);

    summaryFile = fullfile(catalog.getSetValue(catalog.resultPathList, setIx), name, 'summary.mat');
    metadataFile = fullfile(catalog.getSetValue(catalog.resultPathList, setIx), name, 'abfMetadata.mat');

    summary = load(summaryFile);
    metadata = load(metadataFile);

    scanList = summary.steps.mean;
    reference = summary.grand.mean;
    stdDev = summary.grand.std;
    cv = stdDev ./ abs(reference);

    if (epsPct == 0)
        epsPct = median(cv(1:60)) * 150;
    end

    if (nargin == 3)
        minPoints = 3;
    end

    if (minPoints < 1)
        minPoints = ceil(minPoints * length(scanList));
    end

    c = characterize(scanList, reference);
    x = cellfun(@(s) s.knots(2), c.slm);
    y = cellfun(@(s) s.coef(2), c.slm);
    refX = c.refSlm.knots(2);
    refY = c.refSlm.coef(2);

    normX = x / refX;
    normY = y / refY;

    normXY = horzcat(normX, normY);
    eps = epsPct/100;

    [clustIx, lc] = dbscan(normXY, eps, minPoints);

    coreIx = find(lc > 0);
    noiseIx = find(lc == -1);
    borderIx = find(lc == -2);
    clusteredIx = sort(union(coreIx, borderIx));
    nClust = length(unique(clustIx(coreIx)));

    scanMat = cell2mat(scanList');
    time = metadata.sampleIx{1} ./ metadata.sampleFreq(1) * 1e3; % milliseconds


        function resizeAxis(~, ~, ax)
            axes(ax)
            axis equal

            % Uncomment next two lines for same axes sizes while printing
            % set(ax, 'DataAspectRatioMode', 'auto')
            % set(ax, 'Plotboxaspectratiomode', 'auto')
        end


    f = figure;

    colors = colormap(lines(nClust));

    %
    % cluster plot
    %
    eq = subplot(2, 2, [2 4]);
    hold on;

    if ~isempty(borderIx)
        plot(normX(borderIx)*100, normY(borderIx)*100, 'oc', 'MarkerFaceColor', 'c', 'MarkerSize', 15);
    end

    if ~isempty(coreIx)
        for i = 1:nClust
            plotIx = clustIx == i;
            plot(normX(plotIx)*100, normY(plotIx)*100, 'o', ...
                'MarkerEdgeColor', colors(i, :), 'MarkerFaceColor', colors(i, :));
        end
    end

    if ~isempty(noiseIx)
        plot(normX(noiseIx)*100, normY(noiseIx)*100, 'or');
    end

    theta = 0:pi/50:2*pi;
    circX = epsPct * cos(theta) + 100;
    circY = epsPct * sin(theta) + 100;
    plot(circX, circY, ':k');

    title(sprintf('clusters: %d, retained: %d, rejected: %d', nClust, length(clusteredIx), length(noiseIx)));
    xlabel('knot location (% ref)');
    ylabel('knot coefficient (% ref)');
    axis equal;

    hold off;

    set(f, 'ResizeFcn',{@resizeAxis, eq})
    % set(f, 'PaperPositionMode', 'auto') %Avoid resizing the figure when printing



    %
    % CV plot
    %
    subplot(2, 2, 1);
    hold on;

    plotCV = cv;
    
    plot(time, plotCV);
    title('dataset coefficients of variation');
    xlabel('time (ms)');
    ylabel('CV (%)');
    axis tight;
    ylim([0, .25]);

    plot([time(1) time(1)], get(gca, 'YLim'), 'b:');
    plot([time(60) time(60)], get(gca, 'YLim'), 'b:');
    plot([time(1) time(60)], [epsPct epsPct] ./ 100, 'k:');

    xlim([1, 12]);

    hold off;


    %
    % voltammogram plot
    %
    subplot(2, 2, 3);
    hold on;
    
    if ~isempty(coreIx)
        for i = 1:nClust
            plotIx = clustIx == i;
            plot(time, scanMat(:, plotIx), 'Color', colors(i, :));
        end
    end
    
    % if ~isempty(borderIx)
    %     plot(time, scanMat(:, borderIx), 'c');
    % end
    
    if ~isempty(noiseIx)
        plot(time, scanMat(:, noiseIx), 'r');
    end
    
    % plot(time, reference, 'k', 'LineWidth', 2);
    
    title('dataset voltammograms');
    xlabel('time (ms)');
    ylabel('current (nA)');
    axis tight;
    
    plot([time(1) time(1)], get(gca, 'YLim'), 'b:');
    plot([time(60) time(60)], get(gca, 'YLim'), 'b:');
    
    xlim([1, 12]);


    suptitle(sprintf(...
        'dataset #%d: %s\nepsilon = %0.1f%%, min cluster size = %0d', ...
        datasetIx, strrep(name, '_', '-'), epsPct, minPoints));
    
end