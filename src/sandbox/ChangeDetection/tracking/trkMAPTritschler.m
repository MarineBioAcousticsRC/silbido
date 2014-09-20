function trkMAPTritschler(SourceData, varargin)
% trkTritschler(SourceData, OptionalArguments)
% Evaluate the BIC using the algorithm of Tritschler and Gopinath
% (Eurospeech 1999)
%
% Optional arguments
% 	'Window', {AdvanceMS, LengthMS}
%		Set the windowing for the BIC
%		Expects a cell array containing the window
%		advance and length in milliseconds.
%		Default:  {100, 2000}
%	'EnergyPct', N
%		Delete the lowest N*100% energy frames (default .0)
%	'FilterType', 'median'|'lowpass'
%	'Keyboard', N
%		If N positive, pause after processing each utterance in
%		debug mode.
%	'Method', String
%		How should the BIC be computed?
%		'bic' (default) - Traditional Chen & Gopalakrishnan
%		'eBic' - empirical Bayes BIC
%		'llr' - log likelihood ratio
%	'Bayesian', String
%		What point estimate of the posterior distribution
%		should be used?  Valid:  'mean' (default), 'mode'
%	'N-Fold', N
%		Number of folds, only useful for estimating
%		prior data.  Default is 1 (no folding).
%	'PeakDetector', {Options}
%		Cell array of options for peak detection.
%               See spPeakDetector for valid options.
%               Default:  {'Method', 'simple'}
%	'Prior', Structure - Empirical Bayes methods only
%		If the prior data has been previously estimated
%		we may pass it in to avoid recomputing.  
%	'PriorData', CellList - Empirical Bayes methods only
%		List of utterrances to use to estimate the prior.
%		No-op when 'Prior' is specified
%	'Display', N
%		If non-zero, plot a display of the change points
%	'PenaltyWeight, Lambda
%		PenaltyWeight - BIC penalty weight.  Defaults to 1.2
%	'EndPoint', N
%		1 = Raj/Singh endpointing, 0 = no endpointing
%       'SegmentPriors'
%		length of segment in computing priors
%		for example. 2000 mean 2000ms, segment prior speech 
%		into 2 sec segments in computing priors instead of 
%		~290 sec as one segment
%
% This code is copyrighted 2003-2004 by Marie Roch and Yanliang Cheng.
% e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 


% Set up the defaults

Prior = [];
WindowAdvanceMS = 100;
WindowLengthMS = 1000;  % default initial window size 1 s
Method = 'bic';
NFold = 1;
EnergyPct = 0;
FilterType = 'lowpass';
Display = 0;
Keyboard = 0;	% Pause in debug mode?
Bayesian = 'mean';
EndPoint = 0;
PenaltyWeight = 1.2;
%PeakDetectorArgs = {'Method', 'simple'};
PeakDetectorArgs = {'Method', 'regression'};
%seg length in computation of priors
SegmentLength = -1;

%FeatureString = 'sw%s_38.cep';
FeatureString = 'sw%s.mfc';
ChangePointToleranceSecs = .2;


n = 1;
while n <= length(varargin)

  switch varargin{n}
   case 'Window'
    [WindowAdvanceMS, WindowLengthMS] = deal(varargin{n+ 1}{:});
    n=n+2;
    
   case 'Bayesian'
    Bayesian = varargin{n+1}; n=n+2;
    
   case 'Display',
    Display = varargin{n+1}; n=n+2;
    
   case 'EnergyPct'
    EnergyPct = varargin{n+1}; n=n+2;
    
   case 'FilterType'
    FilterType = varargin{n+1}; n=n+2;
    
   case 'Keyboard'
    Keyboard = varargin{n+1}; n=n+2;

   case 'Method'
    Method = varargin{n+1}; n=n+2;
    
   case 'N-Fold'
    NFold = varargin{n+1}; n=n+2;
    
   case 'PeakSelection'
    if iscell(varargin{n+1})
      PeakDetectorArgs = varargin{n+1};
    else
      error('PeakSelection argument must be a cell array.')
    end
    n=n+2;
    
   case 'PenaltyWeight',
    PenaltyWeight = varargin{n+1}; n=n+2;
    
   case 'Prior'
    Prior = varargin{n+1}; n=n+2;

   case 'PriorData'
    PriorData = varargin{n+1}; n=n+2;

   case 'EndPoint'
       EndPoint = varargin{n+1}; n=n+2;

   case 'SegmentPriors'
       SegmentLength = varargin{n+1}; n=n+2;
    
   otherwise
    error(sprintf('Bad optional argument: "%s"', varargin{n}));
  end
