function [left, right] = ...
    trkDropLowIndicesAcrossSplit(SplitPoint, Values, RemovePct) 
% [left, right] = trkDropLowIndicesAcrossSplit(SplitPoint, Magnitudes, ...
%                                              RemovePct)
%
% Given a set of magnitudes, determine which indices remain after removing
% the bottom RemovePct indices based upon 
% This code is copyrighted 2004 by Marie Roch.
% e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 

if RemovePct
  [dumbdata, indices] = sort(Values);
  FirstToKeep = floor(N * LowEnergyPct);
else
  FirstToKeep = 1;
end

if FirstToKeep > 1
  HighIndices = indices(FirstToKeep:end);
  
  % Find indices on left side of split
  left = find(HighIndices <= SplitPoint);
  right = find(HighIndices > SplitPoint);
else
  left = 1:SplitPoint;
  right = SplitPoint+1:length(Values);
end
