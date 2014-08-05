function val = trkBIC_Silence(segvect, winoffset)

% function val = trkNewBIC(segvect, winoffset)
% takes a segmentation of cepstral matrix 'segvect' and compute BIC 
% according to the 'winoffset', i.e. segvect(1:winoffset, :) as model 
% I and segvect(winoffset:N, :) as model II vs the whole segvect as
% one model.

% get the numberof vector in time domain  N, 
% and the dimension of the cepstral space d
[N, d]  = size(segvect);

% compute the penalty factor  p
p = 0.5*(d+(0.5*d*(d+1)))*log(N);

% set the penalty weight w
w = 1.2;

% compute the most likelihood R
R =  N*log(det(cov(segvect)))...
    -winoffset*log(det(cov(segvect(1:winoffset,:))))...
    -(N-winoffset)*log(det(cov(segvect(winoffset+1:N, :))));

% compute BIC value
valtemp = R - w*p;

% modify BIV value with variance of middle vector at winoffset
% see if shrink the false peaks due to silence

Range=-5:5;
mFactor = det(cov(segvect(winoffset+Range,:)));
global mFac
mFac(end+1) = mFactor;
%val = valtemp*mFactor;
if (mFactor < 5)
    val = 0;
else
    val = valtemp;
end

%val = valtemp* log(mFactor);