end

    
switch Method
 case 'llr'
  fprintf('log likelihood ratio\n');
  MethodName = 'LLR'
 case 'bic'
  fprintf('Baseline BIC\n');
  MethodName = 'BIC';
 case 'eBic'
  MethodName = 'EB-BIC';
  fprintf('Empirical Bayes BIC\n');
 otherwise
  error(sprintf('Bad Method argument:  %s', Method));
end


% combined channels
runenv = 'fruitbat';
fprintf('Executing on %s\n', runenv);
noEnd = abs(EndPoint -1); %0;

% hardcoded paths for now --------------------
% feature data
FeaturePath = '/lab/speech/corpora/spidre/cep/';
%FeaturePath = '/zal/mroch/cheng/MelBandNoEnd/';
% prior data
PriorPath = '/lab/speech/corpora/swb2/cep/';
% data base truth tables
TruthPath = '/lab/speech/corpora/spidre/changepoint/';


%output to file
if noEnd
  EndpointString = 'ne';
else
  EndpointString = '';
end

if 0
  if SegmentLength == -1
    outPath = '/zal/cheng/matlab/audio/tracking/results24/';
  else
    % outPath = '/zal/cheng/matlab/audio/tracking/automation/results24/6/';
  end  
  outFile = sprintf('%s%s_L%.2f_A%.2f_E%.2f_%s_%s.txt', ...
		    outPath, MethodName, ...
		    WindowLengthMS/1000, WindowAdvanceMS/1000, EnergyPct, ...
		    Bayesian, EndpointString)
  
  out = fopen(outFile,'w');
else
  out = 1;	% stdout
end


TotalHits = 0;
TotalMisses = 0;
TotalChangePoints = 0;
TotalFalsePositives = 0;

UtteranceCount = length(SourceData);

SampleRate = 1000 / WindowAdvanceMS;
WindowAdvanceSec = WindowAdvanceMS / 1000;

% build a low-pass filter for the BIC
EdgeFreqs = [3.25,  3.5];
MagnitudeResponse = [1 0];
PassBandRippledB = 1;
StopBandAttenuationdB = 18;
DeviationPB = ...
    (10^(PassBandRippledB/20)-1)/(10^(PassBandRippledB/20)+1);
DeviationSB = 10^(-StopBandAttenuationdB/ 20);
% Estimate the design parameters
DesignParameters = firpmord(EdgeFreqs, MagnitudeResponse, ...
			    [DeviationPB DeviationSB], ...
			    SampleRate, 'cell');
BPFilter = firpm(DesignParameters{:});

% Different types of tests    
% CH - speaker change
% OV - speaker overlap
% PA - speaker pausen
TestTypes = {'CH', 'OV', 'PA'};
TestLabels = {'change', 'overlap', 'pause', 'all'};
TestTypeCount = length(TestTypes);

% data structures for tracking performance

% More than one change point can occur within a regions
% which is known to mark an acoustic change point.  This data 
% structure is a histogram of how often this occurs
DuplicateCountRanges = [1:25,500];
DuplicateCounts = zeros(length(TestTypes), length(DuplicateCountRanges));

