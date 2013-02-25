function [ltsainfo, success] = get_headers(ltsainfo)
% [ltsainfo, success] = get_headers(ltsa)
% open data files and read audio headers
% Returns updated ltsa/ltsahd structure along with boolean indicating
% whether or not successful.
%
% 060508 smw
% 060914 smw modified for wav files
%
% Do not modify the following line, maintained by CVS
% $Id: get_headers.m,v 1.6 2008/06/21 16:43:57 mroch Exp $

success = true; % until proven otherwise

m = 0;                         % total number of raw files used for ltsa
ltsainfo.ltsa.nxwav = length(ltsainfo.ltsa.fname);        % number audio files
ltsainfo.ltsahd.fname = cell(ltsainfo.ltsa.nxwav, 1);     % Create cell array for filenames
if ltsainfo.ltsa.ftype == 1
  % Extract dates for WAV files from filenames as they are not encoded in
  % file meta-information.  Dates are stored as an offset to a specific
  % date.
  ltsainfo.ltsahd.dnumStart = ...
      dateregexp(ltsainfo.ltsa.fname, ltsainfo.ltsa.fnameTimeRegExp) - ...
      dateoffset();
end

for k = 1:ltsainfo.ltsa.nxwav            % loop over all each audio file

    if ltsainfo.ltsa.ftype == 1       % do the following for wav files
        m = m + 1;
        WavFile = fullfile(ltsainfo.ltsa.indir,ltsainfo.ltsa.fname{k});
        % check wav file goodness
        [mm dd] = wavfinfo(WavFile);
        if isempty(mm)
            disp_msg(dd)
            disp_msg(WavFile)
            disp_msg('Run wavDirTestFix.m on this directory first, then try again')
            success = false;
            return
        end
        % read wav header and fill up PARAMS
        [SampChan, ltsainfo.ltsahd.sample_rate(m), ltsainfo.ltsa.nBits] = ...
            wavread(WavFile, 'size');
        ltsainfo.ltsahd.nsamp(m) = SampChan(1);
        % Only one number of channels value per LTSA,
        % may cause problems later.
        ltsainfo.ltsa.nch = SampChan(2);
        bytespersample = floor(ltsainfo.ltsa.nBits/8);

        % may not use the following since we'll work in samples, not bytes
        %           ltsainfo.ltsahd.byte_loc(m) = fread(fid,1,'uint32');     % Byte location in xwav file of RawFile start
        %           ltsainfo.ltsahd.byte_length(m) = ltsainfo.ltsa.nsamp(m) * bytespersample;    % Byte length of RawFile in xwav file
        %           ltsainfo.ltsahd.write_length(m) = fread(fid,1,'uint32'); % # of blocks in RawFile length (default = 60000)

        ltsainfo.ltsahd.fname{m} = ltsainfo.ltsa.fname{k};        % xwav file name for this raw file header
        ltsainfo.ltsahd.rfileid(m) = 1;                           % raw file id / number in this xwav file

        % Start times computed outside of loop for wav files.
        % Extract additional time-related information for the header.
        ltsainfo.ltsahd.dvecStart(m,:) = datevec(ltsainfo.ltsahd.dnumStart(m));

        ltsainfo.ltsahd.year(m) = ltsainfo.ltsahd.dvecStart(m,1);          % Year
        ltsainfo.ltsahd.month(m) = ltsainfo.ltsahd.dvecStart(m,2);         % Month
        ltsainfo.ltsahd.day(m) = ltsainfo.ltsahd.dvecStart(m,3);           % Day
        ltsainfo.ltsahd.hour(m) = ltsainfo.ltsahd.dvecStart(m,4);          % Hour
        ltsainfo.ltsahd.minute(m) = ltsainfo.ltsahd.dvecStart(m,5);        % Minute
        ltsainfo.ltsahd.secs(m) = ltsainfo.ltsahd.dvecStart(m,6);          % Seconds
        ltsainfo.ltsahd.ticks(m) = 0;

    elseif ltsainfo.ltsa.ftype == 2               % do the following for xwavs
        fid = fopen(fullfile(ltsainfo.ltsa.indir,ltsainfo.ltsa.fname{k}),'r');
                
        fseek(fid,22,'bof');
        % Only one number of channels value per LTSA,
        % may cause problems later.
        ltsainfo.ltsa.nch = fread(fid,1,'uint16');         % Number of Channels
        
        fseek(fid,34,'bof');
        ltsainfo.ltsa.nBits = fread(fid,1,'uint16');       % # of Bits per Sample : 8bit = 8, 16bit = 16, etc
        if ltsainfo.ltsa.nBits == 16
            ltsainfo.ltsa.dbtype = 'int16';
        elseif ltsainfo.ltsa.nBits == 32
            ltsainfo.ltsa.dbtype = 'int32';
        else
            disp_msg(sprintf('LTSA %d bit XWAVs not supported', ltsainfo.ltsa.nBits))
            success = false;
            return
        end
        
        fseek(fid,80,'bof');
        nrf = fread(fid,1,'uint16');         % Number of RawFiles in XWAV file (80 bytes from bof)

        fseek(fid,100,'bof');
        for r = 1:nrf                           % loop over the number of raw files in this xwav file
            m = m + 1;                                              % count total number of raw files
            ltsainfo.ltsahd.rfileid(m) = r;                           % raw file id / number in this xwav file
            ltsainfo.ltsahd.year(m) = fread(fid,1,'uchar');          % Year
            ltsainfo.ltsahd.month(m) = fread(fid,1,'uchar');         % Month
            ltsainfo.ltsahd.day(m) = fread(fid,1,'uchar');           % Day
            ltsainfo.ltsahd.hour(m) = fread(fid,1,'uchar');          % Hour
            ltsainfo.ltsahd.minute(m) = fread(fid,1,'uchar');        % Minute
            ltsainfo.ltsahd.secs(m) = fread(fid,1,'uchar');          % Seconds
            ltsainfo.ltsahd.ticks(m) = fread(fid,1,'uint16');        % Milliseconds
            ltsainfo.ltsahd.byte_loc(m) = fread(fid,1,'uint32');     % Byte location in xwav file of RawFile start
            ltsainfo.ltsahd.byte_length(m) = fread(fid,1,'uint32');    % Byte length of RawFile in xwav file
            ltsainfo.ltsahd.write_length(m) = fread(fid,1,'uint32'); % # of blocks in RawFile length (default = 60000)
            ltsainfo.ltsahd.sample_rate(m) = fread(fid,1,'uint32');  % sample rate of this RawFile
            ltsainfo.ltsahd.gain(m) = fread(fid,1,'uint8');          % gain (1 = no change)
            ltsainfo.ltsahd.padding = fread(fid,7,'uchar');    % Padding to make it 32 bytes...misc info can be added here
            ltsainfo.ltsahd.fname{m} = ltsainfo.ltsa.fname{k};        % xwav file name for this raw file header

            ltsainfo.ltsahd.dnumStart(m) = datenum([ltsainfo.ltsahd.year(m) ltsainfo.ltsahd.month(m)...
                ltsainfo.ltsahd.day(m) ltsainfo.ltsahd.hour(m) ltsainfo.ltsahd.minute(m) ...
                ltsainfo.ltsahd.secs(m)+(ltsainfo.ltsahd.ticks(m)/1000)]);

        end
        fclose(fid);
    end

end

ltsainfo.ltsa.nrftot = m;     % total number of raw files
