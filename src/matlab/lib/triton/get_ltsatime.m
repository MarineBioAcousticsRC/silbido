function [TimeDnum, RawIdx, OffsetBin, Satisfied] = get_ltsatime(CurrentDnum, TargetDnum, SeekMethod)
% [TimeDnum, RawIdx, OffsetBin, Satisfied] = get_ltastime(CurrentDnum, TargetDnum, SeekMethod)
%
% Given a valid serial date CurrentDnum in an LTSA, determine a
% new time based upon the serial date TargetDnum.  TargetDnum is
% an offset which is interpreted based upon SeekMethod (see below).
%
% RawIdx is the index of the raw file contaning the data.
% RawBin is the bin index within the raw file(RawIdx).
%
% The meaning of Satisifed depends upon the SeekMethod.
%
% 'Relative' - TargetDnum is interpreted as a relative offset to
%       CurrentDnum.  Negative DNums imply seeking earlier and positive
%       DNums seek to later times.  For non-contiguous recordings, the
%       offset is relative to recording time, not absolute time.
%       Satisfied will be false when there is insufficient recorded
%       data to satisfy the request (seeking before/after the
%       beginning/end) and true otherwise.  
%
% 'Absolute' - TargetDnum is interpreted as a new time and CurretnDnum
%       is ignored.  Satisfied is true if data was recorded at time
%       TargetDnum.  If no data was recorded at this time, Satisfied is
%       set to false and the next available recording time is returned.

global PARAMS
tBinWidth = datenum([0 0 PARAMS.ltsa.tave/(60*60*24)]);

switch SeekMethod
 case 'Absolute'
  [RawIdx, OffsetBin, Satisfied] = ltsa_TimeIndexBin(TargetDnum);

 case 'Relative'
  NeedNBins = ceil(TargetDnum / tBinWidth);
  
  % Set data pointers to current raw file and offset
  [RawIdx, OffsetBin, Satisfied] = ltsa_TimeIndexBin(CurrentDnum);
  
  if NeedNBins < 0
    % move backwards
    NeedNBins = - NeedNBins;
    while NeedNBins > 0
      if NeedNBins >= OffsetBin
        % Need to move to previous raw file
        if RawIdx > 1  % make sure there is a previous one
          RawIdx = RawIdx - 1;
          NeedNBins = NeedNBins - OffsetBin;  % moved OffsetBins back
          OffsetBin = PARAMS.ltsa.nave(RawIdx); % last bin in previous
        else
          OffsetBin = 1;  % cannot go any further back
          NeedNBins = -1;  % moved past beginning
        end
      else
        OffsetBin = OffsetBin - NeedNBins;
        NeedNBins = 0;
      end
    end
      
  else
    % move forwards
    while NeedNBins > 0
      if OffsetBin + NeedNBins > PARAMS.ltsa.nave(RawIdx)
        % Move to next raw file (if it exists)
        if RawIdx < PARAMS.ltsa.nrftot
          RawIdx = RawIdx + 1;
          NeedNBins = NeedNBins - (PARAMS.ltsa.nave(RawIdx)-OffsetBin+1);
          OffsetBin = 1; % first bin in next
        else
          OffsetBin = PARAMS.ltsa.nave(RawIdx); % Last possible bin
          NeedNBins = -1; % moved past end
        end
      else
        OffsetBin = OffsetBin + NeedNBins;
        NeedNBins = 0;
      end
    end
  end
  
  if NeedNBins ~= 0
    Satisfied = false;  % Indicate that we ran past end
  else
    Satisfied = true;  % able to satisfy user request
  end
  
 otherwise
  error('Bad SeekMethod: "%s"', SeekMethod)
end

% Convert to time
TimeDnum = PARAMS.ltsa.dnumStart(RawIdx);
if OffsetBin > 1
  TimeDnum = TimeDnum + (OffsetBin - 1) * tBinWidth;
end

  

