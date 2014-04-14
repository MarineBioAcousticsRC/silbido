function dstr = timestr(dinput,dtype)
%
% this function timestr.m can be used instead of datestr.m to solve the
% rounding problems created by datestr.m and outputs msecs and usecs
%
% smw 050512
%
% input types
%   datenum or datevec
%
% output types (dtype)
% 1 : mm/dd/yyyy HH:MM:SS.mmm.uuu
% 2 : HH:MM:SS.mmm.uuu
% 3 : mm/dd/yyyy
% 4 : HH:MM:SS
% 5 : mmm.uuu
% 6 : mm/dd/yyyy HH:MM:SS
%
%
% 060204 - 060227 smw slight mods
%
% Do not modify the following line, maintained by CVS
% $Id: timestr.m,v 1.1.1.1 2006/09/23 22:31:55 msoldevilla Exp $

yoffset = 2000;

% check input for errors
if isempty(dinput)
    disp_msg('Error: empty input')
    disp_msg('syntax: dstr = timestr(dinput,dtype)')
    return
end

if isempty(dtype)   % if no output type
    dtype = 1;      % default output type
end

% if wrong output type
if dtype ~= 1 && dtype ~= 2 && dtype ~= 3 && dtype ~= 4  && dtype ~= 5 && dtype ~= 6
    disp_msg('Wrong output type, setting to type == 1')
    dtype = 1;
end

if ~isnumeric(dinput)  % if input is not a number or vector
    disp_msg('Error: non-numeric input')
    return
end

len = length(dinput);   % figure out input type

if len ~= 1 && len ~= 6
    disp_msg('Error: input should be datenum or datevec format')
    return
end

if len == 1
    % datenum format
    dvec = datevec(dinput);
elseif len == 6
    % datevec format
    dvec = datevec(datenum(dinput));
end

yyyy = dvec(1) + yoffset;
mm = dvec(2);
dd = dvec(3);
HH = dvec(4);
MM = dvec(5);
SS = floor(dvec(6));

useconds = round(1e6 * (dvec(6) - SS));
mmm = floor(useconds/1000);

% get rid of mmm = 1000 problem
if mmm == 1000
    SS = SS + 1;
    if SS == 60
        MM = MM + 1;
        SS = 0;
        if MM == 60
            HH = HH + 1;
            MM = 0;
            if HH == 24
                dd = dd + 1;
                HH = 0;
            end
        end
    end
    mmm = 0;
    uuu = 0;
else
    uuu = floor(useconds - 1000*mmm);
end

% formated string output based on dtype:
if dtype == 1
    dstr = [num2str(mm,'%02g'),'/',num2str(dd,'%02g'),'/',num2str(yyyy,'%04g'),' ',...
        num2str(HH,'%02g'),':',num2str(MM,'%02g'),':',num2str(SS,'%02g'),'.',...
        num2str(mmm,'%03g'),'.',num2str(uuu,'%03g')];
elseif dtype == 2
    dstr = [num2str(HH,'%02g'),':',num2str(MM,'%02g'),':',num2str(SS,'%02g'),'.',...
        num2str(mmm,'%03g'),'.',num2str(uuu,'%03g')];
elseif dtype == 3
    dstr = [num2str(mm,'%02g'),'/',num2str(dd,'%02g'),'/',num2str(yyyy,'%04g')];
elseif dtype == 4
    dstr = [num2str(HH,'%02g'),':',num2str(MM,'%02g'),':',num2str(SS,'%02g')];
elseif dtype == 5
    dstr = [num2str(mmm,'%03g'),'.',num2str(uuu,'%03g')];
elseif dtype == 6
    dstr = [num2str(mm,'%02g'),'/',num2str(dd,'%02g'),'/',num2str(yyyy,'%04g'),' ',...
        num2str(HH,'%02g'),':',num2str(MM,'%02g'),':',num2str(SS,'%02g')];
end