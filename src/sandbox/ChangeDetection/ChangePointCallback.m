classdef ChangePointCallback < handle
   properties
      bicAxes;
      changesAxes;
      handles;
   end % properties
   
   methods
      function cb = ChangePointCallback(bicAxes, changesAxes)
          cb.bicAxes = bicAxes;
          cb.changesAxes = changesAxes;
          cb.handles = [];
      end
      
      function onCandidateLowRes(cb, times, bic)
          h = plot(cb.bicAxes, times, bic, 'b');
          cb.handles = [cb.handles, h];
      end
      
      function onNoCandidateLowRes(cb, times, bic)
          h = plot(cb.bicAxes, times, bic, '--c');
          cb.handles = [cb.handles, h];
      end
      
      function onUnconfirmedHighRes(cb, times, bic)
          h = plot(cb.bicAxes, times, bic, 'r');
          cb.handles = [cb.handles, h];
      end
      
      function onConfirmedHighRes(cb, times, bic)
          h = plot(cb.bicAxes, times, bic, 'g');
          cb.handles = [cb.handles, h];
      end
      
      function clearRendering(cb)
          for idx = 1:length(cb.handles)
              delete(cb.handles(idx));
          end
          cb.handles = [];
      end
      
      function updateChanges(cb, changes)
          lim = ylim(cb.changesAxes);
          lim2 = ylim(cb.bicAxes);
          %cla(cb.changesAxes);
          for idx = 1:length(changes)
              h = plot(cb.changesAxes, ... 
                  [changes(idx) changes(idx)], ...
                  lim,...
                  'c-');
              cb.handles = [cb.handles, h];
              
              h = plot(cb.bicAxes, ... 
                  [changes(idx) changes(idx)], ...
                  lim2,...
                  'c-');
              cb.handles = [cb.handles, h];
          end
      end
   end% methods
end% classdef