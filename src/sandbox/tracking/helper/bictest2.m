function bictest(SourceData, varargin)
% bictest(SourceData, OptionalArguments)
% Evaluate the BIC on a corpus
%
% Optional arguments
% 	'Window', {AdvanceMS, LengthMS}
%		Set the windowing for the BIC
%		Expects a cell array containing the window
%		advance and length in milliseconds.
%		Default:  {100, 2000}
%	'EnergyPct', N
%		Delete the lowest N*100% energy frames (default .10)
%	'FilterType', 'median'|'lowpass'
%	'Keyboard', N
%		If N positive, pause after processing each utterance in
%		debug mode.
%	'Method', String
%		How should the BIC be computed?
%		'bic' (default) - Traditional Chen & Gopalakrishnan
%		'eBic' - empirical Bayes BIC
%	'Bayesian', String
%		What point estimate of the posterior distribution
%		should be used?  Valid:  'mean' (default), 'mode'
%	'N-Fold', N
%		Number of folds, only useful for estimating
%		prior data.  Default is 1 (no folding).
%	'Priors', StructureArray
%		If the prior data has been previously estimated
%		we may pass it in to avoid recomputing.  Each 
%		element of the structure array should contain
%		a structure of prior information.
%	'Display', N
%		If non-zero, plot a display of the change points
%    'EndPoint', N
%       1 = Raj/Singh endpointing, 0 = no endpointing


% Set up the defaults

Priors = [];
WindowAdvanceMS = 100;
WindowLengthMS = 2000;
Method = 'bic';
NFold = 5;
EnergyPct = .10;
FilterType = 'lowpass';
Display = 0;
Keyboard = 0;	% Pause in debug mode?
Bayesian = 'mean';
EndPoint = 1;  %yc


FeatureString = 'sw%s_12.cep';
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
    
   case 'Priors'
    Priors = varargin{n+1}; n=n+2;
   case 'EndPoint'
       EndPoint = varargin{n+1}; n=n+2;
    
   otherwise
    error(sprintf('Bad optional argument: "%s"', varargin{n}));
  end
end

    
switch Method
 case 'bic'
  fprintf('Baseline BIC\n');
  MethodName = 'BIC';
 case 'eBic'
  MethodName = 'EB_BIC';
  fprintf('Empirical Bayes BIC\n');
 otherwise
  error(sprintf('Bad Method argument:  %s', Method));
end


% combined channels
runenv = 'dusky';
noEnd = abs(EndPoint -1); %0;
switch runenv
 case 'dusky'
      if noEnd
          melcepPath = '/cache/cheng/MelBandNoEnd/'; 
          % separated channels
          melcepPathChanSep = '/cache/cheng/MelBandAllChannelNoEnd/';
      else
          melcepPath = '/cache/cheng/MelBand/'; 
          % separated channels
          melcepPathChanSep = '/cache/cheng/MelBandAllChannel/';
      end
      
      
      windowSpacePath = '/zal/cheng/matlab/audio/tracking/automation/try/';
      ChangeTimePath = '/zal/cheng/matlab/audio/tracking/automation/changetime/';
      if Display
         outPath = '/zal/cheng/matlab/audio/tracking/automation/results24/temp/';
      else
         outPath = '/zal/cheng/matlab/audio/tracking/automation/results24/';   
      end

 case 'fruitbat'

     if noEnd
        melcepPath = '/zal/mroch/cheng/MelBandNoEnd/'; 
        % separated channels
        melcepPathChanSep = '/zal/mroch/cheng/MelBandAllChannelNoEnd/'; 
     else
        melcepPath = '/zal/mroch/cheng/MelBand/';
        melcepPathChanSep = '/zal/mroch/cheng/MelBandAllChannel/'; 
     end
      %server path no need to update
      windowSpacePath = '/zal/cheng/matlab/audio/tracking/automation/try/';
      ChangeTimePath = '/zal/cheng/matlab/audio/tracking/automation/changetime/';
      outPath = '/zal/cheng/matlab/audio/tracking/automation/results24/';
  
end

%output to file
if noEnd
    outFile= strcat(outPath,MethodName, '_', ...
                    num2str(WindowLengthMS/1000), '_',...
                    num2str(WindowAdvanceMS/1000),'_',...
                    num2str(EnergyPct),'_1', '_ne.txt');
else
    outFile= strcat(outPath,MethodName, '_', ...
                    num2str(WindowLengthMS/1000), '_',...
                    num2str(WindowAdvanceMS/1000),'_',...
                    num2str(EnergyPct),'_1','.txt');
end
out = fopen(outFile,'w');
fprintf(out, 'Test date: %s \n',datestr(date,1));


TotalHits = 0;
TotalMisses = 0;
TotalChangePoints = 0;
TotalFalsePositives = 0;

UtteranceCount = length(SourceData);

