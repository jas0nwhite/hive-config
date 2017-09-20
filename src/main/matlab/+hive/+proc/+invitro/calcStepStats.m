function [ stats ] = calcStepStats( stepIx, predictions, labels, chems )
%CALCSTEPSTATS Summary of this function goes here
%   Detailed explanation goes here

    nChems = size(labels, 2);

    stats.chems = chems;
    stats.forChem(nChems).stepIx = [];
    stats.fullRmse = nan(1, nChems);
    stats.fullSnr = nan(1, nChems);
    stats.fullSnre = nan(1, nChems);

    for chemIx = 1:nChems
        signal = predictions(:, chemIx);
        truth = labels(:, chemIx);
        noise = signal - truth;
        estimate = nan(size(signal));
        noiseEst = nan(size(signal));

        truthVals = unique(truth);
        nSteps = numel(truthVals);

        stats.forChem(chemIx).labels = nan(nSteps, 1);
        stats.forChem(chemIx).predRmse = nan(nSteps, 1);
        stats.forChem(chemIx).predSnr = nan(nSteps, 1);
        stats.forChem(chemIx).predSnre = nan(nSteps, 1);
        stats.forChem(chemIx).fileIx = cell(nSteps, 1);
        stats.forChem(chemIx).ix = cell(nSteps, 1);
        stats.forChem(chemIx).stepCount = nSteps;
        
        for ix = 1:nSteps
            selectIx = find(truth == truthVals(ix));
            stepSize = numel(selectIx);

            estimate(selectIx) = repmat(mean(signal(selectIx)), stepSize, 1);
            noiseEst(selectIx) = signal(selectIx) - estimate(selectIx);

            stats.forChem(chemIx).labels(ix) = truthVals(ix);
            stats.forChem(chemIx).predRmse(ix) = rms(noise(selectIx));
            stats.forChem(chemIx).predSnr(ix) = snr(signal(selectIx), noise(selectIx));
            stats.forChem(chemIx).predSnre(ix) = snr(signal(selectIx), noiseEst(selectIx));
            stats.forChem(chemIx).mean(ix) = mean(signal(selectIx));
            stats.forChem(chemIx).sd(ix) = std(signal(selectIx));
            stats.forChem(chemIx).n(ix) = stepSize;
            stats.forChem(chemIx).sem(ix) = stats.forChem(chemIx).sd(ix) ./ sqrt(stats.forChem(chemIx).n(ix));
            
            stats.forChem(chemIx).ix{ix} = selectIx;
            stats.forChem(chemIx).fileIx{ix} = find(cellfun(@(v) any(ismember(v, selectIx)), stepIx));
        end

        stats.fullRmse(chemIx) = rms(noise);
        stats.fullSnr(chemIx) = snr(signal, noise);
        stats.fullSnre(chemIx) = snr(signal, noiseEst);
    end
end

