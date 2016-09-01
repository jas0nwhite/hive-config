function summarize(this, dsIxList)
%SUMMARIZE Summary of this function goes here
%   Detailed explanation goes here
    
    t = tic();
    
    %% read in all datasets
    nSets = numel(this.cfg.sourceCatalog);
    
    %%
    for setId = 1:nSets
        %%
        nSources = size(this.cfg.sourceCatalog{setId}, 1);
        chemicals = {Chem.Dopamine.name, Chem.Serotonin.name};
        nChem = numel(chemicals);
        
        labelC = cell(nSources, 1);
        predictionC = cell(nSources, 1);
        
        
        %%
        for sourceId = 1:nSources
            %%
            [id, name, ~] = this.cfg.getSourceInfo(setId, sourceId);
            
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
            
            [~, ~, columnIx] = intersect(chemicals, cv.chemical); % just in case
            labelC{sourceId} = cv.labels(:, columnIx);
            predictionC{sourceId} = cv.predictions(:, columnIx);
            
        end
        %%
        
        truth = vertcat(labelC{:});
        signal = vertcat(predictionC{:});
        noise = signal - truth;
        
        labels = arrayfun(@(c) unique(truth(:, c)), 1:nChem, 'unif', false);
        
        doCalcC = @(f) arrayfun(@(c) (arrayfun(@(i) f(c, i), 1:numel(labels{c}), 'unif', false)), 1:nChem, 'unif', false);
        doCalc = @(f) arrayfun(@(c) cell2mat(arrayfun(@(i) f(c, i), 1:numel(labels{c}), 'unif', false)), 1:nChem, 'unif', false);
        
        ix = doCalcC(@(c, i) truth(:, c) == labels{c}(i));
        n = doCalc(@(c, i) sum(ix{c}{i}));
        x = doCalc(@(c, i) mean(signal(ix{c}{i}, c)));
        sd = doCalc(@(c, i) std(signal(ix{c}{i}, c)));
        rmse = doCalc(@(c, i) rms(noise(ix{c}{i}, c)));
        snrdb = doCalc(@(c, i) snr(signal(ix{c}{i}, c), noise(ix{c}{i}, c)));
        
        
        %%
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
        
        %%
        
        % da ~ DA*SE
        fit_da_DASE = fitlm(data, 'da ~ DA*SE');
        
        figure;
        plotEffects(fit_da_DASE);
        xlim([this.muMin - 100, this.muMax + 100]);
        xlabel('Effect: \Delta [DA] (nM)');
        title(char(fit_da_DASE.Formula));
        grid on;
        box off;
        set(gca, 'Xtick', this.muMin:((this.muMax - this.muMin) / 4):this.muMax);
        
        savefig(gcf, fullfile(figDir, 'fit_da_DASE.fig'));
        hgexport(gcf, fullfile(figDir, 'fit_da_DASE.png'), s);
        close;
        
        disp(fit_da_DASE);
        
        % se ~ DA*SE
        fit_se_DASE = fitlm(data, 'se ~ DA*SE');
        
        figure;
        plotEffects(fit_se_DASE);
        xlim([this.muMin - 100, this.muMax + 100]);
        xlabel('Effect: \Delta [5-HT] (nM)');
        title(char(fit_se_DASE.Formula));
        grid on;
        box off;
        set(gca, 'Xtick', this.muMin:((this.muMax - this.muMin) / 4):this.muMax);
        
        savefig(gcf, fullfile(figDir, 'fit_se_DASE.fig'));
        hgexport(gcf, fullfile(figDir, 'fit_se_DASE.png'), s);
        close;
        
        disp(fit_se_DASE);
        
        %% performance: DA
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
        
        fig = hive.proc.invitro.plotPerformance3(P);
        
        savefig(fig, fullfile(figDir, 'performance-DA.fig'));
        
        s.Height = 8;
        s.Width = 8 * 4 / 3;
        hgexport(fig, fullfile(figDir, 'performance-DA.png'), s);
        
        close(fig);
        
        
        %% performance: 5-HT
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
        
        fig = hive.proc.invitro.plotPerformance3(P);
        
        savefig(fig, fullfile(figDir, 'performance-5HT.fig'));
        
        s.Height = 8;
        s.Width = 8 * 4 / 3;
        hgexport(fig, fullfile(figDir, 'performance-5HT.png'), s);
        
        close(fig);
        
        
    end
    
    %%
    toc(t);

end

