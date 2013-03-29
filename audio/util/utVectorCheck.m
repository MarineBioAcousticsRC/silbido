function Vector = utVectorCheck(Vector, Direction)
% Vector = utVectorCheck(Vector, Direction)
% Checks if input Vector is really a vector.  The function returns an empty
% vector if the input function is not a vector.  If the optional Direction
% is present, will convert to a column or row vector if possible.
%	Direction:  0 => column vector, 1 => row vector

error(nargchk(1,2,nargin))

[Rows, Cols] = size(Vector);

if Rows ~= 1 & Cols ~= 1
  Vector = [];		% Matrix, return empty
end

if nargin > 1
  if (Direction & Rows > 1) | (~Direction & Cols > 1)
    Vector = Vector';
  end
end

  
