function trkTritschler(SourceData, varargin)
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
%	'FilterType', 'none'|'median'|'lowpass'
%	'Keyboard', N
%		If N positive, pause after processing each utterance in
%		debug mode.
%	'Method', String
%		How should the BIC be computed?
%		'bic' (default) - Traditional Chen & Gopalakrishnan
%               'bic-diag' - Chen & Gopalkrishnan with diagonal
%                      covariance matrcies
%		'bic-diag-map' - empirical Bayes BIC
%               'bic-diag-map-muvar', - MAP adapted means/vars
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
% This code is copyrighted 2003-2005 by Marie Roch, Yanliang Cheng,
% and Sonia Arteaga.
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
FilterType = 'none';
FilterArgs = {[3.25, 3.5]};
Display = 0;
Keyboard = 0;	% Pause in debug mode?
Bayesian = 'mean';
EndPoint = 0;
PenaltyWeight = 1.2;
PeakDetectorArgs = {'Method', 'simple'};
%seg length in computation of priors
SegmentLength = -1;

%FeatureString = 'sw%s_38.cep';
FeatureString = 'sw%s.mfc';
ChangePointToleranceSecs = .2;
LineSpecs = {'b', 'm', 'r', 'k','g', 'c','y', 'm^', 'r^', 'k^'};
Handles = [];

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
  fprintf('Tritschler & Gopalkrishnan - BIC\n');
  MethodName = 'BIC';
 case 'bic-diag'
  fprintf(['Tritschler & Gopalkrishnan - BIC w/ diagonal variance/' ...
           'covariance\n'])
  MethodName = Method;
 case 'bic-diag-map-muvar'
  fprintf(['Tritschler & Gopalkrishnan - BIC w/ diagonal cov/' ...
           ' & MAP mu/var\n'])
  MethodName = Method;
 case 'eBic'
  MethodName = 'bic-diag-map';
  fprintf('Empirical Bayes BIC\n');
 otherwise
  error(sprintf('Bad Method argument:  %s', Method));
end


% combined channels
runenv = 'fruitbat';
fprintf('Executing on %s (%s)\n', utMachineName, computer);
noEnd = abs(EndPoint -1); 

% hardcoded paths for now --------------------
Corpus = 'spidre';
FeatureFormat = 'htk';

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

out = 1;        % file handle - 1 = stdout  

TotalHits = 0;
TotalMisses = 0;
TotalChangePoints = 0;
TotalFalsePositives = 0;

UtteranceCount = length(SourceData);

SampleRate = 1000 / WindowAdvanceMS;
WindowAdvanceSec = WindowAdvanceMS / 1000;

% Build appropriate filter if needed

if strcmp(FilterType, 'lowpass')
  % build a low-pass filter for the BIC
  BPFilter = spBuildLP(FilterArgs{1}, SampleRate, [1, 0], [1, 18]);
end

% Different types of tests    
% CH - speaker change
% OV - speaker overlap
% PA - speaker pausen
TestTypes = {'CH', 'OV', 'PA'};
TestLabels = {'change', 'overlap', 'pause', 'all'};
TestTypeCount = length(TestTypes);
TestSymbols = {'k^', 'ks', 'kd'};

% data structures for tracking performance

% More than one change point can occur within a regions
% which is known to mark an acoustic change point.  This data 
% structure is a histogram of how often this occurs
DuplicateCountRanges = [1:25,500];
DuplicateCounts = zeros(length(TestTypes), length(DuplicateCountRanges));

% Initialize counters
Results = trkInitCounts(Test, UtteranceCount);

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
    % One and two model curves for comparison when plotting
    one = [];
    two = [];
    Current = Current + 1;

    % Read in known times and compare to predictions
    mrkTimeFile = sprintf('%ssw%s.csv', ...
			  TruthPath, SourceData{idx});
    [Type, Front, Back, FrontSpeaker, BackSpeaker, ...
     FrontText, BackText ] =...
	textread(mrkTimeFile,'%s %f %f %d %d %q %q');
    % find indices into TestTypes array:  CH/OV/PA
    [DontCare, TypeIndex] = ismember(Type, TestTypes);
    FileName = corFind(Corpus, 'feature', ...
                       sprintf(FeatureString, SourceData{idx}));

    % Read feature file, but do not delete the frame energy.
    % We do not use frame energy for categorization, but we
    % may optionally drop low energy frames
    switch FeatureFormat
     case 'htk'
      [data, info] = spReadFeatureDataHTK(FileName);
      if info.O
        % MFCC 0 included, move position
        data = [data(end,:); data(1:end-1, :)];
        data = data';   % Each column is a feature
      end
      cepSpcMS = info.CepstralSpacingMS;
      
     case 'matlab'
      melcep = corReadFeatureSet(FileName);
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
    
    if Display
      figure('Name', 'Tritschler & Gopinath BIC')
    end
    
    % calculate BIC
    Verbose = 0;
    while tail <= cepLen      
      LineSpecIdx = 1;  % plot specification index
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
        segment = data(head:tail, :);
