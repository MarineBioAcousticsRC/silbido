function [Head, Tail] = utHeadTail(CellArray)
% [Head, Tail] = utHeadTail(CellArray)
%
% List processing, returns first item of a cell array and the remainder
% of the list, much like head/tail or car/cdr in Common LISP.
%
% The Head and Tail of an empty cell arrays are defined as empty cell
% arrays.
%
% This code is copyrighted 2004 by Marie Roch.
% e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 


if iscell(CellArray)
  N = length(CellArray);
  if N
    Head = CellArray{1};
  else
    Head = {};
  end
    
  if N < 2
    % empty tail
    Tail = {};
  else
    Tail = {CellArray{2:end}};
  end
end

    
  
