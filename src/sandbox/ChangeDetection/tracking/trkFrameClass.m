function [Hit, Miss] = trkFrameClass(Times, Front, Back, Threshold)
%[HitFrames, MissFrames] = trkFrameClass(FrameTimes, Front, Back, Threshold)
% 
% Given a set frame times, determine which ones fall within and outside the
% boundaries set by corresponding elements of the Front and Back arrays.

MissIdx = [];
HitIdx = [];

LastBack = -Threshold;
for i = 1:length(Front)
  % Mark everything before the current region as a miss
  MissIdx = [MissIdx, ...
          find(Times > LastBack + Threshold & Times < Front(i) - Threshold)];
  % Mark everything in the current region as a hit.
  HitIdx = [HitIdx, ...
         find(Times >= Front(i) - Threshold & Times <= Back(i) + Threshold)];
  LastBack = Back(i);
end

MissIdx = [MissIdx, find(Times > LastBack + Threshold)];

% convert from indices to values
Hit = Times(HitIdx);
Miss = Times(MissIdx);
        
