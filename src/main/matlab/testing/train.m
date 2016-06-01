%
% usage can be found by typing ?doc cvglmnet? in Matlab
%
%% start up parallel
gcp();

setIx = 1;
sourceIx = 1;
[id, name , ~] = cfg.testing.getSourceInfo(setIx, sourceIx);


%
% TRAINING
%
%% load data
targetPath = cfg.testing.getSetValue(cfg.testing.resultPathList, setIx);
targetDir = fullfile(targetPath, name);

training = load(fullfile(targetDir, cfg.testing.trainingDataFile));

%% cross validated glmnet options
options.alpha = 1.0; % LASSO - to optimize, use 0:.1:1 in a loop
family = 'mgaussian';
type = 'mse';
nfolds = 10; % when finding best alpha, set this to []
foldid = []; % when finding best alpha, set this to a precalculated list of fold ids
parallel = 1; % if true (=1), then will run in parallel mode
keep = 0;
grouped = 1;

%% training data
% training data supplied in ?training.voltammograms? variable
% 1st dimension is observations, 2nd dimension is variables
X = diff(training.voltammograms', 1, 2); % first differential along second dimension

%% training labels
% training labels supplied in ?training.labels? variable
% 1st dimension is observations, 2nd dimension is analyte concentrations
Y = training.labels';

%% this could take a long time, so try it out first with a small amount of data
t = tic;
CVerr = cvglmnet(X, Y, family, options, type, nfolds, foldid, parallel, keep, grouped);
fprintf('TRAINING COMPLETE (%.3fs)\n', toc(t));

save(fullfile(targetDir, 'CVerr.mat'), 'CVerr');


%
% TESTING
%
%% load data
sourcePath = cfg.testing.getSetValue(cfg.testing.importPathList, setIx);
sourceDir = fullfile(sourcePath, name);

testing = load(fullfile(sourceDir, cfg.testing.labelFile));
load(fullfile(sourceDir, cfg.testing.vgramFile));
testing.voltammograms = voltammograms;
clear voltammograms;

%% testing data
x = diff(horzcat(testing.voltammograms{:})', 1, 2);
y0 = vertcat(testing.labels{:});

%% generate predictions
y = cvglmnetPredict(CVerr, x, 'lambda_min');

%% plot
figure;
hold on;
plot(y0(:, 1), '.'); 
plot(y(:, 1), '.');

title(name, 'Interpreter', 'none');
xlabel('sample #');
ylabel('[DA] (nM)');
