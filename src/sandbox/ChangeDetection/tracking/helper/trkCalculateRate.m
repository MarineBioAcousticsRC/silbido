function [hitRate, missRate, falseRate] ...
         = trkCalculateRates(chgpt, Front, Back, threshold)
% "chgpt" is a vectorof computed change points in seconds of time domain
% "Front" and "Back" are pairs of points in time domain. "Front" is the time  
% when the first speaker stops and 'Back' is the time when the second speaker 
% starts.  These data are manually collected by listening to the audio files.
% "threshold" is the error tolerance. If a "chgpt" locates between any
% 'Front(i)-threshold' and 'Back(i) + threshold', then it counts one hit. 
% But multiple hits between any 'Front(i)-threshold' and 'Back(i) + threshold'
% are counted as one.
hit = 0;
multiCount = 0;
% compute hit count with chosen threshold
for i = 1:length(chgpt)
  if(i>1 & (chgpt(i)-chgpt(i-1)) > threshold * 2)  % prevent multi-count of one hit
                                                   %!!MISS close chage points if 
                                                   %threshold is too big
      for j = 1:length(Front)
          if chgpt(i) > (Front(j) - threshold) & chgpt(i) < (Back(j) + threshold)
              hit = hit+1;
          end 
      end
  else
      multiCount = multiCount + 1;
  end          
end
miss = length(Front) - hit;
false = length(chgpt)- hit - multiCount;
hitRate = hit/ length(Front);
missRate = miss/ length(Front);
falseRate = false/length(chgpt);