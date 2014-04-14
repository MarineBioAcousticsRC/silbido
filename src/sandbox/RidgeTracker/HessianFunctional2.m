function A=HessianFunctional2(I,K,mask,horizPriority)
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

% Set some default values for the parameters
if nargin<4
    horizPriority=1;
end

% Calculate the first and second derivates of the image
gx=gfilter(I,K,[0 1]);
gy=gfilter(I,K,[1 0]);
gxx=gfilter(I,K,[0 2]);
gyy=gfilter(I,K,[2 0]);
gxy=gfilter(I,K,[2 2]);
gyx=gxy;

% Set up a mask with NaNs for the uninteresting points
FF=ones(size(I));
FF(find(mask))=NaN;

% Find the points due for processing (f)
f=find(~isnan(FF));
% Set up the output matrix to be full of NaNs by default
A=ones(size(I))*NaN;

% Convert the interesting pixel indices to subscripts
[X,Y]=ind2sub(size(A),f);

% Process each interesting pixel separately
for n=1:length(f)
    x=X(n);
    y=Y(n);
    
    % Find the angle between the gradient and the Hessian dominant
    % eigenvector for the immediate neighbourhood
    
    % Set up the Hessian matrix
    H=[gxx(x,y) gxy(x,y);gyx(x,y) gyy(x,y)];
    % Set up the gradient vector
    g=[gx(x,y);gy(x,y)];
    
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
    A(x,y)=dot(v,g);
end

% If we want to give additional priority to horizontal ridges (which we
% usually do, as whistles are time-monotonic), exclude those pixels where
% gyy>0.  Don't do this if the target signals have strong vertical
% components.
if horizPriority
    A(gyy>0)=NaN;
end