SampleRate = 1000 / WindowAdvanceMS;

% build a low-pass filter for the BIC
EdgeFreqs = [3.25,  3.5];
MagnitudeResponse = [1 0];
PassBandRippledB = 1;
StopBandAttenuationdB = 18;
DeviationPB = ...
    (10^(PassBandRippledB/20)-1)/(10^(PassBandRippledB/20)+1);
DeviationSB = 10^(-StopBandAttenuationdB/ 20);
% Estimate the design parameters
DesignParameters = remezord(EdgeFreqs, MagnitudeResponse, ...
			    [DeviationPB DeviationSB], ...
			    SampleRate, 'cell');
BPFilter = remez(DesignParameters{:});

fprintf(out, 'Test date: %s \n',datestr(date,1));
fprintf(out, ['Utterance\tWindowsLen \t Advance \t hitRate ', ...
	'\t\t missingRate \t\t falseRate \n']);

% Different types of tests    
% CH - speaker change
% OV - speaker overlap
% PA - speaker pausen
TestTypes = {'CH', 'OV', 'PA'};
TestTypeCount = length(TestTypes);

% data structures for tracking performance

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

fprintf(out, 'Window length %d MS, advance %d MS\n', ...
	WindowLengthMS, WindowAdvanceMS);


for foldindx = 1:NFold
  [TrainIndices, TestIndices] = trkNfold(foldindx, NFold, UtteranceCount);
 
  if strcmp(Method, 'eBic')
    if isempty(Priors)
      if isempty(TrainIndices)
	        error(['Unable to estimate priors without training data. Perhaps' ...
	         ' you need to use the NFold or Priors keyword' ...
		    ' arguments']);
      end
      % No prior information given, estimate
      Prior = trkEstimatePriorsNfolder(melcepPathChanSep, ... 
				        SourceData(TrainIndices), .10);  
                        %{SourceData{TrainIndices}}, .10);  
    else
      % Use provided prior information
      Prior = Priors(foldidx);
    end
  end
    
  % Process test utterances in current fold
  plotboth = 1;     % plot BIC + eBIC
  for idx = TestIndices  
    % Reset vectors for this utterance
    time = [];
    bic = [];
    Current = Current + 1;

    FileName = sprintf(FeatureString, SourceData{idx});
