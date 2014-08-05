function Prior = trkEstimatePriors(Corpus, FeatureIds, varargin)
% Prior = trkEstimatePriors(Corpus, FeatureIds, OptionalArgs)
%
% Determine point estimates for a normal-gamma prior distribution
% using the methods of moments on unrelated data.  Both the mean and
% the mode point estimates are returned.  
%
% FeatureIds should contain a cell array of feature ids which are either
% feature filenames relative to the feature resource of the corpus (see
% corBase) or can be mapped to filenames through the use of the optional
% FilenameFormat argument which is described below.
%
% Optional arguments:
%       'FilenameFormat', String - If the FeatureIds list contains only key
%		values, a format string can be passed in to add extraneous
%		information.  As an example, all files in the Spidre corpus
%		contain "swXXXX" where XXXX is the conversation id (the key
%		value) and sw is superfluous.  A FilenameFormat of 'sw_%s.cep' 
%		can be used to convert a FileList of key values to the 
%		appropriate file names.
%       'Channels', ChannelList - Assume that feature data for separated
%              channels is available and that each channel should be
%              processed separately.  When this option is used, a %c
%              format specifier should be used in the FilenameFormat
%              argument, e.g. 'sw_%s%c.cep'.  ChannelList is an
%              list of channels (e.g [0:1] for stereo data) and it is
%              assumed that channel 0 is stored with the character 'a',
%              channel 1 with 'b', etc.  
%       'Dropout', 'ignore'|'segment'|'remove'
%               Handles segments where there is no acoustic energy.  This
%               can occur due to signal enhancement algorithms such as
%               acoustic echo cancellation which is commonly used in
%               telephone speech.  Vectors with the same energy as the 
%               lowest energy frame are processed:
%               'ignore' - No processing is done (default)
%               'segment' - Features on either side of the vector(s) are
%                       treated as separate utterances.
%               'remove' - Vector(s) are simply removed from the data.
%       'Remove', DropPct - This argument permits the user to request 
%               that a percentage [0,1] of low energy frames be dropped.  
%               Note that energy must be stored in the feature set.
%               CURRENTLY NOT FUNCTIONING 
%       'Segment', N 
%               N - Segment into N ms segments.  Default is Inf, or no
%               segmentation.  Segmentation is done after dropout 
%               processing.
%       'Verbose', N
%               If N > 0, print the name of each file as it is processed.
%
%               NOTE: To permit the energy vector to be retained and
%               without dropping any frames, specify 'Energy', 0.
%        'Visualize', String
%               Create plots showing how the hyperparameters fit
%               the data.  String is used to name the figure window
%               that is created.
%        'Multivariate', N
%              If N = 1 then Multivariate case is on
%              Else N = 0(default) and Multivariate case is off
% 
% This code is copyrighted 2003-2005 by 
%       Marie Roch, Yanliang Cheng & Sonia Arteaga.
%       e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 
%

% $Header: /zal/mroch/lib/CVSRepository/audio/tracking/helper/trkEstimatePriors.m,v 1.8 2005/09/17 00:30:32 mroch Exp $
% Last modified by:  $Author: mroch $

% defaults
FormatString = '%s';
SelectedChannels = 0;
Channels = 0;
Visualize = 0;
Verbose=0;
% Flag for Multivariate case
MultiV = 0;
UtteranceArgs = {};
n=1;
while n < length(varargin)
  switch varargin{n}
   case 'Channels'
    SelectedChannels = 1;
    Channels = varargin{n+1}; n=n+2;
   case 'Dropout'
    % Save for later use
    UtteranceArgs = {UtteranceArgs{:}, varargin{n:n+1}}; n=n+2;
   case 'FilenameFormat'   
    FormatString = varargin{n+1}; n=n+2;
   case 'Remove'
    % Save for later use
    UtteranceArgs = {UtteranceArgs{:}, varargin{n:n+1}}; n=n+2;
   case 'Segment',
    % Save for later use
    UtteranceArgs = {UtteranceArgs{:}, varargin{n:n+1}}; n=n+2;
   case 'Verbose'
    Verbose = varargin{n+1}; n=n+2;
   case 'Visualize'
    Visualize = 1;
    VisString = varargin{n+1}; n=n+2;
    if strcmp(VisString, '')
      VisString = 'Hyperparameter fits';
    end
   case 'Multivariate'
    MultiV = varargin{n+1}; n = n+2;
   otherwise
    error(sprintf('Unsupported option %s', varargin{n}));
  end
