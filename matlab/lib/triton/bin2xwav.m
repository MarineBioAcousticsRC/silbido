function bin2xwav(void)
% bin2xwav.m
% 
% ripped off of hrp2wav.m which was ripped off from bin2wav.m
%
% convert *.bin (ARP binary) files into *.wav (pseudo wav) files
%
% hardwired for MAWSON ARP data
%
% 6 Aug, 04 smw make two smaller files (fit on CD 700MB) from larger 1GB
% file and put into triton v1.50 
%
% 5 Aug, 04 smw update to current header format
%
% 07/22/04 yhl implemented the harp header.  Put arbitary data into the
% header (based on the real information from score 15)
%
% 060222 - 060227 smw minimal mods - just make sure it works with new triton v1.60
%
%
% Do not modify the following line, maintained by CVS
% $Id: bin2xwav.m,v 1.1.1.1 2006/09/23 22:31:48 msoldevilla Exp $
global PARAMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
% open file stuff
inpath = PARAMS.inpath;             % some place to start

filterSpec1 = '*.bin';

% user interface retrieve file to open through a dialog box
boxTitle1 = 'Open ARP file to convert to x.wav format';
[infile,inpath]=uigetfile(filterSpec1,boxTitle1);

disp_msg('Opened File: ')
disp_msg([inpath,infile])

% if the cancel button is pushed, then no file is loaded
% so exit this script
if infile == 0
    disp_msg('Cancel Open File')
    return
end

fid = fopen([inpath,infile],'r'); %
if fid == -1
    disp_msg('Error: no such file')
    return
end

outfile = [infile,char(64+1),'.x.wav'];
outpath = inpath;
boxTitle2 = 'Save XWAV file';

[outfile,outpath] = uiputfile(outfile,boxTitle2);

if outfile == 0
    disp_msg('Cancel Save XWAV File')
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate how many bytes -> not checking data file if correct
filesize = getfield(dir([inpath,infile]),'bytes');

% ARP data structure
byteblk = 65536;	                    % bytes per head+data+null block
headblk = 32;		                    % bytes per head block
nullblk = 2;                            % bytes per null block
datablk = byteblk - headblk - nullblk;  % bytes per data block
bytesamp = 2;	                        % bytes per sample
datasamp = datablk/bytesamp;	        % number of samples per data block

% number of data blocks in input file
blkmx = floor(filesize/byteblk);    % calculate the number of blocks in the opened file
disp_msg(['Total Number of Blocks in ',infile,' : ']);
disp_msg(blkmx);
%disp('for testing purposes, make blkmx smaller')
%blkmx = 60000

% defaults
srfactor = 1;                              % sample rate factor
nfiles = 1;                                 % number of XWAV files to make
display_count = 1000;           % some feedback for the user while waiting....
gain = 1;                      % make XWAV file louder so easier to hear on 

%
% user input dialog box for XWAV file size in data blocks
prompt={'Enter number of blocks to write to XWAV ',...
        'Enter XWAV file sample rate change factor' ,...
        'Enter number of XWAV file to generate (0 < nfile < 27) ',...
        'Enter Gain for XWAV file (0 < gain < 50)'};
def={num2str(blkmx),...
        num2str(srfactor),...
        num2str(nfiles),...
        num2str(gain)};
dlgTitle='Set XWAV: file size, fake sample rate factor, # of files, gain';
lineNo=1;
AddOpts.Resize='on';
AddOpts.WindowStyle='normal';
AddOpts.Interpreter='tex';
in=inputdlg(prompt,dlgTitle,lineNo,def,AddOpts);
if length(in) == 0	% if cancel button pushed
    return
else
    blkmx = str2num(deal(in{1}));
    if blkmx ~= fix(blkmx)
        disp_msg('Error - need integer number of blocks')
        return
    else
        disp_msg('Number of Data Blocks used for XWAV file :')
        disp_msg(num2str(blkmx))
    end
    %%%%%%%%%%%%%%%%%%%%%%
    srfactor = str2num(deal(in{2}));
    disp_msg('Sample rate change factor for XWAV file :')
    disp_msg(num2str(srfactor))
    %%%%%%%%%%%%%%%%%%%%%%
    nfiles = str2num(deal(in{3}));
    if nfiles > 26 || nfiles < 1
        disp_msg('Error - too many or too few files to be generated')
        return
    else
        disp_msg('Number of XWAV files to generate :')
        disp_msg(num2str(nfiles))  
    end
    %%%%%%%%%%%%%%%%%%%%%
    gain = str2num(deal(in{4}));
    if gain <= 0 || gain >= 50
        disp_msg('Error - too big or two small (0 < gain < 50')
        return
            else
        disp_msg('Gain for XWAV is :')
        disp_msg(num2str(gain))  
    end
end

% wav file header parameters

% RIFF Header stuff:
%  harpsize = blkmx / byteblk * 32 + 64 - 8;% length of the harp chunk
harpsize = 1 * 32 + 64 - 8;% length of the harp chunk
wavsize = (datablk*blkmx)+36+harpsize+8;  % required for the RIFF header

% Format Chunk stuff:
fsize = 16;  % format chunk size
fcode = 1;   % compression code (PCM = 1)
ch = 1;      % number of channels
bitps = 16;	% bits per sample

