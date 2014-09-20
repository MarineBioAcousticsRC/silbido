function LLR = trkLLR(Features, Index, EnergyPct)
% function LLR = trkLLR(Features, Index, EnergyPct)
% Given a set of row-oriented feature vectors, hypothesize the log
% likelihood ratio between competing hypotheses of one and two speaker
% models.  Each speaker is modeled as a Gaussian.
%
% The first column of features is assumed to contain the energy of the
% feature vector.  It is not used in computing the likelihood ratio, but 
% is used to remove the N lowest energy frames (N is determined by
% the percentage EnergyPct [0,1] of the feature vectors).
%
%
% This code is copyrighted 2003-2004 by Marie Roch and Yanliang Cheng.
% e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 


% get the numberof vector in time domain  N, 
% and the dimension of the cepstral space d
[N, d]  = size(Features);


% Examine energy and determine which indices should be retained.
[dumbdata, indices] = sort(Features(:,1));
rmind = floor(N * EnergyPct);
highengindices = indices(rmind:end);

% Find indices to left & right of the split point.
leftindices = highengindices(find(highengindices <= Index));
rightindices = highengindices(find(highengindices > Index));

% left, right, and all vectors excluding energy field and low energy
% vectors. 
left = Features(leftindices, 2:end);
right = Features(rightindices, 2:end);
all = [left; right];

% find the right and left segment size
leftsize = length(leftindices);
rightsize = length(rightindices);

leftSpeaker = trkBuildGaussianModel(left);
rightSpeaker = trkBuildGaussianModel(right);
singleSpeaker = trkBuildGaussianModel(all);

% Compute likelihoods
leftLogScore = 0;
for t=1:leftsize
  leftLogScore = leftLogScore + ...
      trkGaussianLL(leftSpeaker, left(t,:));
end

rightLogScore = 0;
for t=1:rightsize
  rightLogScore = rightLogScore + ...
      trkGaussianLL(rightSpeaker, right(t,:));
end

singleLogScore = 0;
for t=1:(leftsize+rightsize)
  singleLogScore = singleLogScore + ...
      trkGaussianLL(singleSpeaker, all(t,:));
end

LLR = singleLogScore - leftLogScore - rightLogScore;

% ------------------------------------------------------------
function Model = trkBuildGaussianModel(Features)
% Model = trkBuildGaussianModel(Features)
% Construct a maximum likelihood Gaussian model of data.

[N, Dim] = size(Features);

% Sample statistics are maximum likelihood estimators
Model.mu = mean(Features);
Model.Sigma = cov(Features);
Model.SigmaDet = det(Model.Sigma);
Model.k = (2 * pi) ^ (-1/Dim) / sqrt(Model.SigmaDet);
Model.logk = log(Model.k);
Model.SigmaInv = inv(Model.Sigma);

% ------------------------------------------------------------
function LL = trkGaussianLL(Model, Feature)
% LL = trkGaussianLL(Model, Feature)
% Given a Gaussian model and a row feature vector,
% compute the log likelihood of the feature vector.

MeanOffset = Model.mu - Feature;
LL = Model.logk -.5 * MeanOffset * Model.SigmaInv * MeanOffset';
