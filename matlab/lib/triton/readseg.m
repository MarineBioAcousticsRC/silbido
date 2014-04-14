function readseg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% readseg.m
%
% previously rdtseg.m
%
% read a segment of data from opened file
%
%
% 060203 - 060227 smw
%
% Do not modify the following line, maintained by CVS
% $Id: readseg.m,v 1.4 2007/05/12 01:25:05 mroch Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global PARAMS DATA

check_time      % check to see if ok plot start time (PARAMS.plot.dvec or 
                % PARAMS.plot.dnum)

DATA = [];  % clear DATA matrix

if PARAMS.ftype == 1        % wav file
    % number of samples to skip over
    skip = floor((PARAMS.plot.dnum - PARAMS.start.dnum) * 24 * 60 * 60 * PARAMS.fs);
    % number of desired samples in segment
    PARAMS.tseg.samp = ceil( PARAMS.tseg.sec * PARAMS.fs );
    
    filename = fullfile(PARAMS.inpath, PARAMS.infile);
    Samples = wavread(filename, 'size');
    LastSample = min(skip+PARAMS.tseg.samp, Samples(1));
    DATA = wavread(filename, [skip+1 LastSample]);
    DATA = DATA(:, PARAMS.ch);  % retain selected channel
    xgain = 2^-15;         % un-normalize wave read
elseif PARAMS.ftype == 2    % xwav file
    index = PARAMS.raw.currentIndex;
    if PARAMS.nBits == 16
        dtype = 'int16';
    elseif PARAMS.nBits == 32
        dtype = 'int32';
    else
        disp_msg('PARAMS.nBits = ')
        disp_msg(PARAMS.nBits)
        disp_msg('not supported')
        return
    end
    skip = floor((PARAMS.plot.dnum - PARAMS.raw.dnumStart(index)) * 24 * 60 * 60 * PARAMS.fs);   % number of samples to skip over
    % %
    PARAMS.tseg.samp = ceil( PARAMS.tseg.sec * PARAMS.fs );	% number of samples in segment
    fid = fopen(fullfile(PARAMS.inpath, PARAMS.infile),'r');
    fseek(fid,PARAMS.xhd.byte_loc(index) + skip*PARAMS.nch*PARAMS.samp.byte,'bof');
    DATA = fread(fid,[PARAMS.nch,PARAMS.tseg.samp],dtype);
    DATA = DATA(PARAMS.ch, :);
    fclose(fid);
    xgain = PARAMS.xgain(1);
end

DATA = DATA / xgain;    % Gain compensation
    
    
PARAMS.save.dnum = PARAMS.plot.dnum;    % save it for next time

