function [MaxBIC, Index, bic] = trkBIC_CSA(CSA, Search, PenaltyWeight, Prior)
% [MaxBIC, Index, BIC_Curve] = trkBIC_CSA(CSA, Window, PenaltyWeight, Prior)
% Compute BIC using Cettolo et al.'s cumulative sum approach

        function ll = LogLikelihoodFn(Sigma)
        % Compute log likelihood assuming 0 Mahalanobis distance
          if CSA.Diagonalize
            Det = prod(Sigma);
          else
            Det = det(Sigma);
            if Det < 0
              % If the condition number is large, assume accuracy problems
              % and set determinant to not a number.
              if cond(Sigma) > 1e4
                % Not sure Det =1 is appropriate but testing for now
                Det = 1;
%                 fprintf('* \n');
              else
                warning('Covariance matrix not positive definite.');
              end
            end
          end
          ll = .5 * log(Det);
        end
        
        % ------------------------------------------------------
        function [SV SQ] = Sums(Start, Stop)
        % [SV SQ] = Sums(Start, Stop)
        % Determine sum of vectors and sum of squares over 
        % indicated range.
          SV = zeros(size(CSA.SV(Start,:)));
          SQ = zeros(size(CSA.SQ{Start}));
          for index=Start:Stop
            SV = SV + CSA.SV(index,:);
            SQ = SQ + CSA.SQ{index};
          end
        end
        
        % ------------------------------------------------------
        function [Mu, Sigma] = Moments(SV, SQ, N)
        % Cov = Covariance(SV, SQ, WindowSize)
        % Given sum vectors and square matrices, determine
        % the covariance matrix.
           if Adapt
            SampleMu = SV / N;
            if CSA.Diagonalize
              % Compute sample moments
              SampleSigma = SQ/N - SampleMu .^ 2;
              SumSquaredDeviations = N*SampleSigma;
              % Compute parameters of posterior beta distribution replace
              % with * the +
              Alpha = Prior.alpha .* (N / 2);
              Beta = Prior.beta + .5 * SumSquaredDeviations + ...
                     Prior.tau * N .* (SampleMu - Prior.mu) .^ 2 / ...
                     (2 * (Prior.tau + N));
              % Adapt the variance
              switch Prior.Statistic
               case 'mode'
                Precision = (Alpha - 1) ./ Beta;
               case 'mean'
                Precision = Alpha ./ Beta;
              end
              Sigma = 1 ./ Precision;
              
              % Note that we do not adapt the mean as it is not used.
              %To make code happy
              Mu=Prior.mu;
            else
              error('Adaptation not supported for full covariance')
            end

          else
            Mu = SV / N;
            if CSA.Diagonalize
              Sigma = SQ/N - Mu .^ 2;
            else
              Sigma = SQ/N - Mu' * Mu;
            end
%             We now have the biased variance.
%             For unbiased variance, uncomment the following line
            Sigma = (N/(N-1))*Sigma;
          end
        end
        
        
Adapt = (nargin == 4);  % Use Bayesian adaptation?

% Determine Sums for entire region
Nall = trkWindowSize(Search.Window)*CSA.N;
[SVall, SQall] = Sums(Search.Window(1), Search.Window(2));
[Mu, Sigma] = Moments(SVall, SQall, Nall);
FullLogLikelihood = Nall * LogLikelihoodFn(Sigma);

% $$$ % debugging junk
% $$$ global data
% $$$ global tbic
% $$$ global SearchI
% $$$ SearchDataIdx = trkCSAToIndices(CSA, Search);
% $$$ [bic2, one, two] = trkBIC_d(data([SearchDataIdx.Window(1):SearchDataIdx.Window(2)], :), ...
% $$$                             SearchDataIdx.Range, PenaltyWeight);
% $$$ [maxbic2, maxidx2] = max(bic2);

bic = zeros(length(Search.Range), 1);   % preallocate
Count = 0;
for idx=Search.Range
  % left sums.
  [SVleft, SQleft] = Sums(Search.Window(1), idx);

  % Number of points in each region.  
  Nleft = (idx - Search.Window(1) + 1)*CSA.N;
  Nright = (Search.Window(2) - idx)*CSA.N;
  % Right side is sum over entire region - left sums
  SVright = SVall - SVleft;
  SQright = SQall - SQleft;
  % Having some strange problems, just recompute it
  % [SVright, SQright] = Sums(idx+1, Search.Window(2));

  [MuLeft, SigmaLeft] = Moments(SVleft, SQleft, Nleft);
  [MuRight, SigmaRight] = Moments(SVright, SQright, Nright);
  
  Count = Count + 1;
  bic(Count) = - Nleft * LogLikelihoodFn(SigmaLeft) ...
      - Nright * LogLikelihoodFn(SigmaRight);
end

bic = bic + FullLogLikelihood;

% compute the penalty factor
  % The number of parameters is dependent upon the number of means
  % and the number of covariance parameters.  
if CSA.Diagonalize
  % Diagonal covariance matrix, only Dim covariance parameters.
  %
  % 1 speaker: Dim + Dim    only one distribution
  % 2 speaker:  2 [ Dim + Dim ]      two distributions
  %
  % Difference is 2 Dim.  .5 * 2 Dim = Dim
  Penalty = CSA.Dim * log(Nall);
else
  % Full covariance matrix. 
  % As symmetric, there are only 1 + 2 + 3 + ... + Dim
  % covariance parameters.
  %
  % 1 + 2 + 3 + ... + Dim = Dim * (1 + Dim) / 2
  %
  % 1 speaker:  Dim + .5*Dim*(1+Dim)    only one distribution
  % 2 speaker:  2 [ Dim + .5*Dim*(1+Dim) ]      two distributions
  Penalty = 0.5*(CSA.Dim+(0.5*CSA.Dim*(CSA.Dim+1)))*log(Nall);
end

bic = bic - PenaltyWeight * Penalty;

[MaxBIC, Index] = max(bic);
Index = Search.Range(Index);
end
