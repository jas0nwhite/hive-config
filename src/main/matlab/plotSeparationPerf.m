P = load('/data/hnl/iterate/results_007/model_style_008/cluster_style_001/alpha_select_000/mu_select_000/training-W-uncorrelated-97Hz/2017_09_29_DA_5HT_NE_uncorrelated_octaflow_100k_97Hz/cv-predictions.mat');

%%
s = hgexport('readstyle', 'PNG-4MP');
s.Format = 'png';
s.LineWidthMin = 0.5;


%%
chems = P.chemical;
nChems = numel(chems);
chemset = 1:nChems;

for chemIx = chemset
   principalIx = chemIx;
   confuserset = setdiff(chemset, chemIx);
   
   principal = Chem.get(chems{chemIx});
   
   for confuserIx = confuserset
       confuser = Chem.get(chems{confuserIx});
       
       X = unique(P.labels(:, chemIx));
       Y = unique(P.labels(:, confuserIx));
       Z = nan(numel(X), numel(Y));
       
       for xix = 1:numel(X)
           for yix = 1:numel(Y)
               x = X(xix);
               y = Y(yix);
               pix = P.labels(:, chemIx) == x & P.labels(:, confuserIx) == y;
               Z(yix, xix) = mean(P.predictions(pix, chemIx));
           end
       end
       
       [x, y] = meshgrid(X, Y);
       nanIx = find(isnan(Z));
       x(nanIx) = [];
       y(nanIx) = [];
       Z(nanIx) = [];
       
       tri = delaunay(x, y);
       z = Z(:);
       
       figure;
       
       % reference plane Z = X
       surf([min(X), max(X)], [min(Y), max(Y)], [min(z) max(z); min(z) max(z)], ...
           'EdgeColor', 'none', 'FaceColor', 'k', 'FaceAlpha', 0.25);
       
       hold on;
       
       % predictions
       [xq, yq] = meshgrid(min(X):50:(max(X)+100), min(Y):50:(max(Y)+100));
       zq = griddata(x, y, z, xq, yq);
       surf(xq, yq, zq, 'LineWidth', 0.25);
       scatter3(x, y, z, 'filled', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', 'black');
%        T = trisurf(tri, x, y, z, 'EdgeColor', 'none', 'FaceColor', 'interp');
%        T.Marker = 'o';
%        T.MarkerEdgeColor = 'black';
%        T.MarkerFaceColor = 'black';
       
       % labels
       if isempty(principal.units)
           pUnits = '';
       else
           pUnits = sprintf(' (%s)', principal.units);
       end
       
       if isempty(confuser.units)
           cUnits = '';
       else
           cUnits = sprintf(' (%s)', confuser.units);
       end
       
       xlabel(sprintf('known [%s]%s', principal.label, pUnits));
       ylabel(sprintf('known [%s]%s', confuser.label, cUnits));
       zlabel(sprintf('mean predicted [%s]%s', principal.label, pUnits));
       title(sprintf('%s vs. %s', principal.name, confuser.name));
       
       % finishing touches
       colormap jet;
       colorbar;
       axis tight;
       caxis([0, 3000]);
       xlim([-150, 2650]);
       ylim([-150, 2650]);
       
       hgexport(gcf, sprintf('~/Desktop/%sv%s.png', principal.name, confuser.name), s);
       close;
   end
end