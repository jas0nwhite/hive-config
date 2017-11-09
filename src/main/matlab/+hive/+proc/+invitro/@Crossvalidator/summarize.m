function summarize(this)
%SUMMARIZE Summary of this function goes here
%   Detailed explanation goes here
    
    t = tic();
    
    % read in all datasets
    nSets = numel(this.cfg.sourceCatalog);
    
    for setId = 1:nSets
        nSources = size(this.cfg.sourceCatalog{setId}, 1);
        [~, chemicals] = enumeration('Chem');
        nChem = numel(chemicals);
        
        labelC = cell(nSources, 1);
        predictionC = cell(nSources, 1);
        
        
        for sourceId = 1:nSources
            [~, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
            
            % importDir = fullfile(this.cfg.getSetValue(this.cfg.importPathList, setId), name);
            % metadataFile = fullfile(importDir, this.cfg.metaFile);
            
            resultDir = fullfile(this.testCfg.getSetValue(this.testCfg.resultPathList, setId), name);
            % cvStatsFile = fullfile(resultDir, 'cv-stats.mat');
            % cvTrainFile = fullfile(resultDir, 'cv-training.mat');
            % cvTestFile = fullfile(resultDir, 'cv-testing.mat');
            cvPredFile = fullfile(resultDir, 'cv-predictions.mat');
            
            cv = load(cvPredFile);
            % testing = load(cvTestFile, 'ix');
            % training = load(cvTrainFile);
            % metadata = load(metadataFile);
            
            nObs = size(cv.predictions, 1);
            labels = nan(nObs, nChem);
            predictions = nan(nObs, nChem);
            
            % pre-populate labels with neutral values
            for chemIx = 1:nChem
                chem = Chem.get(chemicals{chemIx});
                labels(:, chemIx) = repmat(chem.neutral, nObs, 1);
            end
            
            % find how our accumulator and the CV results match up
            [~, accIx, cvIx] = intersect(chemicals, cv.chemical);
            
            labels(:, accIx) = cv.labels(:, cvIx);
            predictions(:, accIx) = cv.predictions(:, cvIx);
            
            labelC{sourceId} = labels;
            predictionC{sourceId} = predictions;
        end
        
        truth = vertcat(labelC{:});
        signal = vertcat(predictionC{:});
        noise = signal - truth;
        
        labels = arrayfun(@(c) unique(truth(:, c)), 1:nChem, 'unif', false);
        
        doCalcC = @(f) arrayfun(@(c) (arrayfun(@(i) ...
            f(c, i), ...
            1:numel(labels{c}), 'unif', false)), 1:nChem, 'unif', false);
        
        doCalc = @(f) arrayfun(@(c) cell2mat(arrayfun(@(i) ...
            f(c, i), ...
            1:numel(labels{c}), 'unif', false)), 1:nChem, 'unif', false);
        
        ix = doCalcC(@(c, i) truth(:, c) == labels{c}(i));
        n = doCalc(@(c, i) sum(ix{c}{i}));
        x = doCalc(@(c, i) mean(signal(ix{c}{i}, c)));
        sd = doCalc(@(c, i) std(signal(ix{c}{i}, c)));
        rmse = doCalc(@(c, i) rms(noise(ix{c}{i}, c)));
        snrdb = doCalc(@(c, i) snr(signal(ix{c}{i}, c), noise(ix{c}{i}, c)));
        
        %
        % TASK SPECIFIC
        %
        data = table;
        data.DA = truth(:, 1);
        data.SE = truth(:, 2);
        data.da = signal(:, 1);
        data.se = signal(:, 2);
        
        s = hgexport('readstyle', 'png-4MP');
        s.Resolution = 300;
        s.Height = 3;
        s.Width = 8;
        s.Format = 'png';
        
        figDir = this.testCfg.getSetValue(this.testCfg.resultPathList, setId);
        

        % da ~ DA*SE
        warning off;
        fit_da_DASE = fitlm(data, 'da ~ DA*SE');
        warning on;
        
        figure;
        plotEffects(fit_da_DASE);
        xlim([this.muMin - 100, this.muMax + 100]);
        xlabel('Effect: \Delta da (nM)');
        title(char(fit_da_DASE.Formula));
        grid on;
        box off;
        set(gca, 'Xtick', this.muMin:((this.muMax - this.muMin) / 4):this.muMax);
        
        savefig(gcf, fullfile(figDir, 'fit_da_DASE.fig'));
        hgexport(gcf, fullfile(figDir, 'fit_da_DASE.png'), s);
        close;
        
        fid = fopen(fullfile(figDir, 'fit_da_DASE.txt'), 'w');
        txt = evalc('disp(fit_da_DASE)');
        txt = regexprep(txt, '<[/]?strong>', '');
        fprintf(fid, '%s', txt);
        fclose(fid);
        
        
        % se ~ DA*SE
        warning off;
        fit_se_DASE = fitlm(data, 'se ~ DA*SE');
        warning on;
        
        figure;
        plotEffects(fit_se_DASE);
        xlim([this.muMin - 100, this.muMax + 100]);
        xlabel('Effect: \Delta se (nM)');
        title(char(fit_se_DASE.Formula));
        grid on;
        box off;
        set(gca, 'Xtick', this.muMin:((this.muMax - this.muMin) / 4):this.muMax);
        
        savefig(gcf, fullfile(figDir, 'fit_se_DASE.fig'));
        hgexport(gcf, fullfile(figDir, 'fit_se_DASE.png'), s);
        close;
        
        fid = fopen(fullfile(figDir, 'fit_se_DASE.txt'), 'w');
        txt = evalc('disp(fit_se_DASE)');
        txt = regexprep(txt, '<[/]?strong>', '');
        fprintf(fid, '%s', txt);
        fclose(fid);
        
        
        % performance: DA
        P.N = n(1);
        P.X = truth(:, 1);
        P.Y = signal(:, 1);
        P.Noise = noise(:, 1);
        
        P.Xmin = this.muMin;
        P.Xmax = this.muMax;
        P.Title = 'dopamine';
        P.Chem = Chem.Dopamine;
        
        P.Summary.Fit = fitlm(data, 'da ~ DA');        
        P.Summary.X = labels{1};
        P.Summary.Ymean = x{1};
        P.Summary.Ysd = sd{1};
        P.Summary.Ysnr = snrdb{1};
        P.Summary.Yrmse = rmse{1};
        
        [~, name, ~] = fileparts(figDir);
        fid = fopen(fullfile(figDir, 'performance-DA.txt'), 'w');
        txt = hive.proc.invitro.logPerformance(name, P);
        fprintf(fid, '%s', txt);
        fclose(fid);
        
        fig = hive.proc.invitro.plotPerformance3(P);
        
        savefig(fig, fullfile(figDir, 'performance-DA.fig'));
        
        s.Height = 8;
        s.Width = 8 * 4 / 3;
        hgexport(fig, fullfile(figDir, 'performance-DA.png'), s);
        
        close(fig);
        
        
        % performance: 5-HT
        P.N = n(2);
        P.X = truth(:, 2);
        P.Y = signal(:, 2);
        P.Noise = noise(:, 2);
        
        P.Xmin = this.muMin;
        P.Xmax = this.muMax;
        P.Title = 'serotonin';
        P.Chem = Chem.Serotonin;
        
        P.Summary.Fit = fitlm(data, 'se ~ SE');        
        P.Summary.X = labels{2};
        P.Summary.Ymean = x{2};
        P.Summary.Ysd = sd{2};
        P.Summary.Ysnr = snrdb{2};
        P.Summary.Yrmse = rmse{2};
        
        fid = fopen(fullfile(figDir, 'performance-5HT.txt'), 'w');
        txt = hive.proc.invitro.logPerformance(name, P);
        fprintf(fid, '%s', txt);
        fclose(fid);
        
        fig = hive.proc.invitro.plotPerformance3(P);
        
        savefig(fig, fullfile(figDir, 'performance-5HT.fig'));
        
        s.Height = 8;
        s.Width = 8 * 4 / 3;
        hgexport(fig, fullfile(figDir, 'performance-5HT.png'), s);
        
        close(fig);
        
        
    end
    
    toc(t);

end

