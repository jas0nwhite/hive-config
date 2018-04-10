classdef (Abstract) ChemBase
    % Base class of Chemicals for use in HIVE treatments
        
    methods (Static)
        function n = count()
            n = length(enumeration('Chem'));
        end
        
        function c = get(x)
            [m, s] = enumeration('Chem');
            
            if isnumeric(x)
                try
                    c = m(x);
                catch ME
                    error('hive:Chem', 'Chemical not found for index %d', x);
                end
            elseif ischar(x)
                c = m(find(strcmp(s, x), 1, 'first'));
                if isempty(c)
                    error('hive:Chem', 'Chemical not found for name "%s"', x);
                end
            end
        end
        
        function s = names()
            [~, s] = enumeration('Chem');
        end
        
        function m = members()
            [m, ~] = enumeration('Chem');
        end
    end
    
end
