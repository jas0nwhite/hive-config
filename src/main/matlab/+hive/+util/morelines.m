function c = morelines( m )
    %EXLINES Combines "lines" colormap with more colors
    %   taken from http://colorbrewer2.org

    % start with default matlab pallette
    matlab = lines(8);
    
    % add these from colorbrewer -- more pastel
    colorbrewer = [
        102,194,165;
        252,141,98;
        141,160,203;
        231,138,195;
        166,216,84;
        255,217,47;
        229,196,148;
        179,179,179
        ] / 255;
    
    % combine
    combined = vertcat(matlab, colorbrewer);
    s = size(combined, 1);
    
    % default to returning all colors
    if nargin < 1 || isempty(m) || m < 1
        m = s;
    end
    
    % fail if too many colors are requested
    if m > s
        error('Too many colors! (%d > %d)', m, s);
    end
    
    % return requested subset
    c = combined(1:m, :);
end

