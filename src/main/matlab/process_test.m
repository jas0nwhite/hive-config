%% init
clc;
cfg = Config.init();

addpath(fullfile(pwd, 'lib', 'glmnet_interface'));
addpath(fullfile(pwd, 'testing'));


%% import
t = tic;
hive.proc.train.Importer(cfg).withOverwrite(false).process();
toc(t);

t = tic;
hive.proc.test.Importer(cfg).withOverwrite(false).process();
toc(t);


%% summarize
t = tic;
hive.proc.train.Summarizer(cfg).withOverwrite(false).process().plot();
toc(t);

t = tic;
hive.proc.test.Summarizer(cfg).withOverwrite(false).process().plot();
toc(t);


%% run cross-validation analyses
% crossvalidate(cfg, 125, 0, 4500);

hive.proc.invitro.Crossvalidator(cfg)...
    .withJitterCorrector(hive.proc.invitro.JitterCorrector())...
    .inParallel(true)...
    .withOverwrite(true)...
    .withTrainingPercent(125)...
    .withMinimum(0)...
    .withMaximum(4500)...
    .process()...
    .summarize();