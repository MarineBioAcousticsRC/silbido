function wrxwavhd(oftype)
%
% wrxwavhd - write xwav header
% oftype = output file type:    1 == save window plotted data
%                               2 == decimate whole xwav file
%
% 060222 - 060227 smw modified for decimating xwav ver1 
%       (i.e., multiple raw file)
%
% 060610 smw updated for dSubchunkSize
%%
% Do not modify the following line, maintained by CVS
% $Id: wrxwavhd.m,v 1.1.1.1 2006/09/23 22:31:57 msoldevilla Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% past history:
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global PARAMS

% if making xwav from window plotted data
if oftype == 1
    PARAMS.xhd.NumOfRawFiles = 1;

    dvec = datevec(PARAMS.plot.dnum);
    ticks = floor( 1000*(dvec(6) - floor(dvec(6))));

    PARAMS.xhd.year(1) = dvec(1);          % Year
    PARAMS.xhd.month(1) = dvec(2);         % Month
    PARAMS.xhd.day(1) = dvec(3);           % Day
    PARAMS.xhd.hour(1) = dvec(4);          % Hour
    PARAMS.xhd.minute(1) = dvec(5);        % Minute
    PARAMS.xhd.secs(1) = floor(dvec(6));          % Seconds
    PARAMS.xhd.ticks(1) = ticks;
    
    PARAMS.xhd.BlockAlign = 2;
    
elseif oftype == 2
    % little risky, but give it a try:
    PARAMS.xhd.byte_length = PARAMS.xhd.byte_length ./ PARAMS.df;
    %new sample rate
    PARAMS.xhd.sample_rate = PARAMS.xhd.sample_rate ./ PARAMS.df;
    PARAMS.xhd.ByteRate = PARAMS.xhd.ByteRate ./ PARAMS.df;
    %
    PARAMS.xhd.write_length = PARAMS.xhd.write_length ./ PARAMS.df;
end

newfs = PARAMS.fs/PARAMS.df;

% wav file header parameters
% RIFF Header stuff:
harpsize = PARAMS.xhd.NumOfRawFiles * 32 + 64 - 8;% length of the harp chunk


% HARP Write Header info (one listing per write)
byteloc = (8+4) + (8+16) + 64 + (32 * PARAMS.xhd.NumOfRawFiles) + 8;
% Format Chunk stuff:
fsize = 16;  % format chunk size
if PARAMS.nBits == 16
    fcode = 1;   % compression code (PCM = 1)
elseif PARAMS.nBits == 32
    fcode = 3;   % compression code (PCM = 3) for 32 bit
end


% bytes of data - only one channel

bytelength = PARAMS.xhd.dSubchunkSize / PARAMS.df;

wavsize = bytelength+36+harpsize+8;  % required for the RIFF header

% open output file
fod = fopen([PARAMS.outpath,PARAMS.outfile],'w');

% write xwav file header
%
% RIFF file header                  % length = 12 bytes
fprintf(fod,'%c','R');
fprintf(fod,'%c','I');
fprintf(fod,'%c','F');
fprintf(fod,'%c','F');                      % byte 4
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
fprintf(fod,'%c',' ');                      % byte 16
fwrite(fod,fsize,'uint32');
fwrite(fod,fcode,'uint16');
fwrite(fod,PARAMS.nch/PARAMS.nch,'uint16');         % only one channel of data shown in window
fwrite(fod,newfs,'uint32');
fwrite(fod,PARAMS.xhd.ByteRate/PARAMS.nch,'uint32');
fwrite(fod,PARAMS.xhd.BlockAlign,'uint16');
fwrite(fod,PARAMS.nBits,'uint16');                  % byte 35 & 36

%
% "harp" chunk              (64 bytes long)
fprintf(fod,'%c', 'h');
fprintf(fod,'%c', 'a');
fprintf(fod,'%c', 'r');
fprintf(fod,'%c', 'p');
fwrite(fod, harpsize, 'uint32');
fwrite(fod, PARAMS.xhd.WavVersionNumber , 'uchar');
fprintf(fod, '%c', PARAMS.xhd.FirmwareVersionNuumber);  % 10 char
fprintf(fod, '%c', PARAMS.xhd.InstrumentID);            % 4 char
fprintf(fod, '%c', PARAMS.xhd.SiteName);                % 4 char
fprintf(fod, '%c', PARAMS.xhd.ExperimentName);          % 8 char
fwrite(fod, PARAMS.xhd.DiskSequenceNumber, 'uchar');
fprintf(fod, '%c', PARAMS.xhd.DiskSerialNumber);        % 8 char

fwrite(fod, PARAMS.xhd.NumOfRawFiles, 'uint16');
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
fwrite(fod, 0, 'uchar');                        % byte 100

for k = 1:PARAMS.xhd.NumOfRawFiles
    if k > 1
        PARAMS.xhd.byte_loc(k) = PARAMS.xhd.byte_loc(k-1) ...
            + PARAMS.xhd.byte_length(k-1);
    end
    fwrite(fod, PARAMS.xhd.year(k), 'uchar');
    fwrite(fod, PARAMS.xhd.month(k), 'uchar');
    fwrite(fod, PARAMS.xhd.day(k), 'uchar');
    fwrite(fod, PARAMS.xhd.hour(k), 'uchar');
    fwrite(fod, PARAMS.xhd.minute(k), 'uchar');
    fwrite(fod, PARAMS.xhd.secs(k), 'uchar');
    fwrite(fod, PARAMS.xhd.ticks(k), 'uint16');
    fwrite(fod, PARAMS.xhd.byte_loc(k), 'uint32');
    fwrite(fod, PARAMS.xhd.byte_length(k), 'uint32');
    fwrite(fod, PARAMS.xhd.write_length(k), 'uint32');
    fwrite(fod, PARAMS.xhd.sample_rate(k), 'uint32');
    fwrite(fod, PARAMS.xhd.gain(k), 'uint8');
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

fclose(fod);
disp_msg(['done writing header for ',PARAMS.outpath,PARAMS.outfile])

