function bic = trkEB_BIC_nFold(segin,  winoffsetin, PenaltyWeight, Prior, ...
			       Method, EnergPct)
%  function bic = trkEB_BIC_rmloweng(segin, engin, winoffsetin, Prior)
%  is developed based on function "trkEB_BIC(...)" which is the 
% implementation of Bayesian Information Criterion(BIC),
% one  of the parametric methods in change point detection.
% The parameter "winoffsetin"is the row number which devide the Matrix into two 
% submatice, say, Up= [1:winoffsetin, :] and Down= [winoffsetin+1:size, :]
% Caution: Compare with function "trkEB_BIC(...)" this function may have 
% up and down size changed after eliminating 10 per cent low 
% energy frames from 'segin' as whole.

% According to BIC algorithm we compute the determinants of 
% covariance of Matrix, Up and Down, prepresenting them as
% DETm, DETup, DETd respectively. Let N, Nup, Nd represent 
% size of Matrix, Up and Down. Then the maxium likelihood ratio
%   R(Chg) = N* log(DETm)- Nup* log(DETup) - Nd*log(DETd)
% let d reprent the dimension of the space of Matrix, then
% the penalty is computed P=.5*(d+.5*d(d+1))* logN
% and BIC(Chg) = R(Chg) -w*P
% where w is the penalty weight, we choose w = 1.2 for now.

% Input:    Matrix data, frame energy, divide point for each window
%           alph, beta, mu and tao as priors for sphere files
% Ouput:    Empirical BIC value

% Assume that each observation ~ N(M, R)
% Then, assuming components are independent,
% R ~ gamma(alpha, beta)
% M|R ~ N(mu, tau * r)

% We have estimated our prior alpha, beta, mu, & tau  previously.

% We wish to account for new observed information and update our
% estimate of the priors.  Then, we will take R to be the mean
% of the updated distribution.

% mean(R) = alpha'/beta'
% alpha' = alpha + n/2
% beta' = beta + 1/2 sum_of_the_deviates^2 +
%		tau * n * sum_of_the_deviates^2 / (2 (tau + n))
% 
% We assume that each distribution (all, left, right)
% has a R ~ gamma(alpha, beta)

% We want to estimate a new posterior given the data. 
% We must estimate alpha', beta':

% Number of feature vectors x number of dimensions
[N, d]  = size(segin);

% remove indices with low energy
engin = segin(:,1);  % store the energy in separate vector
segin(:,1) = [];   % remove the energy column

[dumbdata, indices] = sort(engin);
rmind = floor(N*EnergPct);   %floor(N/10);
highengindices = indices(rmind:end);

% Find indices for high energy
leftindices = highengindices(find(highengindices<=winoffsetin));
rightindices = highengindices(find(highengindices>winoffsetin));

% left and right segments after removing low energy vectors
left = segin(leftindices, :);
right = segin(rightindices, :);
% seg = [left', right']';   % be careful of transpose
seg = [left; right];
N_left = size(left, 1);
N_right = size(right, 1);
N_all = size(seg, 1);

% Use Bayesian adaptation to determine the varainces for these segments.
R_all = Adapt(seg, Prior, Method);
R_left = Adapt(left, Prior, Method);
R_right = Adapt(right, Prior, Method);

R = N_all*log(det(R_all))-N_left*log(det(R_left))-N_right*log(det(R_right)); 
% In standard BIC, we count the d(d+1)/2 variance/covariance
% parameters.  In eBIC with independence assumption, there are
% only d variance/covariance parameters.
% .5 * (d + d) * log(# items)
Penalty = d*log(N_all);

bic = R- PenaltyWeight * Penalty;

% Marie's debug code
%if ~ isreal(bic)
%    xyzzzy = 1;
%end

% Adapt 
function Variance = Adapt(Data, Prior, Method)

N = size(Data, 1);
EstMean = mean(Data);
EstVar = var(Data);
SumSquaredDeviations = (N - 1) * EstVar;

% Determine the parameters of the posterior gamma distribution
Alpha = Prior.alpha + N / 2;
Beta = Prior.beta + .5 * SumSquaredDeviations + ...
       Prior.tau .* N .* (EstMean - Prior.mu) .^ 2 / ...
          (2 * (Prior.tau + N));


switch Method
 case 'mode'
  Precision = (Alpha - 1) ./ Beta;

 case 'mean'
  Precision = Alpha ./ Beta;
  
 otherwise
  error('Bad estimator method');
end

Variance = diag(1 ./ Precision);

  
