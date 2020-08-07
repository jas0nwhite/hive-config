classdef (Abstract) CatalogBase < hive.util.Logging
    % base class for catalogs
    
    properties (Abstract, Constant)
        sourceSpecList
        resultPathList
        vgramWindowList
        sourceCatalog
        datasetCatalog
    end
    
    %
    % API
    %
    methods
        
        function [id, name, directory] = getSourceInfo(this, setIx, sourceIx)
            if nargin == 2
                [setIx, sourceIx] = this.getSourceIxByDatasetId(setIx);
            end
            
            if isempty(this.datasetCatalog{setIx})
                id = NaN;
                name = missing;
                directory = missing;
            else                
                id = this.datasetCatalog{setIx}{sourceIx, 1};
                name = this.datasetCatalog{setIx}{sourceIx, 2};
                directory = this.sourceCatalog{setIx}{sourceIx, 2};
            end
        end
        
        function id = getDatasetId(this, setIx, sourceIx)
            if isempty(this.datasetCatalog{setIx})
                id = NaN;
            else                
                id = this.datasetCatalog{setIx}{sourceIx, 1};
            end
        end
        
        function [setIx, sourceIx] = getSourceIxByDatasetId(this, datasetId)
            nSets = size(this.datasetCatalog, 1);
            locations = cell(nSets, 1);
            
            for ix = 1:nSets
                if ~isempty(this.datasetCatalog{ix})
                    ixList = vertcat(this.datasetCatalog{ix}{: , 1});
                    [mL, mIx] = ismember(datasetId, ixList);
                    locations{ix} = mIx(mL);
                else
                    locations{ix} = [];
                end
            end
            
            setIx = find(cellfun(@(v) ~isempty(v), locations));
            
            if numel(datasetId) == 1
                sourceIx = locations{setIx, 1};
            else
                sourceIx = locations(setIx, :);
            end
        end
        
        function val = getSetValue(~, setList, setIx)
            nVals = size(setList, 1);
            
            if setIx > nVals
                val = setList{1};
            else
                val = setList{setIx};
            end
        end
        
        function n = getSize(~, setList, setIx)
            if nargin == 2
                n = sum(cellfun(@(c) size(c, 1), setList));
            else
                n = size(setList{setIx}, 1);
            end
        end
        
    end
    
    %
    % internal API
    %
    methods (Access = protected)
        
    end
    
end
