function dbplot(eps, minpts, data)

[l, lc] = dbscan(data, eps, minpts);
n = find(l == -1);
b = find(lc == -2);
c = find(l > 0);

labs = sort(unique(l));
count = arrayfun(@(x) sum(l == x), labs);

disp(table(labs, count));
fprintf('%d total points\n', length(c));

x = data(:, 1);
y = data(:, 2);
nClust = length(labs) - 1;

figure;

hold on;
colormap(lines(nClust + 2));
colors = colormap;
scatter(x(n), y(n), 10, colors(nClust + 1, :), 'filled', 'MarkerFaceAlpha', 0.5);
scatter(x(b), y(b), 50, colors(nClust + 2, :), 'filled', 'MarkerFaceAlpha', 0.25);
scatter(x(c), y(c), 20, colors(l(c), :), 'filled');
hold off;

end