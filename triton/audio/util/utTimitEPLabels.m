function utTimitEPLabels(Segments,  ...
			 InSegmentLabel, OutOfSegmentLabel, varargin)
% utTimitEPLabels(Points, LastIndex, ...
%	          InSegmentLabel, OutOfSegmentLabel, Optional)
%
% Generates a set of TIMIT labels of the format
%
% begin_sample	end_sample	Label
%
% for a two class problem.  Segments is a matrix where each row
% indicates the begin and end of a region associated with InSegmentLabel.
% Frames not covered by Segments
%
% Optional arguments
%
%	'Last', N - Specifies the last valid index and is useful
%		when the ending region is of class OutOfSegmentLabel
%		(Specifying Last is valid even when the ending
%		region is of class InSegmentLabel)
%
%	'File', String - Save the results to a file instead of printing
%		them.
%
% This code is copyrighted 2003 by Marie Roch.
% e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 


error(nargchk(3, inf, nargin));

if size(Segments, 2) ~= 2
  error('Bad Segments specification')
end

% defaults
STDOUT = 1;
FileHandle = STDOUT;
LastIndex = Segments(end, 2);

n=1;
while n < length(varargin)
  switch varargin{n}
   case 'File'
    File = varargin{n+1}; n=n+2;
    [FileHandle, Message] = fopen(File, 'w');
    if FileHandle == -1
      error(sprintf('Unable to open "%s".  System says:  %s\n', ...
		    File, Message));
    end
    
   case 'Last'
    LastIndex = varargin{n+1}; n=n+2;
   otherwise
    error(sprintf('Bad optional argument: "%s"', varargin{n}));
  end
end

% Count # of segments that have the other class in between
SegmentCount = size(Segments, 1);
Distance = Segments(2:end,2) - Segments(1:(SegmentCount-1),1);
IntraSegmentIndicator = Distance > 1;
IntraSegmentCount = sum(IntraSegmentIndicator);

% process out of segment beginning
if Segments(1,1) < 2
  BeginningOutOfSegment = 1;
  fprintf(FileHandle, '%d\t%d\t%s\n', 1, Segments(1,1)-1, OutOfSegmentLabel);
end

% process segment regions & anything between them
for idx=1:length(IntraSegmentIndicator)
  fprintf(FileHandle, '%d\t%d\t%s\n', ...
	  Segments(idx, 1), Segments(idx,2), InSegmentLabel);
  if IntraSegmentIndicator(idx)
    fprintf(FileHandle, '%d\t%d\t%s\n', ...
	    Segments(idx,2)+1, Segments(idx+1, 1)-1, OutOfSegmentLabel); 
  end
end

% process end

fprintf(FileHandle, '%d\t%d\t%s\n', ...
	Segments(end, 1), Segments(end,2), InSegmentLabel);

if Segments(end, 2) < LastIndex
  EndingOutOfSegment = 1;
  fprintf(FileHandle, '%d\t%d\t%s\n', ...
	  Segments(end,2)+1, LastIndex, OutOfSegmentLabel);
end

if FileHandle ~= STDOUT
  fclose(FileHandle);
end