%    fprintf('%s\n', FileName);

    % Read the file, but do not delete the frame energy.
    % We do not use frame energy for categorization, but we do
    % use it for 
    melcep = corReadFeatureSet(sprintf('%s%s', melcepPath, FileName));
    data = melcep.Data{1};
    
    % Count of cepstrae and spacing between feature vectors
    cepLen  = size(melcep.Data{1},1);
    cepSpcMS = melcep.Attribute.CepstralSpacingMS;
    
    % Determine window length and advance for BIC/eBIC
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
       case 'bic'
	        bic(end+1) = trkBIC_nFold(segment, winoffset, EnergyPct);
	
       case 'eBic'
           if plotboth
                plotbic(end+1) = trkBIC_nFold(segment, winoffset, EnergyPct);
           end
           bic(end+1) = trkEB_BIC_nFold(segment, winoffset, ...
				     EnergyPct, Prior, Bayesian);
      end
      if noEnd   
          time(end+1) = (head+round((tail-head)/2))*cepSpcMS/1000;  %yc
      else 
          time(end+1) = ...
		       melcep.Attribute.SourceTimeSecs(head + round((tail-head)/2));  
      end
      % BIC/eBIC window advance by delta
      head = head + delta;        
      tail = head + win;                  
    end 
          
    % Filter the bic signal
    switch FilterType
     case 'median'
        MedianFilterSize = ceil(delta/2);
	    fBic = mfilt(bic, MedianFilterSize);         

     case 'lowpass'
      fBic = filter(BPFilter, 1, bic);
      Order = length(BPFilter);
      % Account for delay
      Shift = round(Order/2);
      fBic = [ fBic(Shift:end), zeros(1, Shift-1)];    
      if plotboth
          fplotBic = filter(BPFilter, 1, plotbic);
          Order = length(BPFilter);
          % Account for delay
          Shift = round(Order/2);
          fplotBic = [ fplotBic(Shift:end), zeros(1, Shift-1)];
      end
    end
    
    % find the peak and corresponding time
    %          chgptold =[];
    PeakDetector =  'simple'; %'regression'; 
    switch PeakDetector
     case 'simple'
      chgpt = trkPeakTime(fBic, time); %trkPeakTime(fBic, time);
     case 'regression'
      chgpt = time(spPeakSelector(fBic, 'RegressionOrder', 1, ...
				  'Display', 1));
     otherwise
      error(sprintf('Bad peak detector specification "%s"', PeakDetector));
    end

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
    for idx=1:length(TestTypes);
      % Find all known change points of a specific type
      TestPredicates = strcmp(Type, TestTypes{idx});
      Tests{idx} = find(TestPredicates == 1);
      
      % Test - Compute the number of hits and misses for a specific type.
      % As it is possible to have multiple hits in some regions, HitTimes
      % records the time of first hit for any given region, and
      % DupHitTimes records the duplicates.

      [HitTimes{idx}, MissTimes{idx}, DupHitTimes{idx}] = ...
	  trkAccuracy(chgpt, Front(Tests{idx}), Back(Tests{idx}), ...
		      ChangePointToleranceSecs);
      % Gather statistics
      Results.Correct(Current, idx) = length(HitTimes{idx});
      Results.CorrectAll(Current, idx) = length(DupHitTimes{idx});
      Results.Actual(Current, idx) = length(Tests{idx});

      
      % Pool all of the hits so that we can determine how many false
      % positives were detected.
      AllHitTimes = union(union(AllHitTimes, HitTimes{idx}), ...
				DupHitTimes{idx});
    end
    
    % All test types
    Results.Correct(Current, end) = sum(Results.Correct(Current, 1:end-1));
    Results.Actual(Current, end) = sum(Results.Actual(Current, 1:end-1));

    % False positives are all change points not accounted for by
    % one of the 
    FalsePositiveTimes = setdiff(chgpt, AllHitTimes);
    Results.FalsePositives(Current) = length(FalsePositiveTimes);

    fprintf(out, '%s Hits %s\tFalse + %s\n', SourceData{Current}, ...  % not correct sphere name
	    Stat(Results.Correct(Current, end), ...
		 Results.Actual(Current, end)), ...
	    Stat(Results.FalsePositives(Current), ...
		 Results.Detected(Current)));

    if Display
      figure('Name', sprintf('sw_%s', SourceData{Current}));
      % Note, for the front and back we only plot the first one
      % so that the legend will be displayed correctly (kludge!)
      
      %plot(time, bic, time, fBic, 'g--', ...
      plot(time, fplotBic, time, fBic, 'g--', ...    
	   AllHitTimes, repmat(320, length(AllHitTimes), 1), 'bp', ...
	   FalsePositiveTimes, ...
	   repmat(320, length(FalsePositiveTimes), 1), 'c+', ...
	   MissTimes{idx}, repmat(320, length(MissTimes{idx}), 1), 'rx', ...
	   [Front(Tests{1}(1)), Back(Tests{1}(1))], [290 290], 'ko', ...
	   [Front(Tests{2}(1)), Back(Tests{2}(1))], [290 290], 'k^', ...
	   [Front(Tests{3}(1)), Back(Tests{3}(1))], [290 290], 'kd');
       legend('bic', 'ebic', 'hit', 'false +', ...
	     'miss', 'change', 'overlap', 'pause');

      hold on
      % Changepoints, Overlap, Pause
      plot([Front(Tests{1}), Back(Tests{1})], [290 290], 'ko', ...
	   [Front(Tests{2}), Back(Tests{2})], [290 290], 'k^', ...
	   [Front(Tests{3}), Back(Tests{3})], [290 290], 'kd');

      for event=Tests{idx}
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
  
% Final report
fprintf(out, 'Bayesian %s\n', Bayesian);
fprintf(out, 'PeakDetector %s\n', PeakDetector);
fprintf(out, 'FilterType %s\n', FilterType);
fprintf(out, '\n');
fprintf(out, '\t\t AllCat\t\t ChangePt\t\t Overlap\t \t Pause \t\t\ False Positive\n');

Results.Misses = Results.Detected - Results.CorrectAll(:, end);


fprintf(out, 'Overall\n');

for type=[TestTypeCount+1, 1:TestTypeCount]
  fprintf(out, '%s\tt', Stat(sum(Results.Correct(:,type)), ...
		       sum(Results.Actual(:,type))));
end
fprintf(out, '%s\n', Stat(sum(Results.FalsePositives), ...
		       sum(Results.Detected)));

fprintf(out, '\nPer utterance\n');

for idx=1:UtteranceCount
  for type=[TestTypeCount+1, 1:TestTypeCount]
    fprintf(out, '%s\t', Stat(Results.Correct(idx,type), ...
			 Results.Actual(idx,type)));
  end
  fprintf(out, '%s\n', Stat(Results.FalsePositives(idx), ...
		       Results.Detected(idx)));
end

% save the results
switch Method
 case 'bic'
    save bic1.mat Results;
 case 'eBic'
    save eBIC1.mat Results;
    save eBIC_priors_100.mat Priors;
end

% ------------------------------------------------------------

% ResultString = Stat(Numerator, Denominator)
% Format string (N/D) = N/D
function String = Stat(Numerator, Denominator)

String = sprintf('(%3d/%3d)=%.2f%%', Numerator, Denominator, ...
	       Numerator / Denominator * 100);
