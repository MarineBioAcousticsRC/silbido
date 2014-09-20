function csa = trkCSA(Vectors, N, varargin)
% trkCSA(data, Samples, OptionalArgs)
% Cumulative Sum Approach
% Compute sums and squares of row vectors every N samples
%
% OptionalArgs:
% diagonal, N - If N ~= 0 , it is assumed that the user is only interested
%               in computing variances and the SQ data will contain vectors
%               which which represent the squared sum used in computing a
%               covariance matrix with independent components.

Diagonalize = 0;

k = 1;
while k < length(varargin)
  switch varargin{k}
   case 'diagonal'
    Diagonalize = varargin{k+1}; k = k+2;
   otherwise
    error('Unknown keyword %s', varargin{n});
  end
end

[VectorCount, Dim] = size(Vectors);

Counts = ceil(VectorCount/N);

% initialize sum and square of vectors
csa.SV = zeros(Counts, Dim);
csa.SQ = cell(Counts, 1);
csa.N = N;
csa.Dim = Dim;

% Compute the ranges over which we must gather statistics 
RangeColumns = [1:N];
RangeRows = [0:Counts-1]';
Ranges = RangeRows(:, ones(1, N)) * N + RangeColumns(ones(Counts, 1), :);
csa.Ranges = Ranges;    % for debugging

if mod(VectorCount, N)
  % Last range doesn't quite fit, compute it now
  LastRange = Ranges(end,1):VectorCount;
  [csa.SV(end,:) csa.SQ{end}] = CSA(Vectors(LastRange,:), Diagonalize);
  Counts = Counts - 1;
end

for idx=1:Counts
  [csa.SV(idx,:) csa.SQ{idx}] = CSA(Vectors(Ranges(idx,:), :), Diagonalize);
end
  
csa.Diagonalize = Diagonalize;

function [SV, SQ] = CSA(Vectors, Diagonalize)
% Compute cumulative sum approach statistics for Vectors

SV = sum(Vectors, 1);
if Diagonalize
  SQ = sum(Vectors .^ 2, 1);
else
  [N, Dim] = size(Vectors);
  SQ = zeros(Dim, Dim);
  for k = 1:N
    SQ = SQ + Vectors(k,:)' * Vectors(k,:);
  end
end