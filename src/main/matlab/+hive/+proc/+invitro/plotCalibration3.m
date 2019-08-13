function [ fig ] = plotCalibration3( time, predictions, labels, stepIx, chems, muRange, novel, stats )
%PLOTCALIBRATION3 Summary of this function goes here
%   Detailed explanation goes here

    nSteps = size(stepIx, 1);
    nChems = numel(chems);

    muMin = min(muRange);
    muMax = max(muRange);

    desat = @(c) hsv2rgb(min([1, 1, 1], rgb2hsv(c) .* [1.0 0.3 1.2]));
    colors = lines(8);
    labColor = colors(3, :);
    colors = colors([1 4 5 7 6 2], :);

    rows = 3;
    cols = nChems * 2;

    X = time;
    Y = predictions;
    L = labels;

    fig = figure;
    alphaValue = 0.25;

    for chemIx = 1:nChems
        chem = Chem.get(chems{chemIx});
        colorIx = chem.ix;

        %
        % TODO: find the 5th and 95th percentile and set ylim to that for
        % plots
        %

        Lmin = min(L(:, chemIx));
        Lmax = max(L(:, chemIx));

        yq = quantile(Y(:, chemIx), [0.01, 0.99]);
        muLo = min(Lmin, yq(1));
        muHi = max(Lmax, yq(2));

        switch chem
            case Chem.pH
                units = '';

                muMin = Lmin;
                muMax = Lmax;
            otherwise
                units = sprintf(' (%s)', chem.units);

                if (Lmax < 2/3 * muMax)
                    muMax = Lmax;
                end
        end

        muLabel = [chem.label units];

        col = 2 * (chemIx - 1) + 1;
        nextRow = cols;

        subplot(rows, cols, [col, col + 1, nextRow + col, nextRow + col + 1])
        hold on;
        title(chem.label);
        xlabel('time');
        ylabel(muLabel);

        %
        % predicitons
        %
        if numel(X) / nSteps > 100
            % use alpha blending for large numbers of predictions
            hp = scatter(X, Y(:, chemIx), 5, colors(colorIx, :), 'filled');
            alpha(hp, alphaValue);
        else
            plot(X, Y(:, chemIx), '.', 'Color', colors(colorIx, :), 'MarkerSize', 15);
        end

        %
        % actual values
        %
        for ix = 1:nSteps
            selectIx = stepIx{ix};
            stepX = [min(X(selectIx)), max(X(selectIx))];
            stepY = [L(selectIx(1), chemIx), L(selectIx(1), chemIx)];
            
            ha = plot(stepX, stepY, 'Color', labColor, 'LineWidth', 1);
        end

        %
        % calculate limits
        %
        axis tight;
        xl = xlim();
        %yq = quantile(Y(:, chemIx), 20);
        %yl = [min([muMin; yq(1)]), max([muMax; yq(20)])];
        yl = [muLo, muHi];
        xtwix = diff(xl) / 20;
        ytwix = diff(yl) / 20;

        %
        % novel predictions
        %
        hn = 0;
        
        for ix = 1:nSteps
            if novel(ix)
                selectIx = stepIx{ix};
                stepX0 = min(X(selectIx));
                stepX1 = max(X(selectIx));
                stepY0 = L(selectIx(1), chemIx) - 2*ytwix;
                stepY1 = L(selectIx(1), chemIx) + 2*ytwix;
                
                
                
                % draw a yellow rectangle with transparency
                hn = patch(...
                    'XData', [stepX0, stepX1, stepX1, stepX0],...
                    'YData', [stepY0, stepY0, stepY1, stepY1],...
                    'FaceColor', [1, 1, 0],...
                    'FaceAlpha', 0.25,...
                    'EdgeColor', 'none');
            end
        end
        
        %
        % time bar
        %
        barX = (0:14) + 15*xtwix;
        barY = repmat(yl(1) - 2*ytwix, size(barX)); % + 2*ytwix;
        plot(barX, barY, 'k', 'LineWidth', 2);
        text(mean(barX), min(barY) + ytwix, '15s', 'HorizontalAlignment', 'Center', 'FontSize', 10);

        %
        % dummy point for legend (off page)
        %
        hp = scatter(2*xl(2), 2*yl(2), 10, colors(colorIx, :), 'filled');

        %
        % legend
        %
        if hn ~= 0
            legend([hp, ha, hn], {'predicted'; 'actual'; 'novel'}, 'Location', 'best');
        else
            legend([hp, ha], {'predicted'; 'actual'}, 'Location', 'best');
        end

        %
        % set limits
        %
        xlim(xl + [-xtwix, +xtwix]);
        ylim(yl + [-3*ytwix, +2*ytwix]);

        %
        % clean up axes
        %
        set(gca,'xtick',[]);
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
        chem = Chem.get(chems{chemIx});
        colorIx = chem.ix;

        plot(xlim(), [stats.fullRmse(chemIx) stats.fullRmse(chemIx)], '--', 'Color', desat(colors(colorIx, :)));
    end

    for chemIx = 1:nChems
        chem = Chem.get(chems{chemIx});
        colorIx = chem.ix;

        y = stats.predRmse(:, chemIx);
        x = stats.labels(:, chemIx);

        plot(x, y, '.', 'MarkerSize', 25, 'Color', colors(colorIx, :));
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
        chem = Chem.get(chems{chemIx});
        colorIx = chem.ix;

        plot(xlim(), [stats.fullSnr(chemIx) stats.fullSnr(chemIx)], '--', 'Color', desat(colors(colorIx, :)));
    end

    for chemIx = 1:nChems
        chem = Chem.get(chems{chemIx});
        colorIx = chem.ix;

        x = stats.labels(:, chemIx);
        y = stats.predSnr(:, chemIx);

        plot(x(x > 0), y(x > 0), '.', 'MarkerSize', 25, 'Color', colors(colorIx, :));
    end
end

