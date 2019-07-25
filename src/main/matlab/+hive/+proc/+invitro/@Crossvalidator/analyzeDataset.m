function analyzeDataset(this, dsIx)
    t = tic;
    
    % LOAD DATA
    [setId, sourceId] = this.cfg.getSourceIxByDatasetId(dsIx);
    [id, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
    
    importDir = fullfile(this.cfg.getSetValue(this.cfg.importPathList, setId), name);
    metadataFile = fullfile(importDir, this.cfg.metaFile);
    
    resultDir = fullfile(this.testCfg.getSetValue(this.testCfg.resultPathList, setId), name);
    cvStatsFile = fullfile(resultDir, 'cv-stats.mat');
    cvTestFile = fullfile(resultDir, 'cv-testing.mat');
    cvPredFile = fullfile(resultDir, 'cv-predictions.mat');
    cvPlotFile = fullfile(resultDir, 'cv-plot.mat');
    
    if ~this.overwrite && exist(cvPlotFile, 'file')
        fprintf('    %03d: SKIP (%.3fs)\n', id, toc(t));
        return
    end
    
    cv = load(cvPredFile);
    testing = load(cvTestFile, 'ix', 'sweepNumber');
    metadata = load(metadataFile, 'sampleFreq', 'sweepFreq');
    
    
    % GET STATS
    stepIx = testing.ix;    
    predictions = cv.predictions;
    labels = cv.labels;
    chems = cv.chemical;
    stats = hive.proc.invitro.calcStepStats(stepIx, predictions, labels, chems);
    
    
    % PLOT
    time = (testing.sweepNumber - 1) / metadata.sweepFreq(1);
    muRange = [this.muMin, this.muMax];
    
    for plotIx = 1:numel(chems)
        hive.proc.invitro.multiPlotCalibration3(time, predictions, labels, stepIx, chems, muRange, stats, plotIx);


        % DECORATE
        fSample = round(metadata.sampleFreq(1), 0);
        fSweep = round(metadata.sweepFreq(1), 0);
        info = this.cfg.infoCatalog{setId}{sourceId, 2};
        sampleIx = this.cfg.getSetValue(this.cfg.vgramWindowList, setId);
        sampleRange = round(max(sampleIx) - min(sampleIx), -3);
        
        if isempty(info.probeName)
            probe = info.acqDate;
        else
            probe = info.probeName;
        end
        
        % use some (standard?) data to calculate the forcing function and probe names
        forcingFn = hive.util.calculateProtocolTitle(info.protocol, sampleRange, fSample);
        
        % indicate shuffled dataset where appropriate
        if (~isempty(regexp(resultDir, '-shuffled', 'once')))
            forcingFn = sprintf('%s (shuffled)', forcingFn);
        end
        
        subtitle = sprintf('probe %s  |  %s @ %dHz\n\\fontsize{8}%s  |  dataset %03d  |  set %02d  |  source %03d',...
            strrep(regexprep(probe, '[_]+', '_'), '_', '\_'), forcingFn, fSweep,...
            strrep(info.protocol, '_', '\_'), dsIx, setId, sourceId);
        
        suptitle(subtitle);


        % SAVE
        if (numel(chems) > 1)
            filebase = sprintf('cv-plot-%s', lower(Chem.get(chems{plotIx}).colName));
        else
            filebase = 'cv-plot';
        end
        
        savefig(gcf, fullfile(resultDir, [filebase '.fig']));

        s = hgexport('readstyle', 'png-4MP');
        s.Format = 'png';
        s.Height = 9;
        s.Width = 12;
        s.Resolution = 200;
        hgexport(gcf, fullfile(resultDir, [filebase '.png']), s);

        s.Format = 'eps';
        hgexport(gcf, fullfile(resultDir, [filebase '.eps']), s);

        close;
    end
    
    
    save(cvStatsFile, '-struct', 'stats');
    
    hive.util.appendDatasetInfo(cvStatsFile, name, id, setId, sourceId, this.treatment.name);
    
    save(fullfile(resultDir, 'cv-plot.mat'), ...
        'time', 'stepIx', 'muRange', 'cvPredFile', 'cvStatsFile');
        
    fprintf('    %03d: DONE (%.3fs)\n', id, toc(t));
end