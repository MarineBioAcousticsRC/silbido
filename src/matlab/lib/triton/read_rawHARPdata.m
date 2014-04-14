function [dvec, data] = read_rawHARPdata(filename,d,numFile)
%
% usage: >> [dvec, data] = read_rawHARPdata(filename,d,numFile)
%       dvec == date vector -> format: [yyyy mm dd HH MM SS.mmm]
%       data == one raw HARP file of 2-byte data
%       filename == FileSystem file name for raw HARP disk data
%       d = 1 -> display some stuff in command window, = 0 then no display
%       numFile == file number per raw HARP disk data
%
% this function reads one raw HARP disk data file, typically 60000 sectors
% the first timing header will be read and used.  Use a data header (not
% directory listing) timing checker to see if each sector (block) is
% contiguous
%
%   smw 050919
%
% units for HARP raw disk are bytes, sectors, and files
% 1 byte == 8 bits
% 1 sector == 512 bytes
% 1 file == 60000 sectors
%
% Do not modify the following line, maintained by CVS
% $Id: read_rawHARPdata.m,v 1.2 2006/12/20 04:32:06 msoldevilla Exp $

global PARAMS

% check to see if file exists - return if not
if ~exist(filename)
    disp(['Error - no file ',filename])
    return
end

% display flag: display values = 1
if d
    dflag = 1;
else
    dflag = 0;
end

% read raw HARP dirlist (and disk header from within read_rawHARPdir)
read_rawHARPdir(filename,0);

if numFile > PARAMS.head.nextFile
    disp(['Error - last raw file = ',num2str(PARAMS.head.nextFile)])
    disp(['You chose filenumber = ', num2str(numFile)])
    return
end

% open raw HARP file
fid = fopen(filename,'r');
% fod = fopen('F:\DATA\TestData\testdata.bin','w');

% skip to 1st dir sector of data (raw file number)
fseek(fid,512*PARAMS.head.dirlist(numFile,1),'bof');

tic
% loop over the number of sectors for this file
data = zeros(1,60000*250);
count = 1;

dv = fread(fid,12,'uint8');
dvec = [dv(2) dv(1) dv(4) dv(3) dv(6) dv(5) ...
    + little2big_2byte([dv(8) dv(7)])];
data = fread(fid,250,'int16')';
% fwrite(fod,fread(fid,250,'int16'),'int16');

% for ii = 2:PARAMS.dirlist(numFile,10)
for ii = 2:1000
    fseek(fid,12,0);
%     data(250*(ii-1)+1:250*ii) = fread(fid,250,'int16','l');
     data = [data fread(fid,250,'int16')'];
%    fwrite(fod,fread(fid,250,'int16'),'int16');
    count = count + 1;
    if dflag && count == 1000
        disp(['data block [sector] = ',num2str(ii)])    % give the user some feed back during this long process
        count = 0;
    end
end

% close FileSystem file
fclose(fid);
% fclose(fod);

toc