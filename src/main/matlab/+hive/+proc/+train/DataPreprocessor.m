classdef DataPreprocessor < hive.util.Logging
    %DATAPREPROCESSOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        preprocFn = @(x) x;
    end
    
    methods
        function this = DataPreprocessor(cfg)
            %DATAPREPROCESSOR Construct an instance of this class
            %   Detailed explanation goes here
            
            switch cfg.trainingStyleId % for waveform processing
                case 500
                    this.preprocFn = @hive.proc.model.log_P1_fft;
                    
                otherwise
                    this.preprocFn = @hive.proc.model.first_diff;
            end
        end
        
        function fn = getPreprocessFn(this)
            %GETPREPROCESSFN Summary of this method goes here
            %   Detailed explanation goes here
            
            fn = @this.preprocFn;
        end
    end
end

