function L=RidgeLength(T,I)
% RidgeLength
%
% Calculates the length of a ridge either geometrically (if the image 
% parameter is ommitted), or weighted by the intensity along its length (if
% an image parameter is provided).
%
% Input:
%   T - 2-D array of curve points
%   I - (optional) Matrix (image) of intensities
%
% Output:
%   L - Scalar length metric
%

L=0;
if isempty(T)
    return;
end

if nargin==1 || isempty(I)
    % If only one parameter, return the geometric length
    L=sqrt(sum((T(1,:)-T(end,:)).^2));
else
    % If the image is also supplied, sum the intesities along the curve
    for m=1:size(T,1)
        x=round(T(m,1));
        y=round(T(m,2));
        if x>0 && x<=size(I,2) && y>0 && y<=size(I,1)
            s=I(round(T(m,2)),round(T(m,1)));
            if ~isnan(s) && s>0
%                L=L+log(s);
                L=L+s;
            end
        end
    end
end
