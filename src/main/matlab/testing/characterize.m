function dat = characterize(scanList)
    nScans = length(scanList);

    fit = cell(nScans, 1);

    for ix = 1:length(scanList)
        % extract window of interest (WoI)
        if iscell(scanList)
            scan = scanList{ix}(1:60);
        else
            scan = scanList(1:60, ix);
        end
        
        nx = length(scan);
        
        % "resample" with spline to create smoother output
        xp = linspace(1, nx, 3000);
        yp = interp1(1:nx, scan, xp, 'spline');

        % subtract linear trend defined by endpoints of WoI
        yy = yp - linspace(yp(1), yp(end), length(yp));

        % find location and value of maximum
        maxIx = ceil(median(find(yy == max(yy))));
        
        x0 = xp(maxIx);
        y0 = yp(maxIx);

        fit{ix}.xp = [];
        fit{ix}.yp = [];
        fit{ix}.x = x0;
        fit{ix}.y = y0;
    end

    dat.fit = fit;
end