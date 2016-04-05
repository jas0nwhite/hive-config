function [coreIx, noiseIx, borderIx, clustIx] = characterizeDataset(catalog, datasetIx, eps, minPoints)

    [setIx, sourceIx] = catalog.getSourceIxByDatasetId(datasetIx);
    [~, name, ~] = catalog.getSourceInfo(setIx, sourceIx);

    summaryFile = fullfile(catalog.getSetValue(catalog.resultPathList, setIx), name, 'summary.mat');
    metadataFile = fullfile(catalog.getSetValue(catalog.resultPathList, setIx), name, 'abfMetadata.mat');

    summary = load(summaryFile);
    metadata = load(metadataFile);

    scanList = summary.steps.mean;
    reference = summary.grand.mean;
    stdDev = summary.grand.std;
    
    if (eps == 0)
        eps= 1;
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
    % refX = c.refSlm.knots(2);
    % refY = c.refSlm.coef(2);

    normX = zscore(x);
    normY = zscore(y);

    normXY = horzcat(normX, normY);

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
    % SLM plot
    %
    subplot(2, 2, 4);
    hold on;
    
    for ix = 1:length(c.slm)
        model = c.slm{ix};
        
        xrange = model.knots([1, end]);
        xev = linspace(xrange(1), xrange(2), 1001);
        ypred = slmeval(xev, model);
        
        h = plot(model.x, model.y);        
        set(h, ...
            'LineStyle', '-', ...
            'Marker', 'none', ...
            'Color', [0.8 0.8 0.8]);
        
        h = plot(xev, ypred);
        set(h, ...
            'Marker', 'none', ...
            'Color', [1.0 0.8 0.8], ...
            'LineStyle', '-', ...
            'LineWidth', 0.5);
        
        axlim = axis;
        yrange = axlim(3:4);
        knots = model.knots(:);
        
        h = plot(repmat(knots', 2, 1), yrange(:));
        set(h, ...
            'Marker', 'none', ...
            'Color', [0.8 1.0 0.8], ...
            'LineStyle', '--');
    end
    
    plot(x, y, 'LineStyle', 'none', 'Marker', 'o', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', colors(1, :));
    
    xlim([min(x) * 0.9, max(x) * 1.1]);
    ylim([min(y) * 0.9, max(y) * 1.1]);
    
    title('characterization (SLM)');
    xlabel('sample #');
    ylabel('current (nA)');
    hold off;
    
    
    %
    % cluster plot
    %
    eq = subplot(2, 2, 2);
    hold on;

    if ~isempty(borderIx)
        plot(normX(borderIx), normY(borderIx), 'oc', 'MarkerFaceColor', 'c', 'MarkerSize', 15);
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
                [px, py] = polybool('union', px, py, cx + normX(ix), cy + normY(ix));
            end
            
            patch(px, py, colors(i, :), 'FaceAlpha', .1, 'EdgeColor', colors(i, :));
        end
        
        for i = 1:nClust
            plotIx = clustIx == i;
            plot(normX(plotIx), normY(plotIx), 'o', ...
                'MarkerEdgeColor', colors(i, :), 'MarkerFaceColor', colors(i, :));
        end
        
    end

    if ~isempty(noiseIx)
        plot(normX(noiseIx), normY(noiseIx), 'or');
    end

    title(sprintf('clusters: %d, retained: %d, rejected: %d', nClust, length(clusteredIx), length(noiseIx)));
    xlabel('knot location (\sigma)');
    ylabel('knot coefficient (\sigma)');
    axis equal;

    hold off;

    set(f, 'ResizeFcn',{@resizeAxis, eq})
    % set(f, 'PaperPositionMode', 'auto') %Avoid resizing the figure when printing



    %
    % SDT plot
    %
    subplot(2, 2, 1);
    hold on;

    plot(time, stdDev);
    title('dataset standard deviation');
    xlabel('time (ms)');
    ylabel('\sigma (nA)');
    
    axis tight;
    
    plot([time(1) time(1)], get(gca, 'YLim'), 'b:');
    plot([time(60) time(60)], get(gca, 'YLim'), 'b:');
    %plot([time(1) time(60)], [eps eps], 'k:');

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
        'dataset #%d: %s\nepsilon = %0.2f, min cluster size = %0d', ...
        datasetIx, strrep(name, '_', '-'), eps, minPoints));
    
end