function [FirstHitTimes, MissTimes, AllHitTimes, ChangePointsPerRegion] = ...
    trkAccuracy(chgpt, Front, Back, threshold)
%[FirstHitTimes, MissTimes, AllHitTimes, ChangePointsPerRegion] = ...
%   trkAccuracy(chgpt, Front, Back, threshold)
% "chgpt" is a vector of computed change points in seconds of time domain
% "Front" and "Back" are pairs of points in time domain. "Front" is the time  
% when the first speaker stops and 'Back' is the time when the second speaker 
% starts.  These data are manually collected by listening to the audio files.
% "threshold" is the error tolerance. If a "chgpt" locates between any
% 'Front(i)-threshold' and 'Back(i) + threshold', then it counts one hit. 
% But multiple hits between any 'Front(i)-threshold' and 'Back(i) + threshold'
% are counted as one.
%
% Values returned are a list of times detected as correct change points
% and those listed as incorrect times.
%
% When multiple changepoints are detected for the same known region, only
% the first one is returned.  
%
% This code is copyrighted 2003-2004 by Marie Roch and Yanliang Cheng.
% e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 



hit = 0;
FirstHitTimes = [];
AllHitTimes = [];
MissTimes = [];
multCount =0;
ChangePointsPerRegion = zeros(length(Front),1);
% compute hit count with chosen threshold
for j = 1:length(Front)
    % All detected changepoints before the beginning
    b4spkr1 = find(chgpt <= (Front(j)- threshold));
    % All detected changepoints before the end
    b4spkr2 = find(chgpt <= (Back(j) + threshold)); 
    
    b4spkr1Length = length(b4spkr1);
    b4spkr2Length = length(b4spkr2);
    % Number of peaks between the front and the back
    NumberInChangeRegion = b4spkr2Length - b4spkr1Length;
    
    if NumberInChangeRegion > 0        
      % store first one
      % First one is the first entry in b4spkr2 that is not
      % in b4spkr1.
      FirstHitTimes(end+1) = chgpt(b4spkr2(b4spkr1Length+1));
      % Store all of them.
      AllHitTimes = [AllHitTimes, chgpt(b4spkr2(b4spkr1Length+1:end))];
      ChangePointsPerRegion(j) = NumberInChangeRegion;
    else
      % store midpoint of missed change region
      MissTimes(end+1) = (Front(j) + Back(j)) / 2;
    end
end
