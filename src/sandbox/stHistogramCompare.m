function [nelements, centers] = stHistogramCompare(varargin)% counts = stHistogramCompare(A, B, C, ..., OptionalArgs)% Compute a histogram that shows side by side distributions% of different variables.  One or more variables should be provided.%% Optional arguments:%   Bins - Number of bins%% Sample usage:% % stHistrogramCompare(VecA, VecB)  % produce histrogram of 2 variables%% counts = stHistogramCompare(VecA, VecB) - Return historgram counts narginchk(1,Inf);Bins = []; % default% Process argumentsDistributions = 0;idx = 1;firstOptArg = false;while ~ firstOptArg && idx <= length(varargin)    firstOptArg = ischar(varargin{idx});    if ~ firstOptArg        Distributions = idx;        idx = idx + 1;    endend    while idx < length(varargin)    switch varargin{idx}        case 'Bins'            Bins = varargin{idx+1};        otherwise            error('Unknown argument');    end    idx = idx + 2;endif Distributions < 1    error('No distributions specified');endN = max(cellfun(@length, varargin(1:Distributions)));% Fill data matrix with not a numbersdata = zeros(N, Distributions)*NaN;for didx = 1:Distributions    data(1:length(varargin{didx}),didx) = varargin{didx}(:);endif nargout < 1    if isempty(Bins)        hist(data);    else        hist(data, Bins);    endelse    if isempty(Bins)        [nelements, centers] = hist(data);    else        [nelements, centers] = hist(data, bins);    endend