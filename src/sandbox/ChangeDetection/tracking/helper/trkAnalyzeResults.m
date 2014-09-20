function Results = trkAnalyzeResults(Id, ProposedTimes, Truth, Test, Results)

out = 1;
AllHitTimes = [];
AllMissTimes = [];

% Per category statistics
for test=1:length(Test.Types);

  % Find all known change points of a specific type
  Predicates = strcmp(Truth.Type, Test.Types{test});
  Tests{test} = find(Predicates == 1);
      
  % Test - Compute the number of hits and misses for a specific type.
  % As it is possible to have multiple hits in some regions, HitTimes
  % records the time of first hit for any given region, and
  % DupHitTimes records the duplicates.
  
  [HitTimes{test}, MissTimes{test}, DupHitTimes{test}, TestDupCounts] = ...
      trkAccuracy(ProposedTimes, Truth.Front(Tests{test}), Truth.Back(Tests{test}), ...
                  Test.ToleranceS);
  % Gather statistics
  Results.Correct(Id, test) = length(HitTimes{test});
  Results.CorrectAll(Id, test) = length(DupHitTimes{test});
  Results.Actual(Id, test) = length(Tests{test});
  if ~ isempty(TestDupCounts)
    % determine histogram for this test, converting to a row
    % vector if necessary.
    histogram = ...
        utVectorCheck(histc(TestDupCounts, Results.DuplicateCountRanges), 1);
        Results.DuplicateCounts(test,:) = Results.DuplicateCounts(test,:) + histogram;
  end
  
  % Pool all of the hits so that we can determine how many false
  % positives were detected.
  AllHitTimes = union(union(AllHitTimes, HitTimes{test}), ...
                      DupHitTimes{test});
  AllMissTimes = union(AllMissTimes, MissTimes{test});
end

    
% All test types
Results.Correct(Id, end) = sum(Results.Correct(Id, 1:end-1));
Results.Actual(Id, end) = sum(Results.Actual(Id, 1:end-1));

% Determine times at which false positives occurred
FalsePositiveTimes = setdiff(ProposedTimes, AllHitTimes);
Results.FalsePositives(Id) = length(FalsePositiveTimes);

