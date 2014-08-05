function Size = trkWindowSize(WindowVector)
% Size = trkWindowSize(WindowVector)
% Given a window size specifcation [Start, Stop], return the size.

Size = diff(WindowVector)+1;
