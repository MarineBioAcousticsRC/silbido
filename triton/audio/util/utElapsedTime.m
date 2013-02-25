function TimeString = utElapsedTime(StartTime, EndTime)
% TimeString = utElapsedTime(StartTime, EndTime)
% Given a starting and ending clock times (see clock, 
% cputime), return a string showing the elapsed time in 
% an hh:mm:ss format.
%
% Starting and endtime times can either be in seconds 
% (i.e. the result of cputime) or in Matlab's clock 
% vector format, but starting and ending times must
% be in the same format.

% Check congruency of time format
if size(StartTime) ~= size(EndTime)
  error('Both time vectors must be of the same format')
end

if length(StartTime) > 1
  % clock format, get difference in seconds
  ElapsedTime =etime(EndTime, StartTime);
else
  % time in seconds
  ElapsedTime = EndTime - StartTime;
end

TimeString = sectohhmmss(ElapsedTime);
