function [fig, ax1, ax2, ax3] = plotPerformance3(P)
%PLOTPERFORMANCE3 Summary of this function goes here
%   Detailed explanation goes here

    % plot performance in 3 panels
    
    %
    % SETUP
    %
    colors = hive.util.morelines();
    
    if P.Chem == Chem.pH
        units = '';
    else
        units = sprintf(' (%s)', P.Chem.units);
    end
    
    %
    % PERFORMANCE
    %
    fig = figure;
    ax1 = subplot(3, 2, 1:4);
    hold on;
    title(sprintf('performance  |  r^2 = %0.4f  |  RMSE = %0.1f%s',...
        P.Summary.Fit.Rsquared.Ordinary, P.Summary.Fit.RMSE, units));
    xlabel(sprintf('label%s', units));
    ylabel(sprintf('mean prediction%s', units));

    xlim([P.Xmin, P.Xmax]);
    ylim([P.Xmin, P.Xmax]);
    
    xtwix = diff(xlim) / 20;
    ytwix = diff(ylim) / 20;
    
    xlim(xlim + [-2*xtwix, 2*xtwix]);
    ylim(ylim + [-2*ytwix, 2*ytwix]);
    
    h = refline(1, 0);
    h.Color = colors(2, :);
    h.LineStyle = '--';
    
    h = refline(P.Summary.Fit.Coefficients.Estimate(2), P.Summary.Fit.Coefficients.Estimate(1));
    h.Color = colors(7, :);
    h.LineStyle = '--';
    
    errorbar(P.Summary.X, P.Summary.Ymean, P.Summary.Ysd, '.', 'Color', colors(1, :), 'MarkerSize', 15);
    
    legend(...
        {
        'y = x'
        sprintf('fit: y = %0.4fx', P.Summary.Fit.Coefficients.Estimate(2))
        'mean prediction \pm \sigma'
        },...
        'Location', 'best');
    
    grid on;
    box off;
    
    
    %
    % RMSE
    %
    ax2 = subplot(3, 2, 5);
    hold on;
    title(sprintf('RMSE = %0.1f%s', rms(P.Noise), units));
    xlabel(sprintf('label%s', units));
    ylabel(sprintf('RMSE%s', units));
    
    xl = [P.Xmin, P.Xmax];
    yl = [min(P.Summary.Yrmse), max(P.Summary.Yrmse)];
    xtwix = diff(xl) / 20;
    ytwix = diff(yl) / 20;
    
    xlim([xl(1) - xtwix, xl(2) + xtwix]);
    
    if yl(1) < yl(2)
        ylim([yl(1) - 2*ytwix, yl(2) + 2*ytwix]);
        
        h = refline(0, rms(P.Noise));
        h.Color = colors(7, :);
        h.LineStyle = '--';
        
        plot(P.Summary.X, P.Summary.Yrmse, '.', 'Color', colors(1, :), 'MarkerSize', 25);
    end
    
    grid on;
    box off;
    
    
    %
    % SNR
    %
    ax3 = subplot(3, 2, 6);
    hold on;
    title(sprintf('SNR = %0.1f dB', snr(P.Y, P.Noise)));
    xlabel(sprintf('label%s', units));
    ylabel('SNR (dB)');
    
    xl = [max(P.Xmin, P.Xmax / 1000), P.Xmax];
    yl = [min(P.Summary.Ysnr), max(P.Summary.Ysnr)];
    xtwix = diff(xl) / 20;
    ytwix = diff(yl) / 20;
    
    xlim([xl(1) - xtwix, xl(2) + xtwix]);
    
    if yl(1) < yl(2)
        ylim([yl(1) - 2*ytwix, yl(2) + 2*ytwix]);
        
        % set(gca, 'Xscale', 'log');
        % plot(p.Summary.X, p.Summary.Ysnr, '.', 'Color', colors(1, :));
        
        h = refline(0, snr(P.Y, P.Noise));
        h.Color = colors(7, :);
        h.LineStyle = '--';
        
        plot(P.Summary.X, P.Summary.Ysnr, '.', 'Color', colors(1, :), 'MarkerSize', 25);
    end
    
    grid on;
    box off;
    
    suptitle(P.Title);
end

