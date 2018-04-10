function [goodWindow, excludeIx, r, q, fig] = findStableSection(data, sweepWindow)
%FINDSTABLESECTION Summary of this function goes here
%   Detailed explanation goes here
	
    % define dimenstions for clarity
    samplewise = 1;
    sweepwise = 2;
    
    nSweeps = size(data, sweepwise);
    windowSize = numel(sweepWindow);
    
    % calculate "before" and "after" window sizes based on movmean()
    winHead = floor(windowSize / 2);
    winTail = ceil(windowSize / 2) - 1;
    assert(winHead + 1 + winTail == windowSize, 'oops... window head/tail calculation is wrong');
	
    % step 1: find the median waveform for the window centered at each
    % sweep
    M = movmedian(data, windowSize, sweepwise);

    % step 2: find the "difference" by subtracting the window median from
    % each sweep
    D = data - M;
    
    % step 3: find the RMS (samplewise) of the difference
    r = rms(D, samplewise);
    
    % step 4: find the mean RMS of the window centered on each sweep
    % i.e. "quality"
    q = movmean(r, windowSize);
    
    % step 5: find the window centered on the sweep with the lowest q value
    % in the second half of the data
    %
    %         NOTE: restrict min() by truncating q-vector so that the
    %         window does not exceed the vector's bounds
    %
    halfIx = floor(nSweeps / 2);
    startIx = halfIx + 1 + winHead;
    endIx = nSweeps - winTail;
    
    qTrunc = q(startIx:endIx);
    bestWinCenterIx = find(qTrunc == min(qTrunc), 1, 'last') + halfIx + winHead;
    
    goodWindow = (bestWinCenterIx - winHead):(bestWinCenterIx + winTail);
    assert(numel(goodWindow) == windowSize, 'oops... goodWindow calculation is wrong');
    
    % step 6: mark any sweeps where the RMS of the difference is an outlier
    [isOut, lowerT, upperT, centerV] = isoutlier(r(goodWindow));
    excludeIx = find(isOut);
    
    %
    % plot figure
    %
    startIx = goodWindow(1);
    endIx = goodWindow(end);
    
    fig = figure;
    subplot(2, 1, 1);
    hold on;
    
    plot(r);    
    plot(q, 'LineWidth', 1.5);    
    plot([startIx, endIx], [centerV, centerV], 'k', 'LineWidth', 1.5);
    
    plot(goodWindow(excludeIx), repmat(centerV, numel(excludeIx)), 'r.', 'LineWidth', 1.5);
    
    axis tight;
    xlim(xlim + [-.1 .1]*diff(xlim));
    ylim(ylim + [-.1 .1]*diff(ylim));
    
    xlabel('sweep');
    ylabel('value');
    legend({'rms', 'quality', 'window'}, 'Location', 'northeast');
    
    subplot(2, 1, 2);
    hold on;
    
    plotIx = max(1, startIx - floor(windowSize / 4)):min(nSweeps, endIx + floor(windowSize / 4));
    
    plot(plotIx, r(plotIx));    
    plot(plotIx, q(plotIx), 'LineWidth', 1.5);    
    plot([startIx, endIx], [centerV, centerV], 'k', 'LineWidth', 1.5);
    
    plot([startIx, endIx], [upperT, upperT], ':', 'Color', [.5 .5 .5]);
    plot([startIx, endIx], [lowerT, lowerT], ':', 'Color', [.5 .5 .5]);
    
    plot(goodWindow(excludeIx), repmat(centerV, numel(excludeIx)), 'r.', 'LineWidth', 1.5);
    
    axis tight;
    ylim([lowerT, upperT]);
    xlim(xlim + [-.1 .1]*diff(xlim));
    ylim(ylim + [-.1 .1]*diff(ylim));
    
    xlabel('sweep');
    ylabel('value');
    legend({'rms', 'quality', 'window'}, 'Location', 'northeast');
end