% $$$         for hypoth_idx = SearchRange
% $$$           switch Method
% $$$            case 'bic'
% $$$             bic(hypoth_idx) = trkBIC(segment, hypoth_idx, ...
% $$$                                       PenaltyWeight);
% $$$            case 'bic-diag'
% $$$             bic(hypoth_idx) = trkBIC_d(segment, hypoth_idx, PenaltyWeight, ...
% $$$                                        EnergyPct); 
% $$$            case 'bic-diag-map-muvar'
% $$$             [bic(hypoth_idx), one(hypoth_idx), two(hypoth_idx)] = ...
% $$$                 trkBIC_d_u(segment, hypoth_idx, PenaltyWeight, Prior);
% $$$           end
% $$$         end
        bic = []; one = []; two = [];
        switch Method
         case 'bic'
          [bic, one, two] = trkBIC(segment, SearchRange, PenaltyWeight);
         case 'bic-diag'
          [bic, one, two] = trkBIC_d(segment, SearchRange, ...
                                     PenaltyWeight);
         case 'bic-diag-map-muvar'
          % one(SearchRange), two(SearchRange)
          [bic(SearchRange)] = trkBIC_d_u(segment, SearchRange, PenaltyWeight, ...
                                       Prior);
        end
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
        
        if Display
          
          % erase truth information from last plot if necessary
          if ~ isempty(Handles)
            for k=1:length(Handles)
              delete(Handles(k))
            end
            Handles = [];
          end
          
          SecPerIdx = cepSpcMS / 1000;
          Start = head * SecPerIdx;      % Start/Stop time for region
          Stop = tail * SecPerIdx;       %  of interest
          StartSearch = (head + SearchRange(1) - 1) * SecPerIdx;
          StopSearch = (head + SearchRange(end) - 1) * SecPerIdx;
          BICTime = Start:SecPerIdx:StopSearch;
          PeakTime = (head + Peaks - 1) * SecPerIdx;

          % plot current bic curve & peaks
          plot(BICTime, bic, LineSpecs{LineSpecIdx});
          hold on;
          if ~ isempty(one)
            Handles(end+1) = plot(BICTime, one, 'k-');
            Handles(end+1) = plot(BICTime, two, 'k:');
          end
          if ~ isempty(Peaks)
            % show peaks
            plot(PeakTime, bic(Peaks), 'g+');
            % denote largest peak
            [MaxValue, MaxPeakIdx] = max(bic(Peaks));
            if MaxValue > 0
              plot(PeakTime(MaxPeakIdx), bic(Peaks(MaxPeakIdx)), 'b*');
            else
              plot(PeakTime(MaxPeakIdx), bic(Peaks(MaxPeakIdx)), 'bo');
            end
          end
          
          % set up for next curve
          LineSpecIdx = mod(LineSpecIdx, length(LineSpecs)) + 1;
          
          % Retrieve indices of changes in the window of interest
          [Chg ChgType] = trkFindIndices(Front, Back, Start, Stop);
          
          % plot them...
          Elevation = 60;
          for k=1:length(Chg)
            switch ChgType(k)
             case -1
              % ends in region
              Left = Start;
              Right = Back(Chg(k));
              Handles(end+1) = ...
                  plot(Right, Elevation, TestSymbols{TypeIndex(Chg(k))});
             case 0
              % contained in region
              Left = Front(Chg(k));
              Right = Back(Chg(k));
              Handles(end+1) = ...
                  plot([Left, Right], Elevation([1 1]), ...
                       TestSymbols{TypeIndex(Chg(k))});
             case 1
              % starts in region
              Left = Front(Chg(k));
              Right = Stop;
              Handles(end+1) = ...
                  plot(Left, Elevation, TestSymbols{TypeIndex(Chg(k))});
            end
            Handles(end+1) = plot([Left, Right], Elevation([1 1]), 'k-');
          end
          
          if Keyboard
            keyboard
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
        
        if Display
          % clear figure & handle list for new plots
          clf
          Handles = [];
        end
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
        
    % Compare predictions to known times --------------------
    
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
    ComparisonAdvanceMS = 50;
    ComparisonAdvanceS = ComparisonAdvanceMS/1000;
    TestTimes = [0:ComparisonAdvanceS:(cepLen-1)*cepSpcMS/1000];
    [PossibleHits, PossibleMisses] = trkFrameClass(TestTimes, Front, Back, ...
                                                   ChangePointToleranceSecs);
    Results.NoChangeClassCount(Current) = length(PossibleMisses);

    fprintf(out, 'Token %s Errors %s\tFalse + %s\n', SourceData{Current}, ...  
	    trkReportStat(Results.Correct(Current, end), ...
		 Results.Actual(Current, end), 1), ...
	    trkReportStat(Results.FalsePositives(Current), ...
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
fprintf(out, ['Easy cut/paste:  method, peak-sel window length, penalty ', ...
              'all, change, overlap, pause, false+ \n']);
fprintf(out, '%s\t%s\t%.2f\t%f\t', Method, PeakDetectorArgs{2}, ...
        WindowLengthMS / 1000, PenaltyWeight);
for type=[TestTypeCount+1, 1:TestTypeCount]
  fprintf(out, '%.2f\t', ...
  	  (1 - sum(Results.Correct(:,type))/sum(Results.Actual(:,type)))*100)
end
fprintf(out, '%.2f\n', sum(Results.FalsePositives) / ...
                          sum(Results.NoChangeClassCount) * 100);


fprintf(out, 'AllCat\t\t\tChangePt\t\tOverlap\t\t\tPause\t\t\tFalse Positive\n');
for type=[TestTypeCount+1, 1:TestTypeCount]
  fprintf(out, '%s\t', trkReportStat(sum(Results.Correct(:,type)), ...
                            sum(Results.Actual(:,type)), 1));
end
fprintf(out, '%s\n', trkReportStat(sum(Results.FalsePositives), ...
                          sum(Results.NoChangeClassCount)));

% display per utterance stats
fprintf(out, '\nPer utterance error rates\n');
for idx=1:UtteranceCount
  fprintf(out, '%s ', SourceData{idx})
  for type=[TestTypeCount+1, 1:TestTypeCount]
    fprintf(out, '%s\t', trkReportStat(Results.Correct(idx,type), ...
			 Results.Actual(idx,type), 1));
  end
  fprintf(out, '%s\n', trkReportStat(Results.FalsePositives(idx), ...
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

    
