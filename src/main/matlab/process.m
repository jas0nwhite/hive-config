%% init
clc;
cfg = Config;


%% preprocess training data
t = tic;
hive.proc.train.Preprocessor(cfg).withOverwrite(false).process();
toc(t);


%% summarize training data
t = tic;
hive.proc.train.Summarizer(cfg).withOverwrite(false).process(); %.plot();
toc(t);
