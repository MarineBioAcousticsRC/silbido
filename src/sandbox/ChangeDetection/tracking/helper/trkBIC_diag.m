function val = trkBIC_eng(segvect, winoffset)

% function val = trkBIC_eng(segvectin, eng,  winoffsetin)
% takes a segmentation of cepstral matrix 'segvect' and compute BIC 
% according to the 'winoffset', i.e. segvect(1:winoffset, :) as model 
% I and segvect(winoffset:N, :) as model II vs the whole segvect as
% one model.
%
% This code is copyrighted 2003 by Yanliang Cheng.
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 



% get the numberof vector in time domain  N, 
% and the dimension of the cepstral space d
[N, d]  = size(segvect);

% compute the penalty factor  p
p = 0.5*(d+(0.5*d*(d+1)))*log(N);

% set the penalty weight w
w = 1.2;

% compute the most likelihood R
% with main diagonal only of coviances
% The first time calling function 'diag'
% is to pick diagonals and the second time
% to create squre matrix with all other elements(other than
% the diagonal in the square) set to zero, so they do not 
% contribute to the determination
R =  N*log(det(diag(diag(cov(segvect)))))...
    -winoffset*log(det(diag(diag(cov(segvect(1:winoffset,:))))))...
    -(N-winoffset)*log(det(diag(diag(cov(segvect(winoffset+1:N, :))))));

% compute BIC value
val = R - w*p;


