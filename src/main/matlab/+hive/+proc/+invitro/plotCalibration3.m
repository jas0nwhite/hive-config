function [ fig ] = plotCalibration3( time, predictions, labels, stepIx, chems, muRange, stats )
%PLOTCALIBRATION3 Summary of this function goes here
%   Detailed explanation goes here

    nSteps = size(stepIx, 1);
    nChems = numel(chems);
    muMin = min(muRange);
    muMax = max(muRange);
    
    desat = @(c) hsv2rgb(rgb2hsv(c) .* [1.0 0.3 1.2]);
    colors = lines(8);
    labColor = colors(2, :);
    colors = colors([1 4 7 8], :);
    
    rows = 3;
    cols = nChems * 2;

    X = time;
    Y = predictions;
    L = labels;

    fig = figure;    

    for chemIx = 1:nChems
        chem = Chem.get(chems{chemIx});
        
        switch chem
            case Chem.pH
                units = '';
            otherwise
                units = sprintf(' (%s)', chem.units);
        end
        
        muLabel = [chem.label units];
        
        col = 2 * (chemIx - 1) + 1;
        nextRow = cols;
        
        subplot(rows, cols, [col, col + 1, nextRow + col, nextRow + col + 1])
        hold on;
        title(chem.label);
        xlabel('samples');
        ylabel(muLabel);
        
        hp = plot(X, Y(:, chemIx), '.', 'Color', colors(chemIx, :), 'MarkerSize', 10);
        for ix = 1:nSteps
            selectIx = stepIx{ix};
            stepX = [min(X(selectIx)), max(X(selectIx))];
            stepY = [L(selectIx(1), chemIx), L(selectIx(1), chemIx)];
            ha = plot(stepX, stepY, 'Color', labColor, 'LineWidth', 1);
        end
        
        axis tight;
        xl = xlim();
        yl = [min([muMin; Y(:, chemIx)]), max([muMax; Y(:, chemIx)])];
        xtwix = diff(xl) / 20;
        ytwix = diff(yl) / 20;
        
        barX = (0:14) + 15*xtwix;
        barY = repmat(yl(1) - 2*ytwix, size(barX)); % + 2*ytwix;
        plot(barX, barY, 'k', 'LineWidth', 2);
        
        text(mean(barX), min(barY) + ytwix, '15s', 'HorizontalAlignment', 'Center', 'FontSize', 10);
        
        legend([hp, ha], {'predicted'; 'actual'}, 'Location', 'best');
        
        set(gca,'xtick',[]);
        xlim(xl + [-xtwix, +xtwix]);
        ylim(yl + [-3*ytwix, +2*ytwix]);
        axis manual;
    end
    
    
    
    
    %
    % RMSE
    %
    subplot(rows, cols, (rows - 1) * cols + (1:(cols/2)));
    hold on;
    title('RMSE');
    xlabel(muLabel);
    ylabel(['RMSE' units]);
    
    grid on;
    xl = [muMin, muMax];
    yl = [min(stats.predRmse(:)), max(stats.predRmse(:))];
    xtwix = diff(xl) / 20;
    ytwix = diff(yl) / 20;
    xlim(xl + [-xtwix, +xtwix]);
    ylim(yl + [-2*ytwix, +2*ytwix]);
    axis manual;
    
    for chemIx = 1:nChems
        plot(xlim(), [stats.fullRmse(chemIx) stats.fullRmse(chemIx)], '--', 'Color', desat(colors(chemIx, :)));
    end
    
    for chemIx = 1:nChems
        y = stats.predRmse(:, chemIx);
        x = stats.labels(:, chemIx);
        
        plot(x, y, '.', 'MarkerSize', 25, 'Color', colors(chemIx, :));
    end
    
    
    %
    % SNR
    %
    subplot(rows, cols, (rows - 1) * cols + ((cols/2 + 1):cols));
    hold on;
    title('SNR');
    xlabel(muLabel);
    ylabel('SNR (dB)');
    
    
    grid on;
    xl = [muMin, muMax];
    yl = [min([0; stats.predSnr(:)]), max([0; stats.predSnr(:)])];
    xtwix = diff(xl) / 20;
    ytwix = diff(yl) / 20;
    xlim(xl + [-xtwix, +xtwix]);
    ylim(yl + [-2*ytwix, +2*ytwix]);
    axis manual;
    
    for chemIx = 1:nChems
        plot(xlim(), [stats.fullSnr(chemIx) stats.fullSnr(chemIx)], '--', 'Color', desat(colors(chemIx, :)));
    end
    
    for chemIx = 1:nChems
        x = stats.labels(:, chemIx);
        y = stats.predSnr(:, chemIx);
        
        plot(x(x > 0), y(x > 0), '.', 'MarkerSize', 25, 'Color', colors(chemIx, :));
    end
end