% Number of correct detections for each event type
Results.Correct = zeros(UtteranceCount, TestTypeCount+1);
% Number of duplicate detections for each event type
Results.CorrectAll = zeros(UtteranceCount, TestTypeCount+1);
% Total number of events detected regardless of whether or
% not they were correct.  (i.e. # peaks detected)
Results.Detected = zeros(UtteranceCount, 1);
% Number of known events of each test type
% i.e. Number of known change points based upon transcription .
Results.Actual = zeros(UtteranceCount, TestTypeCount+1);
% Number of incorrect predictions.  Not based on any
% type as we do not classify the types.
Results.FalsePositives = zeros(UtteranceCount, 1);

Current = 0;

fprintf(out, 'Test date: %s \n',datestr(date,1));
fprintf(out, 'Window length %d MS, advance %d MS\n', ...
	WindowLengthMS, WindowAdvanceMS);
fprintf(out, 'Peak Detector:  ');
PeakDetectorArgs        % kludge, dump args, perhaps write cell2str later...

fprintf(out, 'Utterance-Error Rate\t\tFalse Positive Rate\n');

% Do we need to compute the hyperparameters of the prior distribution?
if strcmp(Method, 'eBic') && isempty(Prior)
  Prior = trkEstimatePriors(PriorPath, ... 
                            PriorData, EnergyPct);                        
end


for foldindx = 1:NFold
  % TrainIndices not used
  [TrainIndices, TestIndices] = trkNfold(foldindx, NFold, UtteranceCount); 
  
  % Process test utterances in current fold
  for idx = TestIndices  
    % Reset vectors for this utterance
    bic = [];
    Current = Current + 1;

    FileName = sprintf(FeatureString, SourceData{idx});

    % Read the file, but do not delete the frame energy.
    % We do not use frame energy for categorization, but we do
    % may optionally drop low energy frames
    FeatureFormat = 'htk';
    switch FeatureFormat
     case 'htk'
      [data, info] = spReadFeatureDataHTK(sprintf('%s%s', FeaturePath, ...
                                          FileName));
      if info.O
        % MFCC 0 included, move position
        data = [data(end,:); data(1:end-1, :)];
        data = data';   % Each column is a feature
      end
      cepSpcMS = info.CepstralSpacingMS;
      
     case 'matlab'
      melcep = corReadFeatureSet(sprintf('%s%s', FeaturePath, FileName));
      data = melcep.Data{1};
      % spacing between feature vectors in MS
      cepSpcMS = melcep.Attribute.CepstralSpacingMS;
     otherwise
      error(sprintf('Bad feature format %s', FeatureFormat))
    end
    
    % Count of cepstra and spacing between feature vectors
    cepLen  = size(data,1);
    
    % Determine analysis window length and advance
    InitialWindowSize = floor(WindowLengthMS/ cepSpcMS);   
    win = InitialWindowSize;
    % Smallest amount by which the window should grow.
    MinDelta = floor(WindowAdvanceMS / cepSpcMS);

    % portion of left and right windows which should be skipped
    % due to small size
    PadFrames = floor(.20 * InitialWindowSize);
    WindowIncreaseMinMS = 100;
    WindowIncreaseMinFrames = floor(WindowIncreaseMinMS / cepSpcMS);
    WindowIncreaseMaxMS = 400;
    WindowIncreaseMaxFrames = floor(WindowIncreaseMaxMS / cepSpcMS);

    % determine the interval which the initial window will cover
    head = 1; 
    tail = head + win;
    PeakList = [];
    
    % calculate BIC
    Verbose = 0;
    while tail <= cepLen      
      ChangeFound = 0;
      % How much to increase by if no changepoint found
      WindowIncreaseFrames = WindowIncreaseMinFrames;
      while ~ ChangeFound & tail <= cepLen
        SearchRange = DetermineRange(head, tail, PadFrames, cepSpcMS);
        if Verbose
          fprintf('searching (%d:%d) in (%d:%d)\n',...
                  head+SearchRange(1)-1, head+SearchRange(end)-1, head, ...
                  tail);
        end
        % Search left/right
        bic = zeros(length(SearchRange), 1);
        segment = data(head:tail, :);
        for hypoth_idx = SearchRange
          bic(hypoth_idx) = trkEB_BIC(segment, hypoth_idx, ...
                                      PenaltyWeight, Prior, Bayesian);
        end
        
        % low pas filter
        %fBic = filter(BPFilter, 1, bic);
        %Order = length(BPFilter);
        % Account for delay
        %Shift = round(Order/2);
        %fBic = [fBic(Shift:end); zeros(Shift-1, 1)];
        
        % Select best changepoint if any.
        Peaks = spPeakSelector(bic, PeakDetectorArgs{:});
        if ~ isempty(Peaks)
          % Found something, pick best one
          [BestPeakValue, BestPeakIndex] = max(bic(Peaks));
          % Best peak must be positive to be a change point
          if BestPeakValue > 0
            ChangeFound = 1;   % found one
            BestPeak = Peaks(BestPeakIndex);
          end
        end
          
        if ~ ChangeFound
          % no changepoints, expand search
          tail = tail + WindowIncreaseFrames;
          SearchRange = DetermineRange(head, tail, PadFrames, cepSpcMS);
          
          if tail > cepLen
            Done = 1;           % !no mas!
          end
          
          % Next time we miss, we'll grow by twice as much
          % up to a limit.
          WindowIncreaseFrames = 2 * WindowIncreaseFrames;
          if WindowIncreaseFrames > WindowIncreaseMaxFrames
            WindowIncreaseFrames = WindowIncreaseMaxFrames;
          end
        end
      end

      if ChangeFound
        PeakList = [PeakList; head + BestPeak - 1];

        % Reset for new search
        head = PeakList(end) + 1;
        tail = head + win;
        WindowIncreaseFrames = WindowIncreaseMinFrames;
        ChangeFound = 0;
      end
    end
    
    % Build time axis
    time = (1:cepLen) * cepSpcMS / 1000;
    % Note source times associated with peaks
    if PeakList
      chgpt = time(PeakList);
    else
      chgpt = [];
    end
        
    % Record how many peaks we detected.
    Results.Detected(Current) = length(chgpt);
    
    % Read in known times and compare to predictions
    mrkTimeFile = sprintf('%ssw%s.csv', ...
			  TruthPath, SourceData{idx});
    [Type, Front, Back, FrontSpeaker, BackSpeaker, ...
     FrontText, BackText ] =...
	textread(mrkTimeFile,'%s %f %f %d %d %q %q');
    
    % Isolate into different test types
    AllHitTimes = [];
    AllMissTimes = [];	% For display use only
    for test=1:length(TestTypes);
      % Find all known change points of a specific type
      TestPredicates = strcmp(Type, TestTypes{test});
      Tests{test} = find(TestPredicates == 1);
      
      % Test - Compute the number of hits and misses for a specific type.
      % As it is possible to have multiple hits in some regions, HitTimes
      % records the time of first hit for any given region, and
      % DupHitTimes records the duplicates.

      [HitTimes{test}, MissTimes{test}, DupHitTimes{test}, TestDupCounts] = ...
	  trkAccuracy(chgpt, Front(Tests{test}), Back(Tests{test}), ...
		      ChangePointToleranceSecs);
      % Gather statistics
      Results.Correct(Current, test) = length(HitTimes{test});
      Results.CorrectAll(Current, test) = length(DupHitTimes{test});
      Results.Actual(Current, test) = length(Tests{test});
      if ~ isempty(TestDupCounts)
        % determine histogram for this test, converting to a row
        % vector if necessary.
        histogram = ...
            utVectorCheck(histc(TestDupCounts, DuplicateCountRanges), 1);
        DuplicateCounts(test,:) = DuplicateCounts(test,:) + histogram;
      end
      
      % Pool all of the hits so that we can determine how many false
      % positives were detected.
      AllHitTimes = union(union(AllHitTimes, HitTimes{test}), ...
				DupHitTimes{test});
      AllMissTimes = union(AllMissTimes, MissTimes{test});
    end
    
    
    % All test types
    Results.Correct(Current, end) = sum(Results.Correct(Current, 1:end-1));
    Results.Actual(Current, end) = sum(Results.Actual(Current, 1:end-1));

    % Determine times at which false positives occurred
    FalsePositiveTimes = setdiff(chgpt, AllHitTimes);
    Results.FalsePositives(Current) = length(FalsePositiveTimes);

    % Determine how many unclassified points there were so that we can
    % compute the false postive rate.
    TestTimes = [0:.050:(cepLen-1)*cepSpcMS/1000];
    [PossibleHits, PossibleMisses] = trkFrameClass(TestTimes, Front, Back, ...
                                                   ChangePointToleranceSecs);
    Results.NoChangeClassCount(Current) = length(PossibleMisses);

    fprintf(out, 'Token %s Errors %s\tFalse + %s\n', SourceData{Current}, ...  
	    Stat(Results.Correct(Current, end), ...
		 Results.Actual(Current, end), 1), ...
	    Stat(Results.FalsePositives(Current), ...
		 Results.NoChangeClassCount(Current)));

    if Display
      figure('Name', sprintf('sw_%s', SourceData{Current}));
      % Note, for the front and back we only plot the first one
      % so that the legend will be displayed correctly (kludge!)
      plot(...
	   AllHitTimes, repmat(320, length(AllHitTimes), 1), 'bp', ...
	   FalsePositiveTimes, ...
	   repmat(320, length(FalsePositiveTimes), 1), 'c+', ...
	   AllMissTimes, repmat(320, length(AllMissTimes), 1), 'rx', ...
	   [Front(Tests{1}(1)), Back(Tests{1}(1))], [290 290], 'ko', ...
	   [Front(Tests{2}(1)), Back(Tests{2}(1))], [290 290], 'k^', ...
	   [Front(Tests{3}(1)), Back(Tests{3}(1))], [290 290], 'kd');
      legend('hit', 'false +', ...
	     'miss', 'change', 'overlap', 'pause');

      hold on
      % Changepoints, Overlap, Pause
      plot([Front(Tests{1}), Back(Tests{1})], [290 290], 'ko', ...
	   [Front(Tests{2}), Back(Tests{2})], [290 290], 'k^', ...
	   [Front(Tests{3}), Back(Tests{3})], [290 290], 'kd');

      for event=1:length(Front)
	    plot([Front(event), Back(event)], [290 290], 'k-')
      end
      
      title(sprintf('%s changepoints - %d/%d correct (%f)', ...
		    MethodName, Results.Correct(Current), ...
		    Results.Actual(Current), ...
		    Results.Correct(Current) / Results.Actual(Current)));
    end
    
    if Keyboard
      fprintf('Pausing, dbcont to continue or enter debug commands')
      keyboard
    end
    
  end % end utterances in current fold

end % end fold loop
  
Results.Misses = Results.Detected - Results.CorrectAll(:, end);

% Final report ----------------------------------------

% Parameter summary
fprintf(out, 'Method %s  ', Method);
switch Method
 case 'eBic'
  fprintf('statistic:  %s\n', Bayesian);
 otherwise
  fprintf('\n');
end
fprintf(out, 'Window length %d MS, advance %d MS\n', ...
	WindowLengthMS, WindowAdvanceMS);
fprintf(out, 'FilterType %s\n', FilterType);
fprintf(out, '\n');


fprintf('Overall ERROR RATES\n');
fprintf(out, ['Easy cut/paste:  window length, all, change, overlap, ', ...
              'pause, false+ \n']);
fprintf(out, '%.2f\t', WindowLengthMS / 1000);
for type=[TestTypeCount+1, 1:TestTypeCount]
  fprintf(out, '%.2f\t', ...
  	  (1 - sum(Results.Correct(:,type))/sum(Results.Actual(:,type)))*100)
end
fprintf(out, '%.2f\n', sum(Results.FalsePositives) / ...
                          sum(Results.NoChangeClassCount) * 100);


fprintf(out, 'AllCat\t\t\tChangePt\t\tOverlap\t\t\tPause\t\t\tFalse Positive\n');
for type=[TestTypeCount+1, 1:TestTypeCount]
  fprintf(out, '%s\t', Stat(sum(Results.Correct(:,type)), ...
                            sum(Results.Actual(:,type)), 1));
end
fprintf(out, '%s\n', Stat(sum(Results.FalsePositives), ...
                          sum(Results.NoChangeClassCount)));

% display per utterance stats
fprintf(out, '\nPer utterance error rates\n');
for idx=1:UtteranceCount
  fprintf(out, '%s ', SourceData{idx})
  for type=[TestTypeCount+1, 1:TestTypeCount]
    fprintf(out, '%s\t', Stat(Results.Correct(idx,type), ...
			 Results.Actual(idx,type), 1));
  end
  fprintf(out, '%s\n', Stat(Results.FalsePositives(idx), ...
		       Results.NoChangeClassCount(idx)));
end

% Statistics on per utterance stats
fprintf('type\tmin\tmax\tvar\n');
for type=[TestTypeCount+1, 1:TestTypeCount]
  Denominator = Results.Actual(:,type);
  Denominator(find(Denominator == 0)) = 1;       % eliminate / 0
  ErrorRates = (Results.Actual(:,type) - Results.Correct(:,type)) ./ ...
      Denominator * 100;
  fprintf(out, '%s\t', TestLabels{type});
  fprintf(out, '%.3f\t', min(ErrorRates), max(ErrorRates), ...
          var(ErrorRates))
  fprintf(out, '\n');
end

Denominator = Results.NoChangeClassCount';
Denominator(find(Denominator == 0)) = 1;        % eliminate / 0
ErrorRates = Results.FalsePositives ./ Denominator * 100;
fprintf(out, 'False+\t');
fprintf(out, '%.3f\t', min(ErrorRates), max(ErrorRates), ...
        var(ErrorRates))
fprintf(out, '\n');
  
fprintf(out, 'Duplicate counts table\n')
DuplicateCounts
fprintf(out, 'Duplicate counts percentages\n')
DuplicateCounts ./ repmat(sum(DuplicateCounts,2), 1, size(DuplicateCounts, 2))

% ------------------------------------------------------------

function String = Stat(Numerator, Denominator, Complement)
% ResultString = Stat(Numerator, Denominator, Complement)
% Format string (N/D) = N/D

if nargin < 3
  Complement = 0;
end
if Denominator == 0
  String = sprintf('N/A\t\t');
else
  if Complement
    % Use 1 - percentage instead of percentage
    Numerator = Denominator - Numerator;
  end

  Percent = Numerator / Denominator * 100;

  % format with leading spaces such that whole number portion
  % always takes three digits
  if Percent < 100
    if Percent < 10
      LeadSpaces = '  ';
    else
      LeadSpaces = ' ';
    end
  else
    LeadSpaces = '';
  end

  String = sprintf('(%3d/%3d)=%s%.2f%%', Numerator, Denominator, ...
                   LeadSpaces, Percent);
end

% ------------------------------------------------------------
function Range = DetermineRange(Begin, End, PadFrames, cepSpcMS)
% Range = DetermineRange(Begin, End)
% Given a window, where should we search relative to the window?

LongWindowThreshold_s = 8;  % How long is a long window?
LongWindowSkip = .40;       % Skip first N% on long windows

% Compute length in s. and frames
WindowLength_s = (End - Begin) * cepSpcMS / 1000 ;
WindowLengthFrames = (End - Begin) + 1;

if WindowLength_s > LongWindowThreshold_s
  % long segment, skip beginning
  StartSearch = floor(WindowLengthFrames *.40);
  Range = StartSearch:WindowLengthFrames-PadFrames;
else
  % short segment, test it all
  Range = PadFrames:WindowLengthFrames-PadFrames;
end

    
