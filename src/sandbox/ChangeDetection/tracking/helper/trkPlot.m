function trkPlot(New, maxidx, time, Search, bic, Test, Truth, Sec ,Compare)
% trkPlot(time, Search, bic, Test, Truth, Sec)
% Used for plotting comparing graph with thicker line
% Sec is a variable used for trkIndices
% Compare used when comparing two plots.
% If Compare = 1 then it will plot that plot with a thicker line else set
% Compare = 0, so it will plot the plot as before

persistent Handles;     
persistent LineType;

Center = 0;

if New
  clf
  Handles = [];
  LineType = 0;
  return
else
  % erase truth information from last plot
  if ~ isempty(Handles)
    for k=1:length(Handles)
      delete(Handles(k))
    end
    Handles = [];
  end
end

LineType = mod(LineType, length(Test.BICLines)) + 1;
%plot(time(Search.Range), bic, Test.BICLines{LineType});
if Compare == 1
    plot(time(Search.Range), bic, Test.BICLines{LineType}, 'LineWidth',2);
else
    plot(time(Search.Range), bic, Test.BICLines{LineType});
end
hold on
% Show changepoint if found
if ~isempty(maxidx)
   bicidx = find(Search.Range == maxidx);
   if Compare ==1
   plot(time(maxidx), bic(bicidx), 'r*', 'LineWidth', 2);
   else
     plot(time(maxidx), bic(bicidx), 'r*');
   end
end;

Start = time(Search.Window(1)) - Test.ToleranceS;
Stop = time(Search.Window(2)) + Test.ToleranceS;
if Center
  set(gca, 'XLim', [Start, Stop])
end
Elevation = max(bic)*1.1;

% plot known events in the window


[FrChg, BkChg, ChgType] = trkFindIndices(Truth.Front, Truth.Back, Sec, Start, Stop);
if length(FrChg) > length(BkChg)
    LChg = length(BkChg);
else
    LChg = length(FrChg);
end
for k=1:LChg
  switch ChgType(k)
   case -1
    % ends in region
    Left = Start;
    Right = Truth.Back(BkChg(k));
    Handles(end+1) = ...
        plot(Right, Elevation, Test.TypeSymbols{Truth.TypeIndex(BkChg(k))});
    %Handles(end+1) = ...
    if(k == LChg)
       plot(Truth.Back(BkChg(end)), Elevation, Test.TypeSymbols{Truth.TypeIndex(BkChg(end))});
    end
   case 0
    % contained in region
    Left = Truth.Front(FrChg(k));
    Right = Truth.Back(BkChg(k));
    Handles(end+1) = ...
        plot([Left, Right], Elevation([1 1]), ...
             Test.TypeSymbols{Truth.TypeIndex(FrChg(k))});
   case 1
    % starts in region
    Left = Truth.Front(FrChg(k));
    Right = Stop;
    Handles(end+1) = ...
        plot(Left, Elevation, Test.TypeSymbols{Truth.TypeIndex(FrChg(k))});
    %Handles(end+1) = ...
    if(k == LChg)
       plot(Truth.Front(FrChg(end)), Elevation, Test.TypeSymbols{Truth.TypeIndex(FrChg(end))});
    end
  end
  Handles(end+1) = plot([Left, Right], Elevation([1 1]), 'k-');
end




