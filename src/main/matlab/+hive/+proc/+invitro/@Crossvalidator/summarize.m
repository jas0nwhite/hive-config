function summarize(this)
    %SUMMARIZE Summary of this function goes here
    %   Detailed explanation goes here

    t = tic();

    % read in all datasets
    nSets = numel(this.cfg.sourceCatalog);

    parfor (setId = 1:nSets, this.getNumWorkers())
        nSources = size(this.cfg.sourceCatalog{setId}, 1); %#ok<PFBNS>

        % if there's nothing to do, move on...
        if nSources == 0
            continue;
        end
        
        % summarize probe responses
        hive.proc.analyze.summarizeTrainingProbeResponses(this.treatment, setId);

        chemicals = Chem.names;
        nChem = Chem.count;

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

        index = doCalcC(@(c, i) (truth(:, c) == labels{c}(i)));
        n = doCalc(@(c, i) sum(index{c}{i}));
        x = doCalc(@(c, i) mean(signal(index{c}{i}, c)));
        sd = doCalc(@(c, i) std(signal(index{c}{i}, c)));
        rmse = doCalc(@(c, i) rms(noise(index{c}{i}, c)));
        snrdb = doCalc(@(c, i) snr(signal(index{c}{i}, c), noise(index{c}{i}, c)));

        %
        % GENERALIZED
        %
        signalNames = arrayfun(@(c) lower(c.prefix), Chem.members, 'UniformOutput', false);
        truthNames = arrayfun(@(c) upper(c.prefix), Chem.members, 'UniformOutput', false);

        data = array2table(horzcat(signal, truth), 'VariableNames', horzcat(signalNames', truthNames'));

        % find the set of chemicals that are present in this set
        validChemIx = find(table2array(varfun(@(v) ~all(isnan(v)), data(:, 1:nChem))));
        nValidChems = numel(validChemIx);
        validTruthNames = truthNames(validChemIx);
        validSignalNames = signalNames(validChemIx);

        figDir = this.testCfg.getSetValue(this.testCfg.resultPathList, setId);

        %
        % SAVE DATA
        %
        vars = struct();
        vars.signalNames = signalNames;
        vars.truthNames =  truthNames;
        vars.data =        data;
        vars.validChemIx = validChemIx;
        vars.n =           n;
        vars.x =           x;
        vars.sd =          sd;
        vars.rmse =        rmse;
        vars.snrdb =       snrdb;
        vars.truth =       truth;
        vars.signal =      signal;
        vars.noise =       noise;
        
        saveStruct(fullfile(figDir, 'data.mat'), vars);
        
        %
        % PLOTS PER CHEM
        %
        s = hgexport('readstyle', 'png-4MP');
        s.Resolution = 300;
        s.Format = 'png';
        
        for ix = 1:nValidChems
            signalName = validSignalNames{ix};
            truthName = validTruthNames{ix};
            chemIx = validChemIx(ix);
            
            minTruth = min(truth(:, chemIx));
            maxTruth = max(truth(:, chemIx));
            deltaTruth = maxTruth - minTruth;
            
            interactions = [sprintf('%s*', validTruthNames{1:(end-1)}), validTruthNames{end}];
            formula = sprintf('%s ~ 1 + %s', signalName, interactions);

            chem = Chem.get(chemIx);
            if chem == Chem.pH
                units = '';
            else
                units = sprintf(' (%s)', chem.units);
            end

            
            % main effects plot
            warning off;
            fit = fitlm(data, formula);
            warning on;

            fig = figure;
            plotEffects(fit);
            xlabel(sprintf('Effect: \\Delta %s%s', signalName, units));
            title(char(formula));
            grid on;
            box off;
            
            xl = xlim;
            xlim([min(xl(1), 0), max(xl(2), deltaTruth)]);
            dx = diff(xlim) / 20;
            xlim(xlim + [-dx, dx]);

            savefig(fig, fullfile(figDir, sprintf('fit-%s.fig', lower(chem.colName))));
            
            s.Height = 3;
            s.Width = 8;
            hgexport(fig, fullfile(figDir, sprintf('fit-%s.png', lower(chem.colName))), s);
            
            close(fig);

            fid = fopen(fullfile(figDir, sprintf('fit-%s.txt', lower(chem.colName))), 'w');
            txt = getDispText(fit);
            txt = regexprep(txt, '<[/]?strong>', '');
            fprintf(fid, '%s', txt);
            fclose(fid);
            
            
            % performance plot
            P = struct;
            P.N = n(chemIx);
            P.X = truth(:, chemIx);
            P.Y = signal(:, chemIx);
            P.Noise = noise(:, chemIx);
            
            P.Xmin = minTruth;
            P.Xmax = maxTruth;
            P.Title = lower(chem.name);
            P.Chem = chem;
            
            P.Summary.Fit = fitlm(data, sprintf('%s ~ %s', signalName, truthName));
            P.Summary.X = labels{chemIx};
            P.Summary.Ymean = x{chemIx};
            P.Summary.Ysd = sd{chemIx};
            P.Summary.Ysnr = snrdb{chemIx};
            P.Summary.Yrmse = rmse{chemIx};
            
            [~, name, ~] = fileparts(figDir);
            fid = fopen(fullfile(figDir, sprintf('performance-%s.txt', lower(chem.colName))), 'w');
            txt = hive.proc.invitro.logPerformance(name, P);
            fprintf(fid, '%s', txt);
            fclose(fid);
            
            fig = hive.proc.invitro.plotPerformance3(P);
            
            savefig(fig, fullfile(figDir, sprintf('performance-%s.fig', lower(chem.colName))));
            
            s.Height = 8;
            s.Width = 8 * 4 / 3;
            hgexport(fig, fullfile(figDir, sprintf('performance-%s.png', lower(chem.colName))), s);
            
            close(fig);
        end
    end

    toc(t);

end

function saveStruct(file, S)
    save(file, '-struct', 'S');
end

function text = getDispText(object) %#ok<INUSD>
    text = evalc('disp(object)');
end