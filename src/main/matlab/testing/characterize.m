function dat = characterize(scanList)
    nScans = length(scanList);

    fit = cell(nScans, 1);
    d = 2;
    x = 1:30;    
    
    prescription = slmset('degree', 3, ...
        'interiorknots', 'free', ...
        'plot', 'off');

    parfor ix = 1:length(scanList)
        scan = scanList{ix};
        
        y = scan(x);
        
        slm = slmengine(x, y, prescription);
        xp = linspace(min(x), max(x), 10001);
        yp = slmeval(xp, slm);
        
        xx = xp((d+1):end);
        yy = diff(yp, d);
        
        minIx = find(yy == min(yy), 1, 'first');
        
        fit{ix}.xp = xp;
        fit{ix}.yp = yp;
        fit{ix}.xx = xx;
        fit{ix}.yy = yy;
        fit{ix}.x = xp(minIx + d);
        fit{ix}.y = yp(minIx + d);
    end

    dat.fit = fit;
end