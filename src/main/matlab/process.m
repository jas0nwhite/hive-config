%% config
!./make-config treatment-24.conf
% !./make-config treatment-013-008.conf


%% init
restoredefaultpath;
clear RESTOREDEFAULTPATH_EXECUTED;
clear classes; %#ok<CLCLS>

clc;
cfg = Config.init();

overwrite = false;
parallel = true;
R2017a = strcmp(version('-release'), '2017a');

% set default mat-file version to v6 for speed -- files will be big!
rootgroup = settings();
rootgroup.matlab.general.matfile.SaveFormat.PersonalValue = 'v6';

if parallel && isempty(gcp('nocreate'))
    parpool(feature('numcores')); % number of cross-validation folds
end

% jitterCorrector = hive.proc.invitro.JitterCorrector()...
%     .withExamWindow(1:30);
defaultJitterCorrector = [];


%% import
t = tic;
hive.proc.train.Importer(cfg)...
    .inParallel(parallel)...
    .withOverwrite(overwrite)...
    .withJitterCorrector(defaultJitterCorrector)...
    .withUnderflowCorrection()...
    .purgeExcludedData()...
    .process();
toc(t);

t = tic;
hive.proc.test.Importer(cfg)...
    .inParallel(parallel)...
    .withOverwrite(overwrite)...
    .withJitterCorrector(defaultJitterCorrector)...
    .withUnderflowCorrection()...
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


%% build training datasets
t = tic;
hive.proc.test.TrainingDataAssembler(cfg)...
    .withMuSpec(Chem.Dopamine, 0, 4500, 300)...
    .withMuSpec(Chem.Serotonin, 0, 4500, 300)...
    .withMuSpec(Chem.pH, 6.85, 7.85, 0.1)...
    .histogram()...
    .withNearest(5)...
    .process();
toc(t);
