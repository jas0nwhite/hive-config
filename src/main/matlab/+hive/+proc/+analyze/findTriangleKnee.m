function [ x, y ] = characterizeVoltammogram( voltammogram )
%CHARACTERIZEVOLTAMMOGRAM Performs a basic characterization of the given voltammogram
%   [ x, y ] = CHARACTERIZEVOLTAMMOGRAM( voltammogram ) returns coordinates of the first "knee"
%
%   This characterization is the location of the first "knee" in the rising
%   slope of the voltammogram.
%
%   The method to find the knee is:
%     1. extract ROI of first 60 samples
%     2. subtract linear trend defined by endpoints of ROI
%     3. find the x coordinate of the maximum of the de-trended ROI
%     4. return the x and y coordinates of the maximum point on the original voltammogram

    % define region of interest
    roi = voltammogram(1:60);
    nx = length(roi);

    % "resample" with spline to create smoother output
    xp = linspace(1, nx, 10000);
    yp = interp1(1:nx, roi, xp, 'spline');

    % subtract linear trend defined by endpoints of ROI
    yy = yp - linspace(yp(1), yp(end), length(yp));

    % find location and value of maximum
    maxIx = ceil(median(find(yy == max(yy))));

    % return coordinates of maximum
    x = xp(maxIx);
    y = yp(maxIx);

end

