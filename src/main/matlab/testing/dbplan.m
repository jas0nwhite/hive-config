function dbplan(data)

for e = 0.05:0.05:0.5
    
    for m = 10:1:50
        [l, ~] = dbscan(data.u, e, m);
        labs = sort(unique(l));
        cnt = arrayfun(@(x) sum(l == x), labs);
        
        if (length(labs) > 1)
            fprintf('eps: %0.2f, minp: %d, %s, %s\n', e, m, mat2str(labs), mat2str(cnt));
        end
    end
    
end

end