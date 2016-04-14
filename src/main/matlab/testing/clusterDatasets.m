function [coreIx, noiseIx, borderIx, clustIx] = clusterDatasets(catalog, datasetIxList, minPoints, epsX, epsY)

    nDatasets = length(datasetIxList);
    scanList = cell(nDatasets, 1);
    sampleFreq = nan(nDatasets, 1);
    sampleIx = cell(nDatasets, 1);
    
    parfor listIx = 1:nDatasets
        [setIx, sourceIx] = catalog.getSourceIxByDatasetId(datasetIxList(listIx)); %#ok<PFBNS>
        [~, name, ~] = catalog.getSourceInfo(setIx, sourceIx);

        resultPath = catalog.getSetValue(catalog.resultPathList, setIx);
        summaryFile = fullfile(resultPath, name, 'summary.mat');
        metadataFile = fullfile(resultPath, name, 'abfMetadata.mat');
        labelFile = fullfile(resultPath, name, catalog.labelFile);

        summary = load(summaryFile);
        metadata = load(metadataFile);
        labeldata = load(labelFile);

        sampleFreq(listIx) = metadata.sampleFreq(1);
        sampleIx{listIx} = metadata.sampleIx{1};
        
        neutral = cellfun(@(c) Chem.get(c).neutral, labeldata.chemicals);
        distance = cellfun(@(step) sum((step(1, :) - neutral).^2), labeldata.labels);

        neutralStepIx = find(distance == min(distance), 1, 'first');

        scanList(listIx) = summary.steps.mean(neutralStepIx);
    end

    if (nargin < 3)
        minPoints = 3;
    end

    if (nargin < 4)
        epsX = 1;
    end
    
    if (nargin < 5)
        epsY = epsX;
    end
    
    if (epsX == 0)
        epsX = 1;
    end
    
    if (epsY == 0)
        epsY = 1;
    end

    if (minPoints < 1)
        minPoints = ceil(minPoints * length(scanList));
    end

    c = characterize(scanList);
    % x = cellfun(@(s) s.knots(2), c.slm);
    % y = cellfun(@(s) s.coef(2), c.slm);
    % refX = c.refSlm.knots(2);
    % refY = c.refSlm.coef(2);
    x = cellfun(@(s) s.x, c.fit);
    y = cellfun(@(s) s.y, c.fit);

    eps = 1;
    
    normX = (x - mean(x)) / epsX;
    normY = (y - mean(y)) / epsY;

    normXY = horzcat(normX, normY);

    [clustIx, lc] = dbscan(normXY, eps, minPoints);

    coreIx = find(lc > 0);
    noiseIx = find(lc == -1);
    borderIx = find(lc == -2);
    clusteredIx = sort(union(coreIx, borderIx));
    nClust = length(unique(clustIx(coreIx)));

    scanMat = cell2mat(scanList');
    
    samplesPerSecond = unique(sampleFreq);
    samplesPerMs = samplesPerSecond / 1e3; % milliseconds
    samplesPerUs = samplesPerSecond / 1e6; % microseconds
    
    time = sampleIx{1} ./ samplesPerMs;
    index2ms = @(s) ((s - 1) / samplesPerMs) + time(1);
    index2us = @(s) index2ms(s) * 1e3; %#ok<NASGU>

    
    norm2ms = @(v) (v * epsX) / samplesPerMs; %#ok<NASGU>
    norm2us = @(v) (v * epsX) / samplesPerUs;
    norm2current = @(v) v * epsY;
    epsXus = norm2us(1);

    figure;
    colors = colormap(lines(nClust));

    %
    % characterization
    %
    subplot(2, 2, 1);
    hold on;
    
    scanX = 1:60;
    plotX = time(scanX);
    
    if ~isempty(coreIx)
        scanY = horzcat(scanList{coreIx});
        plotY = scanY(scanX, :);
        
        plot(plotX, plotY, ...
            'LineStyle', '-', ...
            'Marker', 'none', ...
            'Color', [0.8 0.8 0.8]);
    end
    
    if ~isempty(borderIx)
        scanY = horzcat(scanList{borderIx});
        plotY = scanY(scanX, :);
        
        plot(plotX, plotY, ...
            'LineStyle', '-', ...
            'Marker', 'none', ...
            'Color', [0.8 0.8 0.8]);
    end
    
    if ~isempty(noiseIx)
        scanY = horzcat(scanList{noiseIx});
        plotY = scanY(scanX, :);
        
        plot(plotX, plotY, ...
            'LineStyle', '-', ...
            'Marker', 'none', ...
            'Color', [1 0.5 0.5]);
    end
    
    for i = 1:nClust
        plotIx = clustIx == i;
        plot(index2ms(x(plotIx)), y(plotIx), 'o', ...
            'MarkerEdgeColor', colors(i, :), 'MarkerFaceColor', colors(i, :));
    end
    
    if ~isempty(noiseIx)
        plot(index2ms(x(noiseIx)), y(noiseIx), 'or');
    end
    
    
    % xlim([min(x) * 0.9, max(x) * 1.1]);
    % ylim([min(y) * 0.9, max(y) * 1.1]);
    % xlim([min(plotX), max(plotX)]);
    
    title('characterization');
    xlabel('time (ms)');
    ylabel('current (nA)');
    hold off;
    
    
    %
    % cluster plot
    %
    subplot(2, 2, 2);
    hold on;

    if ~isempty(borderIx)
        plot(norm2us(normX(borderIx)), norm2current(normY(borderIx)), 'oc', 'MarkerFaceColor', 'c', 'MarkerSize', 15);
    end

    theta = linspace(0, 2*pi, 100);
    cx = eps * cos(theta);
    cy = eps * -sin(theta); % -sin(theta) to make a clockwise contour
    
    if ~isempty(coreIx)
    
        for i = 1:nClust
            patchIx = find(lc == i);
            px = [];
            py = [];
           
            for j = 1:length(patchIx)
                ix = patchIx(j);
                [px, py] = polybool('union', px, py, norm2us(cx + normX(ix)), norm2current(cy + normY(ix)));
            end
            
            patch(px, py, colors(i, :), 'FaceAlpha', .1, 'EdgeColor', colors(i, :));
        end
        
        for i = 1:nClust
            plotIx = clustIx == i;
            plot(norm2us(normX(plotIx)), norm2current(normY(plotIx)), 'o', ...
                'MarkerEdgeColor', colors(i, :), 'MarkerFaceColor', colors(i, :));
        end
        
    end

    if ~isempty(noiseIx)
        plot(norm2us(normX(noiseIx)), norm2current(normY(noiseIx)), 'or');
    end

    title(sprintf('clusters: %d, retained: %d, rejected: %d', nClust, length(clusteredIx), length(noiseIx)));
    xlabel('\Delta time (µs)');
    ylabel('\Delta current (nA)');
    axis tight;
    
    hold off;



    %
    % SDT plot
    %
    % subplot(2, 2, 3);
    % hold on;
    % 
    % plot(time, stdDev);
    % title('dataset standard deviation');
    % xlabel('time (ms)');
    % ylabel('\sigma (nA)');
    % 
    % axis tight;
    % 
    % plot([time(1) time(1)], get(gca, 'YLim'), 'b:');
    % plot([time(60) time(60)], get(gca, 'YLim'), 'b:');
    % %plot([time(1) time(60)], [eps eps], 'k:');
    % 
    % xlim([1, 12]);
    % 
    % hold off;


    %
    % voltammogram plot
    %
    subplot(2, 2, [3 4]);
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
    
    xlim([1, 12]);
    ylim([-2050, 2050]);
    
    plot([time(1) time(1)], get(gca, 'YLim'), 'b:');
    plot([time(60) time(60)], get(gca, 'YLim'), 'b:');
    

    suptitle(sprintf(...
        'epsilon = %0.2f µs x %0.2f nA, min cluster size = %0d', ...
        epsXus, epsY, minPoints));
    
end