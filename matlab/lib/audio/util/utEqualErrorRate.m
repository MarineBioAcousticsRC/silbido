function [EER, Threshold] = utEqualErrorRate(Class0, Class1, Plot)
% [EER, Threshold] = utEqualErrorRate(Class0, Class1, Plot)
% Determines the equal error rate between classification scores for two
% column vectors.  The equal error rate is the percentage of misclassifications
% when the classification threshold is set such that both classes receive an
% equal percentage of misclassifications.  It is assume that the goal of the
% classification is to have higher scores for Class0.
%
% If no output arguments are specified or the optional Plot argument is set
% to nonzero, a plot is produced.

error(nargchk(2,3,nargin))

if nargin < 3, Plot=0; end

FitOrder = 4;			% order polynomial for polynomial fitting
Class0 = sort(Class0);		% sort data
Class1 = sort(Class1);

Size0 = length(Class0);		% number of elements
Size1 = length(Class1);
Indices0 = (1:Size0)';
Indices1 = (1:Size1)';
Indices1Rev = (Size1:-1:1)';

% determine misclassification errors
Error0 = (Indices0 - 1) / Size0;
Error1 = (Indices1Rev - 1) / Size1;

% Correct for duplicates
% Class 0 threshold >=, so when duplicates occur, copy error rate backwards
for m = utReverse(eerFindDuplicates(Class0))'
  % Note that "FOR Var = [MxN]" operates on columns, so we need
  % to transpose our column vector to a row vector.
  Error0(m) = Error0(m+1);
end
% Class 1 threshold <, copy error rates forwards
for m=eerFindDuplicates(Class1)'
  Error1(m+1) = Error1(m);
end

% estimate ROI curves
ROI0 = polyfit(Class0, Error0, FitOrder);
ROI1 = polyfit(Class1, Error1, FitOrder);

EstHigh=min(Class0(Size0), Class1(Size1));
EstLow=max(Class0(1), Class1(1));

% Find intersection
ROIDiff = ROI0 - ROI1;
Intercepts = roots(ROIDiff);
% Find real intercepts and take the first one 
InterceptIdx = find(Intercepts > EstLow & Intercepts < EstHigh ... 
    & Intercepts == real(Intercepts));
if isempty(InterceptIdx)	  % no intersection 
  % 0 or 100% EER, interpolate threshold
  if Class0(1) >= Class1(Size1)
    EER = 0;
    Threshold = mean(Class0(1), Class1(Size1));
  else
    EER = 1;
    Threshold = mean(Class0(Size0), Class1(1));
  end
else  
  Threshold = Intercepts(InterceptIdx(1));
  % compute the error rate at the intercept.
  EER = polyval(ROI1, Threshold);
end

if nargout == 0 | Plot
  cax = newplot;
  HoldState = ishold;
  
  RangeStep=500;
  EstRange0 = Class0(1):(Class0(Size0)-Class0(1))/(RangeStep*Size0):Class0(Size0);
  EstRange1 = Class1(1):(Class1(Size1)-Class1(1))/(RangeStep*Size1):Class1(Size1);
  
  EstROI0 = polyval(ROI0, EstRange0);
  EstROI1 = polyval(ROI1, EstRange1);
  
  EstROI0(find(EstROI0 > 1)) = 1;	% Clean up out of range
  EstROI1(find(EstROI1 > 1)) = 1;
  EstROI0(find(EstROI0 < 0)) = 0;
  EstROI1(find(EstROI1 < 0)) = 0;
  
  plot(EstRange0, EstROI0, 'g:');
  hold on
  plot(EstRange1, EstROI1, 'r:');
  
  plot(Class0, Error0, 'g.', Class1, Error1, 'r.');
  
  EERLine = 0:.01:EER;
  plot(Threshold(ones(length(EERLine),1)), EERLine, 'y');
  text(min(Class0(1),Class1(1)), EER, ...
      sprintf('EER %.2f%% Threshold %.3f', EER*100, Threshold));
  
  if ~HoldState, hold off, end
end

function DupIndices = eerFindDuplicates(Vector)
% DupIndices = eerFindDuplicates(Vector)
% Returns all indices N where Vector(N) == Vector(N+1)
Len = length(Vector);
Diff = [diff(Vector); 1];
DupIndices = find(Diff == 0);
