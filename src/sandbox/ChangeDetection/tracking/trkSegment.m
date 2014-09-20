function trkSegment(SourceData, varargin)
% trkSegment(SourceData, OptionalArguments)
% Evaluate the BIC on a corpus
%
% Optional arguments
% 	'Window', {AdvanceMS, LengthMS}
%		Set the windowing for the BIC
%		Expects a cell array containing the window
%		advance and length in milliseconds.
%		Default:  {100, 2000}
%	'EnergyPct', N
%		Delete the lowest N*100% energy frames (default .0)
%	'FilterType', {Type, Arguments} or Type
%               Specifies how the BIC signal should be filtered before
%               searching for peaks.  User may either specify the type
%               string alone, or a cell array to specify the type and
%               any arguments.  Valide types
%               'none' - no filtering
%               'median' - median filtering
%               'lowpass', [PassBandStop, CutoffStart] - Construct a 
%                       lowpass equiripple filter with 1 dB of ripple
%                       in the passband and 18 dB of ripple in the
%                       stopband.  Default is [3.25, 3.5]
%	'Keyboard', N
%		If N positive, pause after processing each utterance in
%		debug mode.
%	'Method', String
%		How should the BIC be computed?
%		'ls-bic-full' (default) - linear search BIC with full 
%                       covariance matrices
%               'ls-bic-diag' - linear search BIC with diagonal
%                      covariance matrices
%               'ls-bic-map-diag' - linear search BIC with empirical
%                       Bayes MAP estimator, diagonal covariance matrices
%		'llr' - log likelihood ratio
%	'Bayesian', String
%		What point estimate of the posterior distribution
%		should be used?  Valid:  'mean', 'mode' (default)
%	'N-Fold', N
%		Number of folds, only useful for estimating
%		prior data.  Default is 1 (no folding).
%	'PeakSelection', {Options}
%		Cell array of options for peak detection.
%               See spPeakDetector for valid options.
%               Default:  {'Method', 'simple'}
%	'Prior', Structure - Empirical Bayes methods only
%		If the prior data has been previously estimated
%		we may pass it in to avoid recomputing.  
%	'Display', N
%		If non-zero, plot a display of the change points
%	'PenaltyWeight, Lambda
%		PenaltyWeight - BIC penalty weight.  Defaults to 1.2
%
% This code is copyrighted 2003-2005 by Marie Roch and Yanliang Cheng.
% e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 


% Set up the defaults

Prior = [];
WindowAdvanceMS = 100;
WindowLengthMS = 2000;
Method = 'ls-bic-full';
NFold = 1;
EnergyPct = 0;
FilterType = 'lowpass';
FilterArgs = {[3.25, 3.5]};
Display = 0;
Keyboard = 0;	% Pause in debug mode?
Bayesian = 'mode';
PenaltyWeight = 1.2;
PeakDetectorArgs = {'Method', 'simple'};

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
    Arg = varargin{n+1}; n=n+2;
    if iscell(Arg)
      FilterType = Arg{1};
      if length(Arg) > 1
        FilterArgs = {Arg{2:end}};
      else
        FilterArgs = {};
      end
    else
      FilterType = Arg;
    end
    
    
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

   otherwise
    error('Bad optional argument: "%s"', varargin{n});
  end
end

if ~ isempty(Prior)
  Prior.Statistic = Bayesian;
end

switch Method
 case 'llr'
  fprintf('log likelihood ratio\n');
 case 'ls-bic-full'
  fprintf('Full covariance linear search BIC\n');
 case 'ls-bic-diag'
  fprintf('Diagonal covariance linear search BIC\n');
 case 'ls-bic-map-diag-pdf'
  fprintf('Likelihood diagonal covariance linear search EB BIC\n');
 case 'ls-bic-map-diag'
  fprintf('Diagonal covariance linear search Empirical Bayes BIC\n');
 case 'ls-bic-map'
  fprintf('Full covariance linear search Empirical Bayes BIC\n');
  error('Not yet implemented')
 otherwise
  error('Bad Method argument:  %s', Method);
end


