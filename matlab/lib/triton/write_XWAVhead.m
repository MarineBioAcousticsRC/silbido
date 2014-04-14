function write_XWAVhead(fod,fhdr,nhrp)
%
%   useage: >> write_XWAVhead(fod,fhdr,nhrp)
%   fod == XWAV output file id... should be open from calling program
%   fhdr == first header in raw file corresponding to first data in XWAV
%   nhrp == number of raw files used to make XWAV file (should be 30 or
%   less)
%   
%   smw 050920
%
%
% Do not modify the following line, maintained by CVS
% $Id: write_XWAVhead.m,v 1.2 2006/12/20 04:32:06 msoldevilla Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Past history (stolen from wrxwavhd:
% wrxwavhd - write xwav header
%
% stolen from obs2xwav.m
% smw 20 Oct, 2004
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global PARAMS

fs = PARAMS.head.samplerate;

% wav file header parameters
% RIFF Header stuff:
harpsize = nhrp * 32 + 64 - 8;% length of the harp chunk

% HARP Write Header info (one listing per write)
byteloc = (8+4) + (8+16) + 64 + (32 * nhrp) + 8;
% writelength = 1;            % use total number of blocks
% Format Chunk stuff:
fsize = 16;  % format chunk size
% if PARAMS.nBits == 16
fcode = 1;   % compression code (PCM = 1)
% elseif PARAMS.nBits == 32
%     fcode = 3;   % compression code (PCM = 3) for 32 bit
% end


% bytes of data - only one channel
%%PARAMS.xhd.BlockAlign = fread(fid,1,'uint16'); % # of Bytes per Sample Slice = NumChannels * BitsPerSample / 8
% bytelength = PARAMS.tseg.samp * (PARAMS.xhd.BlockAlign/PARAMS.nch);
% or
% bytelength = length(DATA) * PARAMS.nBits/8;
% bytelength = PARAMS.tseg.samp * PARAMS.nBits/8;

PARAMS.nBits = 16;
PARAMS.nch = 1;
PARAMS.samp.byte = floor(PARAMS.nBits/8);
PARAMS.xhd.BitsPerSample = PARAMS.nch * PARAMS.samp.byte;
PARAMS.xhd.ByteRate = fs*PARAMS.xhd.BitsPerSample;
PARAMS.xhd.WavVersionNumber = 1;
PARAMS.xgain(1) = 1;

% number of samples in XWAV file
PARAMS.nsamp = sum(PARAMS.head.dirlist(fhdr:fhdr+nhrp-1,10))* 250;
bytelength = PARAMS.nsamp * PARAMS.nBits/8;

wavsize = bytelength+36+harpsize+8;  % required for the RIFF header

% HARP Write Header info (one listing per write)
PARAMS.xhd.byte_loc = 8+4+8+16+64+32+8;

% time conversions
% secperday = 60 * 60 * 24;
% dvec = datevec((PARAMS.start.sec + secperday) / secperday );
% dvec = datevec(PARAMS.plot.dnum);
% ticks = floor( 1000*(dvec(6) - floor(dvec(6))));
% dvec(6) = floor(dvec(6));
%dvec(1) = PARAMS.start.yr - 2000;

% open output file
% fod = fopen([PARAMS.outpath,PARAMS.outfile],'w');

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
fwrite(fod,PARAMS.nch/PARAMS.nch,'uint16');         % only one channel of data shown in window
fwrite(fod,fs,'uint32');
fwrite(fod,PARAMS.xhd.ByteRate/PARAMS.nch,'uint32');
fwrite(fod,PARAMS.xhd.BitsPerSample/PARAMS.nch,'uint16');
fwrite(fod,PARAMS.nBits,'uint16');

%
% "harp" chunk
fprintf(fod,'%c', 'h');
fprintf(fod,'%c', 'a');
fprintf(fod,'%c', 'r');
fprintf(fod,'%c', 'p');
fwrite(fod, harpsize, 'uint32');
fwrite(fod, PARAMS.xhd.WavVersionNumber , 'uchar');
fprintf(fod, '%c', PARAMS.head.firmwareVersion);     % 10 char
fprintf(fod, '%c', PARAMS.xhd.InstrumentID);    % 4 char
fprintf(fod, '%c', PARAMS.xhd.SiteName);        % 4 char
fprintf(fod, '%c', PARAMS.xhd.ExperimentName);  % 8 char
fwrite(fod, PARAMS.head.disknumberSector2, 'uchar');

% hardwired for read in xwav with bad values? smw 050126
DiskSerialNumber = '12345678'; % disk serial number
fprintf(fod, '%c', DiskSerialNumber);
% fprintf(fod, PARAMS.xhd.DiskSerialNumber, 'uchar');

% hardwired - only need one right (if read in xwav could be wrong for output)
% NumOfWrites = 1;
%
fwrite(fod, nhrp, 'uint16');
fwrite(fod, PARAMS.xhd.Longitude, 'int32');
fwrite(fod, PARAMS.xhd.Latitude, 'int32');
fwrite(fod, PARAMS.xhd.Depth, 'int16');
fwrite(fod, 0, 'uchar');   % padding
fwrite(fod, 0, 'uchar');
fwrite(fod, 0, 'uchar');
fwrite(fod, 0, 'uchar');
fwrite(fod, 0, 'uchar');
fwrite(fod, 0, 'uchar');
fwrite(fod, 0, 'uchar');
fwrite(fod, 0, 'uchar');

for k = 1:nhrp
    % to get here fseek(fid,100,'bof')
    % "harp" write entries
    % entry 1
    % fwrite(fod, dvec(1), 'uchar');
    % fwrite(fod, dvec(2), 'uchar');
    % fwrite(fod, dvec(3), 'uchar');
    % fwrite(fod, dvec(4), 'uchar');
    % fwrite(fod, dvec(5), 'uchar');
    % fwrite(fod, dvec(6), 'uchar');
    % fwrite(fod, ticks, 'uint16');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,2) , 'uchar');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,3), 'uchar');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,4), 'uchar');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,5), 'uchar');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,6), 'uchar');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,7), 'uchar');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,8), 'uint16');
    if k > 1
        fwrite(fod, byteloc + sum(PARAMS.head.dirlist(fhdr:fhdr+k-2,10))*500, 'uint32');
    else
        fwrite(fod, byteloc , 'uint32');
    end
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,10)*500, 'uint32');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,10), 'uint32');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,9), 'uint32');
    fwrite(fod, PARAMS.xgain(1), 'uint8');
    fwrite(fod, 0, 'uchar'); % padding
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
end

% Data area -- variable length
fprintf(fod,'%c','d');
fprintf(fod,'%c','a');
fprintf(fod,'%c','t');
fprintf(fod,'%c','a');
fwrite(fod,bytelength,'uint32');

% fclose(fod);
% disp(['done writing header for ',PARAMS.outpath,PARAMS.outfile])

