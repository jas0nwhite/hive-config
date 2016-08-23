classdef InvitroDataset
    %INVITRODATASET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        acqDate
        analyteClass
        protocol
        probeDesignation
        probeDate
        probeName
    end
    
    methods
        function this = InvitroDataset(dsDate, dsClass, dsProtocol, pName, pDate)
            this.acqDate = dsDate;
            this.analyteClass = dsClass;
            this.protocol = dsProtocol;
            this.probeDesignation = pName;
            this.probeDate = pDate;
            
            if (length(pDate) == 0)
                this.probeName = pName;
            else
                this.probeName = [pName '_' pDate];
            end
        end
    end
    
end

