function T=RemoveOverlappingPoints(T)
% RemoveOverlappingPoints
%
% For a 2-D curve, removes those points that fall on the same x pixel
%
% Input: 
%   T - 2-D array of points
%
% Output:
%   T - 2-D array of points with overlapping points removed
%

% Identify the x "pixel" for each point
X=round(T(:,1));

Y=T(:,2);
bad=[];

% Count how many points fall in each x pixel
[h,b]=hist(X,unique(X));
% Find those x values with duplicates
f=find(h>1);
for n=1:length(f)
    g=find(X==b(f(n)));
    % Choose the one with the maximum Y value (pretty arbitrary...)
    [~,mn]=max(Y(g));
    % Remove all the others
    bad=[bad; g((1:length(g))~=mn)];
end

T(bad,:)=[];
