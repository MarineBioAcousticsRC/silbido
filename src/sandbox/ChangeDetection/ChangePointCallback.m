classdef ChangePointCallback < handle
   properties
      bicAxes;
      changesAxes;
   end % properties
   
   methods
      function cb = ChangePointCallback(bicAxes, changesAxes)
          cb.bicAxes = bicAxes;
          cb.changesAxes = changesAxes;
      end
      
      function onCandidateLowRes(cb, times, bic)
          plot(cb.bicAxes, times, bic, 'b');
      end
      
      function onNoCandidateLowRes(cb, times, bic)
          plot(cb.bicAxes, times, bic, '--c');
      end
      
      function onUnconfirmedHighRes(cb, times, bic)
          plot(cb.bicAxes, times, bic, 'r');
      end
      
      function onConfirmedHighRes(cb, times, bic)
          plot(cb.bicAxes, times, bic, 'g');
      end
      
      function updateChanges(cb, changes)
          lim = ylim(cb.changesAxes);
          %cla(cb.changesAxes);
          for idx = 1:length(changes)
              plot(cb.changesAxes, ... 
                  [changes(idx) changes(idx)], ...
                  lim,...
                  'c-');
          end
      end
   end% methods
end% classdef