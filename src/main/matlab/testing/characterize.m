function dat = characterize(scanList)
    nScans = length(scanList);

    fit = cell(nScans, 1);

    for ix = 1:length(scanList)
        scan = scanList{ix}(1:60);
        nx = length(scan);
        
        xp = linspace(1, nx, 3000);
        yp = interp1(1:nx, scan, xp, 'spline');

        yy = yp - linspace(yp(1), yp(end), length(yp));

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