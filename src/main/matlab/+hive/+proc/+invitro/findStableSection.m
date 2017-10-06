function [goodWindow, excludeIx, r, q, fig] = findStableSection(data, sweepWindow)
%FINDSTABLESECTION Summary of this function goes here
%   Detailed explanation goes here
	
    nSweeps = size(data, 2);
    windowSize = numel(sweepWindow);
    nLags = nSweeps;
	
    r = nan(1, nLags);
    M = movmean(data, windowSize, 2);

    for ix = 1:nSweeps
       R = corrcoef(data(:, ix), M(:, ix));
       r(ix) = R(1, 2);
    end
    
    
    q = arrayfun(@(i) mean(r((1:windowSize) + (i - 1))), 1:(nSweeps - windowSize));
    
    [pkY, pkX] = findpeaks(q, 'MinPeakDistance', windowSize, 'MinPeakHeight', .95);
    
    startIx = pkX(end);
    endIx = pkX(end) + windowSize;
    goodWindow = startIx:endIx;
    
    rM = mean(r(goodWindow));
    rS = std(r(goodWindow));
    thresh = 2*rS;
    
    excludeIx = find(abs(r(goodWindow) - rM) > thresh);
    
    fig = figure;
    hold on;
    
    plot(r);    
    plot(q, 'LineWidth', 1.5);
    
    axis tight;
    ylim([.75, 1]);
    dy = diff(ylim);
    winY = min(ylim) + .75*dy;
    
    plot([startIx, endIx], [winY, winY], 'k', 'LineWidth', 1.5);
    plot(goodWindow(excludeIx), repmat(winY, numel(excludeIx)), 'r.', 'LineWidth', 1.5);
    plot(startIx, pkY(end)+.025*dy, 'vk', 'MarkerSize', 5, 'MarkerFaceColor', 'black');
    plot([startIx, startIx], [pkY(end), winY], ':k');    

    axis tight;
    ylim([.75, 1]);
    xlim(xlim + [-.1 .1]*diff(xlim));
    ylim(ylim + [-.1 .1]*diff(ylim));
    
    xlabel('sweep');
    ylabel('value');
    legend({'corr coef', 'quality', 'window'}, 'Location', 'southwest');
end

