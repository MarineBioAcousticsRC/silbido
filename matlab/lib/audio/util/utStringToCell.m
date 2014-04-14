function Cells = utStringToCell(String)
% Cells = utStringToCell(String)
% Given a string, separate it into a cell array of white space
% separated tokens.

Cells = cell(0);

[Token, Remaining] = strtok(String);
while ~ isempty(Token)
  Cells{end+1} = Token;
  [Token, Remaining] = strtok(Remaining);
end

