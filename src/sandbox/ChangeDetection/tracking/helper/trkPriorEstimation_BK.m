function Prior = trkPriorEstimation(melcepPath,  SourceData, ...
				    RemoveNPct)

% function Prior =trkPriorEstimation(melcepPath, SourceData,RemoveNPct)
% calculate gamma distribution parameter ...
% The output data are saved as alphMB, betaMB, muMB, tauMB in file
% priorsMB.mat in directory  .../automation
% --------------------------------------------------------------------
% The gamma distribution is:
%  E(R) = A/B
%  V(R) = A/(B*B)
%  E(M) = U
%  V(M) = B/(A-1)/T
% suppose 'mat' has n columns (c1, ..., Cn) which represent
% the n dimensions (components) of the cepstrum; and its row number is 
% corresponding to the lenghth of speech segment
ondusky = 1;
if ondusky
    melcepPth ='/cache/cheng/MelBandAllChannel/';
end

melcep ={};

WithEnergy = 0;

SpeakerCount = length(SourceData);
Channels = 'ab';
FormatString = [melcepPath, 'sw%s%c_12.cep'];
FirstTime = 1;

SegmentLength =1600;	% N seconds
SegmentIdx = 0;
for i = 1:SpeakerCount
  for channel = 1:length(Channels)	% Handle each channel separately
    FeatureFile = sprintf(FormatString, SourceData{i}, Channels(channel));
    Feature = corReadFeatureSet(FeatureFile);
    [FeatureVectorsN, Components] = size(Feature.Data{1});
    
    % Find and remove lowest N % with respect to energy
    if RemoveNPct
      [EnergyValues EnergyIndices] = sort(Feature.Data{1}(:,1));
      BottomNPct = round(RemoveNPct * FeatureVectorsN);
      Feature.Data{1}(EnergyIndices(1:BottomNPct), :) = [];
    end

    % Do we still need energy?
    if ~ WithEnergy
      Feature.Data{1}(:,1) = [];	% Remove energy
      Components = Components - 1;
    end
    
    if FirstTime
      FirstTime = 0;
      Means = zeros(SpeakerCount * length(Channels), Components);
      Variances = zeros(SpeakerCount * length(Channels), Components);
    end
    
    % Step through the features SegmentLength features at a time
    % and compute the trace of each block's variance-covariance matrix.
    Start = 1;  End = SegmentLength;
    while End < size(Feature.Data{1}, 1)
      SegmentIdx = SegmentIdx + 1;
      SegmentTrace(SegmentIdx) = sum(var(Feature.Data{1}(Start:End,:)));
      Start = Start + SegmentLength;
      End = End + SegmentLength;
    end

    Means((i-1)* length(Channels) + channel, :) = mean(Feature.Data{1});
    Variances((i-1)* length(Channels) + channel, :) = var(Feature.Data{1});
  end
end

TracesEntireUtterance = sum(Variances, 2);

% Take average of each component's variance as E(R)
% Take variance of all the component's variance as V(R)
meanR = mean(Variances);
varianceR = var(Variances);

% Compute alph (A) and beta (B) according to the equations above
beta = meanR ./ varianceR;
alpha  = beta .* meanR;
mu = mean(Means);
tau = beta ./ ((alpha - 1) .* var(Means));

% Package into structure
Prior.alpha = alpha;
Prior.beta = beta;
Prior.mu = mu;
Prior.tau = tau;
save prior16sSeg.mat Prior