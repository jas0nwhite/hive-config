function fig = plotPerformance3(P)
%PLOTPERFORMANCE3 Summary of this function goes here
%   Detailed explanation goes here

    % plot performance in 3 panels
    
    %
    % SETUP
    %
    colors = lines(8);
    
    %
    % PERFORMANCE
    %
    fig = figure;
    subplot(3, 2, 1:4);
    hold on;
    title(sprintf('performance  |  r^2 = %0.4f  |  RMSE = %0.1f nM',...
        P.Summary.Fit.Rsquared.Ordinary, P.Summary.Fit.RMSE));
    xlabel('label (nM)');
    ylabel('mean prediction (nM)');

    xlim([P.Xmin - 200, P.Xmax + 200]);
    ylim([P.Xmin - 200, P.Xmax + 200]);
    
    h = refline(P.Summary.Fit.Coefficients.Estimate(2), P.Summary.Fit.Coefficients.Estimate(1));
    h.Color = colors(7, :);
    h.LineStyle = '--';
    
    errorbar(P.Summary.X, P.Summary.Ymean, P.Summary.Ysd, '.', 'Color', colors(1, :), 'MarkerSize', 15);
    
    legend(...
        {
        sprintf('fit: y = %0.4fx', P.Summary.Fit.Coefficients.Estimate(2))
        'mean prediction \pm \sigma'
        },...
        'Location', 'best');
    
    grid on;
    box off;
    
    
    %
    % RMSE
    %
    subplot(3, 2, 5);
    hold on;
    title(sprintf('RMSE = %0.1f nM', rms(P.Noise)));
    xlabel('label (nM)');
    ylabel('RMSE (nM)');
    
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
        
        plot(P.Summary.X, P.Summary.Yrmse, '.', 'Color', colors(1, :), 'MarkerSize', 15);
    end
    
    grid on;
    box off;
    
    
    %
    % SNR
    %
    subplot(3, 2, 6);
    hold on;
    title(sprintf('SNR = %0.1f dB', snr(P.Y, P.Noise)));
    xlabel('label (nM)');
    ylabel('SNR (dB)');
    
    xl = [10, P.Xmax];
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
        
        plot(P.Summary.X, P.Summary.Ysnr, '.', 'Color', colors(1, :), 'MarkerSize', 15);
    end
    
    grid on;
    box off;
    
    suptitle(P.Title);
end

