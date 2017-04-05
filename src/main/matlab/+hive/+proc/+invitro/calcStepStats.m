function [ stats ] = calcStepStats( stepIx, predictions, labels )
%CALCSTEPSTATS Summary of this function goes here
%   Detailed explanation goes here

    nSteps = size(stepIx, 1);
    nChems = size(labels, 2);
    
    stats.labels = nan(nSteps, nChems);
    stats.predRmse = nan(nSteps, nChems);
    stats.predSnr = nan(nSteps, nChems);
    stats.predSnre = nan(nSteps, nChems);
    
    signal = predictions;
    truth = labels;
    noise = signal - truth;
    estimate = nan(size(signal));
    noiseEst = nan(size(signal));
    
    for ix = 1:nSteps
        selectIx = stepIx{ix};
        stepSize = numel(selectIx);
        
        estimate(selectIx, :) = repmat(mean(signal(selectIx, :)), stepSize, 1);
        noiseEst(selectIx, :) = signal(selectIx, :) - estimate(selectIx, :);
        
        stats.labels(ix, :) = truth(selectIx(1), :);        
        stats.predRmse(ix, :) = arrayfun(@(i) rms(noise(selectIx, i)), 1:nChems);
        stats.predSnr(ix, :) = arrayfun(@(i) snr(signal(selectIx, i), noise(selectIx, i)), 1:nChems);
        stats.predSnre(ix, :) = arrayfun(@(i) snr(signal(selectIx, i), noiseEst(selectIx, i)), 1:nChems);
        stats.mean(ix, :) = mean(signal(selectIx, :));
        stats.sd(ix, :) = std(signal(selectIx, :));
        stats.n(ix, :) = numel(signal(selectIx, :));
        stats.sem(ix, :) = stats.sd(ix, :) ./ sqrt(stats.n(ix, :));
    end
    
    stats.fullRmse = arrayfun(@(i) rms(noise(:, i)), 1:nChems);
    stats.fullSnr = arrayfun(@(i) snr(signal(:, i), noise(:, i)), 1:nChems);
    stats.fullSnre = arrayfun(@(i) snr(signal(:, i), noiseEst(:, i)), 1:nChems);
end

