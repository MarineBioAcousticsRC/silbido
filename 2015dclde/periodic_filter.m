function [valid, outliers] = periodic_filter(detections, period_s, varargin)
% [valid, outliers] = periodic_filter(detections, period_s)
% Look for how detection times occur over a given period.
% Return an indicator function where an abnormal number of detections
% within a short interval (as per an outlier test) are marked as invalid.
% On HARP data, the peridoic disk write is periodic frequently detected
% by silbido as a tonal contour.  This function eliminates these as there
% will be many more of this type of detection.  It also eliminates correct
% detections that occur at the same time as the disk write.
%
% outliers is a structure representing information about histogram used to
% determine outlier regions.  It include fields:
% edges - bin edges in s
% centers - bin centers in s
% binwdith - Width of bin in s
% bincounts - # detections within each bin
% thr - Outlier count threshold
% quartiles - Quartile values for .25 .5 .75
% outlierP - outlier bin predicate outlierP(k)=1 --> bin(k) is an outlier
% outlierIdx - Indices of outlier bins == find(outliers.outlierP)

periodOutlierPercent = 0;

vidx=1;
while vidx < length(varargin)
  switch varargin{vidx}
        case 'periodOutlierPercent'
            periodOutlierPercent = varargin{vidx+1};
            vidx = vidx+2;
  end
end


moddet = rem(detections, period_s);  % rewrite detections modulo period

% distribute number of bins/s evenly across period and get hist counts
bins_per_s = 3;
edges = linspace(0, period_s, period_s*bins_per_s + 1);
centers = mean([edges(1:end-1); edges(2:end)]);
counts = hist(moddet, centers);
% determine bin assignments for each detection
binwidth_s = edges(2) - edges(1);
binassignments = ceil(moddet / binwidth_s);



if periodOutlierPercent ~= 0
    outliers.outlierIdx = find(moddet > ...
        (period_s*(1-periodOutlierPercent/100))...
        | moddet < (period_s*periodOutlierPercent/100));
    outliers.outlierP = moddet(outliers.outlierIdx);
    valid = ~ismember(1:size(detections,1),outliers.outlierIdx);
else
    % perform outlier test
    Q = stQuartiles(counts);
    [outliers.outlierP, thr] = stTukeyRightOutlier(counts, Q(1), Q(3));
    outliers.outlierIdx = find(outliers.outlierP);





    % Report informationa bout outliers
    outliers.edges = edges;  % bin edges
    outliers.centers = centers;
    outliers.bincounts = counts;
    outliers.thr = thr; 
    outliers.quartiles = Q;
    outliers.bin_width = edges(2) - edges(1);

    valid = ~ ismember(binassignments, outliers.outlierIdx);

end
