function spWriteHTK(file,d,fp,tc)
%WRITEHTK write data in HTK format []=(FILE,D,FP,TC)
%
% Inputs:
%    FILE = name of file to write (no default extension)
%       D = data to write: one row per frame
%      FP = frame period in seconds
%      TC = type code = the sum of a data type and (optionally) one or more of the listed modifiers
%             0  WAVEFORM     Acoustic waveform
%             1  LPC          Linear prediction coefficients
%             2  LPREFC       LPC Reflection coefficients:  -lpcar2rf([1 LPC]);LPREFC(1)=[];
%             3  LPCEPSTRA    LPC Cepstral coefficients
%             4  LPDELCEP     LPC cepstral+delta coefficients (obsolete)
%             5  IREFC        LPC Reflection coefficients (16 bit fixed point)
%             6  MFCC         Mel frequency cepstral coefficients
%             7  FBANK        Log Fliter bank energies
%             8  MELSPEC      linear Mel-scaled spectrum
%             9  USER         User defined features
%            10  DISCRETE     Vector quantised codebook
%            11  PLP          Perceptual Linear prediction
%            12  ANON
%            64  _E  Includes energy terms                  hd(1) 
%           128  _N  Suppress absolute energy               hd(2)
%           256  _D  Include delta coefs                    hd(3)
%           512  _A  Include acceleration coefs             hd(4)
%          1024  _C  Compressed                             hd(5)
%          2048  _Z  Zero mean static coefs                 hd(6)
%          4096  _K  CRC checksum (not implemented yet)     hd(7) (ignored)
%          8192  _0  Include 0'th cepstral coef             hd(8)
%         16384  _V  Attach VQ index                        hd(9)
%         32768  _T  Attach delta-delta-delta index         hd(10)

%      Copyright (C) Mike Brookes 2005
%      Version: $Id: spWriteHTK.m,v 1.1 2006/06/12 15:11:08 mroch Exp $
%
%   VOICEBOX is a MATLAB toolbox for speech processing.
%   Home page: http://www.ee.ic.ac.uk/hp/staff/dmb/voicebox/voicebox.html
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This program is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation; either version 2 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You can obtain a copy of the GNU General Public License from
%   ftp://prep.ai.mit.edu/pub/gnu/COPYING-2.0 or by writing to
%   Free Software Foundation, Inc.,675 Mass Ave, Cambridge, MA 02139, USA.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fid=fopen(file,'w','b');
if fid < 0
    error(sprintf('Cannot write to file %s',file));
end
tc=bitset(tc,13,0);                 % silently ignore a checksum request

[nf,nv]=size(d);
nhb=10;                             % number of suffix codes
ndt=6;                              % number of bits for base type
hb=floor(tc*pow2(-(ndt+nhb):-ndt));
hd=hb(nhb+1:-1:2)-2*hb(nhb:-1:1);   % extract bits from type code
dt=tc-pow2(hb(end),ndt);            % low six bits of tc represent data type

if ~dt & (size(d,1)==1)             % if waveform is a row vector
    d=d(:);                         % ... convert it to a column vector
    [nf,nv]=size(d);
end

if hd(5)                            % if compressed
    dx=max(d,[],1);
    dn=min(d,[],1);
    a=ones(1,nv);                   % default compression factors for cols with max=min
    b=dx;
    mk=dx>dn;
    a(mk)=65534./(dx(mk)-dn(mk));   % calculate compression factors for each column
    b(mk)=0.5*(dx(mk)+dn(mk)).*a(mk);
    d=d.*repmat(a,nf,1)-repmat(b,nf,1); % compress the data
    nf=nf+4;                        % adjust frame count to include compression factors
end
fwrite(fid,nf,'int32', 'b');    % number of vectors
fwrite(fid,round(fp*1.E7),'int32', 'b');  % frame advance (period)
if any(dt==[0,5,10]) | hd(5)        % write data as shorts
    if dt==5                        % IREFC has fixed scale factor
        d=d*32767;
        if hd(5)
            error('Cannot use compression with IREFC format');
        end        
    end
    fwrite(fid,nv*2,'int32', 'b');
    fwrite(fid,tc,'int32', 'b');
    if hd(5)
        fwrite(fid,a,'float32', 'b');        % write compression factors
        fwrite(fid,b,'float32', 'b');      
    end
    fwrite(fid,d.','int32', 'b');  
else
    fwrite(fid,4*nv,'int16', 'b');
    fwrite(fid,tc,'int16', 'b');
    fwrite(fid,d.','float32', 'b');  
end
fclose(fid);
1;