fprintf('Executing on %s (%s)\n', utMachineName, computer);

% hardcoded information --------------------
Corpus = 'spidre';
FeatureFormat = 'htk';

% prior data
PriorPath = '/lab/speech/corpora/swb2/cep/';
% data base truth tables
TruthPath = '/lab/speech/corpora/spidre/changepoint/';

out=1;     % Output handle (1=stdout, 2=stderr, or fopen result)

UtteranceCount = length(SourceData);

SampleRate = 1000 / WindowAdvanceMS;
WindowAdvanceSec = WindowAdvanceMS / 1000;

% Build appropriate filter if needed
if strcmp(FilterType, 'lowpass')
  % build a low-pass filter for the BIC
  BPFilter = spBuildLP(FilterArgs{1}, SampleRate, [1, 0], [1, 18]);
end

% data structure describing test types
Test = trkInitTest(ChangePointToleranceSecs); 

% Initialize counters
Results = trkInitCounts(Test, UtteranceCount);

% data structures for tracking performance
% More than one change point can occur within a region
% which is known to mark an acoustic change point.  This data 
% structure is a histogram of how often this occurs
DuplicateCountRanges = [1:25,500];
DuplicateCounts = zeros(Test.TypeCount, length(DuplicateCountRanges));



Current = 0;
fprintf(out, 'Test date: %s \n',datestr(date,1));

fprintf(out, 'Token\tAllCat\t\t\tChangePt\t\tOverlap\t\t\tPause\t\t\tFalse Positive\n');

% Track time used from here on
StartWallClock = clock;
StartCPUClock = cputime;

