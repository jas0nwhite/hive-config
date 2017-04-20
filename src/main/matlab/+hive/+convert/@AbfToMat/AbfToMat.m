classdef AbfToMat < hive.util.Logging
    %ABFTOMAT Converter for ABF files to MATLAB files
    
    properties (Access = protected)
        inputFiles
        vgramChannel
        outputFile
        metadataFile
        otherFile
        sampleWindow
        timeWindow
        overwrite = false
        chemLabels = nan(0);
        chemNames = {};
        labelFile
        dsName
        dsId
        setId
        sourceId
        treatmentName
    end
    
    %
    % builders
    %
    methods
        
        function this = AbfToMat(inputFiles, vgramChannel, outputFile, metadataFile, otherFile, sampleWindow, timeWindow)
            this.inputFiles = inputFiles;
            this.vgramChannel = vgramChannel;
            this.outputFile = outputFile;
            this.metadataFile = metadataFile;
            this.otherFile = otherFile;
            this.sampleWindow = this.windowToRange(sampleWindow);
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
            this.labelFile = labelFile;
        end
        
        function this = withDatasetInfo(this, dsName, dsId, setId, sourceId, treatmentName)
            this.dsName = dsName;
            this.dsId = dsId;
            this.setId = setId;
            this.sourceId = sourceId;
            this.treatmentName = treatmentName;
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
                results = this.doCreateLabels(results);
            end
            
            status = results.status;
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
            tf = ~ isempty(this.chemLabels);
        end
        
        function range = windowToRange(~, window)
            if sum(isnan(window)) > 0
                range = NaN;
            elseif length(window) == 2
                range = window(1):window(2);
            else
                range = window;
            end
        end
        
        function appendDatasetInfo(this, filename)
            hive.util.appendDatasetInfo(filename, ...
                this.dsName, this.dsId, this.setId, this.sourceId, this.treatmentName);
        end
        
        function results = readAbf(this, ix)
            abfFile = this.inputFiles{ix};
            
            % load the data from the ABF file
            [raw, sampInterval, header] = hive.convert.AbfToMat.abfload(abfFile);
            
            % find the channel index
            vgramChannelIx = arrayfun(@(s) strcmpi(s, this.vgramChannel), header.recChNames);
            
            if numel(vgramChannelIx) > 1
                otherChannels = header.recChNames{~vgramChannelIx};
            else
                otherChannels = {};
            end
            
            % convert data to convenient format
            sampInterval = sampInterval * 1e-6; % seconds
            otherData = squeeze(raw(:, ~vgramChannelIx, :)); % extract other data
            data = squeeze(raw(:, vgramChannelIx, :)); % extract voltammogram data
            sweepInterval = sampInterval * unique(diff(header.sweepStartInPts));
            
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
            if sum(isnan(this.sampleWindow)) > 0
                sampWindow = 1:size(data, 1);
            else
                sampWindow = this.sampleWindow;
            end
            
            data = data(sampWindow, sweepWindow);
            
            sampleFreq = 1/sampInterval;
            sweepFreq = 1/sweepInterval;
            
            % return results
            results.data = data;
            results.sampleFreq = sampleFreq;
            results.sweepFreq = sweepFreq;
            results.header = header;
            results.sampleWindow = sampWindow;
            results.sweepWindow = sweepWindow;
            results.otherData = otherData;
            results.otherChannels = otherChannels;            
        end
        
        function results = doConvertData(this)
            nFiles = length(this.inputFiles);
            
            % check files
            checkList = cellfun(@(f) this.checkFile(f, true), this.inputFiles);
            
            if ~ prod(checkList)
                results.status = hive.Status.Failure;
                return;
            end
            
            % allocate cells for outputs
            voltammograms = cell(nFiles, 1);
            headers = cell(nFiles, 1);
            sampleFreq = NaN(nFiles, 1);
            sweepFreq = NaN(nFiles, 1);
            nSamples = NaN(nFiles, 1);
            nSweeps = NaN(nFiles, 1);
            recTime = NaN(nFiles, 1);
            sampleIx = cell(nFiles, 1);
            sweepIx = cell(nFiles, 1);
            otherData = cell(nFiles, 1);
            otherChannels = cell(nFiles, 1);
            
            
            % read files
            for ix = 1:nFiles                
                abf = this.readAbf(ix);
                
                voltammograms{ix} = abf.data;
                sampleFreq(ix) = abf.sampleFreq;
                sweepFreq(ix) = abf.sweepFreq;
                headers{ix} = abf.header;
                sampleIx{ix} = abf.sampleWindow;
                sweepIx{ix} = abf.sweepWindow;
                otherData{ix} = abf.otherData;
                otherChannels{ix} = abf.otherChannels;
                
                [nSamples(ix), nSweeps(ix)] = size(voltammograms{ix});
                recTime(ix) = diff(headers{ix}.recTime);
            end
            
            save(this.outputFile, 'voltammograms');
            this.appendDatasetInfo(this.outputFile);
            
            if sum(arrayfun(@(c) numel(c{:}), otherData)) > 0
                save(this.otherFile, 'otherData', 'otherChannels');
                this.appendDatasetInfo(this.otherFile);
            end
            
            % copy vars for save
            results.headers = headers;
            results.sampleFreq = sampleFreq;
            results.sweepFreq = sweepFreq;
            results.nSamples = nSamples;
            results.nSweeps = nSweeps;
            results.sampleIx = sampleIx;
            results.sweepIx = sweepIx;
            results.files = this.inputFiles;
            results.recTime = recTime;
            
            save(this.metadataFile, '-struct', 'results');
            this.appendDatasetInfo(this.metadataFile);
            
            results.status = hive.Status.Success;
        end
        
        function results = doCreateLabels(this, results)
            nFiles = length(results.files);
            data.labels = cell(nFiles, 1);
            
            for ix = 1:nFiles
                data.labels{ix} = repmat(this.chemLabels(ix, :), results.nSweeps(ix), 1);
            end
            
            data.chemicals = this.chemNames; %#ok<STRNU>
            
            save(this.labelFile, '-struct', 'data');
            this.appendDatasetInfo(this.labelFile);
            
            results.status = hive.Status.Success;
        end
        
    end
    
end

