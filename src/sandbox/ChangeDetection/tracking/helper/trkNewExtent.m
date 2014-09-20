function  NewExtent = trkNewExtent(Search, MinPoints);

% function NewExtent = trkNewExtent(Search, MinPoints);
% Calculate the needed number of points on each side of the window to
% ensure that the minimum amount of points are available for calculating
% the peaks

sizeOfRange = length(Search.Range);
if sizeOfRange < MinPoints
    
    NewExtent = ceil((MinPoints-sizeOfRange)/2);
    
elseif sizeOfRange >= MinPoints
    NewExtent = 0;
else
    error ('Unaccounted for situation');
end

    
 