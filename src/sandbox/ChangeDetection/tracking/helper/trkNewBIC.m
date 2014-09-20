function val = trkBIC_eng(segvectin, eng, winoffsetin)

% function val = trkBIC_eng(segvectin, eng,  winoffsetin)
% takes a segmentation of cepstral matrix 'segvect' and compute BIC 
% according to the 'winoffset', i.e. segvect(1:winoffset, :) as model 
% I and segvect(winoffset:N, :) as model II vs the whole segvect as
% one model.

% get the numberof vector in time domain  N, 
% and the dimension of the cepstral space d
[N, d]  = size(segvect);

% Eliminate the rows with low frame energy
[sval, sind] = sort(eng); 


% compute the penalty factor  p
p = 0.5*(d+(0.5*d*(d+1)))*log(N);

% set the penalty weight w
w = 1.2;

% compute the most likelihood R
R =  N*log(det(cov(segvect)))...
    -winoffset*log(det(cov(segvect(1:winoffset,:))))...
    -(N-winoffset)*log(det(cov(segvect(winoffset+1:N, :))));

% compute BIC value
val = R - w*p;


