function [Sorted, ndx] = sortrecords(Unsorted, RecordName)
% [Sorted, ndx] = sortrecords(Unsorted, RecordName)
% Assuming that Unsorted is a vector of records with RecordName,
% sorts the records based on the field contained in RecordName.
%
% Warning:  The record type of record RecordName must be a type 
% which is handled by sort.  Also, the field must be homogeneous
% across the array.  This prevents the sorting of variable length
% strings.

if nargin < 2
  error('Not enough input arguments.');
end

if ~ ischar(RecordName)
  error('RecordName must contain a string');
else
  if ~ isfield(Unsorted, RecordName)
    error(['Record <', RecordName, '> does not exist.']);
  end
end

% preallocate
Keys = repmat(getfield(Unsorted(1), RecordName), [1, size(Unsorted, 2)]); 

for i = 1:size(Unsorted, 2)
  % extract key field
  Keys(i) = getfield(Unsorted(i), RecordName);
end

[gigo, ndx] = sort(Keys);

Sorted = Unsorted;	% preallocate
for i = 1:size(Unsorted, 2)
  Sorted(i) = Unsorted(ndx(i));
end
