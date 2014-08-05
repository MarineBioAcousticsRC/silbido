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
multCount =0;
%multiCount = 0;
% compute hit count with chosen threshold
for j = 1:length(Front)
    b4spkr1 = find(chgpt <= (Front(j)- threshold));
    b4spkr2 = find(chgpt <= (Back(j) + threshold));    
    %hit = hit + (length(b4spkr2) - length(b4spkr1));    
    if (length(b4spkr2) - length(b4spkr1)) >0        
        hit = hit+1;
        multCount = multCount + (length(b4spkr2) - length(b4spkr1)-1);
    end 
end
 
miss = length(Front) - hit;
false = length(chgpt)- hit - multCount;

hitRate = hit/ length(Front);
missRate = 1- hitRate; %miss/ length(Front);
falseRate = false/length(chgpt);