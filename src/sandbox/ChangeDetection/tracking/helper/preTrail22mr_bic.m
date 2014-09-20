function preTrial22_bic
% New trial structure for N-fold test
% This file is modified version of preTrial_CR and preTrial_FF
% Corrected the hit count to reduce false positives
% C0 is NOT used as for energy
% Counting hits threshold is set dynamically 

% function chgPt  = ...
% implementing BIC or EM BIC in speaker segmentation detection.
% The mcep is mel cepstral data extracted from speech segments
% in sphere fromat. It is the output of function 'corCreateCep(...)'
% It includes two parts 'Data' and 'Attribute'. The 'Attribute' gives 
% information on the windowing, spacing, sample rate etc when extracting
% features from a sphere file.
% Data is N by D matix of ceptral data, N represents speech length and D
% the ceptrum dimension i.e. column number. The scanning step is:
%  (1) |________| 
%  (2)     |________|
%  (3) 	       |________|
%                      ... 
%	     ->|   |<-  <=delta 
%            ->|________|<-  <=window size 
%      	  
%		 
%  (4) 
%  test: window size = 2 seconds, slid step = .05 
%
% load  ceptrum file
% the following sourcedata are of 2 female speakers
SourceData= {
        '2122'
    '2303'
    '2361'
    '2437'
    '2471'
    '2523'
    '2631'
    '2640'
    '2651'
    '2673'
    '2888'
    '2941'
    '2945'
    '2956'
    '2958'
    '2998'
    '3006'
    '3018'
    '3091'
    '3102'
    '3162'
    '3169'
    '3223'
    '3231'
    '3247'
    '3282'
    '3294'
    '3337'
    '3394'
    '3429'
    '3436'
%    '3438'
    '3522'
    '3563'
    '3588'
    '3611'
    '3641'
    '3669'
    '3679'
    '3704'
    '3719'
    '3725'
    '3755'
    '3770'
    '3779'
    '3782'
    '3809'
    '3857'
    '3880'
%    '3882'
    '3905'
    '3960'
    '3971'
    '3972'
    '3975'
    '3977'
    '4014'
    '4031'
    '4033'
    '4068'
    '4096'
    '4099'
    '4122'
    '4143'
    '4149'
    '4166'
    '4168'
    '4170'
    '4179'
    '4341'
    '4357'
    '4375'
    '4387'
    '4512'
    '4548'
    '4606'
    '4612'
    '4667'
    '4669'
    '4680'
    '4682'
    '4688'
    '4720'
    '4721'
    '4723'
    '4752'
    '4758'   
    %femal + female    
    '2022'    
    '2053'
    '2113'
    '2355'
    '2488'
    '2519'
    '2727'
    '2748'
    '2834'
    '2885'
    '2911'
    '2917'
    '2929'
    '2943'
    '2950'
    '2952'
    '2994'
    '3004'

};
% segmenting 
%melcepPath = '/zal/cheng/speech/runs/scripts/melcmu/';  % old path

% combined channels
%melcepPath = '/zal/mroch/cheng/MelBand/'; % '/zal/cheng/cache/cheng/MelBand/';
% separated channels
melcepPathChanSep = '/cache/cheng/MelBandAllChannel/'; %'/zal/cheng/cache/cheng/MelBandAllChannel/';
%Use local machine to cache data of huge volumn
melcepPath = '/cache/cheng/MelBand/';

windowSpacePath = '/zal/mroch/matlab/audio/tracking/automation/try/';
ChangeTimePath = '/zal/mroch/matlab/audio/tracking/automation/changetime/';
outPath = '/zal/mroch/matlab/audio/tracking/automation/results22_mr/';

% Randomly permute the 102 cepstrums and get the new order permute102
regroup = 0
if regroup 
    permute102 = randperm(102);
    save permute102 permute102;
else
    load permute102;
end
% N-fold testing, 
nfold = 5;
testlen = floor(length(permute102)/nfold);
testdata = {};
priordata = {};

TotalHits = 0;
TotalMisses = 0;
TotalChangePoints = 0;
TotalFalsePositives = 0;
for i = 1:nfold
    testdata{i} = SourceData(permute102((i-1)*testlen+1: i*testlen));
    priordata{i} = setdiff(SourceData, testdata{i});    
end
	
