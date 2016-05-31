% restore default matlab path
restoredefaultpath;

% clear out auto-generated class definitions (just in case)
clear Config Chem hive.cfg.TargetCatalog hive.cfg.TestingCatalog hive.cfg.TrainingCatalog; 

% clear variables
clear;

% clear screen
clc;

% config
cfg = Config.init;


%% TESTING
addpath(fullfile(pwd, 'lib', 'dbscan'))
addpath(fullfile(pwd, 'lib', 'SLMTools'))
addpath(fullfile(pwd, 'lib', 'glmnet_interface'))
addpath(fullfile(pwd, 'testing'))