for foldindx = 1:NFold
  % TrainIndices not used
  [TrainIndices, TestIndices] = trkNfold(foldindx, NFold, UtteranceCount); 
  
  % Process test utterances in current fold
  for idx = TestIndices  
    % Reset vectors for this utterance
    time = [];
    bic = [];
    bic2 = [];  % kludge for plotting comparisons
    Current = Current + 1;

    [data, cepSpcMS] = trkReadFeatures(Corpus, SourceData{idx}, ...
                                       FeatureFormat, FeatureString);

    Energy = data(:,1); % assume energy in feature set and remove it
    data(:,1) = [];     
    
    % Count of cepstra and spacing between feature vectors
    cepLen  = size(data,1);
    
    % Determine analysis window length and advance
    win = floor(WindowLengthMS/ cepSpcMS);   
    delta = floor(WindowAdvanceMS / cepSpcMS);

    % determine the interval which the initial window will cover
    head = 1; 
    tail = head + win;

    % calculate BIC of EBIC, here index coupling BIC/eBIC 
    % values with corresponding time
    % A struct will be better to store them pair by pair
    while tail <= cepLen      
      segment = data(head:tail, :); 
      winoffset = round((tail-head)/2);
      
      switch Method
       case 'llr'
	% log likelihood ratio
	bic(end+1) = trkLLR(segment, winoffset, EnergyPct);

       case 'ls-bic-full'
	% segmented BIC
	bic(end+1) = trkBIC(segment, winoffset, PenaltyWeight, EnergyPct);

       case 'ls-bic-diag'
        bic(end+1) = trkBIC_d(segment, winoffset, PenaltyWeight);

       case 'ls-bic-map-diag'
	% empirical Bayes BIC
	bic(end+1) = trkBIC_d(segment, winoffset, ...
                              PenaltyWeight, Prior);
        if ~ isreal(bic(end))
          fprintf('complex # detected\n')
          keyboard
        end
        % Kludge so that we can plot them side by side...
        if Display
          %bic2(end+1) = trkBIC_d(segment, winoffset, PenaltyWeight, Prior2);
          bic2(end+1) = trkBIC_d(segment, winoffset, PenaltyWeight);
        end

       case 'ls-bic-map-diag-u'
        % linear search BIC, diagonal covar matrix, mean present
        bic(end+1) = trkBIC_d_u(segment, winoffset, PenaltyWeight, Prior);
        if Display
          %bic2(end+1) = trkBIC_d(segment, winoffset, PenaltyWeight, Prior2);
          bic2(end+1) = trkBIC_d_u(segment, winoffset, 1.0);
        end
      end
      
      time(end+1) = (head+round((tail-head)/2))*cepSpcMS/1000;  %yc
      % BIC/eBIC window advance by delta
      head = head + delta;        
      tail = head + win;                  
    end           
    % Filter the bic signal
    switch FilterType
     case 'none'
      fBic = bic;
      
     case 'median'
      MedianFilterSize = ceil(delta/2);
      fBic = mfilt(bic, MedianFilterSize);         

     case 'lowpass'
      fBic = filter(BPFilter, 1, bic);
      Order = length(BPFilter);
      % Account for delay
      Shift = round(Order/2);
      fBic = [ fBic(Shift:end), zeros(1, Shift-1)];

    end
    
    % Find peaks in filtered BIC curve
    Peaks = spPeakSelector(fBic, PeakDetectorArgs{:});
    % Only retain those where BIC is positive.
    PositivePeaks = Peaks(fBic(Peaks) > 0);
    % Find timestamp of change points
    chgpt = time(PositivePeaks);
    
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
    for test=1:length(Test.Types);
      % Find all known change points of a specific type
      TestPredicates = strcmp(Type, Test.Types{test});
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
    TestTimes = (1:length(fBic))*WindowAdvanceSec;
    [PossibleHits, PossibleMisses] = trkFrameClass(TestTimes, Front, Back, ...
                                                   ChangePointToleranceSecs);
    Results.NoChangeClassCount(Current) = length(PossibleMisses);

    % print file id and results
    fprintf(out, '%s\t', SourceData{Current});
    for type=[Test.TypeCount+1, 1:Test.TypeCount]
      fprintf(out, '%s\t', trkReportStat(Results.Correct(idx,type), ...
                                         Results.Actual(idx,type), 1));
    end
    fprintf(out, '%s\n', trkReportStat(Results.FalsePositives(idx), ...
                                       Results.NoChangeClassCount(idx)));
    if Display
      figure('Name', sprintf('sw_%s', SourceData{Current}));
      % Note, for the front and back we only plot the first one
      % so that the legend will be displayed correctly (kludge!)


      plot(time, bic, 'b-')
      legendstring = {'bic'};
      hold on
      if ~ strcmp(FilterType, 'none')
        % filtering present
        plot(time, fBic, 'm-');
        legendstring{end+1} = 'filt bic';
      end
      if ~ isempty(bic2)
        plot(time, bic2, 'k--');
        legendstring{end+1} = 'bic2';
      end
      DetectionHeight = max(bic)* 1.05;
      plot(AllHitTimes, repmat(DetectionHeight, length(AllHitTimes), 1), 'bp', ...
	   FalsePositiveTimes, ...
	   repmat(DetectionHeight, length(FalsePositiveTimes), 1), 'c+', ...
	   AllMissTimes, repmat(DetectionHeight, length(AllMissTimes), 1), 'rx');
      legendstring = {legendstring{:}, 'hit', 'false +', 'miss'};
      
      hold on
      % plot first one only of CH/OV/PA
      TruthHeight = max(bic) * 1.04;
      TruthHeight = TruthHeight([1 1]);
      for k=1:3
        if ~ isempty(Tests{k})
          % only plot if there's something there
          plot([Front(Tests{k}(1)), Back(Tests{k}(1))], TruthHeight, ...
               Test.Symbols{k});
          legendstring{end+1} = Test.Labels{k};
        end
      end
      legend(legendstring{:});

      % plot all Changepoints, Overlap, Pause
      for k=1:3
        if ~ isempty(Tests{k})
          plot([Front(Tests{k}), Back(Tests{k})], TruthHeight, Test.Symbols{k});
        end
      end
      % draw horizontal lines connecting symbols
      for event=1:length(Front)
	    plot([Front(event), Back(event)], TruthHeight, Test.LineStyles{k})
      end
      
      ChangePtIdx = find(strcmp(Test.Types, 'CH') == 1);
      title(sprintf('%s overall %s changepoints %s false +:  %s', ...
		    Method, ...
                    trkReportStat(Results.Correct(Current, Test.TypeCount + 1), ...
                         Results.Actual(Current, Test.TypeCount + 1), 1), ...
                    trkReportStat(Results.Correct(Current, ChangePtIdx), ...
                         Results.Actual(Current, ChangePtIdx), 1), ...
                    trkReportStat(Results.FalsePositives(Current), ...
                         Results.NoChangeClassCount(Current))))

      % plot peaks on curves
      plot(time(PositivePeaks), bic(PositivePeaks), 'ko');
      % plot comparison bic
      if length(bic2) == length(time)
            % Find peaks in filtered BIC curve
            Peaks2 = spPeakSelector(bic2, PeakDetectorArgs{:});
            % Only retain those where BIC is positive.
            PositivePeaks2 = Peaks(bic2(Peaks) > 0);
            plot(time(PositivePeaks2), bic2(PositivePeaks2), 'ko');
      end
      
      plot(time, zeros(size(time)), 'k:')           % plot 0 line 
    end
    
    if Keyboard
      fprintf('Pausing, dbcont to continue or enter debug commands')
      keyboard
    end
    
  end % end utterances in current fold