%try...
setFile = strcat(windowSpacePath, 'trial22.csv');
[WindowsLengthMS, AdvanceMS] = textread(setFile,' %d %d %*[^\n]','delimiter',',', 'headerlines', 1); 

BIC = 1
if BIC          
    method = 'bic';
else    
    method = 'eBic';    % THIS PART DOES NOT WORK YET
    % Compute priors for each individual fold to compute eBIC, 
	% !!!!! and save [alphMB, betaMB, muMB, tauMB] IN ORDER, ONE FOLD ONE ROW
	priors = {};  %(nfold,4);
	for fold = 1:nfold  
	    [alphMB, betaMB, muMB, tauMB] = trkEstimatePriorsNfolder(melcepPathChanSep, priordata{fold}, .10); 
		priors{end+1} = alphMB;  % fold*(nfold-1)+1}
        priors{end+1} = betaMB;
        priors{end+1} = muMB;
        priors{end+1} = tauMB;	
    end
end


% Try different size of windows and advaces
winNumtested = size(WindowsLengthMS, 1);
for winsize = 1 %1:winNumtested
    % the output file with test setting
    
    outFile= strcat(outPath,method,'_',  num2str(WindowsLengthMS(winsize) /1000),...
                    '_',  num2str(AdvanceMS(winsize) /1000),'.txt');
    SampleRate = 1000 / AdvanceMS(winsize);
    out = fopen(outFile,'w');
    fprintf(out, 'Test date: %s \n',datestr(date,1));
    fprintf(out, 'sphereFile \t WindowsLen \t Advance \t hitRate \t\t missingRate \t\t falseRate \n');
    
    % build a low-pass filter for the BIC
    EdgeFreqs = [2,  2.25];
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
    
    % To hold hit, miss and false rates for all cepstrum in each fold
    hitRates = [];
    falseRates = [];
    for foldindx = 1:nfold
        testdata{foldindx} = SourceData(permute102((foldindx-1)*testlen+1: foldindx*testlen));        
		% process the melCep files in each fold
		for cepindx = 1:size(testdata{foldindx}) %SourceData)
          fprintf('Processing sw %s \n', testdata{foldindx}{cepindx}); % SourceData{ind}); 
          %melcepPath = '/zal/cheng/matlab/audio/tracking/automation/melcmu/';
          melcepFile = strcat(melcepPath, 'sw', testdata{foldindx}{cepindx}, '_12.cep');
          melcep = corReadFeatureSet(melcepFile); 
         
          % Frame enegy is kept in data
          data = melcep.Data{1};
         
          cepLen  = size(melcep.Data{1},1); 			% # row of ceptrum matrix
          cepSpc = melcep.Attribute.CepstralSpacingMS;  	% Cep spacing in milliseconds
		
          % parameters for calculating BIC/eBIC
          win = floor(WindowsLengthMS(winsize)/ cepSpc);   % window size for a BIC/eBIC
          delta = floor(AdvanceMS(winsize) / cepSpc);      % advace for BIC/eBIC      
          fprintf('Window length %d, advance %d\n', win, delta);
          
          %!!!!!!! Time consuming using this data structure 
          % whenever a new data added, relocate/delocate memory once
          time = [];
          ebic = [];
          bic = [];  
          
          % interval head, initial value for start point for first window
          head = 1; 
          % interval tail, initial value for stop point for first window	        	
          tail = head + win;		

          % In computing BIC/eBIC, half of window size are used as dividing point for fixed window 
          % or for first round of dynamical window      
          winoffset = floor(win/2);
          
          % calculate BIC of EBIC, here index coupling BIC/eBIC values with corresponding time
          % A struct will be better to store them pair by pair
          while tail <= cepLen      
              segment = data(head:tail, :); 
              if BIC
                  winoffset = round((tail-head)/2);
                  bic(end+1) = trkBIC_nFold(segment, winoffset);   
              else
                  winoffset = round((tail-head)/2);
                  ebic(end+1) = trkEB_BIC_nFold(segment, winoffset,...   %alphMB, betaMB, muMB, tauMB);
                               priors{(foldindx-1)*nfold+1}, priors{(foldindx-1)*nfold+2},...
                               priors{(foldindx-1)*nfold+3}, priors{(foldindx-1)*nfold+4});
              end    
              time(end+1) = melcep.Attribute.SourceTimeSecs(head + round((tail-head)/2));       
              % BIC/eBIC window advance by delta
              head = head + delta;        
              tail = head + win;                  
          end 
          
          % mean or non-linear filtering
	  FilterType = 'lowpass';
	  switch FilterType
	    case 'median'
	     MedianFilterSize = ceil(delta/2);
	     if BIC
	       fBic = mfilt(bic, MedianFilterSize);         
	     else % ebic
	       fBic = mfilt(ebic, MedianFilterSize); 
	     end
	   case 'lowpass'
	    fBic = filter(BPFilter, 1, bic);
	    Order = length(BPFilter);
	    % Account for delay
	    Shift = round(Order/2);
	    fBic = [ fBic(Shift:end), zeros(1, Shift-1)];
	  end

          % find the peak and corresponding time
	  PeakMethod = 'simple';
	  switch PeakMethod
	   case 'simple'
	    chgpt = trkPeakTime(fBic, time);
	   case 'regression'
	    chgpt = time(spPeakSelector(fBic, 'RegressionOrder', 2, ...
					'Display', 0));
	  end
       
          % compare time and computate the rates
          mrkTimeFile = strcat(ChangeTimePath, 'spidre_sw', testdata{foldindx}{cepindx}, '.csv');
          [Front, Back] =...
                textread(mrkTimeFile,'%f %f %*[^\n]','delimiter',',', 'headerlines', 1); 
          % reset hit count each round
          threshold = 0.2;
	  %          [hitRate, missRate, falseRate] = trkCalculateRates(chgpt, Front, Back, threshold)
	  [FirstHitTimes, MissTimes, AllHitTimes] = ...
	      trkAccuracy(chgpt, Front, Back, threshold);
	  
	  hits = length(FirstHitTimes);
	  misses = length(MissTimes);

	  FalsePositiveTimes = setdiff(chgpt, AllHitTimes);
	  FalsePositives = length(FalsePositiveTimes);

	  hitRate = hits / (hits + misses);
	  missRate = 1 - hitRate;
	  falseRate = FalsePositives / length(chgpt);
	  TotalHits = TotalHits + hits;
	  TotalMisses = TotalMisses + misses;
	  TotalFalsePositives = TotalFalsePositives + FalsePositives;
	  TotalChangePoints = TotalChangePoints + length(chgpt);
	  
	  fprintf('%d changepoints:  Hit %f, False Pos %f\n', ...
		  length(Front), hitRate, falseRate);
	  fprintf(out, 'sw%s \t\t %d \t\t\t %d \t\t %f \t\t %f \t\t %f \n',... 
                testdata{foldindx}{cepindx}, WindowsLengthMS(winsize),AdvanceMS(winsize),...
                hitRate, missRate, falseRate);

          % save every rates for overall rates average
          hitRates(end+1) = hitRate;        %To calculate mean for each fold
          falseRates(end+1) = falseRate;    %To calcualte mean for for each fold          
	  Display = 1;
          if Display
            figure('Name', sprintf('sw_%s', testdata{foldindx}{cepindx}));
            plot(time, bic, time, fBic, ...
		 Front, repmat(290, length(Front), 1), 'k>', ...
		 Back, repmat(290, length(Back), 1), 'k<', ...
		 MissTimes, repmat(320, length(MissTimes), 1), 'rv', ...
		 AllHitTimes, repmat(320, length(AllHitTimes), 1), 'gv', ...
		 FalsePositiveTimes, ...
		 repmat(320, length(FalsePositiveTimes), 1), 'ms');
		
	    
	    title(sprintf('changepoints - %d/%d correct (%f)', ...
			  hits, hits+misses, hitRate));
	    legend('bic', 'filt bic', 'front', 'back', ...
		   'miss', 'hit', 'false +')
          end

      end% end loop ceptsrae
  end  % end the loop for folds
  fprintf(out, 'cepstrum mean \t\t  \t\t\t \t\t %f \t\t %f \t\t %f \n',... 
                mean(hitRates), 1-mean(hitRates), mean(falseRates));          
  OverallHitRate = TotalHits / (TotalHits + TotalMisses);
  OverallMissRate = TotalMisses / (TotalHits + TotalMisses);
  OverallFalsePositiveRate = TotalFalsePositives / TotalFalseChangePoints;
  fprintf(out, 'Overall  \t\t  \t\t\t \t\t %f \t\t %f \t\t %f \n',...
                OverallHitRate, OverallMissRate, OverallFalsePositiveRate);
  fclose(out);    
end % end loop for diff win/advance

