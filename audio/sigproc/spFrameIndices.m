function Indices = spFrameIndices(SampleCount,FrameLength, FrameShift, ...
    ExtractedFrameLength, frames_per_s, Offset)
% Indices = spFrameIndices(SampleCount, FrameLength, 
%		FrameShift, ExtractedFrameLength, SampleRate, Offset)
%	Determine indices for overlapping frames of data for a data set
%	which contains SampleCount samples.  Frame Indices for incomplete
%	frames are computed.  
%
%   Optional positional arguments:
%   ExtractedFrameLength - forces spFrameExtract to zero pad frames 
%       to a desired size when data is extracted from a specific frame.  
%   SampleRate - used compute start times for each
%   Offset - offsets all frames by Offset samples
%
%	Any FrameLength < 0 indicates that all samples should
%	be used as a single frame.  This is useful for variable
%	length inputs.
%
%	Indices is a structure which contains the following fields:
%		.FrameShift - samples window shifted by
%		.FrameLength - length of window in samples
%		.FrameCount - Number of frames
%		.FrameLastComplete - Index of last complete frame.
%		.FrameExtractSize - When extracting frames from
%			data (spFrameExtract), pad frames to this
%			length.
%		.idx - A matrix whose rows represent frame indices.
%			Column 1 contains the starting sample
%			Column 2 contains the ending sample.
%		.timeidx - A column vector containing the starting
%			time in seconds for each frame.  This field
%			only exists if the optional SampleRate argument
%			is present.
%
% This code is copyrighted 1997-2003 by Marie Roch.
% e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 

error(nargchk(3, 6, nargin))

if nargin < 6
    Offset = 0;
end

if FrameLength > 0
  FrameCount = floor((SampleCount - Offset) / FrameShift);
else
  % Use all samples to form a single frame
  FrameLength = SampleCount;
  FrameCount = 1;
  FrameShift = 1;	% FrameShift no longer relevant set to 1
end

Indices.idx = zeros(FrameCount, 2);
Indices.FrameCount = FrameCount;
Indices.FrameLength = FrameLength;
Indices.FrameShift = FrameShift;
Indices.FrameLastComplete = ...
    floor((SampleCount - Offset - FrameLength + FrameShift) / FrameShift);

for k =1:FrameCount
    Start = (k-1)*FrameShift + 1 + Offset;
    Stop = Start + FrameLength - 1;
    Indices.idx(k,:) = [Start, min(Stop, SampleCount)];
end  

if nargin > 3
  if ExtractedFrameLength <= FrameLength
    % Don't allow truncation. 
    % Don't set FrameExtractSize equal to frame length
    if ExtractedFrameLength ~= FrameLength
      error('Specified extracted frame length smaller than frame length\n');
    else
      Indices.FrameExtractSize = 0;
    end
  else
    Indices.FrameExtractSize = ExtractedFrameLength;
  end

  if nargin > 4
    Indices.timeidx = (0:FrameCount-1)' ./ frames_per_s;
  end
else
  Indices.FrameExtractSize = 0;
end
