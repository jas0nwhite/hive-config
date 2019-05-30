function X = first_diff(x, dim)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    narginchk(1, 2);
    
    if (nargin < 2)
        dim = 1;
    end
    
    X = diff(x, 1, dim);
end

