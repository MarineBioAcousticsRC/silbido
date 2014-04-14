function read_ltsadata
%
%   ai = spectral average start bin
%   an = numberof spectral averages to read
%
% read ltsa data 
%
% 060511 smw
%
%
% Do not modify the following line, maintained by CVS
% $Id: read_ltsadata.m,v 1.5 2007/11/30 00:19:47 mroch Exp $

global PARAMS

check_ltsa_time

ltsafile = fullfile(PARAMS.ltsa.inpath,PARAMS.ltsa.infile);
fid = fopen(ltsafile,'r');
if fid == -1
    error('Unable top open LTSA file %s', ltsafile);
end

% nbin = floor(PARAMS.tseg.sec / PARAMS.psd.tlen); % number of bins to read/plot

% nbin = PARAMS.psd.b2-PARAMS.psd.b1;         % how many bins to grab
% b1 = PARAMS.psd.b1;                         % first bin

% which raw file to start plot with
PARAMS.ltsa.plotStartRawIndex = [];
% PARAMS.ltsa.plotStartRawIndex = find(PARAMS.ltsa.plot.dnum - PARAMS.ltsa.dnumStart >= ...
%      - datenum([0 0 0 0 0 PARAMS.ltsa.tave]) & PARAMS.ltsa.plot.dnum <= PARAMS.ltsa.dnumEnd);
% find with raw file the plot start time is in
PARAMS.ltsa.plotStartRawIndex = find(PARAMS.ltsa.plot.dnum >= PARAMS.ltsa.dnumStart ...
    & PARAMS.ltsa.plot.dnum + datenum([0 0 0 0 0 PARAMS.ltsa.tave])  <= PARAMS.ltsa.dnumEnd );
% if the plot start time is not within a raw file, find which ones it is
% between
if isempty(PARAMS.ltsa.plotStartRawIndex)
    PARAMS.ltsa.plotStartRawIndex = min(find(PARAMS.ltsa.plot.dnum <= PARAMS.ltsa.dnumStart));
    PARAMS.ltsa.plot.dnum = PARAMS.ltsa.dnumStart(PARAMS.ltsa.plotStartRawIndex);
end

if ~ isscalar(PARAMS.ltsa.plotStartRawIndex)
    % This should not happen.  If it does, the source materials overlap.
    % or there is a bug.
    disp_msg('Start time occurs in >1 file, may have overlap in audio data timestamps.');
    PARAMS.ltsa.plotStartRawIndex = min(PARAMS.ltsa.plotStartRawIndex);
end

index = PARAMS.ltsa.plotStartRawIndex;

% disp_msg(['index= ',num2str(index)]);
% time bin number at start of plot within rawfile (index)
PARAMS.ltsa.plotStartBin = floor((PARAMS.ltsa.plot.dnum - PARAMS.ltsa.dnumStart(index))...
    * 24 * 60 * 60 / PARAMS.ltsa.tave) + 1;

% samples to skip over in ltsa file
skip = PARAMS.ltsa.byteloc(index) + (PARAMS.ltsa.plotStartBin - 1) * PARAMS.ltsa.nf;

nbin = floor(PARAMS.ltsa.tseg.sec / PARAMS.ltsa.tave);

%skip = PARAMS.ltsa.dataStartLoc + ((ai - 1) * 1 * PARAMS.ltsa.nf);
% disp_msg(['skip= ',num2str(skip)]);
fseek(fid,skip,-1);    % skip over header + other data
PARAMS.ltsa.pwr = [];
PARAMS.ltsa.pwr = fread(fid,[PARAMS.ltsa.nf,nbin],'int8');   % read data

if size(PARAMS.ltsa.pwr, 2) < nbin
    % Account for short reads
    nbin = size(PARAMS.ltsa.pwr, 2);
end

% time bins
tbinsz = PARAMS.ltsa.tave/(60*60);
% only good for continuous data
PARAMS.ltsa.t = [];
PARAMS.ltsa.t = [0.5*tbinsz:tbinsz:(nbin-0.5)*tbinsz];

fclose(fid);

