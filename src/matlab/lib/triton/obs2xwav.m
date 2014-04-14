function obs2xwav(void)
% obs2xwav.m
%
% 10/18/04 smw - 32-bit, preamp gains, AGC applied.
%
% 10/4/04 smw - ripped off from bin2xwav.m
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
%%
% Do not modify the following line, maintained by CVS
% $Id: obs2xwav.m,v 1.1.1.1 2006/09/23 22:31:54 msoldevilla Exp $

tic
global PARAMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% open file stuff
inpath = PARAMS.inpath;             % some place to start

filterSpec1 = '*.obs';

% user interface retrieve file to open through a dialog box
boxTitle1 = 'Open OBS file to convert to x.wav format';
[infile,inpath]=uigetfile(filterSpec1,boxTitle1);

disp('Opened File: ')
disp([inpath,infile])
disp(' ')


% if the cancel button is pushed, then no file is loaded
% so exit this script
if infile == 0
    disp('Cancel Open File')
    return
end

fid = fopen([inpath,infile],'r','b'); % open obs file
% fid = fopen([inpath,infile],'r'); 
if fid == -1
    disp('Error: no such file')
    return
end

% outfile = [infile,'.x.wav'];
outpath = inpath;
% boxTitle2 = 'Save XWAV file';
%
% [outfile,outpath] = uiputfile(outfile,boxTitle2);
%
% if outfile == 0
%     disp('Cancel Save XWAV File')
%     return
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate how many bytes -> not checking data file if correct
filesize = getfield(dir([inpath,infile]),'bytes');

% OBS data structure

SIZES.samp.data = 128;			    % number of samples(words) per data block

% obs input file
headblk = 32;		                    % bytes per head block
bytesamp = 2;	                        % bytes per sample
sr = 128;                               % sample per second
nchan = 4;                              % number of channels
byteblk = headblk + nchan*SIZES.samp.data*bytesamp;     % bytes per head + nchan*data block
datablk = byteblk - headblk;            % bytes per data block

% number of data blocks in input file
tblkmx = floor(filesize/byteblk);    % calculate the number of blocks in the opened file
disp(['Total Number of Blocks in ',infile,' : ']);
disp(tblkmx);
disp('for testing purposes, make blkmx smaller')
blkmx = 60*60*24
% blkmx = 3600

disp('Number of posible files :')
nposfile = ceil(tblkmx/blkmx)

% defaults
srfactor = 1;                              % sample rate factor
nfiles = 1;                                 % number of XWAV files to make
display_count = 3600;           % some feedback for the user while waiting....
xgain = 1;                      % make XWAV file louder so easier to hear on

%
% user input dialog box for XWAV file size in data blocks
prompt={'Enter number of blocks to write to each XWAV file',...
    'Enter XWAV file sample rate change factor' ,...
    ['Enter number of XWAV files to generate (0 < nfile < ',num2str(nposfile),') '],...
    'Enter Gain for XWAV file (0 < gain < 50)'};
def={num2str(blkmx),...
    num2str(srfactor),...
    num2str(nfiles),...
    num2str(xgain)};
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
        disp('Error - need integer number of blocks')
        return
    else
        disp('Number of Data Blocks used for each XWAV file :')
        disp(num2str(blkmx))
    end
    %%%%%%%%%%%%%%%%%%%%%%
    srfactor = str2num(deal(in{2}));
    disp('Sample rate change factor for XWAV file :')
    disp(num2str(srfactor))
    %%%%%%%%%%%%%%%%%%%%%%
    nfiles = str2num(deal(in{3}));
    if nfiles > nposfile || nfiles < 1
        disp('Error - too many or too few files to be generated')
        return
    else
        disp('Number of XWAV files to generate :')
        disp(num2str(nfiles))
    end
    %%%%%%%%%%%%%%%%%%%%%
    xgain = str2num(deal(in{4}));
    if xgain <= 0 || xgain >= 50
        disp('Error - too big or two small (0 < gain < 50')
        return
    else
        disp('Gain for XWAV is :')
        disp(num2str(xgain))
    end
end

% wav file header parameters

% RIFF Header stuff:
bitps = 32;	% bits per sample
obytesamp = nchan*bitps/8;
harpsize = 1 * 32 + 64 - 8;% length of the harp chunk
odatablk = nchan*SIZES.samp.data*(bitps/8);


% Format Chunk stuff:
fsize = 16;  % format chunk size
fcode = 1;   % compression code (PCM = 1)
nch = 4;      % number of channels


% Harp Chunk stuff:
%  harpsize = blkmx / 60000 * 32 + 64 - 8;% length of the harp chunk
harpwavversion = 0;            % harp wav header version number
harpfirmware = '1.xxx     ';   % arp firmware version number, 10 chars
diskseqnumber = 1;             % disk sequence number
diskserialnumber = '00000000'; % disk serial number
%   numofwrites = blkmx / 60000;   % number of writes
numofwrites = 1;
% 
% the following is hardwired in and should be put into query dialog box
% input 
harpinstrument = '05  ';       % harp instrument number
sitename = '1   ';             % site name
experimentname = 'OBSFLIP ';   % experiment name
longitude = 3269152;         % longitude
latitude = -11933382;          % latitude
depth = 402;                   % depth


