function dat = characterizeSlope(scanList, reference)
    nScans = length(scanList);

    slope = nan(nScans, 2);

    parfor ix = 1:length(scanList)
        scan = scanList{ix};

        slope(ix, 1) = 
    end

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

end