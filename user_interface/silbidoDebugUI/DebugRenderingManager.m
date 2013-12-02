classdef DebugRenderingManager < handle
   properties
      handles;
      thr;
      
      new_peak_handles;
      active_set_peak_handles;
      orphan_set_peak_handles;
      status_marker_handle;
      progress_handles;
      active_graph_handles;
      orphan_graph_handles;
      breakpoint_handles;
      fit_plot_handles;
      graph_handles;
      
      fit_plots_enabled;
      
      subgraphs_closed;

      graph_cmap;
      graph_cmap_idx;
   end % properties
   
   methods
      function cb = DebugRenderingManager(handles, thr)
          cb.handles = handles;
          cb.thr = thr;
          
          cb.new_peak_handles = [];
          cb.active_set_peak_handles = [];
          cb.orphan_set_peak_handles = [];
          cb.progress_handles = [];
          cb.active_graph_handles = [];
          cb.orphan_graph_handles = [];
          cb.fit_plot_handles = [];
          cb.breakpoint_handles = [];
          cb.graph_handles = [];
          
          cb.subgraphs_closed = 0; 

          cb.graph_cmap = hsv(20);
          cb.graph_cmap = cb.graph_cmap(randperm(20), :);
          
          cb.fit_plots_enabled = false;
          cb.graph_cmap_idx = 1;
          
      end
      
      function blockStarted(cb, ~, start_s, end_s)
          set(cb.handles.blockStartTimeField, 'String', sprintf('%.5fs', start_s));
          set(cb.handles.blockEndTimeField, 'String', sprintf('%.5fs', end_s));
      end % process_block_begin
      
      function blockCompleted(cb)
          if (cb.status_marker_handle > 0)
              delete(cb.status_marker_handle);
              cb.status_marker_handle = -1;
          end
          
          if ~ isempty(cb.new_peak_handles)
              delete(cb.new_peak_handles);     % remove plots from last iteration
              cb.new_peak_handles = [];
          end
          
          drawnow update;
      end % block_completed
      
      function frameAdvanced(cb,tt)
          current_s = tt.current_s;
          cb.clearFits();
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
                  'b-');
          
          %set(cb.handles.progressAxes, 'xlim', get(cb.handles.spectrogram, 'xlim'));
          set(cb.handles.frameStartTimeField, 'String', sprintf('%.5fs', current_s));
          set(cb.handles.frameEndTimeField, 'String', sprintf('%.5fs', current_s + cb.thr.advance_s));
          
          if (cb.fit_plots_enabled)
              cb.plotFits(tt);
          end
          
          drawnow update;
      end
      
      function handleBroadbandFrame(cb, current_s)
          cb.progress_handles(end+1) = ...
              plot(cb.handles.progressAxes, ...
                  [current_s current_s], ...
                  [0,1], ...
                  'r-');
          drawnow update;
      end
      
      function handleFramePeaks(cb, current_time, peaks)
          % Plot the peaks that were just detected.
          cb.new_peak_handles = plot(cb.handles.spectrogram,...
              current_time(ones(size(peaks))),...
              peaks/1000, ...
              'r^');
          cb.progress_handles(end+1) = ...
              plot(cb.handles.progressAxes, ...
                  [current_time current_time], ...
                  [0,1], ...
                  'g-');
          drawnow update;
      end
      
      function updateBreakpoints(cb, breakpoints)
          if ~isempty(cb.breakpoint_handles)
              delete(cb.breakpoint_handles);     
              cb.breakpoint_handles = zeros(length(breakpoints));
          end
          
          for idx = 1:length(breakpoints)
              cb.breakpoint_handles(idx) = ...
                  plot(cb.handles.progressAxes, ... 
                      [breakpoints(idx) breakpoints(idx)], ...
                      [0,1],...
                      'm-');
          end
      end
      
      function handleActiveSetExtension(cb, tt)
          active_set = tt.getActiveSet();
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
              cb.handles.spectrogram, ...
              active_set.getActiveSet(), ...
              '-','m');
           
            % Plot the peaks that are currently in the active set.
          cb.active_set_peak_handles = plot(...
              cb.handles.spectrogram,...
              active_set.getActiveSet().get_time(), ...
              active_set.getActiveSet().get_freq/1000, ...
              'g*');

          cb.orphan_graph_handles = cb.plot_graph(...
              cb.handles.spectrogram, ...
              active_set.getOrphanSet(), ...
              '-','c');
           
          % Plot the peaks that are currently in the orphan set.
          cb.orphan_set_peak_handles = plot(...
              cb.handles.spectrogram, ...
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
                  [newh, cb.graph_cmap_idx] = dtPlotGraph(g, ...
                      'ColorMap', cb.graph_cmap, 'LineStyle', '--', ...
                      'ColorIdx', cb.graph_cmap_idx, 'Marker', '.', ...
                      'DistinguishEdges', true);
                  
                  cb.graph_handles = [cb.graph_handles, newh{:}];
              end
          end
           
          drawnow update;
      end
      
      function clearAll(cb)
          if (~isempty(cb.fit_plot_handles))
              delete(cb.fit_plot_handles);
              cb.fit_plot_handles = [];
          end
          
          if (cb.status_marker_handle > 0)
              delete(cb.status_marker_handle);
              cb.status_marker_handle = -1;
          end
          
          if (~isempty(cb.new_peak_handles))
              delete(cb.new_peak_handles);     % remove plots from last iteration
              cb.new_peak_handles = {};
          end
          
          if (~isempty(cb.graph_handles))
              delete(cb.graph_handles);     % remove plots from last iteration
              cb.graph_handles = {};
          end
          
          if (~isempty(cb.progress_handles))
              delete(cb.progress_handles);     % remove plots from last iteration
              cb.progress_handles = [];
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
          
          set(cb.handles.frameStartTimeField, 'String', '');
          set(cb.handles.frameEndTimeField, 'String', '');
          set(cb.handles.blockStartTimeField, 'String', '');
          set(cb.handles.blockEndTimeField, 'String', '');
      end
      
      function plotFits(cb, tt)
          activeSet = tt.getActiveSet();
          frontier = activeSet.getMergedFrontier();
          it = frontier.iterator();
          while it.hasNext()
              node = it.next();
              if (node.chained_forward())
                  continue;
              end
              fits = activeSet.getFitsForNode(node,0.025);
              fitIteraror = fits.iterator();
              while fitIteraror.hasNext()
                  fit = fitIteraror.next();
                  times = node.time:tt.Advance_s:tt.current_s;
                  freqs = zeros(size(times));
                  for idx = 1:length(times)
                      freqs(idx) = fit.predict(times(idx));
                  end

                  % Plot the fit.
                  cb.fit_plot_handles(end+1) = plot(...
                      cb.handles.spectrogram, ...
                      times, ...
                      freqs/1000, ...
                      'LineWidth', .5, ...
                      'LineStyle', '--',...
                      'Color', 'g');
                  
                 
                  % Plot the vertical line of the range.
                  upper_limit = freqs(end) + tt.thr.maxslope_Hz_per_ms;
                  lower_limit = max(0, freqs(end) - tt.thr.maxslope_Hz_per_ms);
                  
                  range_times = [tt.current_s tt.current_s];
                  range_freqs = [lower_limit upper_limit];
                  cb.fit_plot_handles(end+1) = plot(...
                      cb.handles.spectrogram, ...
                      range_times, ...
                      range_freqs/1000, ...
                      'LineWidth', .5, ...
                      'LineStyle', '-',...
                      'Color', 'g');
                  
                  cb.fit_plot_handles(end+1) = plot(...
                      cb.handles.spectrogram, ...
                      tt.current_s, ...
                      upper_limit/1000, ...
                      '+g');
                  
                  cb.fit_plot_handles(end+1) = plot(...
                      cb.handles.spectrogram, ...
                      tt.current_s, ...
                      lower_limit/1000, ...
                      '+g');
                  
              end
          end
      end
      
      function clearFits(cb)
          if (~isempty(cb.fit_plot_handles))
              delete(cb.fit_plot_handles);
              cb.fit_plot_handles = [];
          end
      end
      
      function setFitPlotsEnabled(cb, enabled)
          cb.fit_plots_enabled = enabled;
      end
      
      function handles = plot_graph(cb, axisH, set, style, color)
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
                        'Axis', axisH,...
                        'Color', color, 'LineStyle', style, ...
                        'DistinguishEdges', false);
  
                    handles = [handles, newh{:}];
                end
            end
        end
      end
   end% methods
end% classdef