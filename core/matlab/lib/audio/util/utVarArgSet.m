function Args = utVarArgSet(Name, Value, Args)
% VarArgs = utVarArgSet(Name, Value, CellArrayOfArgumentNames)
% Given a set of named arguments in the format name, value,
% update the value of argument Name to Value.
%
% Example:
%	>> utVarArgSet('Duration', 30, {'Delta', 1, 'Duration', 40})
%	ans = {'Delta', 1, 'Duration', 30}
%
% If the argument is not present in Args, it is added:
%	>> utVarArgSet('Duration', 30, {'Delta', 1})
%	ans = {'Delta', 1, 'Duration', 30}
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

if ~ Position
  % Wasn't found, set Position to one past end and populate name
  Position = length(Args) + 1;
  Args{Position} = Name;
end

Args{Position+1} = Value;	% set value 

