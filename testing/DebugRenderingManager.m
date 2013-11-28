classdef DebugRenderingManager < handle
   properties
      handles;
      thr;
      
      new_peak_handles;
      active_set_peak_handles;
      orphan_set_peak_handles;
      status_marker_handle;
      broadband_peak_handles;
      active_graph_handles;
      orphan_graph_handles;
      
      subgraphs_closed;
      
      cmap;      
   end % properties
   
   methods
      function cb = DebugRenderingManager(handles, thr)
          cb.handles = handles;
          cb.thr = thr;
          
          cb.new_peak_handles = [];
          cb.active_set_peak_handles = [];
          cb.orphan_set_peak_handles = [];
          cb.broadband_peak_handles = [];
          cb.active_graph_handles = [];
          cb.orphan_graph_handles = [];
          
          cb.subgraphs_closed = 0; 
          
          cb.cmap = [[0 1 1];[1 0 1]];
      end
      
      function blockStarted(cb, spectrogram, start_s, end_s)
          
      end % process_block_begin
      
      function blockCompleted(cb)
          if (cb.status_marker_handle > 0)
              delete(cb.status_marker_handle);
              cb.status_marker_handle = -1;
          end
          
          if ~ isempty(cb.new_peak_handles)
              delete(cb.new_peak_handles);     % remove plots from last iteration
              cb.new_peak_handles = {};
          end
          
          drawnow update;
      end % block_completed
      
      function frameAdvanced(cb, current_s)
          if (cb.status_marker_handle > 0)
               delete(cb.status_marker_handle);
          end
          
          if (~isempty(cb.new_peak_handles))
              delete(cb.new_peak_handles);
              cb.new_peak_handles = [];
          end
          
          cb.status_marker_handle = ...
              plot(cb.handles.progressAxes, ... 
                  [current_s current_s], ...
                  [0,1],...
                  'g-');
          set(cb.handles.progressAxes, 'xlim', get(cb.handles.spectrogram, 'xlim'));
          set(cb.handles.timeField, 'String', sprintf('%fs', current_s));
          drawnow update;
      end
      
      function handleBroadbandFrame(cb, current_s)
          cb.broadband_peak_handles(end+1) = ...
              plot(cb.handles.progressAxes, ...
                  [current_s current_s], ...
                  [0,1], ...
                  'm-');
          drawnow update;
      end
      
      function handleFramePeaks(cb, current_time, peaks)
          % Plot the peaks that were just detected.
          cb.new_peak_handles = plot(...
              current_time(ones(size(peaks))),...
              peaks/1000, ...
              'r^');
          
          drawnow update;
      end
      
      function handleActiveSetExtension(cb, active_set)
          if (~isempty(cb.active_graph_handles))
              delete(cb.active_graph_handles);
              cb.active_graph_handles = [];
          end
          
          if (~isempty(cb.active_set_peak_handles))
              delete(cb.active_set_peak_handles);
              cb.active_set_peak_handles = [];
          end
          
          if (~isempty(cb.orphan_graph_handles))
              delete(cb.orphan_graph_handles);
              cb.orphan_graph_handles = [];
          end
          
          if (~isempty(cb.orphan_set_peak_handles))
              delete(cb.orphan_set_peak_handles);
              cb.orphan_set_peak_handles = [];
          end
          
          cb.active_graph_handles = cb.plot_graph(...
               active_set.getActiveSet(), ...
               '-',2);
           
            % Plot the peaks that are currently in the active set.
          cb.active_set_peak_handles = plot(...
              active_set.getActiveSet().get_time(), ...
              active_set.getActiveSet().get_freq/1000, ...
              'g*');

          cb.orphan_graph_handles = cb.plot_graph(...
              active_set.getOrphanSet(), ...
              '-',1);
           
          % Plot the peaks that are currently in the orphan set.
          cb.orphan_set_peak_handles = plot(...
              active_set.getOrphanSet().get_time(), ...
              active_set.getOrphanSet().get_freq/1000, ...
              'y*');
           
          % Check for any new subgraphs as a result of pruning
          prev_closed = cb.subgraphs_closed;
          cb.subgraphs_closed = active_set.getResultGraphs().size();
          if  cb.subgraphs_closed > prev_closed
              % plot out the new closed off subgraphs
              % we don't save their handles as we aren't
              % planning on deleting them (yet at least)
              for k = prev_closed:(cb.subgraphs_closed-1)
                  g = active_set.getResultGraphs().get(k);
                  dtPlotGraph(g, ...
                      'ColorMap', cb.cmap, 'LineStyle', '-', ...
                      'ColorIdx', 1, 'Marker', '.', ...
                      'DistinguishEdges', false);
              end
          end
           
          drawnow update;
      end
      
      function clearAll(cb)
          if (cb.status_marker_handle > 0)
              delete(cb.status_marker_handle);
              cb.status_marker_handle = -1;
          end
          
          if (~isempty(cb.new_peak_handles))
              delete(cb.new_peak_handles);     % remove plots from last iteration
              cb.new_peak_handles = {};
          end
          
          if (~isempty(cb.broadband_peak_handles))
              delete(cb.broadband_peak_handles);     % remove plots from last iteration
              cb.broadband_peak_handles = [];
          end
          
          if (~isempty(cb.active_graph_handles))
              delete(cb.active_graph_handles);
              cb.active_graph_handles = [];
          end
          
          if (~isempty(cb.active_set_peak_handles))
              delete(cb.active_set_peak_handles);
              cb.active_set_peak_handles = [];
          end
          
          if (~isempty(cb.orphan_graph_handles))
              delete(cb.orphan_graph_handles);
              cb.orphan_graph_handles = [];
          end
          
          if (~isempty(cb.orphan_set_peak_handles))
              delete(cb.orphan_set_peak_handles);
              cb.orphan_set_peak_handles = [];
          end
      end
      
      function handles = plot_graph(cb, set, style, colorixd)
        % Given a tfTressSet set, create the subgraph associated with each
        % node and plot it.  Nodes attached to the same subset will only
        % be plotted once.  
        % cmap is a colormap, and coloridx is the next color to plot.  
        % coloridx is incremented modulo the # of entries in the colormap
        % and returned on exit along with a cell array of handles for each
        % subgraph that is plotted.

        import tonals.*;

        handles = [];
        piter = set.iterator();

        seen = [];
        while piter.hasNext();
            p = piter.next();
            % only plot if there's something attached to this.
            if p.chained_backward()
                % check if we have already plotted the
                % graph associated with this peak
                need_plot = true;
                for k=1:length(seen)
                    if p.ismember(seen{k})
                        need_plot = false;
                    end
                end
                if need_plot
                    % Store the set associated with this one
                    seen{end+1} = p.find();
                    g = graph(p);
                    [newh, ~] = dtPlotGraph(g, ...
                        'ColorMap', cb.cmap, 'LineStyle', style, ...
                        'ColorIdx', colorixd, ...
                        'DistinguishEdges', false);
  
                    handles = [handles, newh{:}];
                end
            end
        end
      end
   end% methods
end% classdef