% HARP Write Header info (one listing per write)
byteloc = 8+4+8+16+64+32+8;

for ii=1:nfiles                    % make N files
    if(ii ~= 1)                     % read the header during the last file, so need to rewind
        fseek(fid,-32,'cof');
    end
    if (tblkmx - (ii-1) * blkmx) < blkmx
        ke = tblkmx - (ii-1) * blkmx - 1;   % close last file nicely
    else
        ke = blkmx;
    end
    % number of data blocks in output file
    writelength = ke;            % use total number of blocks
    bytelength = writelength * odatablk;    % number of blocks of data per write
    wavsize = (odatablk * ke)+36+harpsize+8;  % required for the RIFF header

    %% Read in obs header from triton(v1.40) rdhdr_v140
    startBytes = fread(fid,4,'uint8');
    bigtime = fread(fid,1,'uint32'); % seconds from 1970
    %disp(num2str(bigtime,'%d'))
    %bgtime_v140(0)  % go from TIMES.bigtime to TIMES.head.yr and TIMES.head.sec
    sample_rate = 2 ^ fread(fid,1,'ubit4');
    nch = fread(fid,1,'ubit4');
    id = fread(fid,1,'ubit8');
    pag = fread(fid,6,'ubit4');
    empty = fread(fid,1,'uint8');
    fgc = fread(fid,18,'uint8');

    dvec = datevec(datenum(1970,1,1,0,0,bigtime));
%     disp(datestr(dvec))

    %ticks = floor(1000*(dvec(6) - floor(dvec(6)))); % get milliseconds
    ticks = 0;                            % obs bigtime is only 1 second precision
    dvec(6) = floor(dvec(6));                     % make integer number of seconds
    yyyy = dvec(1);
    ddd = floor(datenum(dvec(1),dvec(2),dvec(3)) - datenum(dvec(1),0,0));  % gotta remove the one day datenum adds
    hh = dvec(4);
    mm = dvec(5);
    dvec(1) = dvec(1) - 2000;                    % years since 2000 as per HARP data

    disp('true sample rate is : ')
    disp(num2str(sample_rate))

    fs = sample_rate * srfactor;                % fake sampling rate

    bps	=	fs*nch*(bitps/8);	                    % bytes per second for xwav header
    disp('fake sample rate is : ')
    disp(num2str(fs))

    % open output file
    %     outfile = [outfile(1:length(outfile)-6),num2str(yyyy),num2str(ddd),'_'...
    outfile = ['S',sitename(1),'_',num2str(yyyy),num2str(ddd),'_',...
        num2str(hh),num2str(mm),'.x.wav']
    fod = fopen([outpath,outfile],'w');

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
    fwrite(fod,nch,'uint16');
    fwrite(fod,fs,'uint32');
    fwrite(fod,bps,'uint32');
    fwrite(fod,obytesamp,'uint16');
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
    fwrite(fod, xgain, 'uint8');
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
    fwrite(fod,odatablk*blkmx,'uint32');

    % read data blocks from ARP file and write to XWAV file
    d = [];
    count = 1;
    ki = 1;
    disp('reading/writing : ')

    for ki= 1:ke
        %fseek(fid,headblk,0);	                            % skip over header
        % read one block of data
        nsamp = nch * SIZES.samp.data;
        nsamp = datablk/bytesamp;
        d = reshape(fread(fid,nsamp,'uint16')-2^15,nch,SIZES.samp.data);
        %size(d)
        % use preamp gains from previous header ??
        for ii = 1:nch
            d(ii,:) = 2^(9-pag(ii)) .* d(ii,:);
        end
        % get preamp & AGC gains from that next header
        fseek(fid,10,0); % skip next 10 bytes of header
        pag = fread(fid,6,'ubit4');
        empty = fread(fid,1,'uint8');
        fgc = fread(fid,18,'uint8');
        %fseek(fid,-32,0);	% skip back 32 bytes to beginning of header
        gain = ones(nch,SIZES.samp.data); % gen gain matrix
        gainloc = reshape(fgc,6,3);	% gain change locations
        for ii = 1:nch
            gainlocold = 0;
            for j = 3:-1:1
                if gainloc(ii,j) ~= 0 & gainlocold == 0
                    gain(ii,gainloc(ii,j):SIZES.samp.data) = 2^(2*j);
                    gainlocold = gainloc(ii,j);
                elseif gainloc(ii,j) ~=0 & gainlocold ~= 0
                    gain(ii,gainloc(ii,j):gainlocold-1) = 2^(2*j);
                    gainlocold = gainloc(ii,j);
                end
            end
        end
        % apply AGC gains
        for ii = 1:nch
            d(ii,:) = gain(ii) .* d(ii,:);
        end
        % output data to file - note: 32-bit file
        fwrite(fod,d,'int32'); % write
        if count == display_count
            disp(['data block ',num2str(ki)])    % give the user some feed back during this long process
            count = 0;
        end
        count = count + 1;
    end

    fclose(fod);
    disp(['done with ',outfile])

end                                     % end ii

fclose(fid);
toc
