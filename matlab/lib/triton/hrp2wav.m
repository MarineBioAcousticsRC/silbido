% hrp2wav.m
% 
% ripped off of bin2wav.m
%
% convert *.hrp (harp -> RDR) files into *.wav (pseudo wav) files
%
% include in triton 1.50 for easier ftp/HARP to wav data conversion
% 05/18/04 smw
%
%
% added gui for input file and sample rate, added ftp file reading
% capability
%
% hrp files have 12 byte header every 512 bytes (500 bytes or 250 samples
% of data i.e., 2 bytes/sample) essentially, all the many headers are
% stripped and replaced with on larger header which includes standard wav
% file header at the beginning so that standard wav file readers will work.
% Following this header will be information that can be used in
% in-house-built programs like triton, neptune, etc.
%
% 03/18/04 smw
% 
%
%
% 08/07/01 smw read and write at same time - dont fill up vector
% this is much, much faster - had to figure out wav header...
%
% 08/06/01 smw
% 
% 060219 - 060227 smw modified for v1.60
%
% Do not modify the following line, maintained by CVS
% $Id: hrp2wav.m,v 1.1.1.1 2006/09/23 22:31:50 msoldevilla Exp $

%clear all

tic % start stopwatch timer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
fs = 200000;	% sample rate
ftype = 2;

% user input dialog box
prompt={'Enter sampling frequency (Hz) : ',...
        'Enter file type (1 = USB2.0, 2 = FTP) : '};
def={num2str(fs),...
        num2str(ftype)};
dlgTitle='Set Frequency Parameters';
lineNo=1;
AddOpts.Resize='on';
AddOpts.WindowStyle='normal';
AddOpts.Interpreter='tex';
in=inputdlg(prompt,dlgTitle,lineNo,def,AddOpts);
if length(in) == 0	% if cancel button pushed
    return
end
fs = str2num(deal(in{1}));
ftype = str2num(deal(in{2}));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
% open file stuff
if ftype == 1
    filterSpec1 = '*.hrp';
elseif ftype == 2
    filterSpec1 = '*.*';
end
% user interface retrieve file to open through a dialog box
boxTitle1 = 'Open HARP file to convert to wav format';
[infile,inpath]=uigetfile(filterSpec1,boxTitle1);

disp_msg('Opened File: ')
disp_msg([inpath,infile])

% if the cancel button is pushed, then no file is loaded
% so exit this script
if strcmp(num2str(infile),'0')
    infile = num2str(infile);
    break
end

if ftype == 1
    fid = fopen([inpath,infile],'r','l'); % for USB2.0 file
elseif ftype == 2
    fid = fopen([inpath,infile],'r','b'); % for ftp file
end
if fid == -1
    disp_msg('Error: no such file')
    break
end

outfile = [infile,'.wav'];

cd(inpath)
fod = fopen(outfile,'w');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate how many blocks -> not checking data file if correct

% calculate the number of blocks in the opened file
filesize = getfield(dir([inpath,infile]),'bytes');
byteblk = 512;	%bytes per head+data block
headblk = 12;		% bytes per head block
datablk = byteblk - headblk; % bytes per data block
bytesamp = 2;	% bytes per sample
datasamp = datablk/bytesamp;	%number of samples per data block
blkmx = floor(filesize/byteblk);
disp_msg(['Total Number of Blocks in ',infile,' :']);
disp_msg(blkmx);

% for testing purposes, make blkmx smaller
%blkmx = 60000;
display_count = 10000;

% wav file header parameters
wavsize = datablk*blkmx+36;

ch = 1;	% number of channels
fcode = 1;	% formate code
flen = 16;	% format info length
bps	=	fs*ch*bytesamp;	%	bytes per second
bitps = 16;	% bits per sample

%write wav file header
% RIFF file header
fprintf(fod,'%c','R');
fprintf(fod,'%c','I');
fprintf(fod,'%c','F');
fprintf(fod,'%c','F');
fwrite(fod,wavsize,'uint32');
fprintf(fod,'%c','W');
fprintf(fod,'%c','A');
fprintf(fod,'%c','V');
fprintf(fod,'%c','E');
% Format information
fprintf(fod,'%c','f');
fprintf(fod,'%c','m');
fprintf(fod,'%c','t');
fprintf(fod,'%c',' ');
fwrite(fod,flen,'uint32');
fwrite(fod,fcode,'uint16');
fwrite(fod,ch,'uint16');
fwrite(fod,fs,'uint32');
fwrite(fod,bps,'uint32');
fwrite(fod,bytesamp,'uint16');
fwrite(fod,bitps,'uint16');
% Data area -- variable length
fprintf(fod,'%c','d');
fprintf(fod,'%c','a');
fprintf(fod,'%c','t');
fprintf(fod,'%c','a');
fwrite(fod,datablk*blkmx,'uint32');

fseek(fid,0,-1);	% start at the beginning, just to be sure, rewind input file

dmx = 2^15;	% max sample value, normalizing factor, needed only for wavwrite
count = 1;
disp_msg('reading/writing : ')
for i= 1:blkmx
    fseek(fid,headblk,0);	% skip over header
    fwrite(fod,fread(fid,datasamp,'int16'),'int16');
    if count == display_count
        disp_msg(['data block ',num2str(i)])
        count = 0;
    end
    count = count + 1;
end

fclose(fid);
fclose(fod);
disp_msg('done')

t = toc; % get elasped time
disp_msg(['Elasped time for making file ',outfile,' = ',num2str(t)])
