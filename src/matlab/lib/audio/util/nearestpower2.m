function [Length, Time] = nearestpower2(DesiredTime, SampleRate)
% [Length, Time] = nearestpower2(Desiredtime, SampleRate)
% Some algorithms (i.e. Fourier transforms) have efficient
% implementations when working with data which is a length of
% a power of two.  Given the desired amount of time and the
% sample rate, this routine determines the closest power of two window
% and its duration.

DesiredLength = DesiredTime * SampleRate;

Bits = DesiredLength;
UpperBoundBitPos = 0;
while (Bits)
  Bits = bitshift(Bits, -1);
  UpperBoundBitPos = UpperBoundBitPos + 1;
end

Length = 2 ^ UpperBoundBitPos;	% upper bound
if Length ~= DesiredLength
  LowerLength = 2 ^ (UpperBoundBitPos - 1);
  % Find out which is closer.
  if (DesiredLength  - LowerLength < Length - DesiredLength)
    Length = LowerLength;
  end
end

Time = Length / SampleRate;
