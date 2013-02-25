function multibin2xwav(void)
% multibin2xwav.m
%
% ripped off from bin2xwav.m
%
% 060627 smw
%

% hardwired header info
%

global PARAMS


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get input directory with only x.wav files
%
PARAMS.idir = [];

PARAMS.ddir = 'C:\';     % default directory
PARAMS.idir = uigetdir(PARAMS.ddir,'Select Directory with ARP *.bin files');
% if the cancel button is pushed, then no file is loaded so exit this script
if strcmp(num2str(PARAMS.idir),'0')
    disp_msg('Canceled Button Pushed - no directory selected for ARP *.bin files')
    return
else
    disp_msg('Input file directory : ')
    disp_msg([PARAMS.idir])
    %     disp(' ')
end
% get info on bin files in dir
d = dir(fullfile(PARAMS.idir,'*.bin'));    % directory info

PARAMS.fname = char(d.name);                % bin file names
fnsz = size(PARAMS.fname);
PARAMS.nfiles = fnsz(1);   % number of bin files in directory

disp_msg(['Number of ARP *.bin files in Input file directory is ',num2str(PARAMS.nfiles)])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% get output directory

outpath = uigetdir(PARAMS.idir,'Select Directory for OUTPUT *.x.wav files');
outpath = [outpath,'\'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
inpath = [PARAMS.idir,'\'];             % some place to start

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % calculate how many bytes -> not checking data file if correct
% filesize = getfield(dir([inpath,infile]),'bytes');

% ARP data structure
byteblk = 65536;	                    % bytes per head+data+null block
headblk = 32;		                    % bytes per head block
nullblk = 2;                            % bytes per null block
datablk = byteblk - headblk - nullblk;  % bytes per data block
bytesamp = 2;	                        % bytes per sample
datasamp = datablk/bytesamp;	        % number of samples per data block

% defaults
srfactor = 1;                              % sample rate factor
nfiles = 1;                                 % number of XWAV files to make
display_count = 1000;           % some feedback for the user while waiting....
gain = 1;                      % make XWAV file louder so easier to hear on


% wav file header parameters

% RIFF Header stuff:
%  harpsize = blkmx / byteblk * 32 + 64 - 8;% length of the harp chunk
harpsize = 1 * 32 + 64 - 8;% length of the harp chunk

% Format Chunk stuff:
fsize = 16;  % format chunk size
fcode = 1;   % compression code (PCM = 1)
ch = 1;      % number of channels
bitps = 16;	% bits per sample

% Harp Chunk stuff:
%  harpsize = blkmx / 60000 * 32 + 64 - 8;% length of the harp chunk
harpwavversion = 0;            % harp wav header version number
harpfirmware = '1.07b     ';   % arp firmware version number, 10 chars
harpinstrument = '00  ';       % harp instrument number
sitename = 'xxxx';             % site name
experimentname = 'UNKNOWN ';   % experiment name
diskseqnumber = 1;             % disk sequence number
diskserialnumber = '00000000'; % disk serial number
%   numofwrites = blkmx / 60000;   % number of writes
numofwrites = 1;
longitude = 899990;         % longitude
latitude = -899999;          % latitude
depth = 0;                   % depth

% HARP Write Header info (one listing per write)
byteloc = 8+4+8+16+64+32+8;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k = 1: PARAMS.nfiles

    infile = deblank(PARAMS.fname(k,:));
    fid = fopen([inpath,infile],'r'); %
    if fid == -1
        disp_msg('Error: no such file')
        return
    else
        disp_msg('Opened File: ')
        disp_msg([inpath,infile])
    end
    
    % calculate how many bytes -> not checking data file if correct
    filesize = getfield(dir([inpath,infile]),'bytes');

    % number of data blocks in input file
    blkmx = floor(filesize/byteblk);    % calculate the number of blocks in the opened file
%     blkmx = 10; % set to small number for testing purposes
    disp_msg(['Total Number of Blocks in ',infile,' : ']);
    disp_msg(blkmx);

    wavsize = (datablk*blkmx)+36+harpsize+8;  % required for the RIFF header
    writelength = blkmx;            % use total number of blocks since only one 'write' for Mawson data
    bytelength = writelength * datablk;    % number of blocks of data per write


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
%     disp_msg('true sample rate is : ')
%     disp_msg(num2str(sample_rate))

    fs = sample_rate * srfactor;                % fake sampling rate
    bps	=	fs*ch*bytesamp;	                    % bytes per second for xwav header
%     disp_msg('fake sample rate is : ')
%     disp_msg(num2str(fs))

    % open output file
    outfile = [infile,char(64+1),'.x.wav'];
    outfile = [outfile(1:length(outfile)-7),char(64+1),'.x.wav'];
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


    fclose(fid);

end
