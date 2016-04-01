function dat = characterize(scanList, reference)
    nScans = length(scanList);

    slm = cell(nScans, 1);
    x = 1:60;

    parfor ix = 1:length(scanList)
        scan = scanList{ix};

        slm{ix} = slmengine(x, scan(x), 'degree', 3, 'knots', 3, 'interiorknots', 'free', 'plot', 'off');
    end
    
    refSlm = slmengine(x, reference(x), 'degree', 3, 'knots', 3, 'interiorknots', 'free', 'plot', 'off');

%    k = mean(cellfun(@(s) s.knots(2), slm));
%
%    parfor ix = 1:length(scanList)
%        scan = scanList{ix};
%
%        x = 1:length(scan);
%        y = scan;
%
%        slm{ix} = slmengine(x(1:60), y(1:60), 'degree', 3, 'knots', [1, k, 60], 'plot', 'off');
%    end

    dat.slm = slm;
    dat.refSlm = refSlm;

end