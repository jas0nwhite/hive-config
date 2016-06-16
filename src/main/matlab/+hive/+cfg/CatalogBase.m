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
            nSets = size(this.datasetCatalog, 1);
            locations = cell(nSets, 1);
            
            for ix = 1:nSets
                if ~isempty(this.datasetCatalog{ix})
                    locations{ix} = find(vertcat(this.datasetCatalog{ix}{: , 1}) == datasetId);
                else
                    locations{ix} = [];
                end
            end
            
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
