classdef AbfToMat < hive.convert.ConverterBase
    %ABFTOMAT Converter for ABF files to MATLAB files
    
    %
    % builders
    %
    methods
        
        function this = AbfToMat(...
                inputFiles, ...
                vgramChannel, ...
                outputFile, ...
                metadataFile, ...
                otherFile, ...
                sampleWindow, ...
                timeWindow)
            this = this@hive.convert.ConverterBase(...
                inputFiles, ...
                vgramChannel, ...
                outputFile, ...
                metadataFile, ...
                otherFile, ...
                sampleWindow, ...
                timeWindow);
        end
        
    end
    
    
    %
    % external functions
    %
    methods (Static)
        [d, si, h] = abfload(fn, varargin)
    end
    
    
    %
    % delegate implementation
    %
    methods (Access = protected)
        
        function [raw, sampInterval, header] = loadRaw(this, rawFile)
            [raw, sampInterval, header] = this.abfload(rawFile);
            
            % format creation date from values found in the header
            startDate = num2str(header.uFileStartDate);
            startTime = header.uFileStartTimeMS / 1000;
            
            try
                startDate = datetime(startDate, 'InputFormat', 'yyyyMMdd');
            catch
                log.warning('ABF file contains invalid date');
                startDate = today('datetime');
            end
            
            timeStamp = startDate + seconds(startTime);
            header.abfTimestamp = posixtime(timeStamp);
        end
        
    end
    
end

