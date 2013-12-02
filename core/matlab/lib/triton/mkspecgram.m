function mkspecgram
%
% pulled out of plottseg
%
% 060227 smw for v1.60
%
% Do not modify the following line, maintained by CVS
% $Id: mkspecgram.m,v 1.3 2008/11/24 04:52:31 mroch Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global PARAMS DATA

   % some spectra stuff 
   window = hanning(PARAMS.nfft);
   noverlap = round((PARAMS.overlap/100)*PARAMS.nfft);
   if noverlap == PARAMS.nfft
       noverlap = PARAMS.nfft - 1;
   end
   % calculate spectrogram plot (need signal toolbox)
   [sg,f,PARAMS.t]=specgram(DATA,PARAMS.nfft,PARAMS.fs,window,noverlap);
   % produce image (gain) only within limits
   nf = length(f);

   df = PARAMS.fs/PARAMS.nfft;
   k = length(PARAMS.t);
   fimin = ceil(PARAMS.freq0 / df)+1;
   fimax = ceil(PARAMS.freq1 / df);
   sg = sg(fimin:fimax,:);
   PARAMS.f = f(fimin:fimax);
   PARAMS.pwr = 20*log10(abs(sg))...		% counts^2/Hz
      - 10*log10(sum(window)^2)...  % undo normalizing factor
      + 3;      % add in the other side that matlab doesn't do

   % Floor log frequencies at the ETSI ES 201 108 v1.1.2 2000-04
   % specification of log(1.9287e-22) = -50
   PARAMS.pwr(PARAMS.pwr < -50) = -50;

   PARAMS.fimin = fimin;
   PARAMS.fimax = fimax;

 
