function Search = trkDistBICRange(Window, Margin, Delta)
% Range = trkDistBICRange(Window, Margin, Delta)
% Determine indices to search within a local window subject to the given 
% no search margin
% adjust margin so that Last doesn't overlapp into First


First = Window(1) + Margin;
Last = Window(end) - Margin;
% while First >= Last
%     Margin = round(Margin/2);
%     First = Window(1) + Margin;
%     Last = Window(end) - Margin;
% end 

% uncomment the following 4 lines to see when the margin is adjusted
% if Margin < 10
%     %fprintf('Margin size has dropped:  New margin:  %d on (%d - %d)\n', ...
%      %   Margin, First, Last);
% end
Search.Range = First:Delta:Last;
% To account for a changing margin which in turn will change the search
% window, we return the new window along with the range
Search.Window = Window;

