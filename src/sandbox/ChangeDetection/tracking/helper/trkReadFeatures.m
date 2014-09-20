function [features, spacingMS] = trkReadFeatures(Corpus, Id, ...
                                                 Format, FeatureString)
% features, spacingMS = trkReadFeatures(Corpus, Id, Format, FeatureString)
% Read feature Id from the specified Corpus.
% Id is formatted sprintf formatting in the optional  FeatureString 
% Format is either htk or sands.
%
% Feature data is returned in features, the time in MS between
% the start of each feature is returned in spacingMS.

if nargin < 4
  FeatureString = '%s';
end

Verbose = 0;    % debug support
% Locate the file
FileName = corFind(Corpus, 'feature', ...
                   sprintf(FeatureString, Id));

if Verbose
  fprintf('Resolved filename:  "%s"\n', FileName);
end

if isempty(FileName)
  warning('No such file: %s', FileName) 
  features = [];        % unable to read
else
  switch Format
   case 'htk'
    [features, info] = spReadFeatureDataHTK(FileName);
    if info.O
      % MFCC 0 included, move position
      features = [features(end,:); features(1:end-1, :)];
      features = features';   % Each column is a feature
    end
    spacingMS = info.CepstralSpacingMS;
      
   case 'matlab'
    melcep = corReadFeatureSet(FileName);
    features = melcep.Data{1};
    % spacing between feature vectors in MS
    spacingMS = melcep.Attribute.CepstralSpacingMS;
   otherwise
    error('Bad feature format %s', Format)
  end
end
