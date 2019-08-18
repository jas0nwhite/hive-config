%% config hive
%!./make-config /data/hnl/iterate/results_103/100-full.conf
%!./make-config treatment-burst.conf
%!./make-config treatment-burst-008.conf
!./make-config treatment-rodent-008.conf
%!./make-config treatment-rodent-009.conf

%% init
restoredefaultpath;
clear RESTOREDEFAULTPATH_EXECUTED;
clear classes; %#ok<CLCLS>
clc;
cfg = Config.init();

addpath(fullfile(pwd, 'lib', 'glmnet_interface'));
addpath(fullfile(pwd, 'testing'));

overwrite = false;
parallel = true;
R2017a = strcmp(version('-release'), '2017a');

% set default mat-file version to v6 for speed -- files will be big!
rootgroup = settings();
rootgroup.matlab.general.matfile.SaveFormat.PersonalValue = 'v6';

if parallel && isempty(gcp('nocreate'))
    parpool(feature('numcores')); % number of cross-validation folds
end


%% import
t = tic;
% jitterCorrector = hive.proc.invitro.JitterCorrector()...
%     .withExamWindow(1:30);
emptyJitterCorrector = [];

hive.proc.train.Importer(cfg)...
    .inParallel(parallel)...
    .withOverwrite(overwrite)...
    .withJitterCorrector(emptyJitterCorrector)...
    .purgeExcludedData()...
    .process();
toc(t);

t = tic;
hive.proc.test.Importer(cfg)...
    .inParallel(parallel)...
    .withOverwrite(overwrite)...
    .withJitterCorrector(emptyJitterCorrector)...
    .purgeExcludedData()...
    .process();
toc(t);


%% summarize
t = tic;
hive.proc.train.Summarizer(cfg)...
    .inParallel(parallel)...
    .withOverwrite(overwrite)...
    .process()...
    .plot();
toc(t);

t = tic;
hive.proc.test.Summarizer(cfg)...
    .inParallel(parallel)...
    .withOverwrite(overwrite)...
    .process()...  
    .plot();
toc(t);


%% run cross-validation analyses
% crossvalidate(cfg, 125, 0, 4500);
hive.proc.invitro.Crossvalidator(cfg)...
    .withJitterRemoval(true)...
    .inParallel(parallel && ~R2017a)... % to avoid licence issue with R2017a
    .withOverwrite(overwrite)...
    .withTrainingPercent(125)... %.withTrainingPercent(100)...
    .withMinimum(0)...
    .withMaximum(8000)... %.withMaximum(3500)...
    .withMedianLabelHoldout()...
    .process(); %...
    %.summarize();


%% run report on models
report = hive.proc.invitro.reportModelStats(cfg);
writetable(report, fullfile(cfg.muHome, 'cv-model-stats.csv'));

