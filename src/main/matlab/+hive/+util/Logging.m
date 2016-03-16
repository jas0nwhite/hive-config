classdef (Abstract) Logging
    %LOGGING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function warn(this, id, message, varargin)
            this.doWarn(3, id, message, varargin{:})
        end
        
        function error(this, id, message, varargin)
            this.doError(3, id, message, varargin{:})
        end
        
        function exists = checkFile(this, file, shouldContinue)
            if nargin < 3
                shouldContinue = false;
            end
            
            exists = exist(file, 'file');
            
            if ~ exists
                if (shouldContinue)
                    this.doWarn(3, 'FileNotFound', 'file "%s" does not exist', file);
                else
                    this.doError(3, 'FileNotFound', 'file "%s" does not exist', file);
                end
            end
        end
    end
    
    methods (Access = protected)
        function doWarn(~, ix, id, message, varargin)
            [cls, fn] = hive.util.Logging.currentFrame(ix);
            msgId = sprintf('HIVE:%s', id);
            warning(msgId, [message ' (in %s:%s)'], varargin{:}, cls, fn);
        end
        
        function doError(~, ix, id, message, varargin)
            [cls, fn] = hive.util.Logging.currentFrame(ix);
            msgId = sprintf('HIVE:%s', id);
            error(msgId, [message ' (in %s:%s)'], varargin{:}, cls, fn);
        end
    end
    
    methods (Static, Access = protected)
        function [cls, fn] = currentFrame(ix)
            if nargin == 0
                ix = 1;
            end
            
            dbk = dbstack( 1, '-completenames' );
            if isempty(dbk)
                str = 'base';
            else
                ix = min(ix, length(dbk));
                str = dbk(ix).name;
            end
            cac = regexp( str, '\.', 'split' );
            switch  numel( cac )
                case 1
                case 2
                    %cls = meta.class.fromName( cac{1} );
                    cls = cac{1};
                    fn = cac{2};
                case 3
                otherwise
            end
        end
    end
end

