function Truth = trkReadTruth(Corpus, Source, Format, Test, DeltaS)
% Truth = trkReadTruth(Corpus, Source, Format)
% Read in truth table

File = corFind(Corpus, 'changepoint', sprintf(Format, Source));

[Truth.Type, Truth.Front, Truth.Back, ...
 FrontSpeaker, BackSpeaker, ...
 FrontText, BackText ] = textread(File,'%s %f %f %d %d %q %q');

% find indices into TestTypes array:  CH/OV/PA
[DontCare, Truth.TypeIndex] = ismember(Truth.Type, Test.Types);

% for debugging purposes
Truth.Indices = [Truth.Front, Truth.Back] ./ DeltaS.High;
