function dnum = timenum(sinput,stype)
%
% this function timenum.m can be used instead of datenum.m to
% convert string time in format made from timestr.m (which is used to solve the
% rounding problems created by datestr.m and outputs msecs and usecs)
%
% smw 050513
% remove yr 2000 from calculations to improve precision
%
% fixed rounding error??? & modify for v1.60
% 060204 - 060227 smw
%
% input string types (stype)
% 1 : mm/dd/yyyy HH:MM:SS.mmm.uuu
% 2 : HH:MM:SS.mmm.uuu
% 3 : mm/dd/yyyy
% 4 : HH:MM:SS
% 5 : mmm.uuu
% 6 : mm/dd/yyyy HH:MM:SS
%
% Do not modify the following line, maintained by CVS
% $Id: timenum.m,v 1.1.1.1 2006/09/23 22:31:55 msoldevilla Exp $

yoffset = 2000; % year offset

if ~isstr(sinput)
    disp_msg('Error: input is not string')
    dnum = 0;
    return
end

if stype == 1
    if length(sinput) ~= 27
        disp_msg('Error: wrong format for type == 1')
        dnum = 0;
        return
    end
    sec1 = str2num(sinput(21:23))/1e3 + str2num(sinput(25:27))/1e6;
    dnum = datenum(round( datevec(sinput(1:19))) + [-yoffset 0 0 0 0 sec1]);

elseif stype == 6

    if length(sinput) ~= 19
        disp_msg('Error: wrong format for type == 6')
        dnum = 0;
        return
    end
    dnum = datenum( round(datevec(sinput(1:19))) - [yoffset 0 0 0 0 0] );

end