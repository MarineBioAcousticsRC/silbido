function read_rawHARPhead(filename,d)
%
% usage: >> read_rawHARPhead(filename,d)
%       if d = 1, then display header values in command window
%
% function to read raw HARP disk header info from raw HARP datafile (*.hrp)
% and put disk header info into global variable structure PARAMS
%
% FYI: one sector = 512 bytes
%
% note: at the hardware level of the processors & hard disk the
% odd and even bytes are swapped between datalogger processor
% Motorola MC68xxx and processing machine - PC (Intel) processor
% i.e., as if 2-byte words converted from big-endian to little-endian
% byteswap for header info is accomplished with:
% sector_swap = reshape(circshift(reshape(sector,2,256),1),512,1);
% use big-endian format for 2-byte data: fid = fopen(filename,'r','b'); or
% x = fread(fid,250,'int16','b');
%
% HARP raw disk structure is:
% sector 0 => Disktype and Disk Number + empty space
% sector 1 => empty
% sector 2 => Disk Header - directory structure information + empty space
% sector 3-7 => empty
% sector 8 => Directory Listing of disk writes + some empty space
% sector 181 => Start of Data for 80 GB disk & HARP firmware version 1.17
%               Data are written in sectors with the first 12 bytes timing
%               info and the next 500 bytes = 250 2-byte(16bit) samples.
%
% smw 050916 - 050917
%
% revised 051108 smw for trashed disk headers
%
% Do not modify the following line, maintained by CVS
% $Id: read_rawHARPhead.m,v 1.2 2006/12/20 04:32:06 msoldevilla Exp $
%

global PARAMS

PARAMS.head = [];

% display flag: display values = 1
if d
    dflag = 1;
else
    dflag = 0;
end

% check to see if file exists - return if not
if ~exist(filename)
    disp_msg(['Error - no file ',filename])
    return
end

% open raw HARP file
fid = fopen(filename,'r');

% read first 3 sectors:

% sector0
sector0 = fread(fid,512,'uint8');
% swap byte locations
sector0_swap = reshape(circshift(reshape(sector0,2,256),1),512,1);

% display sector0 disk type/disk number
% disp(['Sector 0 => ',char(sector0_swap(1:14)')])

% disk type
PARAMS.head.disktype = char(sector0_swap(1:4))';
if ~strcmp(PARAMS.head.disktype,'HARP') & dflag
    disp_msg(['Error - wrong file type ',PARAMS.head.disktype])
    % return
end

% disk number
PARAMS.head.disknumberSector0 = str2num(char(sector0_swap(13:14))');

% sector 1 is empty
sector1 = fread(fid,512,'uint8');

% sector 2 = disk header - directory location info
sector2 = fread(fid,512,'uint8');
% swap byte locations
s2s = reshape(circshift(reshape(sector2,2,256),1),512,1);

% PARAMS.nextSector = s2s(4) + 2^8 * s2s(3) + 2^16 * s2s(2) + 2^24 * s2s(1);
% units for HARP raw disk are bytes, sectors, and files
% 1 byte == 8 bits
% 1 sector == 512 bytes
% 1 file == 60000 sectors
%
% write-block       - next sector to be written on disk
PARAMS.head.nextFileSector = little2big_4byte(s2s(1:4));
% dir_start         - directory start sector
PARAMS.head.firstDirSector = little2big_4byte(s2s(13:16));
% if PARAMS.head.firstDirSector == 8
    % dir_size          - number of sectors in directory
    PARAMS.head.maxFile = little2big_4byte(s2s(17:20));
    % dir_block         - current directory sector
    PARAMS.head.currDirSector = little2big_4byte(s2s(21:24));
    % dir_count         - next directory entry
    PARAMS.head.nextFile = little2big_4byte(s2s(25:28));
    % data_start        - sector number where data starts
    PARAMS.head.firstFileSector = little2big_4byte(s2s(61:64));
    % sample_rate       - current sample rate
    PARAMS.head.samplerate = little2big_4byte(s2s(65:68));
    % disk number       - disk drive position; 1=drive1, 2=drive2
    PARAMS.head.disknumberSector2 = little2big_2byte(s2s(69:70));
    % soft_version[10]  - firmware version number
    PARAMS.head.firmwareVersion = char(s2s(71:80))';
    % description[80]   - unused
    PARAMS.head.description = char(s2s(81:160))';
    % disk_size         - size of disk in 512 byte sectors
    PARAMS.head.disksizeSector = little2big_4byte(s2s(173:176));
    % avail_sects       - unused sectors on drive
    PARAMS.head.unusedSector = little2big_4byte(s2s(177:180));

% else    % disk header is trashed, so hardwire PARAMS values
%     % write-block       - next sector to be written on disk
%     PARAMS.head.nextFileSector = 4740171;  % probably should be smaller
%     % dir_start         - directory start sector
%     PARAMS.head.firstDirSector = 8;
%     % dir_size          - number of sectors in directory
%     PARAMS.head.maxFile = 2606;
%     % dir_block         - current directory sector
%     PARAMS.head.currDirSector = 170;
%     % dir_count         - next directory entry
%     PARAMS.head.nextFile = 79;        % probably needs a smaller value
%     % data_start        - sector number where data starts
%     PARAMS.head.firstFileSector = 171;
%     % sample_rate       - current sample rate
%     PARAMS.head.samplerate = 80000;
%     % disk number       - disk drive position; 1=drive1, 2=drive2
%     PARAMS.head.disknumberSector2 = PARAMS.head.disknumberSector0;
%     % soft_version[10]  - firmware version number
%     PARAMS.head.firmwareVersion = '1.14c     ';
%     % description[80]   - unused
%     PARAMS.head.description = char(s2s(81:160))';
%     % disk_size         - size of disk in 512 byte sectors
%     PARAMS.head.disksizeSector = 156301488;
%     % avail_sects       - unused sectors on drive
%     PARAMS.head.unusedSector = 1315;
% 
% end

if dflag
    disp_msg(' ')
    disp_msg('Sector 0: ')
    disp_msg(['Disk Type = ',PARAMS.head.disktype])
    disp_msg(['Disk Number = ',num2str(PARAMS.head.disknumberSector0)])
    disp_msg(' ')

    disp_msg('Sector 2: ')
    disp_msg(['First Directory Location [Sectors] = ',num2str(PARAMS.head.firstDirSector)])
    disp_msg(['Current Directory Location [Sectors] = ',num2str(PARAMS.head.currDirSector)])
    disp_msg(' ')
    disp_msg(['First File Location [Sectors] = ',num2str(PARAMS.head.firstFileSector)])
    disp_msg(['Next File Location [Sectors] = ',num2str(PARAMS.head.nextFileSector)])
    disp_msg(' ')
    disp_msg(['Max Number of Files = ',num2str(PARAMS.head.maxFile)])
    disp_msg(['Next File = ',num2str(PARAMS.head.nextFile)])
    disp_msg(' ')
    disp_msg(['Sample rate = ',num2str(PARAMS.head.samplerate)])
    disp_msg(['Disk Number = ',num2str(PARAMS.head.disknumberSector2)])
    disp_msg(['Firmware Version = ',PARAMS.head.firmwareVersion])
    disp_msg(['Description = ',PARAMS.head.description])
    disp_msg(['Disk Size [Sectors] = ',num2str(PARAMS.head.disksizeSector)])
    disp_msg(['Unused Disk [Sectors] = ',num2str(PARAMS.head.unusedSector)])
end
% close raw HARP file
fclose(fid);