function NormData = normalize(Data)
% Given a multivariate matrix with data in columns,
% normalizes each column to the range [-1,1] to ease in comparisons.

NormData = Data ./ repmat(max(abs(Data)), [size(Data, 1), 1]);
