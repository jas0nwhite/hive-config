function process_cluster_sets( nodeId, nodeCount, cpuCount, threadCount )

    %% init
    cfg = Config.init();

    addpath(fullfile(pwd, 'lib', 'glmnet_interface'));
    addpath(fullfile(pwd, 'testing'));

    overwrite = true;
    parallel = (cpuCount > 1);
    R2017a = strcmp(version('-release'), '2017a');

    % set default mat-file version to v6 for speed -- files will be big!
    rootgroup = settings();
    rootgroup.matlab.general.matfile.SaveFormat.PersonalValue = 'v6';

    % set up and configure parallel pool
    if parallel && isempty(gcp('nocreate'))
        pc = parcluster('local');

        jobDir = fullfile(pc.JobStorageLocation, sprintf('job%03d', nodeId));
        if ~exist(jobDir, 'dir')
            mkdir(jobDir);
        end

        pc.JobStorageLocation = jobDir;
        pc.NumThreads = threadCount;
        pc.NumWorkers = cpuCount;

        disp(pc);

        parpool(pc, cpuCount, 'IdleTimeout', Inf);
    end


    %% summarize training probes
    t = tic;
    hive.proc.train.Summarizer(cfg)...
        .inParallel(parallel)...
        .withOverwrite(overwrite)...
        .forNodeSpec(nodeId, nodeCount)...
        .summarizeTrainingProbes();
    toc(t);


    %% run cross-validation analyses
    % crossvalidate(cfg, 125, 0, 4500);
    hive.proc.invitro.Crossvalidator(cfg)...
        .forSetsOnly()...
        .withJitterRemoval(true)...
        .inParallel(parallel && ~R2017a)... % to avoid licence issue with R2017a
        .withOverwrite(overwrite)...
        .forNodeSpec(nodeId, nodeCount)...
        .withTrainingPercent(125)... %.withTrainingPercent(100)...
        ... %.withSkipTrainingLabels(Chem.Dopamine, 1600)...
        ... %.withSkipTrainingLabels(Chem.Serotonin, 1600)...
        ... %.withSkipTrainingLabels(Chem.Norepinephrine, 1600)...
        ... %.withSkipTrainingLabels(Chem.HydroxyindoleaceticAcid, 1600)...
        .withMinimum(0)...
        .withMaximum(8000)... %.withMaximum(3500)...
        .process()...
        .summarize();


    %% run report on models
    report = hive.proc.invitro.reportModelStats(cfg);
    writetable(report, fullfile(cfg.muHome, 'cv-model-stats.csv'));



