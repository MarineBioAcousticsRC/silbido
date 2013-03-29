function Indices = utFindIndices(SearchValues, Target)
% For a vector of search values, finds the indices of all the elements
% of vector Target who match any of the values.

Indices = [];
for m=1:length(SearchValues)
  Indices = [Indices ; find(Target == SearchValues(m))'];
end
  
