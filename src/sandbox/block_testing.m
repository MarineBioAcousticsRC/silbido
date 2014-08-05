allBocks = zeros(0,2);

allBocks = vertcat(allBocks, [0, 2]);
allBocks = vertcat(allBocks, [2, 5]);
allBocks = vertcat(allBocks, [5, 9]);
allBocks = vertcat(allBocks, [9, 14]);
allBocks = vertcat(allBocks, [14, 20]);
allBocks = vertcat(allBocks, [20, 27]);
allBocks = vertcat(allBocks, [27, 45]);
allBocks = vertcat(allBocks, [45, 45.3]);
allBocks = vertcat(allBocks, [45.3, 51.3]);
allBocks = vertcat(allBocks, [51.3, 51.7]);

segmentBlocks = dtBlocksForSegment(allBocks, 6, 29);
segmentBlocks