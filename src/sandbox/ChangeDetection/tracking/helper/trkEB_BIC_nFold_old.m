function bic = trkEB_BIC_rmloweng(segin,  winoffsetin,  alpha, beta, mu, tau)
%  function bic = trkEB_BIC_rmloweng(segin, engin, winoffsetin, alpha, beta, mu, tau)
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

[N, d]  = size(segin);

% remove indices with low energy
engin = segin(:,1);  % store the energy in separate vector
segin(:,1) = [];   % remove the energy column

[dumbdata, indices] = sort(engin);
rmind = floor(N/10);
highengindices = indices(rmind:end);

% Find indices for high energy
leftindices = highengindices(find(highengindices<=winoffsetin));
rightindices = highengindices(find(highengindices>winoffsetin));

% left and right segments after removing low energy vectors
left = segin(leftindices, :);
right = segin(rightindices, :);
% seg = [left', right']';   % be careful of transpose
seg = [left; right];

% find the right and left segment size
leftsize = length(leftindices);
rightsize = length(rightindices);

% N = size(seg, 1);	% # of row
% d = size(seg, 2);	% dimension of matrix space, i.e. components
PenaltyWeight = 1.2;

R1 = zeros(d);
R2 = zeros(d);
R3 = zeros(d);

 
% seg is 90% of segin now:
N_all = rmind;          % N;
mu_all = mean(seg);
var_all = var(seg);
sumdevsq_all = (N_all - 1) * var_all;

% Left segment
%left = 1:chg;
%N_left = chg;
%mu_left = mean(seg(left,:));
%var_left = var(seg(left,:));
%sumdevsq_left = (N_left - 1) * var_left;

%left = 1:chg;
N_left = leftsize;
mu_left = mean(left);
var_left = var(left);
sumdevsq_left = (N_left - 1) * var_left;


% right segment
%right = chg+1:N;
%N_right = (N - chg);
%mu_right = mean(seg(right,:));
%var_right = var(seg(right,:));
%sumdevsq_right = (N_right - 1) * var_right;

%right = chg+1:N;
N_right = rightsize;            %(N - chg);
mu_right = mean(right);
var_right = var(right);
sumdevsq_right = (N_right - 1) * var_right;


%
beta_all = beta + .5 * sumdevsq_all + ...
    .5 * tau * N_all .* (mu_all - mu).^2 ./ (tau + N_all);

beta_left = beta + .5 * sumdevsq_left + ...
    .5 * tau * N_left .* (mu_left - mu).^2 ./ (tau + N_left);

beta_right = beta + .5 * sumdevsq_right + ...
    .5 * tau * N_right .* (mu_right - mu).^2 ./ (tau + N_right);

alpha_all = alpha + 0.5 * N_all;
alpha_left = alpha + 0.5 * N_left;
alpha_right = alpha + 0.5 * N_right;
        
% $$$ R_all = diag(alpha_all ./ beta_all);
% $$$ R_left = diag(alpha_left ./ beta_left);
% $$$ R_right = diag(alpha_right ./ beta_right);

R_all = diag(beta_all ./ alpha_all );
R_left = diag(beta_left ./ alpha_left);
R_right = diag(beta_right ./ alpha_right);

R = N_all*log(det(R_all))-N_left*log(det(R_left))-N_right*log(det(R_right)); 
Penalty = .5*(d+0.5*d*(d+1))*log(N_all);
bic = R- PenaltyWeight * Penalty;

% Marie's debug code
%if ~ isreal(bic)
%    xyzzzy = 1;
%end
