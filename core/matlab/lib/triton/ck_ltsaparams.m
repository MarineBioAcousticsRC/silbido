function [ltsainfo, result] = ck_ltsaparams(ltsainfo)
% [ltsainfo, result] = ck_ltsaparams(ltsainfo)
% check user defined ltsa parameters and adjusts/gives suggestions of
% better parameters so that there is integer number of averages per xwav
% file
%
% Returns boolean indicating success/failure and updated ltsa/ltsahd 
% structures.
%
% called by mk_ltsa
%
% 060802 smw
% 060914 smw modified for wav files
%
% Do not modify the following line, maintained by CVS
% $Id: ck_ltsaparams.m,v 1.7 2007/11/27 21:32:57 mroch Exp $

result = true;  % Assume correct until we find out otherwise
% get sample rate - only the first file sr for now.....
if ltsainfo.ltsa.ftype == 1   % wav
    [y, ltsainfo.ltsa.fs, nBits, OPTS] = ...
        wavread(fullfile(ltsainfo.ltsa.indir,ltsainfo.ltsa.fname{1}),10);
elseif ltsainfo.ltsa.ftype == 2   % xwav
    fid = fopen(fullfile(ltsainfo.ltsa.indir,ltsainfo.ltsa.fname{1}),'r');
    fseek(fid,24,'bof');
    ltsainfo.ltsa.fs = fread(fid,1,'uint32');          % Sampling Rate (samples/second)
    fclose(fid);
end

% check that all sample rates match first file
I = [];
I = find(ltsainfo.ltsahd.sample_rate ~= ltsainfo.ltsa.fs);
if ~isempty(I)
  disp_msg('LTSA generation aborted')
  disp_msg(sprintf('Sample rates differ from %s''s sample rate of %d', ...
                   ltsainfo.ltsa.fname{1}, ...
                   ltsainfo.ltsahd.sample_rate(1)));
  badfiles = '';
  for idx=I
    badfiles = sprintf('%s\n%s Fs=%d ', badfiles, ...
                       ltsainfo.ltsa.fname{idx}, ...
                       ltsainfo.ltsahd.sample_rate(idx));
  end
  disp_msg('List of files:');
  disp_msg(badfiles);
  errordlg('All files in LTSA must have the same sample rate (see message panel)', ...
           'LTSA Generation Failed');
  result = false;
  return
end

% check to see if header times are in correct order based on file names
tf = issorted(ltsainfo.ltsahd.dnumStart);
if ~tf
    [B,IX] = sort(ltsainfo.ltsahd.dnumStart);
    seq = 1:1:length(B);
    IY = find(IX ~= seq);
    disp_msg('Raw files out of sequence are : ')
    disp_msg(num2str(IX(IY)))
    disp_msg('header times are NOT sequential')
    % result = false;
    % return
end

% number of samples per data 'block' HARP=1sector(512bytes), ARP=64kB
if ltsainfo.ltsa.dtype == 1       % HARP data => 12 byte header
    ltsainfo.ltsa.blksz = (512 - 12)/2;
elseif ltsainfo.ltsa.dtype == 2   % ARP data => 32 byte header + 2 byte tailer
    ltsainfo.ltsa.blksz = (65536 - 34)/2;
elseif ltsainfo.ltsa.dtype == 3   % OBS data => 128 samples per block
    ltsainfo.ltsa.blksz = 128;
elseif ltsainfo.ltsa.dtype == 4   % Ishmael data => wave files from sonobuoy/arrays
    % don't worry about it for this type...
else
    disp_msg('Error - non-supported data type')
    disp_msg(['ltsainfo.ltsa.dtype = ',num2str(ltsainfo.ltsa.dtype)])
    result = false;
    return
end

% check to see if tave is too big, if so, set to max length
%
% maxTave = (ltsainfo.ltsahd.write_length(1) * 250) / ltsainfo.ltsa.fs;
if ltsainfo.ltsa.ftype ~= 1
    maxTave = (ltsainfo.ltsahd.write_length(1) * ltsainfo.ltsa.blksz) / ltsainfo.ltsa.fs;
    if ltsainfo.ltsa.tave > maxTave
        ltsainfo.ltsa.tave = maxTave;
        disp_msg('Averaging time too long, set to maximum')
        disp_msg(['Tave = ',num2str(ltsainfo.ltsa.tave)])
    end
end

% number of samples for fft - make sure it is an integer
ltsainfo.ltsa.nfft = ceil(ltsainfo.ltsa.fs / ltsainfo.ltsa.dfreq);
disp_msg(['LTSA - Number of samples for fft: ', num2str(ltsainfo.ltsa.nfft)])

% number of frequencies in each spectral average:
ltsainfo.ltsa.nfreq = ltsainfo.ltsa.nfft/2 + 1;
% compression factor
ltsainfo.ltsa.cfact = ltsainfo.ltsa.tave * ltsainfo.ltsa.fs / ltsainfo.ltsa.nfft;
disp_msg(sprintf('LTSA - Audio Compression Factor: %f',ltsainfo.ltsa.cfact))


