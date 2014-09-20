function trkEPsegment(SourceData, EndpointPath, varargin)
% trkEPsegment(SourceData, EndpointPath, OptionalArguments)
% Given a list of utterances, evaluate endpoint segmentation on a corpus.
% Endpoint files should be located in directory EndpointPath.
%
% Optional arguments
%	'Corpus', String
%		Name of corpus.  Defaults to spidre.
%	'Display', N
%		If non-zero, plot a display of the change points
%	'Keyboard', N
%		If N positive, pause after processing each utterance in
%		debug mode.
%	'FeatureString, String
%		String which speicifies how endpoint files are named.
%		It should contain a %s which will be replaced by the
%		name of the indvidual tokens passed in SourceData.
%
% This code is copyrighted 2003-2004 by Marie Roch and Yanliang Cheng.
% e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 


% Set up the defaults

Corpus = 'spidre';
Display = 0;
Keyboard = 0;	% Pause in debug mode?
FeatureString = 'sw%s.lab';	% How are feature files named?

ChangePointToleranceSecs = .2;

n = 1;
while n <= length(varargin)

  switch varargin{n}
    
   case 'Corpus'
    Corpus =  varargin{n+1}; n=n+2;
    
   case 'Display',
    Display = varargin{n+1}; n=n+2;
    
   case 'FeatureString'
    FeatureString = varargin{n+1}; n=n+2;
    
   case 'Keyboard'
    Keyboard = varargin{n+1}; n=n+2;

   otherwise
    error(sprintf('Bad optional argument: "%s"', varargin{n}));
  end
end

ChangeTimePath = ['/lab/speech/corpora/', Corpus, ...
		  corResourceDir(Corpus, 'changepoint'), '/'];

EndPoint = 0;
noEnd = abs(EndPoint -1); %0;

outPath = '/zal/mroch/speech/runs/test/';

out = 1;	% Output to stdout

TotalHits = 0;
TotalMisses = 0;
TotalChangePoints = 0;
TotalFalsePositives = 0;

UtteranceCount = length(SourceData);

% Set samplerate to frame rate.  Hardcode for now
SampleRate = 8000;	% Telephone speech
FrameRate = 100;	% 10 ms advance

fprintf(out, 'Test date: %s \n',datestr(date,1));
fprintf(out, ['Utterance\tWindowsLen \t Advance \t hitRate ', ...
	'\t\t missingRate \t\t falseRate \n']);

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

fprintf(out, 'Frame sample rate\n', SampleRate);

firstTime = 1;

% If EndpointPath exists, make sure it ends in a /
if (~ isempty(EndpointPath) && EndpointPath(end) ~= '/')
  EndpointPath(end+1) = '/';
end
  
