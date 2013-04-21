function angle=HessianFunctional(derivatives, x, y)
% HessianFunctional2
%
% Calculates the "functional" matrix, i.e. the angle between the dominant
% eigenvector of the Hessian matrix, and the gradient vector for each pixel
% not excluded by the mask.
%
% Input:
%   I - The spectrogram image.
%   K - Gaussian kernel standard deviation (in pixels) for calculating the
%       gradients.
%   mask - Interest mask.  Greatly reduces processing time by skipping
%          pixels not considered "interesting".  Note that a zero in the
%          mask is a pixel that _should_ be processed (the opposite of what
%          you might expect...)
%   horizPriority - Whether to give priority to the detection of horizontal
%                   ridges by considering only those pixels where gyy<=0.

%
% Output:
%   A - Functional matrix (angles).
%
    
% Find the angle between the gradient and the Hessian dominant
% eigenvector for the immediate neighbourhood

% Set up the Hessian matrix
xx = derivatives.gxx(x,y);
xy = derivatives.gxy(x,y);
yx = derivatives.gyx(x,y);
yy = derivatives.gyy(x,y);

if (yy>0)
    angle = NaN;
    return;
end
    
H=[xx xy;yx yy];
% Set up the gradient vector
g=[derivatives.gx(x,y);derivatives.gy(x,y)];

% Find the dominant eigenvector of the Hessian matrix
[V,E]=eig(H);
if abs(E(1,1))>abs(E(2,2))
    v=V(:,1);
else
    v=V(:,2);
end

% Calculate the angle between V and g and place it in A
v=v/norm(v);
g=g/norm(g);
angle=dot(v,g);


