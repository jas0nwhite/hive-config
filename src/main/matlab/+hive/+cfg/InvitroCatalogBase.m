classdef (Abstract) InvitroCatalogBase < hive.cfg.CatalogBase
    % base class for catalogs
    
    properties (Abstract, Constant)
        
    end
    
    %
    % API
    %
    methods
        
        function datasets = getDatasetTable(this, setIx)
            
            % return if nothing to do
            if setIx < 1 || setIx > numel(this.infoCatalog)
                this.error(...
                    'InvalidSetIx',...
                    'invalid setIx %d: number of sets = %d',...
                    setIx, numel(this.infoCatalog));
            end
            
            % get the array of dataset indices for this set
            dsIx = arrayfun(@(s) s, vertcat(this.infoCatalog{setIx}{:, 1}));
            
            % get the array of InvitroDataset objects for this set
            s = arrayfun(@(s) s, vertcat(this.infoCatalog{setIx}{:, 2}));
            
            % convert the array of objects into a table by coercing each object
            % into a structure
            w = warning('off', 'MATLAB:structOnObject');
            datasets = struct2table(arrayfun(@struct, s));
            warning(w);
            
            % convert column types
            vn = datasets.Properties.VariableNames;
            datasets = varfun(@string, datasets);
            datasets.Properties.VariableNames = vn;
            datasets.acqDate = datetime(datasets.acqDate, 'InputFormat', 'yyyy-MM-dd');
            
            % add index
            datasets.dsIx = dsIx;
            
            % sort it nicely for processing
            datasets = sortrows(datasets, {'probeName', 'acqDate', 'dsIx'});
            
        end
        
    end
    
    %
    % internal API
    %
    methods (Access = protected)
        
    end
    
end