% Process test utterances in current fold
for idx = 1:UtteranceCount  
  % Reset segments for this utterance
  [Start, Stop, Label] = ...
      textread(sprintf(['%s', FeatureString], EndpointPath, SourceData{idx}), ...
	       '%d %d %s');
  % Convert samples to time
  Start = Start / SampleRate;
  Stop = Stop / SampleRate;
  
  % Determine changepoints
  
  % Find indices marked as speech
  SpeechIndices = strmatch('s', Label);
  
  Simple = 0;
  Midpoints = (Stop(1:end-1) + Start(2:end)) / 2;
  if Simple
    % Hypothesize change points have occurring half way between
    % each silence.
    ChangePointHyp = [Start(1)
		      Midpoints
		      Stop(SpeechIndices(end))];
  else
    % Determine how far apart in time stops and starts are.
    Distances = (Stop(1:end-1) - Start(2:end));

    % Separate into short and long change points.  
    LongThreshold = .3;
    Long = find(Distances > LongThreshold);
    Short = find(Distances <= LongThreshold);
    
    ChangePointHyp = [Start(1),
		      Midpoints(Short)
		      Start(Long)
		      Stop(Long+1)
		      ];
  end
  
  time = [];
  Current = Current + 1;

  chgpt = ChangePointHyp';	% for compat w/ old code

  % Record how many peaks we detected.
  Results.Detected(Current) = length(chgpt);
    
  % Read in known times and compare to predictions
  mrkTimeFile = sprintf('%ssw%s.csv', ...
			ChangeTimePath, SourceData{idx});
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
      
      [HitTimes{test}, MissTimes{test}, DupHitTimes{test}] = ...
	  trkAccuracy(chgpt, Front(Tests{test}), Back(Tests{test}), ...
		      ChangePointToleranceSecs);
      % Gather statistics
      Results.Correct(Current, test) = length(HitTimes{test});
      Results.CorrectAll(Current, test) = length(DupHitTimes{test});
      Results.Actual(Current, test) = length(Tests{test});
      
      
      % Pool all of the hits so that we can determine how many false
      % positives were detected.
      AllHitTimes = union(union(AllHitTimes, HitTimes{test}), ...
			  DupHitTimes{test});
      AllMissTimes = union(AllMissTimes, MissTimes{test});
 end
  
  % All test types
  Results.Correct(Current, end) = sum(Results.Correct(Current, 1:end-1));
  Results.Actual(Current, end) = sum(Results.Actual(Current, 1:end-1));
  
  % False positives are all change points not accounted for by
  % one of the change points in the data base (AllHitTimes)
  FalsePositiveTimes = setdiff(chgpt, AllHitTimes);
  Results.FalsePositives(Current) = length(FalsePositiveTimes);

  % Determine how many unclassified points there were so that we can
  % compute the false positive rate.

  FeatureFormat = 'htk';
  FeaturePath = '/lab/speech/corpora/spidre/cep/'; 
  switch FeatureFormat
   case 'htk'
    FileName = sprintf('sw%s.mfc', SourceData{idx});
    [data, info] = spReadFeatureDataHTK(sprintf('%s%s', FeaturePath, ...
                                                FileName));
    data = data';
    cepSpcMS = info.CepstralSpacingMS;
      
   case 'matlab'
    melcep = corReadFeatureSet(sprintf('%s%s', FeaturePath, FileName));
    data = melcep.Data{1};
    % spacing between feature vectors in MS
    cepSpcMS = melcep.Attribute.CepstralSpacingMS;
   otherwise
    error(sprintf('Bad feature format %s', FeatureFormat))
  end
  FrameCount = size(data, 1);
  FrameTimes = (0:FrameCount-1)/FrameRate;

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
    % compute the false postive rate.  To compute on a similar scale
    % as for the BIC, we'll assume a possible hypothesis every N frames
    HypothEveryN = 5;
    WindowAdvanceMS = 10;
    WindowAdvanceSec = WindowAdvanceMS / 1000;

    TestTimes = (1:round(FrameCount / HypothEveryN))*WindowAdvanceSec;
    [PossibleHits, PossibleMisses] = trkFrameClass(TestTimes, Front, Back, ...
                                                   ChangePointToleranceSecs);
    Results.NoChangeClassCount(Current) = length(PossibleMisses);

    % old method for computing false +
    %[BogusHits, BogusMisses, DupBogusHits] = ...
    %   trkAccuracy(TestTimes, Front, Back, ChangePointToleranceSecs);
    %Results.NoChangeClassCount(Current) = length(TestTimes) - length(DupBogusHits);


    fprintf(out, 'Token %s Errors %s\tFalse + %s\n', SourceData{Current}, ...  % not correct sphere name
	    Stat(Results.Correct(Current, end), ...
		 Results.Actual(Current, end), 1), ...
	    Stat(Results.FalsePositives(Current), ...
		 Results.NoChangeClassCount(Current)));

    if Display
      figure('Name', sprintf('sw_%s', SourceData{Current}));
      % Note, for the front and back we only plot the first one
      % so that the legend will be displayed correctly (kludge!)
      plot(time, bic, time, fBic, 'g--', ...
	   AllHitTimes, repmat(320, length(AllHitTimes), 1), 'bp', ...
	   FalsePositiveTimes, ...
	   repmat(320, length(FalsePositiveTimes), 1), 'c+', ...
	   AllMissTimes, repmat(320, length(AllMissTimes), 1), 'rx', ...
	   [Front(Tests{1}(1)), Back(Tests{1}(1))], [290 290], 'ko', ...
	   [Front(Tests{2}(1)), Back(Tests{2}(1))], [290 290], 'k^', ...
	   [Front(Tests{3}(1)), Back(Tests{3}(1))], [290 290], 'kd');
      legend('bic', 'filt bic', 'hit', 'false +', ...
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
fprintf(out, 'Window advance %d MS\n', WindowAdvanceMS);
fprintf(out, 'Forged hypothesis every %d frames (for false + similarity)\n', HypothEveryN);
fprintf(out, '\n');


fprintf('Overall ERROR RATES\n');
fprintf(out, ['Easy cut/paste:  window length, all, change, overlap, ', ...
              'pause, false+ \n']);
fprintf(out, 'NA\t')
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
