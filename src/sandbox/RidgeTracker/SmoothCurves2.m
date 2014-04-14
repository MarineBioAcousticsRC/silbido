function R=SmoothCurves2(TT,type,smoothing)
% SmoothCurves2
%
% Performs modified 2-D Kalman smoothing on a set of curves, and removes
% any non-monotonicities.
%
% Input:
%   TT - Cell array of curves
%   type - Type of smoothing. 1: 1-dimensional smoothing. 2: not
%          implemented
%   smoothing - Smoothing parameter to Kalman filter
%
% Output:
%   R - Cell array of smoothed curves
%

if nargin<2
    type=1;
end
if nargin<3
    smoothing=1000;
end

% smooth each of the ridges in TT, using the Kalman filter
for n=1:length(TT);
    r=KalmanSmoothCurve2(TT{n},type,smoothing);
    % Remove non-monotonic step (time reversals)
    R{n}=RemoveNonMonotonicities(r);
end
