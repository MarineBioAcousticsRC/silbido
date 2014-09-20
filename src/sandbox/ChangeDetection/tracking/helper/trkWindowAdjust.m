function [Search,TimeInPastEnd, ShiftlftClear, LeftNeed] = ...
    trkWindowAdjust(Search, WinHighUnit, Peaks, ...
       DeltaHighUnit, CSACount, MinimumPoints)
% Function recenters or shifts the window to avoid staying in an infinite
% loop.  It also checks for when the search window is past the end.  Then
% it returns the variables need for the rest of the algorithm

% Use trkNewExtent to figure out number of points needed
% on either side of search window
NewExtent = trkNewExtent(Search, MinimumPoints);

% Initialize some parameters
LeftNeed = 0;
ShiftlftClear=0;
TimeInPastEnd = 0;

%Seven was minimum points required for regression
if NewExtent > 0
    %Adjust window size using New Extent
    Search.Window = Search.Window + [-NewExtent,NewExtent];
    if (Search.Window(1) <= 0)
        % Take care of overlapping into the beginning of the
        % window.  Check how far to to left of the beginning we
        % are and then shift to the right by that amount, where
        % the begining of the window is always 1
        ShiftLeftBeg = 1- Search.Window(1);
        Search.Window = Search.Window +[ShiftLeftBeg, ShiftLeftBeg];
    end
end
% Want to always check if we are into the previous changepoint
if (~isempty(Peaks)) && (Search.Window(1) < Peaks(end))
    %Find the amount of overlap into the previous window size.  Then
    %use this change to adjust the new window so that there's no
    %overlap
    OffSetShift = Peaks(end) - Search.Window(1)+1;
    Search.Window = Search.Window + [OffSetShift, OffSetShift];
end
Search = trkDistBICRange(Search.Window, ...
    WinHighUnit.Margin, ...
    DeltaHighUnit.High);
%PastEnd denotes if we are past the end of the utterance
PastEnd =(Search.Window(2)) - CSACount;
if PastEnd >= 0 && ~isempty(Peaks)
    % LeftNeed is number of points we go past the utterance
    LeftNeed = PastEnd;
    Search.Window(2) = CSACount;
    % ShiftleftAvail is number of points available to
    % shift to the left in order to compensate for being
    % at the end
    ShiftleftAvail = Search.Window(1)-Peaks(end);
    %Record if we were in PastEnd where PastEnd is a flag
    TimeInPastEnd = 1;
    % Calculates if we have enought points to shift
    ShiftlftClear = ShiftleftAvail - LeftNeed;
elseif PastEnd >= 0 && isempty(Peaks)
    Search.Window(2) = CSACount;
end
 Search = trkDistBICRange(Search.Window, ...
                WinHighUnit.Margin, ...
                DeltaHighUnit.High);