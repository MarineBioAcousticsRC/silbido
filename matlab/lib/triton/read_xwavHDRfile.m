function read_xwavHDRfile(hdrfilename,d)
%
% usage: >> read_xwavHDRfile(hdrfilename,d)
%
%
% hdrfile format:

% % Cross1.hdr
% % hdrfile for hrp2xwavs input for generating xwavs from hrp files
% % experiment specific
% % smw 060126
% %
% PARAMS.xhd.ExperimentName = 'Cross_01'; % experiment name - 8 chars
% PARAMS.xhd.InstrumentID = 'DL11';       % harp instrument number - 4 chars
% PARAMS.xhd.SiteName = 'XXXX';           % site name - 4 chars
% PARAMS.xhd.Longitude = -15825383;       % decimal deg * 10^5
% PARAMS.xhd.Latitude = 1872208;          % decimal deg * 10^5
% PARAMS.xhd.Depth = 398;                 % meters down is positive

%
% smw 050920
% smw 060126
%
%
% Do not modify the following line, maintained by CVS
% $Id: read_xwavHDRfile.m,v 1.1.1.1 2006/09/23 22:31:55 msoldevilla Exp $

global PARAMS


% check to see if file exists 
if exist(hdrfilename)
    % open hdr file
    [fid,message] = fopen(hdrfilename, 'r');
    if message == -1
        disp(['Error - no file ',hdrfilename])
        return
    end
end

% display flag: display values = 1
if d
    dflag = 1;
else
    dflag = 0;
end

% read each line of the hdrfile and evaluate it
while ~feof(fid)            % not EOF
    tline=fgets(fid);
    eval(tline)
    if dflag
        disp(tline)
    end
end

% close hdr file
fclose(fid);