% Harp Chunk stuff:
%  harpsize = blkmx / 60000 * 32 + 64 - 8;% length of the harp chunk
harpwavversion = 0;            % harp wav header version number
harpfirmware = '1.07b     ';   % arp firmware version number, 10 chars
harpinstrument = '35  ';       % harp instrument number
sitename = '2003';             % site name
experimentname = 'MAWSON  ';   % experiment name
diskseqnumber = 1;             % disk sequence number
diskserialnumber = '00000000'; % disk serial number
%   numofwrites = blkmx / 60000;   % number of writes
numofwrites = 1;
longitude = 6981250;         % longitude
latitude = -6673733;          % latitude
depth = 1321;                   % depth

% HARP Write Header info (one listing per write)
byteloc = 8+4+8+16+64+32+8;

% number of data blocks in output file
%writelength = 224;             % number of blocks per write
writelength = blkmx;            % use total number of blocks since only one 'write' for Mawson data
bytelength = writelength * datablk;    % number of blocks of data per write


for ii=1:nfiles                    % make N files
        
    head = fread(fid,headblk/bytesamp,'uint16');         % read all of header
    fseek(fid,-headblk,0);                            % rewind to start of header
    year = head(9);                             % get year YYYY
    dnum = datenum(['01-Jan-',num2str(year)]);  % convert to days since 1-Jan-0000
    
    timesec = (head(10)*2^16+head(11))/100;      % seconds since 1-Jan-YYYY 
    timeday = timesec/(60 * 60 * 24);            % days since 1-Jan-YYYY
    
    dvec = datevec(dnum + timeday);              % date vector [Y M D H MI S]
    ticks = floor(1000*(dvec(6) - floor(dvec(6)))); % get milliseconds
    dvec(6) = floor(dvec(6));                     % make integer number of seconds
    dvec(1) = dvec(1) - 2000;                    % years since 2000 as per HARP data
    
    sample_rate = 1000/(head(12)*2^16+head(13)); % true sample rate
    disp_msg('true sample rate is : ')
    disp_msg(num2str(sample_rate))
    
    fs = sample_rate * srfactor;                % fake sampling rate
    bps	=	fs*ch*bytesamp;	                    % bytes per second for xwav header
    disp_msg('fake sample rate is : ')
    disp_msg(num2str(fs))
    
    % open output file
    outfile = [outfile(1:length(outfile)-7),char(64+ii),'.x.wav'];
    fod = fopen([outpath,outfile],'w');
    disp_msg(['Output file : ',outfile])
    
    % write xwav file header
    %
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
    
    %
    % Format information
    fprintf(fod,'%c','f');
    fprintf(fod,'%c','m');
    fprintf(fod,'%c','t');
    fprintf(fod,'%c',' ');
    fwrite(fod,fsize,'uint32');
    fwrite(fod,fcode,'uint16');
    fwrite(fod,ch,'uint16');
    fwrite(fod,fs,'uint32');
    fwrite(fod,bps,'uint32');
    fwrite(fod,bytesamp,'uint16');
    fwrite(fod,bitps,'uint16');
    
    %
    % "harp" chunk
    fprintf(fod,'%c', 'h');
    fprintf(fod,'%c', 'a');
    fprintf(fod,'%c', 'r');
    fprintf(fod,'%c', 'p');
    fwrite(fod, harpsize, 'uint32');
    fwrite(fod, harpwavversion, 'uchar');
    fwrite(fod, harpfirmware, 'uchar');
    fprintf(fod, harpinstrument, 'uchar');
    fprintf(fod, sitename, 'uchar');
    fprintf(fod, experimentname, 'uchar');
    fwrite(fod, diskseqnumber, 'uchar');
    fprintf(fod, '%s', diskserialnumber);
    fwrite(fod, numofwrites, 'uint16');
    fwrite(fod, longitude, 'int32');
    fwrite(fod, latitude, 'int32');
    fwrite(fod, depth, 'int16');
    fwrite(fod, 0, 'uchar');   % padding
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    
    % "harp" write entries
    % entry 1
    fwrite(fod, dvec(1), 'uchar');
    fwrite(fod, dvec(2), 'uchar');
    fwrite(fod, dvec(3), 'uchar');
    fwrite(fod, dvec(4), 'uchar');
    fwrite(fod, dvec(5), 'uchar');
    fwrite(fod, dvec(6), 'uchar');
    fwrite(fod, ticks, 'uint16');
    fwrite(fod, byteloc, 'uint32');
    fwrite(fod, bytelength, 'uint32');
    fwrite(fod, writelength, 'uint32');
    fwrite(fod, sample_rate, 'uint32');
    fwrite(fod, gain, 'uint8'); 
    fwrite(fod, 0, 'uchar'); % padding
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    
    % Data area -- variable length
    fprintf(fod,'%c','d');
    fprintf(fod,'%c','a');
    fprintf(fod,'%c','t');
    fprintf(fod,'%c','a');
    fwrite(fod,datablk*blkmx,'uint32');
     
    % read data blocks from ARP file and write to XWAV file
    count = 1;
    disp_msg('reading/writing : ')
    for i= 1:blkmx
        fseek(fid,headblk,0);	                            % skip over header
        fwrite(fod,gain * fread(fid,datablk/bytesamp,'int16'),'int16'); % read and write
        fseek(fid,nullblk,0);                               % skip over null block
        if count == display_count
            disp_msg(['data block ',num2str(i)])    % give the user some feed back during this long process
            count = 0;
        end
        count = count + 1;
    end
    
    fclose(fod);
    disp_msg(['done with ',outfile])
    
end                                     % end ii 

fclose(fid);
