function [Indices, Condition] = trkFindIndices(Start, ...
                                                  Stop, TimeStart, TimeStop)
% [Indices, IntersectionType]
%       trkFindIndices(Start, Stop, TimeStart, TimeStop)
% Given a series of regions defined by vectors Start and Stop,
% locate the regions which intersect with a given time range.
%
% Indices contains indices which indicate which Start/Stop pairs
% intersect with the region.  IntersectionType(idx) describes
% how Start(idx)/Stop(idx) intersects:
%       -1 - ends in range, but started before TimeStart
%        0 - contained in [TimeStart, TimeStop]
%       +1 - starts in range, but continues after TimeStop
%
% This code is copyrighted 2003-2004 by Marie Roch and Sonia Arteaga.
% e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 


% region begins or ends...
Begins = find(Start >= TimeStart & Start <= TimeStop)';
Ends = find(Stop >= TimeStart & Stop <= TimeStop)';
% any type of event 
Indices = union(Begins, Ends);

if nargout > 1
  % figure out what types of intersections exist.
  
  % Assume starts in ragne & continues after TimeStop
  Condition = ones(1, length(Indices));      

  % regions which start & end must be in both
  Spans = intersect(Begins, Ends);
  if ~ isempty(Spans)
    [Member MemberIdx] = ismember(Spans, Indices);
    Condition(MemberIdx) = zeros(size(Spans));
  end
  
  % The ones that begin before the region are those that
  % are in the Ends set and not the Spans set.
  Begins = setdiff(Ends, Spans);
  if ~ isempty(Begins)
    [Member MemberIdx] = ismember(Begins, Indices);
    Condition(MemberIdx) = -1 * ones(size(Begins));
  end
  
end
