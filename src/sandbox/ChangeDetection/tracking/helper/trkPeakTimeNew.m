function peaktime = trkPeakTimeNew(val, time)

% function peaktime = trkPeakTimeNew(val, time)
% is developed based on trkPeakTime(val, time)
% New version is aim at eliminating shoulder peaks, which cause false positive
% for most cases.
% "val" and "time" are of same size. They should be inherently related data
% in practice. Otherwise, nonsense to use this function.
%

local = 0.2 ; % in seconds
range = local/(time(2)-time(1));

localMax = 0;
postoverpre = 1.2;

peaktime =[];
if ~isempty(val)
  for i = 2:length(val)-1
      if ( val(i)-val(i-1))>0 & (val(i+1) - val(i))<0 & val(i) > 0 %find all peaks
          % exclude shoulder peaks
          if localMax 
              if((i>range) & ((i+range) <length(val)) & (val(i) == max(val(i-range:i+range))))
                  peaktime= [peaktime,time(i)];  
              end
          else
              pre = val(1:i);
              len = length(val);
              post = val(i:len);
              
              r = findValley(pre, i, 'pre') / findVallley(post, i, 'post');
              if r< postoverpre | r > (1/postoverpre)
                  peaktime =[peaktime, time(i)];
              end              
          end
      end
  end
end

