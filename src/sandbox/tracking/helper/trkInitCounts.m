function Results = trkInitCounts(Test, UtteranceCount)
% Results = trkInitResults(Test, UtteranceCount)
% Create a structure to track the results of segmentation experiments

% Number of correct detections for each event type
Results.Correct = zeros(UtteranceCount, Test.TypeCount+1);
% Number of duplicate detections for each event type
Results.CorrectAll = zeros(UtteranceCount, Test.TypeCount+1);
% Total number of events detected regardless of whether or
% not they were correct.  (i.e. # peaks detected)
Results.Detected = zeros(UtteranceCount, 1);
% Number of known events of each test type
% i.e. Number of known change points based upon transcription .
Results.Actual = zeros(UtteranceCount, Test.TypeCount+1);
% Number of incorrect predictions.  Not based on any
% type as we do not classify the types.
Results.FalsePositives = zeros(UtteranceCount, 1);

% More than one change point can occur within a region
% which is known to mark an acoustic change point.  This data 
% structure is a histogram of how often this occurs
MaxBin = 10;
Results.DuplicateCountRanges = [1:MaxBin,500];
Results.DuplicateCounts = zeros(length(Test.Types), length(Results.DuplicateCountRanges));
