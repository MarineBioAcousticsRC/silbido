function Seconds = utToSec(String)
% utToSec(TimeString)
% Convert a time string to seconds.  Time must be a 
% colon separated sequence of digits representing
% hours:minutes:seconds.  Any of the larger units
% of time may be omitted.
% 
% Example
%
% How many seconds in 2 hours, 23 minutes and 32 seconds?
%	utToSec('2:23:32')
%
% How many seconds in 23 minutes and 32 seconds?
%	utToSec('23:32')
%
% How many seconds in 32 seconds? :-)
%	utToSec('32')

Colon = strfind(String, ':');
if Colon == 1
  String(Colon) = [];		% strip beginning :
end

TimeVec = sscanf(String, '%f:%f:%f');
switch length(TimeVec)
 case 3
  % HH:MM:SS
  Units = [3600 60 1];	% seconds in hour, min, sec
 case 2
  Units = [60 1];		% seconds in min, sec
 case 1
  Units = 1;			% seconds in a second
 otherwise
  error('bad time string')
end

Seconds = dot(Units, TimeVec);	% Seconds = dot product

