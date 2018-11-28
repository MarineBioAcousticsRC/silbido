function Q = stQuartiles(data)
% Q = stQuartiles(data)
% Return values of 1st, 2nd, and 3rd quartiles in data set.

sdata = sort(data);
indices = round([.25 .5 .75]*length(data));
Q = sdata(indices);
