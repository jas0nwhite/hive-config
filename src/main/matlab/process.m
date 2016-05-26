%% init
clc;
cfg = Config;


%% preprocess
t = tic;
hive.proc.train.Preprocessor(cfg).withOverwrite(false).process();
toc(t);

t = tic;
hive.proc.test.Preprocessor(cfg).withOverwrite(false).process();
toc(t);


%% summarize
t = tic;
hive.proc.train.Summarizer(cfg).withOverwrite(false).process().plot();
toc(t);

t = tic;
hive.proc.test.Summarizer(cfg).withOverwrite(false).process().plot();
toc(t);


%% characterize
t = tic;
hive.proc.train.Characterizer(cfg).withOverwrite(false).process();
toc(t);

t = tic;
hive.proc.test.Characterizer(cfg).withOverwrite(false).process();
toc(t);


%% 