classdef (Abstract) CatalogBase
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
            
            id = this.datasetCatalog{setIx}{sourceIx, 1};
            name = this.datasetCatalog{setIx}{sourceIx, 2};
            directory = this.sourceCatalog{setIx}{sourceIx, 2};
        end
        
        function [setIx, sourceIx] = getSourceIxByDatasetId(this, datasetId)
            locations = cellfun(@(c) find(vertcat(c{:, 1}) == datasetId), this.datasetCatalog,...
                'UniformOutput', false);
            
            setIx = find(cellfun(@(v) ~isempty(v), locations));
            sourceIx = locations{setIx};
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
                n = sum(cellfun(@(c) length(c), setList));
            else
                n = length(setList{setIx});
            end
        end
        
    end
    
    %
    % internal API
    %
    methods (Access = protected)
        
    end
    
end