end % end fold loop
  
Results.Misses = Results.Detected - Results.CorrectAll(:, end);

% All done, save time
ElapsedWallClock = etime(clock, StartWallClock);
ElapsedCPUClock = cputime - StartCPUClock;

% Final report ----------------------------------------

fprintf('Elapsed wall clock time: %s\n', ...
	sectohhmmss(ElapsedWallClock));

fprintf('Elapsed CPU time: %s\n', sectohhmmss(ElapsedCPUClock));

% Parameter summary
fprintf(out, 'Method %s  ', Method);
switch Method
 case 'ls-bic-map-diag'
  fprintf('EB statistic:  %s\n', Bayesian);
 otherwise
  fprintf('\n');
end

fprintf(out, 'Window length %d MS, advance %d MS\n', ...
	WindowLengthMS, WindowAdvanceMS);
fprintf(out, 'filtering %s ', FilterType);
switch FilterType
 case 'none'
  fprintf(out, '\n');
 otherwise
  FilterArgs{:}
end
PeakDetectorArgs{:}

fprintf(out, '\n');


fprintf('Overall ERROR RATES\n');
fprintf(out, ['Easy cut/paste:  method, peak-sel window length, penalty ', ...
              'all, change, overlap, pause, false+ \n']);
fprintf(out, '%s\t%s\t%.2f\t%f\t', Method, PeakDetectorArgs{2}, ...
        WindowLengthMS / 1000, PenaltyWeight);
for type=[Test.TypeCount+1, 1:Test.TypeCount]
  fprintf(out, '%.2f\t', ...
  	  (1 - sum(Results.Correct(:,type))/sum(Results.Actual(:,type)))*100)
end
fprintf(out, '%.2f\n', sum(Results.FalsePositives) / ...
                          sum(Results.NoChangeClassCount) * 100);


fprintf(out, 'AllCat\t\t\tChangePt\t\tOverlap\t\t\tPause\t\t\tFalse Positive\n');
for type=[Test.TypeCount+1, 1:Test.TypeCount]
  fprintf(out, '%s\t', trkReportStat(sum(Results.Correct(:,type)), ...
                            sum(Results.Actual(:,type)), 1));
end
fprintf(out, '%s\n', trkReportStat(sum(Results.FalsePositives), ...
                          sum(Results.NoChangeClassCount)));


% Statistics on per utterance stats
fprintf('type\tmin\tmax\tvar\n');
for type=[Test.TypeCount+1, 1:Test.TypeCount]
  Denominator = Results.Actual(:,type);
  Denominator(find(Denominator == 0)) = 1;       % eliminate / 0
  ErrorRates = (Results.Actual(:,type) - Results.Correct(:,type)) ./ ...
      Denominator * 100;
  fprintf(out, '%s\t', Test.Labels{type});
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

