classdef H5ToMat < hive.convert.ConverterBase
    %H5TOMAT Converter for HDF5 files to MATLAB files
    
    %
    % builders
    %
    methods
        
        function this = H5ToMat(...
                inputFiles, ...
                vgramChPattern, ...
                outputFile, ...
                metadataFile, ...
                otherFile, ...
                sampleWindow, ...
                timeWindow)
            this = this@hive.convert.ConverterBase(...
                inputFiles, ...
                vgramChPattern, ...
                outputFile, ...
                metadataFile, ...
                otherFile, ...
                sampleWindow, ...
                timeWindow);
        end
        
    end
    
    
    %
    % delegate implementation
    %
    methods (Access = protected)
        
        function [raw, sampInterval, header] = loadRaw(~, rawFile)
            % header req's: sampInterval, recChNames, recTime, sweepStartInPts
            header = struct();
            header.abfTimestamp = h5readatt(rawFile, '/header', 'abfTimestamp');
            header.recChNames = h5readatt(rawFile, '/header', 'recChNames');
            header.recTime = h5readatt(rawFile, '/header', 'recTime');
            header.sampleFreq = h5readatt(rawFile, '/header', 'sampleFreq');
            header.sweepCount = h5readatt(rawFile, '/header', 'sweepCount');
            header.sweepFreq = h5readatt(rawFile, '/header', 'sweepFreq');
            header.sweepSampleCount = h5readatt(rawFile, '/header', 'sweepSampleCount');
            
            header.sweepStartInPts = h5read(rawFile, '/header/sweepStartInPts');
            header.sweepTimes = h5read(rawFile, '/header/sweepTimes');

            sampInterval = h5readatt(rawFile, '/header', 'si');
            
            raw = h5read(rawFile, '/data');
            raw = permute(raw, [3, 2, 1]);
        end
        
    end
    
end

