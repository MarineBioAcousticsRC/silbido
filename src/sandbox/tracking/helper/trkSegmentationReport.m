function trkSegmentationReport(Results, CategoryLabels)
% Given a segmentation results structure:
%	Actual(UtteranceIdx, TestType) - How many change points of
%		the specfied type should have been detected?
%	Correct(UtteranceIdx, TestType) - How many segments of type
%		TestType were counted as correct?
%	FalsePositives(UtteranceIdx) - How many false positives
%		were reported for each utterance?  (The proposed
%		change point was not any of the known categories.)

[Utterances, TestTypes] = size(Results.Actual);

% Overall
for type=1:TestTypes
  
end

% per utterance
for u=1:Utterances
  for type=1:TestTypes
  end
end
