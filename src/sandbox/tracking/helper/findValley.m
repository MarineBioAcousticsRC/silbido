    
function valley = findValley(val, i, direct)
%function valley = findPostValley(val, i, direct)
%if direct = 'pre'
%    termin = 2;
%    step = -1;
%else
%    termin = length(val)-1;
%    step = 1;
%end

if direct = 'pre'
    termin = 2;
    step = -1;
else
    termin = length(val)-1;
    step = 1;
end

for idx = i:step: termin 
    if( val(idx)-val(idx-1))<0 & (val(idx+1) - val(idx))>0 & val(idx) > 0
        valley = val(idx);
    end
end
