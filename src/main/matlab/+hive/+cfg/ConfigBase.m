classdef (Abstract) ConfigBase
    % configruation base class for all HIVE treatments
    
    %
    % treatment definition
    %
    properties (Abstract, Constant)
        name
        trainingSetId
        trainingStyleId
        clusterStyleId
        alphaSelectId
        muSelectId
    end
    
    %
    % treatment directories
    %
    properties (Abstract, Constant)
        projectHome
        trainingHome
        testingHome
        modelHome
        clusterHome
        alphaHome
        muHome
        codePath
    end
    
    %
    % catalogs
    %
    properties (Abstract, Constant)
        training
        testing
        target
    end
    
end
