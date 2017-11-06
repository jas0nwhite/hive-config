function [ fig ] = multiPlotCalibration3( time, predictions, labels, stepIx, chems, muRange, stats, plotIx )
%MULTIPLOTCALIBRATION3 Summary of this function goes here
%   Detailed explanation goes here
    
    xpredictions = predictions(:, plotIx);
    xlabels = labels(:, plotIx);
    xchems = chems(plotIx);
    xstats.predRmse = stats.forChem(plotIx).predRmse;
    xstats.fullRmse = stats.fullRmse(plotIx);
    xstats.predSnr = stats.forChem(plotIx).predSnr;
    xstats.fullSnr = stats.fullSnr(plotIx);
    xstats.labels = stats.forChem(plotIx).labels;
    
    fig = hive.proc.invitro.plotCalibration3(time, xpredictions, xlabels, stepIx, xchems, muRange, xstats, plotIx);
end

