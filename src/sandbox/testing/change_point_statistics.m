function [] = change_point_statistics()

[path, ~, ~] = fileparts(mfilename('fullpath'));
changes_cache = fullfile(path, 'cache');
changesFiles = utFindFiles({'*.mat'}, changes_cache, true);

allLentghs = [];

for i = 1:length(changesFiles)
    changes = matfile(changesFiles{i});
    nb = changes.noiseBoundaries;
    lengths = diff(nb);
    allLentghs = horzcat(allLentghs, lengths);
end

blockMean = mean(allLentghs);
blockStdDev = std(allLentghs);

filtered = allLentghs(allLentghs <= blockMean + 3 * blockStdDev);

figure(1);
hist(filtered, 200);