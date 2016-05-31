%% init
clc;
cfg = Config;


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


%% characterize
t = tic;
hive.proc.train.Characterizer(cfg).withOverwrite(false).process();
toc(t);

t = tic;
hive.proc.test.Characterizer(cfg).withOverwrite(false).process();
toc(t);


%% index
t = tic;
hive.proc.train.Indexer(cfg).withOverwrite(false).process().plot();
toc(t);

t = tic;
hive.proc.test.Indexer(cfg).withOverwrite(false).process().plot();
toc(t);


%% build index cloud for clustering
t = tic;
hive.proc.train.Aggregator(cfg).process();
toc(t);


%% build training datasets
t = tic;
hive.proc.test.TrainingDataAssembler(cfg)...
    .withMuSpec(Chem.Dopamine, 0, 4500, 300)...
    .withMuSpec(Chem.Serotonin, 0, 4500, 300)...
    .withMuSpec(Chem.pH, 6.85, 7.85, 0.1)...
    .histogram()...
    .withNearest(3)...
    .process();
toc(t);
