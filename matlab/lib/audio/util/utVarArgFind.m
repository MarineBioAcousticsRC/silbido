function Position = utVarArgFind(Name, Args)
% Index = utVarArgFind(Name, CellArrayOfArgumentNames)
% Given a set of named arguments in the format name, value,
% find the index of the name, value pair starting at Name.
% If no such argument exists, return 0.
%
% Examples:
%	>> utVarArgFind('Duration', {'Delta', 1, 'Duration', 40})
%	ans = 3
%
%	>> utVarArgFind('Duration', {'Delta', 1})
%	ans = 0
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

Position = 0;
Index = 1;
while ~ Position & Index < length(Args)
  if strcmp(Args{Index}, Name)
    Position = Index;
  else
    Index = Index + 2;
  end
end
