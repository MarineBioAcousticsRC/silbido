function [outliers, threshold] = stTukeyRightOutlier(data, q1, q3, scale)
% [outliers, threshold] = stTukeyRightOutlier(data, q1, q3, scale)
% Given first and third quartiles for a dataset data,
% return indicator function outliers where 1 indicates a right-sided
% outlier:
%   data > q3 + scale * (q3-q1)
%
% If omitted, scale is the canonical scale factor of 1.5
%
% Optional output threshold returns the criterion value q3+scale*(q3-q1)
%
% Reference:
% Emerson, J. D., and Strenio, J. (1983). "Boxplots and batch
% comparison," in
% _Understanding Robust and Exploratory Data Analysis_, edited by D. C.
% Hoaglin, F. Mosteller, and J. W. Tukey (John Wiley & Sons, Inc., 
% New York), pp. 58-96.

if nargin < 4
    scale = 1.5;
end

threshold = q3 + scale * (q3 - q1);
outliers = data > threshold;

