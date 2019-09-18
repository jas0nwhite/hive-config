classdef LabelTransformer < hive.util.Logging
    %LABELTRANSFORMER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fwdXformFn
        revXformFn
    end
    
    %
    % PUBLIC API
    %
    methods (Static)
        function this = forTrainingStyle(style)
            this = hive.proc.model.LabelTransformer();
            this = this.setFunctions(style);
        end
    end
    
    methods
        function y2 = apply(this, y)
            y2 = this.fwdXformFn(y);
        end
        
        function y = unapply(this, y2)
            y = this.revXformFn(y2);
        end
    end
    
     %
     % IMPLEMENTATION
     %
     methods (Access = protected)
         function this = setFunctions(this, style)
             switch style
                 case 10
                     %
                     % square-root / sign-preserving square
                     %
                     this.fwdXformFn = @(x) realsqrt(x); % labels should not be negative
                     this.revXformFn = @(x) sign(x) .* power(x, 2); % preserve sign
                 otherwise
                     %
                     % pass-thru
                     %
                     this.fwdXformFn = @(x) x;
                     this.revXformFn = @(x) x;
             end
         end
     end
end

