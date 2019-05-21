classdef (Abstract) ConverterBase < hive.util.Logging
    %CONVERTERBASE Summary of this class goes here
    %   Detailed explanation goes here
    
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
        jitterCorrector = []
        doParfor = false
        doStability = true
    end
    
    %
    % builders
    %
    methods
        
        function this = ConverterBase(...
                inputFiles, ...
                vgramChannel, ...
                outputFile, ...
                metadataFile, ...
                otherFile, ...
                sampleWindow, ...
                timeWindow)
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
        
        function this = withJitterCorrector(this, object)
            this.jitterCorrector = object;
        end
        
        function this = inParallel(this, flag)
            this.doParfor = flag;
        end
        
        function this = withStabilitySearch(this, flag)
            this.doStability = flag;
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
    % delegates
    %
    methods (Abstract, Access = protected)
        [raw, sampInterval, header] = loadRaw(this, rawFile);
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
        
        function results = readRaw(this, ix)
            rawFile = this.inputFiles{ix};
            
            % load the data from the raw file
            try
                [raw, sampInterval, header] = this.loadRaw(rawFile);
            catch ME
                fprintf('\n***\n*** ERROR processing file %s\n***\n', rawFile);
                rethrow(ME);
            end
            
            % find the channel index
            vgramChannelIx = ~isempty(regexpi(header.recChNames, this.vgramChannel));
            
            if numel(vgramChannelIx) > 1
                otherChannels = header.recChNames{~vgramChannelIx};
            else
                otherChannels = {};
            end
            
            % convert data to convenient format
            sampInterval = sampInterval * 1e-6; % seconds
            otherData = squeeze(raw(:, ~vgramChannelIx, :)); % extract other data
            data = squeeze(raw(:, vgramChannelIx, :)); % extract voltammogram data
            sweepInterval = sampInterval * unique(round(diff(header.sweepStartInPts), 6));
            
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
            
            
            %
            % TODO: clean this up
            %
            
            if this.doStability
                % find the most stable region of the file
                [sweepWindow, excludeIx, r, q, fig] = ...
                    hive.proc.invitro.findStableSection(data, sweepWindow);
                
                % annotate the plot
                [dirName, filename, ~] = fileparts(rawFile);
                [~, dirName, ~] = fileparts(dirName);
                ax = findobj(fig, 'type', 'axes', 'Tag', '');
                
                plotTitle = strrep(dirName, '_', '\_');
                plotSubtitle = strrep(strrep(filename, dirName, ''), '_', '');
                
                title(ax(end), {
                    plotTitle
                    plotSubtitle
                    });
                
                
                % save the plot in the output directory
                s = hgexport('readstyle', 'PNG-4MP');
                s.Format = 'png';
                [outDir, ~, ~] = fileparts(this.outputFile);
                hgexport(fig, fullfile(outDir, [filename '.png']), s);
                close(fig);
            else
                excludeIx = [];
                r = [];
                q = [];
            end
            
            
            % extract the sweeps
            data = data(:, sweepWindow);
            
            % detect jitter
            if isobject(this.jitterCorrector)
                % TODO: FIX THIS HACK
                switch round(1/sweepInterval)
                    case 10
                        jitterWindow = 160:1159;
                    case 97
                        jitterWindow = 16:1015;
                    case 242
                        jitterWindow = 16:1015;
                    otherwise
                        error('HACK: nhandled sweep frequency %0.2f', 1/sweepInterval);
                end
                
                jitterIx = this.jitterCorrector.findJitter(data(jitterWindow, :));
            else
                jitterIx = excludeIx;
            end
            
            % extract the samples
            if sum(isnan(this.sampleWindow)) > 0
                sampWindow = 1:size(data, 1);
            else
                sampWindow = this.sampleWindow;
            end
            
            try
                data = data(sampWindow, :);
            catch ME
                if strcmp(ME.identifier, 'MATLAB:badsubscript')
                    this.warn( ...
                        'BadSampleWindow', ...
                        'sample window [%d:%d] exceeds data dimensions [%d]', ...
                        min(sampWindow), max(sampWindow), size(data, 1));
                end
            end
            
            sampleFreq = 1/sampInterval;
            
            if isempty(sweepInterval)
                % single sweep
                sweepFreq = NaN;
            else
                % multiple sweep
                sweepFreq = 1/sweepInterval;
            end
            
            % return results
            results.data = data;
            results.sampleFreq = sampleFreq;
            results.sweepFreq = sweepFreq;
            results.header = header;
            results.sampleWindow = sampWindow;
            results.sweepWindow = sweepWindow;
            results.otherData = otherData;
            results.otherChannels = otherChannels;
            results.jitterIx = jitterIx;
            results.sweepWindowCorrCoef = r;
            results.sweepWindowQuality = q;
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
            jitterIx = cell(nFiles, 1);
            sweepWindowCorrCoef = cell(nFiles, 1);
            sweepWindowQuality = cell(nFiles, 1);
            
            % read files
            if (this.doParfor)
                parfor ix = 1:nFiles
                    raw = this.readRaw(ix); %#ok<PFBNS>
                    
                    voltammograms{ix} = raw.data; %#ok<PFOUS>
                    sampleFreq(ix) = raw.sampleFreq;
                    sweepFreq(ix) = raw.sweepFreq;
                    headers{ix} = raw.header;
                    sampleIx{ix} = raw.sampleWindow;
                    sweepIx{ix} = raw.sweepWindow;
                    otherData{ix} = raw.otherData;
                    otherChannels{ix} = raw.otherChannels; %#ok<PFOUS>
                    jitterIx{ix} = raw.jitterIx;
                    sweepWindowCorrCoef{ix} = raw.sweepWindowCorrCoef;
                    sweepWindowQuality{ix} = raw.sweepWindowQuality;
                    
                    [nSamples(ix), nSweeps(ix)] = size(voltammograms{ix});
                    recTime(ix) = diff(headers{ix}.recTime);
                end
            else
                for ix = 1:nFiles
                    raw = this.readRaw(ix);
                    
                    voltammograms{ix} = raw.data;
                    sampleFreq(ix) = raw.sampleFreq;
                    sweepFreq(ix) = raw.sweepFreq;
                    headers{ix} = raw.header;
                    sampleIx{ix} = raw.sampleWindow;
                    sweepIx{ix} = raw.sweepWindow;
                    otherData{ix} = raw.otherData;
                    otherChannels{ix} = raw.otherChannels;
                    jitterIx{ix} = raw.jitterIx;
                    sweepWindowCorrCoef{ix} = raw.sweepWindowCorrCoef;
                    sweepWindowQuality{ix} = raw.sweepWindowQuality;
                    
                    [nSamples(ix), nSweeps(ix)] = size(voltammograms{ix});
                    recTime(ix) = diff(headers{ix}.recTime);
                end
            end
            
            varinfo = whos('voltammograms');
            formatArgs = {};
            if varinfo.bytes > 1.75 * 2^30
                % vgrams are over 1.75G... use v7.3 format
                formatArgs = {'-v7.3', '-nocompression'};
            end
            
            save(this.outputFile, 'voltammograms', formatArgs{:});
            this.appendDatasetInfo(this.outputFile);
            
            if sum(arrayfun(@(c) numel(c{:}), otherData)) > 0
                save(this.otherFile, 'otherData', 'otherChannels', '-v7.3', '-nocompression');
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
            results.jitterIx = jitterIx;
            results.sweepWindowCorrCoef = sweepWindowCorrCoef;
            results.sweepWindowQuality = sweepWindowQuality;
            
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
            
            data.chemicals = this.chemNames;
            
            save(this.labelFile, '-struct', 'data');
            this.appendDatasetInfo(this.labelFile);
            
            results.status = hive.Status.Success;
        end
        
    end
end

