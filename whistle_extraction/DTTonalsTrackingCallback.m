classdef DTTonalsTrackingCallback < handle
   properties
      currentFigureH;
      peaksH;
      ridgesH;
   end % properties
   methods
      function cb = DTTonalsTrackingCallback()

      end
      function cb = new_block(cb, peak_spectrogram, ridge_spectrogram)
          cb.currentFigureH = figure('Name', 'spectrogram');
          cb.peaksH = subplot(2,1,1);
          imagesc(peak_spectrogram);
          set(gca,'YDir','normal');
          colormap(gray);
          hold on;

          cb.ridgesH = subplot(2,1,2);
          imagesc(ridge_spectrogram);
          set(gca,'YDir','normal');
          colormap(gray);
          hold on;
    
          all_ha = findobj( cb.currentFigureH, 'type', 'axes', 'tag', '' );
          linkaxes( all_ha, 'xy' );
      end % new_block
      
      function handle_non_ridge_peak(cb, frame_idx, p, ridge)
          if( size(ridge,1) > 1)
              plot(cb.ridgesH, ridge(:,1), ridge(:,2), 'y', 'LineWidth', 2);
              plot(cb.ridgesH, frame_idx, p, 'g', 'LineWidth', 3);
              plot(cb.ridgesH, ridge(end,1), ridge(end,2), 'r', 'LineWidth', 3);                   
              plot(cb.peaksH, frame_idx, p, 'g', 'LineWidth', 2);
          else
              axes(cb.ridgesH);
              plot(frame_idx, p, 'c', 'LineWidth', 2);
              plot(cb.peaksH, frame_idx, p, 'c', 'LineWidth', 2);
          end
      end % handle_non_ridge_peak
      
      function handle_ridge_peak(cb, frame_idx, p)
          plot(cb.peaksH, frame_idx, p, 'y', 'LineWidth', 2);
      end % handle_ridge_peak
   end% methods
end% classdef