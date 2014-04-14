function X = synthtrax(F, M, SR, WIN, HOP, DUR)
% X = synthtrax(F, M, SR, WIN, HOP, DUR)      Reconstruct a sound from track rep'n.
%	Each row of F and M contains a series of frequency and magnitude 
%	samples for a particular track.  These will be remodulated and 
%	overlaid into the output sound X which will run at sample rate SR, 
%	although the columns in F and M are subsampled, being derived from 
%   an STFT with win length WIN and hop HOP (default 256/128).
%	If DUR is nonzero, X will be padded or
%	truncated to correspond to just this much time.
% dpwe@icsi.berkeley.edu 1994aug20, 1996aug22

if(nargin<4)
  WIN = 256;
end

if(nargin<5)
  HOP = WIN/2;
end

if(nargin<6)
  DUR = 0;
end

rows = size(F,1);
cols = size(F,2);

opsamps = round(DUR*SR);
if(DUR == 0)
  opsamps = WIN + ((cols-1)*HOP);
end

X = zeros(1, opsamps);

for row = 1:rows
%  fprintf(1, 'row %d.. \n', row);
  mm = M(row,:);
  ff = F(row,:);
  % Where mm = 0, ff is undefined.  But interp will care, so find points 
  % and set.
  % First, find onsets - points where mm goes from zero (or NaN) to nzero
  % Before that, even, set all nan values of mm to zero
  mm(find(isnan(mm))) = zeros(1, sum(isnan(mm)));
  ff(find(isnan(ff))) = zeros(1, sum(isnan(ff)));
  nzv = find(mm);
  firstcol = min(nzv);
  lastcol = max(nzv);
  % for speed, chop off regions of initial and final zero magnitude - 
  % but want to include one zero from each end if they are there 
  zz = [max(1, firstcol-1):min(cols,lastcol+1)];
  mm = mm(zz);
  ff = ff(zz);
  nzcols = prod(size(zz));
  mz = (mm==0);
  mask = mz & (0==[mz(2:nzcols),1]);
  ff = ff.*(1-mask) + mask.*[ff(2:nzcols),0];
  % Do offsets too
  mask = mz & (0==[1,mz(1:(nzcols-1))]);
  ff = ff.*(1-mask) + mask.*[0,ff(1:(nzcols-1))];
  % Ok. Can interpolate now
  % This is actually the slow part
%  % these parameters to interp make it do linear interpolation
%  ff = interp(ff, HOP, 1, 0.001);
%  mm = interp(mm, HOP, 1, 0.001);
%  % chop off past-the-end vals from interp
%  ff = ff(1:((nzcols-1)*HOP)+1);
%  mm = mm(1:((nzcols-1)*HOP)+1);
  % slinterp does linear interpolation, doesn't extrapolate, 4x faster
  ff = slinterp(ff, HOP);
  mm = slinterp(mm, HOP);
  % convert frequency to phase values
  pp = cumsum(2*pi*ff/SR);
  % run the oscillator and apply the magnitude envelope
  xx = mm.*cos(pp);
  % add it in to the correct place in the array
  base = WIN-HOP+HOP*(zz(1)-1);
  sizex = prod(size(xx));
  ww = (base-1)+[1:sizex];
  X(ww) = X(ww) + xx;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Y = slinterp(X,F)
% Y = slinterp(X,F)  Simple linear-interpolate X by a factor F
%        Y will have ((size(X)-1)*F)+1 points i.e. no extrapolation
% dpwe@icsi.berkeley.edu  fast, narrow version for SWS

% Do it by rows

sx = prod(size(X));

% Ravel X to a row
X = X(1:sx);
X1 = [X(2:sx),0];

XX = zeros(F, sx);

for i=0:(F-1)
  XX((i+1),:) = ((F-i)/F)*X + (i/F)*X1;
end

% Ravel columns of X for output, discard extrapolation at end
Y = XX(1:((sx-1)*F+1));
