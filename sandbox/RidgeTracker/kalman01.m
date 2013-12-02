%
%   ---------------------------------------------------------------------
%
%   Copyright 2011 The MathWorks, Inc.
%
%   ---------------------------------------------------------------------
%
function y = kalman01(z,smoothing) 
if nargin<2
    smoothing=1000;
end

% Initialize state transition matrix
dt=1;
A=[ 1 0 dt 0 0 0;...
    0 1 0 dt 0 0;...
    0 0 1 0 dt 0;...
    0 0 0 1 0 dt;...
    0 0 0 0 1 0 ;...
    0 0 0 0 0 1 ];

% Measurement matrix
H = [ 1 0 0 0 0 0; 0 1 0 0 0 0 ];
Q = eye(6);
R = smoothing * eye(2);

% Initial conditions
persistent x_est p_est
if isempty(x_est)
    x_est = zeros(6, 1);
x_est(1:2)=z;
    p_est = zeros(6, 6);
end

% Predicted state and covariance
x_prd = A * x_est;
p_prd = A * p_est * A' + Q;

% Estimation
S = H * p_prd' * H' + R;
B = H * p_prd';
klm_gain = (S \ B)';

% Estimated state and covariance
x_est = x_prd + klm_gain * (z - H * x_prd);
p_est = p_prd - klm_gain * H * p_prd;

% Compute the estimated measurements
y = H * x_est;
end