end

% Distributions 
%
% NOTE: For convenience, we use precision rather than variance, thus n(M,R)
% denotes a normal distribution with mean M and variance 1/R.
%
% As per M. H. DeGroot, _Optimal Statistical Decisions_, 
%       New York, McGraw-Hill, 1970:
%
% if X ~ normal(M, R)      (iid, n observations)
% with a joint prior of M and R which satisfies:
%       R ~ gamma(alpha, beta)
%       M | R = r ~ n(mu, r * tau)
%
% then the joint posterior is
%
% M, R | X ~ n(mu', (tau + n)*r)
%       mu' = (tau * mu + n*E[x])/(tau + n)
% 
% and the marginal posterior of R is:
% 
% R | X ~ gamma(alpha + n/2, beta')
%        b' = beta + 1/2 sum_{i=1}^{n} (x_i - E[x])^2 +
%               (n * tau * (E[x] - mu)^2) / (2 * (tau + n)

% In this function, we estimate the parameters of the prior distributions:
%       R ~ gamma(alpha, beta)
%       M | R = r ~ n(mu, r * tau)
% using the method of moments.
%
% For details, see:
% M. Roch and Y. Cheng, "Speaker Segmentation Using the MAP-Adapted
% Bayesian Information Criterion," Proceedings of Odyssey 2004, Toledo,
% Spain, May 2004.

SpeakerCount = length(FeatureIds);
FirstTime = 1;
FeatureType = 'HTK';

Means = [];     % Accumulators - gathers statistics of individual
Variances = []; % tokens.
Ns = [];

% KLUDGE - Find smallest values
MinValues = Inf;
MinValues = MinValues(ones(1,12));
for i = 1:SpeakerCount
  for channel = 1:length(Channels)	% Handle each channel separately
    if SelectedChannels
      FeatureFile = ...
          sprintf(FormatString, FeatureIds{i}, 'a' + Channels(channel));
    else
      FeatureFile = sprintf(FormatString, FeatureIds{i});
    end

    PathToFile = corFind(Corpus, 'feature', FeatureFile);
    if isempty(PathToFile)
      error(sprintf('Could not find %s', FeatureFile));
    end
    
    if Verbose
      fprintf('Processing %s\n', FeatureFile);
    end
    
    switch FeatureType
     case 'HTK'         % hidden Markov model toolkit - Cambridge
      [FeatureData, Info] = spReadFeatureDataHTK(PathToFile);
      FeatureData = FeatureData';

      UtteranceArgs = {UtteranceArgs{:}, 'SampleRate', ...
                       1000 / Info.CepstralSpacingMS};
      if Info.O && Info.E
        % in this case, we're not sure what to use...
        error('Both MFCC0 and RMS Energy are prsent.');
      end

      if Info.O
        % energy present, should be last column
        UtteranceArgs = {UtteranceArgs{:}, 'Energy', FeatureData(:,end)};
        FeatureData(:,end) = [];    % remove the energy
      end

      
     case 'sands'       % San Diego speech system
      % Need to add stuff to determine how to process energy 
      % properly.  Not worth doing now, using HTK features
      error('sands feature type not currently supported');
      Feature = corReadFeatureSet(FeatureFile);
      FeatureData = Feature.Data{1};
      Info = Feature.Info;
    end
    
    [FeatureVectorsN, Components] = size(FeatureData);

     UtteranceMin = min(FeatureData);
     MinValues = min([MinValues; UtteranceMin]);
  end
end

% Compute moments for each conversation/subconversation
SegmentIdx = 0;
for i = 1:SpeakerCount
  for channel = 1:length(Channels)	% Handle each channel separately
    if SelectedChannels
      FeatureFile = ...
          sprintf(FormatString, FeatureIds{i}, 'a' + Channels(channel));
    else
      FeatureFile = sprintf(FormatString, FeatureIds{i});
    end

    PathToFile = corFind(Corpus, 'feature', FeatureFile);
    if isempty(PathToFile)
      error(sprintf('Could not find %s', FeatureFile));
    end
    
    if Verbose
      fprintf('Processing %s\n', FeatureFile);
    end
    
    switch FeatureType
     case 'HTK'         % hidden Markov model toolkit - Cambridge
      [FeatureData, Info] = spReadFeatureDataHTK(PathToFile);
      FeatureData = FeatureData';

      UtteranceArgs = {UtteranceArgs{:}, 'SampleRate', ...
                       1000 / Info.CepstralSpacingMS};
      if Info.O && Info.E
        % in this case, we're not sure what to use...
        error('Both MFCC0 and RMS Energy are prsent.');
      end

      if Info.O
        % energy present, should be last column
        UtteranceArgs = {UtteranceArgs{:}, 'Energy', FeatureData(:,end)};
        FeatureData(:,end) = [];    % remove the energy
      end

     case 'sands'       % San Diego speech system
      % Need to add stuff to determine how to process energy 
      % properly.  Not worth doing now, using HTK features
      error('sands feature type not currently supported');
      Feature = corReadFeatureSet(FeatureFile);
      FeatureData = Feature.Data{1};
      Info = Feature.Info;
    end
    
    [FeatureVectorsN, Components] = size(FeatureData);
    
    % Compute moments for this utterance
    [ChanMu, ChanVariances, ChanNs ] = ...
        trkMoments(FeatureData, UtteranceArgs{:});

    % Add to moments collected for other utterances 
    Means = [Means; ChanMu];
    Variances = [Variances; ChanVariances];
    Ns = [Ns; ChanNs];
  end
end

RHat = 1 ./ Variances;    % sample precisions
% RHat ~ Gamma(alpha, beta)
% mu(RHat) = alpha/beta, var(RHat) = alpha * beta^2

MeanRHat = mean(RHat);  % moments
VarRHat =  var(RHat);

% solution of moment equations
Prior.beta = VarRHat ./ MeanRHat;
Prior.alpha = VarRHat ./ (Prior.beta .^ 2);

Prior.mu = mean(Means);
% Prior distribution of M has noncentral t distribution of 2 alpha degrees
% of freedom, location parameter mu, and precision (different from precision
% as inverse of variance) alpha * tau / beta.  It can be shown:
%
% var(M) = beta / (tau * (alpha - 1)).
%
% Solving for tau:
Prior.tau = Prior.beta ./ ((Prior.alpha - 1) .* var(Means));

% Statistics about the number of samples used to construct the estimates
Prior.SampleCount_mu = mean(Ns);
Prior.SampleCount_var = var(Ns);

Visualize = 1;
if Visualize
  if MultiV == 0
    broken = 1; % coincident axes broken in R14SP2 on subplots
    if broken
      % Show fit of gamma distribution on each component
      for k = 1:length(Prior.alpha)
        figure('Name', sprintf('%s - c%d', VisString, k));
        visGammaFit(Prior.alpha(k), Prior.beta(k), RHat(:,k))
      end
    else
      % Show fit of gamma distribution on each component
      figure('Name', VisString);
      visGammaFit(Prior.alpha, Prior.beta, RHat)
    end
  else
    warning('Multivariate visualization not suppported')
  end
end
keyboard

function [Means, Variances, Ns] = trkMoments(Data, varargin)
% [Means, Precisions, Ns] = trkMoments(Data, OptionalArguments) Given data
% from a specific utterance, collect the moments.
%
% Data is multivariate data to analyze, each row is an observation.
%
% Optional arguments: 
%       'Energy', Vector - A vector of energy features.
%               Necessary if it is desired to drop low energy frames 
%               or segment based upon energy.
%       'SampleRate', N - Number of feature vectors per second.  If not
%               present, assumed to be 100.
%       'Verbose', N - Report progress if N ~= 0
%
%       The following arguments require that the Energy option be
%       present.  See parent function for interpretation of arguments.
%
%       'Dropout', DropoutType
%       'Segment', SegmentationType 
%       'Remove', DropPct 
%
%

SampleRate = 100;
TokenLength = Inf;
DropPct = 0;
Verbose = 0;
SegmentType = 'none';
Dropout = 'ignore';
Energy = [];

n=1;
while n < length(varargin)
  switch varargin{n}
   case 'Dropout'
    Dropout = varargin{n+1}; n=n+2;
   case 'Energy'
    Energy = varargin{n+1}; n=n+2;
   case 'SampleRate'
    SampleRate = varargin{n+1}; n=n+2;
   case 'Segment'
    if ischar(varargin{n+1})
      SegmentType = varargin{n+1};
    elseif isnumeric(varargin{n+1})
        TokenLength = varargin{n+1};
    else
      error('Argument to Segment must be a string or number');
    end
    n=n+2;
   case 'Remove'
    DropPct = varargin{n+1}; n=n+2;
   case 'Verbose'
    Verbose = varargin{n+1}; n=n+2;
   otherwise
    error(sprintf('Unsupported option %s', varargin{n}));
  end
end

% Energy required for any type of segmentation
if ~ isempty(Energy)
  switch Dropout
   case 'ignore'
    % One big segment
    Segments = [1, size(Data, 1)];
   case {'remove', 'segment'}
    % Find low energy frames
    % Find the indices of the low energy (floored) frames.
    FloorIndices = find(Energy == min(Energy));

    % Break them into groups so that we know where each one begins 
    % and how long it is.  When we take the first difference of the
    % low energy frames, a new group starts each time the first
    % difference is > 1 and of course at the first frame in the
    % list.
    % FloorIndices(StartIndexIntoFloors) and 
    % FloorIndices(EndIndexIntoFloors) index the start and end
    % of each of the low energy regions.
    Delta = diff(FloorIndices);
    % Areas where Delta > 1 indicate new region, + 1 since length
    % of sequence drops by 1.
    StartIndexIntoFloors = [1; find(Delta > 1) + 1];
    EndIndexIntoFloors = [StartIndexIntoFloors(2:end) - 1;
        length(FloorIndices)]; 
    StartLow = FloorIndices(StartIndexIntoFloors);
    EndLow = FloorIndices(EndIndexIntoFloors);
    
    CurrentIdx = 1;
    Segments = [];
    
    switch Dropout
     case 'remove'
      % Remove the offending regions
      for region=length(StartLow):-1:1
        Data(StartLow(region):EndLow(region), :) = [];
        Energy(StartLow(region):EndLow(region)) = [];
      end
      Segments = [1 size(Data, 1)];
      
     case 'segment'
      % Create set of segments around the dropout regions
      for region=1:length(StartLow)
        if CurrentIdx < StartLow(region)
          % CurrentIdx occurs before the start of the next minimum energy region.
          % Create a segment between CurrentIdx and the beginning of this
          % region.
          Segments = [Segments; [CurrentIdx, StartLow(region) - 1]];
          % Move to next region
          CurrentIdx = EndLow(region) + 1;
        elseif CurrentIdx <= EndLow(region)
        % CurrentIdx occurs in the current region.  
        % Move it past the minimum energy
        CurrentIdx = EndLow(region)+1;
        end
      end
      if CurrentIdx < length(Energy)
        % last minimum energy region was before end of utterance
        Segments = [Segments; [CurrentIdx, length(Energy)]];
      end

     otherwise
      error('Bad Dropout argument "%s"', Dropout);
    end
  end
else
  % One big segment to start
  Segments = [1, size(Data,1)];
end

if TokenLength < Inf
  SampleSize = spMS2Sample(TokenLength, SampleRate);
  
  NewSegments = [];
  RetainPartialSegments = 0;  % keep fragments < TokenLength?
  
  Start = 1;
  Stop = 2;
  SegmentLengths = Segments(:, Stop) - Segments(:, Start) + 1;
  
  if ~ RetainPartialSegments
    % Remove all segments < specified token length
    ShortIndices = find(SegmentLengths < SampleSize);
    Segments(ShortIndices, :) = [];
    SegmentLengths(ShortIndices) = [];
  end
  
  % Break up segments longer than specified token length
  NumberTokensPerSegment = floor(SegmentLengths / SampleSize);
  PartialTokenSamples = mod(SegmentLengths, SampleSize);
  for idx=1:size(Segments, 1)
    % break up segment into tokens
    Range = 0:NumberTokensPerSegment(idx)-1;
    NewSegments(end+1:end+NumberTokensPerSegment(idx), :) = ...
        Segments(idx, Start) + ...
        [Range*SampleSize
         (Range+1)*SampleSize - 1]';
    
    % keep/discard small piece of segment
    if RetainPartialSegments && PartialTokenSamples(idx)
      NewSegments(end+1,:) = ...
          NewSegments(end, Stop) + ...
          [1 PartialTokenSamples(idx)];
    end
  end
  
  Segments = NewSegments;
end

% At this point, we know how many segments we have, preallocate
SegmentCount = size(Segments, 1);
Dim = size(Data, 2);

Means = zeros(SegmentCount, Dim);
Variances = zeros(SegmentCount, Dim);
Ns = zeros(SegmentCount, 1);

% Analyze each segment
for idx=1:SegmentCount
  Segment = Data(Segments(idx,1):Segments(idx,2), :);
  Means(idx, :) = mean(Segment);
  Variances(idx, :) = var(Segment);
  Ns(idx) = size(Segment, 1);
end



