function dat = characterize(scanList, reference)
    nScans = length(scanList);

    slm = cell(nScans, 1);
    x = 1:60;
    knots = 3; %[1 15 60];
    
    prescription = slmset('degree', 1, ...
        'knots', knots, ...
        'interiorknots', 'free', ...
        'plot', 'off');

    refSlm = slmengine(x, reference(x), prescription);
    
    refKnots = refSlm.knots;
    
    parfor ix = 1:length(scanList)
        scan = scanList{ix};
        
        slm{ix} = slmengine(x, scan(x), prescription, 'knots', refKnots);
    end

    dat.slm = slm;
    dat.refSlm = refSlm;

end