classdef AbfToMat < hive.util.Logging
    %ABFTOMAT Converter for ABF files to MATLAB files
    
    properties (Access = protected)
        inputFiles
        outputFile
        metadataFile
        sampleWindow
        timeWindow
        overwrite = false
        chemLabels = nan(0);
        chemNames = {};
        labelFile
    end
    
    %
    % builders
    %
    methods
        
        function this = AbfToMat(inputFiles, outputFile, metadataFile, sampleWindow, timeWindow)
            this.inputFiles = inputFiles;
            this.outputFile = outputFile;
            this.metadataFile = metadataFile;
            this.sampleWindow = sampleWindow;
            this.timeWindow = timeWindow;
        end
        
        function this = withOverwrite(this, setting)
            if nargin == 1
                setting = true;
            end
            
            this.overwrite = setting;
        end
        
        function this = withLabels(this, chemLabels, chemNames, labelFile)
            this.chemLabels = chemLabels;
            this.chemNames = chemNames;
        end
        
    end
    
    %
    % API
    %
    methods
        
        function status = convert(this)
            outFilesMissing = ~(exist(this.outputFile, 'file') && exist(this.metadataFile, 'file'));
            labelFileMissing = ~exist(this.labelFile, 'file');
            
            mustConvertData = this.overwrite || outFilesMissing;
            mustCreateLabels = this.shouldCreateLabels & (mustConvertData || labelFileMissing);
            
            if (~ mustConvertData) && (~ mustCreateLabels)
                status = hive.Status.Skipped;
                return;
            end
            
            if mustConvertData
                results = this.doConvertData();
            else
                results = load(this.metadataFile);
                results.status = hive.Status.Success;
            end
            
            if mustCreateLabels && results.status ~= hive.Status.Failure
                results = doCreateLables(results);
            end
            
            status = results.status;
        end
        
        
        function results = doConvertData(this)            
            nFiles = length(this.inputFiles);
            
            % check files
            checkList = cellfun(@(f) this.checkFile(f, true), this.inputFiles);
            
            if ~ prod(checkList)
                status = hive.Status.Failure;
                return;
            end
            
            % allocate cells for outputs
            data = cell(nFiles, 1);
            header = cell(nFiles, 1);
            fSamp = NaN(nFiles, 1);
            fSweep = NaN(nFiles, 1);
            nSamp = NaN(nFiles, 1);
            nSweep = NaN(nFiles, 1);
            
            % read files
            parfor ix = 1:nFiles
                [data{ix}, fSamp(ix), fSweep(ix), header{ix}] = this.readAbf(ix); %#ok<PFBNS,PFOUS>
                [nSamp(ix), nSweep(ix)] = size(data{ix}); %#ok<PFOUS>
            end
            
            save(this.outputFile, 'data');
            
            % copy vars for save
            files = this.inputFiles; %#ok<NASGU>
            samples = this.sampleWindow; %#ok<NASGU>
            times = this.timeWindow; %#ok<NASGU>
            
            save(this.metadataFile, ...
                'fSamp', 'fSweep', 'header', 'nSamp', 'nSweep', 'files', 'samples', 'times');
            
            if ~ isempty(this.labels)
                % create label file if one doesn't already exist
                if 
            end
            
            status = hive.Status.Success;
        end
    end
    
    %
    % external functions
    %
    methods (Static)
        [d, si, h] = abfload(fn, varargin)
    end
    
    %
    % internal API
    %
    methods (Access = protected)
        
        function tf = shouldCreateLabels(this)
            tf = isempty(this.labels);
        end
        
        function [data, fSamp, fSweep, header] = readAbf(this, ix)
            abfFile = this.inputFiles{ix};
            
            % load the data from the ABF file
            [data, sampInterval, header] = hive.convert.AbfToMat.abfload(abfFile);
            
            % convert data to convenient format
            sampInterval = sampInterval * 1e-6; % seconds
            data = squeeze(data); % remove extra dimensions
            sweepInterval = sampInterval * size(data, 1);
            
            % calculate the time window
            if isnan(this.timeWindow)
                sweepWindow = 1:size(data, 2);
            else
                sweepStart = min(this.timeWindow);
                sweepEnd = max(this.timeWindow);
                
                sweepStartIx = max(1, round(sweepStart / sweepInterval) + 1);
                sweepEndIx = min(size(data, 2), round(sweepEnd / sweepInterval));
                
                sweepWindow = sweepStartIx:sweepEndIx;
            end
            
            % extract the data
            if isnan(this.sampleWindow)
                data = data(:, sweepWindow);
            else
                data = data(this.sampleWindow, sweepWindow);
            end
            
            fSamp = 1/sampInterval;
            fSweep = 1/sweepInterval;
        end
        
    end
    
end

