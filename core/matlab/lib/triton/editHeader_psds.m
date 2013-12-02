function editHeader_psds()
%
% editHeader_psds.m
%
% 060226 - 060227 smw
%
% used to change time or other header values for psds files
%
%
% Do not modify the following line, maintained by CVS
% $Id: editHeader_psds.m,v 1.1.1.1 2006/09/23 22:31:50 msoldevilla Exp $
%
global PARAMS HANDLES

% header format:
%
% % read header info
% PARAMS.ltsa.nfft = fread(fid,1,'int32');
% PARAMS.ltsa.fs = fread(fid,1,'int32');
% PARAMS.ltsa.psd.num = fread(fid,1,'int32');
% PARAMS.ltsa.nf = PARAMS.ltsa.nfft/2 + 1;			% number of frequencies
% PARAMS.ltsa.freq = fread(fid,PARAMS.ltsa.nf,'int32');	% this should be 'float'=32bit=4bytes
% PARAMS.ltsa.begin.sec = fread(fid,1,'int32');
% PARAMS.ltsa.psd.tlen = fread(fid,1,'int16');
% PARAMS.ltsa.psd.nsamp = fread(fid,1,'int32');
% PARAMS.ltsa.wintype = fread(fid,1,'int8');
% PARAMS.ltsa.overlap = fread(fid,1,'int8');
%
% PARAMS.ltsa.begin.yr = fread(fid,1,'int16') - 2000;
% PARAMS.ltsa.begin.dnum = datenum([PARAMS.ltsa.begin.yr 0 0 0 0 PARAMS.ltsa.begin.sec]);
% %     % skip over null data
% %     skip = 2*(20-16);
% %     fseek(fid,skip,0);
%

% user interface retrieve file to open through a dialog box
boxTitle1 = 'Open PSDS File to Modify';   % psds is old neptune format
filterSpec1 = '*.psds';
[PARAMS.ltsa.infile,PARAMS.ltsa.inpath]=uigetfile(filterSpec1,boxTitle1);

% if the cancel button is pushed, then no file is loaded so exit this script
if strcmp(num2str(PARAMS.ltsa.infile),'0')
    return
else % give user some feedback
    disp_msg('Opened File: ')
    disp_msg([PARAMS.ltsa.inpath,PARAMS.ltsa.infile])
    cd(PARAMS.ltsa.inpath)
end

fid = fopen([PARAMS.ltsa.inpath,PARAMS.ltsa.infile],'r');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read the header
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.ltsa.nfft = fread(fid,1,'int32');
PARAMS.ltsa.fs = fread(fid,1,'int32');
PARAMS.ltsa.psd.num = fread(fid,1,'int32');
PARAMS.ltsa.nf = PARAMS.ltsa.nfft/2 + 1;			% number of frequencies
PARAMS.ltsa.freq = fread(fid,PARAMS.ltsa.nf,'int32');	% this should be 'float'=32bit=4bytes
ptr_sec = ftell(fid);
PARAMS.ltsa.begin.sec = fread(fid,1,'int32');
PARAMS.ltsa.psd.tlen = fread(fid,1,'int16');
PARAMS.ltsa.psd.nsamp = fread(fid,1,'int32');
PARAMS.ltsa.wintype = fread(fid,1,'int8');
PARAMS.ltsa.overlap = fread(fid,1,'int8');
ptr_yr = ftell(fid);
PARAMS.ltsa.begin.yr = fread(fid,1,'int16');

fclose(fid);
PARAMS.ltsa.begin.dnum = datenum([PARAMS.ltsa.begin.yr-2000 0 0 0 0 PARAMS.ltsa.begin.sec]);

% user input dialog box
prompt={['Original PSDS Start Time: ',timestr(PARAMS.ltsa.begin.dnum,6)]};
def={timestr(PARAMS.ltsa.begin.dnum,6)};
dlgTitle='Modify PSDS Start Time';
lineNo=1;
AddOpts.Resize='on';
AddOpts.WindowStyle='normal';
AddOpts.Interpreter='tex';
in=inputdlg(prompt,dlgTitle,lineNo,def,AddOpts);
if length(in) == 0	% if cancel button pushed
    return
end

input = deal(in{1});

tnum = [];
tnum = timenum(input,6);

if isempty(tnum)
    disp_msg('Error, Time format should be: dd/mm/yyyy HH:MM:SS')
    disp_msg(['Input was : ',input])
    return
end

fod = fopen([PARAMS.ltsa.inpath,PARAMS.ltsa.infile],'r+');
%

PARAMS.ltsa.begin.yr = str2num(input(7:10));
tsec = (tnum - datenum([PARAMS.ltsa.begin.yr-2000 0 0 0 0 0]) ) * 24 * 60 * 60;
PARAMS.ltsa.begin.sec = tsec;
disp_msg(['New PSDS Start Time: ',input])

fseek(fod,ptr_sec,'bof');
fwrite(fod,PARAMS.ltsa.begin.sec,'int32');

fseek(fod,ptr_yr,'bof');
fwrite(fod,PARAMS.ltsa.begin.yr,'int16');

fclose(fod);

disp_msg(['Finished modifying PSDS file: ',PARAMS.ltsa.inpath,PARAMS.ltsa.infile])