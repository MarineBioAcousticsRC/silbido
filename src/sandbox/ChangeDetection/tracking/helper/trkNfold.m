function [Train, Test] = trkNfold(WhichFold, FoldCount, DataSetSize) 
% [Train, Test] = trkNfold(WhichFold, FoldCount, DataSetSize) 
%
% Given a specific fold (WhichFold) of an N-fold (FoldCount) test 
% with a population of DataSetSize.  Return indices 1:DataSetSize
% broken into training and test portions.
%
% Sample:
%	Suppose we have 20 objects and we wish to conduct a 3-fold test.
%
% Indices for the second fold could be produced with:
% [train, test] = trkNfold(2, 3, 20)
%
% train =  1     2     3     4     5     6     7    15    16    17    18    19    20
% test =   8     9    10    11    12    13    14	
%
% This code is copyrighted 2003-2004 by Marie Roch and Yanliang Cheng.
% e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 


error(nargchk(3,3, nargin));	% Check arguments

if DataSetSize < 1
  error('Bad DataSetSize')
end

if FoldCount < 2
  Train = [];
  Test = 1:DataSetSize;
else

  if WhichFold < 1 | WhichFold > FoldCount
    error('Bad WhichFold');
  end
  
  ItemsPerFold = round(DataSetSize/FoldCount);
  
  % Determine which items belong to the the selected FoldCount.
  
  TestStart = (WhichFold-1)*ItemsPerFold + 1;
  TestEnd = TestStart + ItemsPerFold - 1;
  if WhichFold == FoldCount
    % Last fold, depending upon rounding may be too short/long
    TestEnd = DataSetSize;
  end
  
  % Construct test indices
  Test = TestStart:TestEnd;
  
  % Construct training indices
  Train = setdiff(1:DataSetSize, Test);
end







