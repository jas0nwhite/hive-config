classdef (Abstract) CatalogBase
    % base class for catalogs

    properties (Abstract, Constant)
    	sourceSpecList
	resultPathList
	voltammetryWindow
	sourceCatalog
	datasetCatalog
   end

end
