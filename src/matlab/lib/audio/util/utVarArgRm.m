function Args = utVarArgRm(Name, Args)
% VarArgs = utVarArgRm(Name, CellArrayOfArgumentNames)
% Given a set of named arguments in the format name, value,
% remove argument Name and its corresponding value from the 
% list.
%
% Example:
%	>> utVarArgRm('Duration', {'Delta', 1, 'Duration', 40})
%	ans = {'Delta', 1}
%
% It is assumed that all items are pairs of named arguments and their
% values.
%
% This code is copyrighted 2002 by Marie Roch.
% e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 

Position = utVarArgFind(Name, Args);

if Position
  Args(Position:Position+1) = [];
end
