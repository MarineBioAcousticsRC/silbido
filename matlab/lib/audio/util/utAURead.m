function [PCM, Info] = utAURead(FileName, varargin)
% [PCM Info] = utAURead(FileName, Options...)
% Read in a Next/Sun audio file.
%
% Options are in pair values:
%	'Duration', N		- only return the N seconds of data
%	'Normalize', N		- Values normalized between -1,1
%				  Normalization performed if N non-zero
%				  (default is no normalization)
%
% PCM contains the sample data and Samples the number of samples read.
% Info is a structure which contains information which depends upon the
%	audio format.  At a minimum, SampleRate, and SampleCount fields 
%	will be populated.
%
% This code is copyrighted 2000 by Marie Roch.
% e-mail:  marie-roch@uiowa.edu
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 

% defaults
MaxTimeSec = Inf;
Normalize = 0;
NormalizationConstant = 1;

for m=1:2:length(varargin)
  switch varargin{m}
   case 'Duration'
    MaxTimeSec = varargin{m+1}; m=m+2;
   case 'Normalize'
    Normalize = varargin{m+1}; m=m+2;
    otherwise
      error(sprintf('Bad option %s', varargin{m}));
  end
end 

[Size, Info.SampleRate, Bits] = auread(FileName, 'size');
Info.BytesPerSample = Bits / 8;
MaxTimeSamples = round(MaxTimeSec * Info.SampleRate);
Info.SampleCount = min(MaxTimeSamples, Size(1));
Info.Channels = Size(2);
PCM = auread(FileName, [1 Info.SampleCount]);

if ~ Normalize
  NormalizationConstant = 2^15;
end

if min(size(PCM)) == 1
  % vector of samples
  MaxSamples = round(MaxTimeSec * Info.SampleRate);
  PCMReadSecs = length(PCM) / Info.SampleRate;
  if length(PCM) > MaxSamples
    PCM(MaxSamples+1:end) = [];
  end
else
  error('Not a vector.  Can''t handle stereo data');
end

% If normalization needed, perform on truncated data
if NormalizationConstant ~= 1
  PCM = NormalizationConstant * PCM;
end

