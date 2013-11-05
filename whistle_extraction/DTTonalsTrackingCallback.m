classdef DTTonalsTrackingCallback < handle
   properties
      currentFigureH;
      peaksH;
      ridgesH;
      time_scale;
      fkHz;
   end % properties
   methods
      function cb = DTTonalsTrackingCallback()

      end
      function cb = new_block(cb, peak_spectrogram, time_scale, ridge_spectrogram, derivatives)
          bright_dB = 10;
          contrast_Pct = 200;
          
          fHz = 5000:125:50000;
          cb.fkHz = fHz / 1000;
          cb.time_scale = time_scale;
          
          cb.currentFigureH = figure('Name', 'spectrogram');
          cb.peaksH = subplot(2,1,1);
          image_h = image(cb.time_scale, cb.fkHz, peak_spectrogram);
          set(gca,'YDir','normal');
          colorData = (contrast_Pct/100) .* peak_spectrogram + bright_dB;
          set(image_h, 'CData', colorData);
         
          
          colormap(gray);
          hold on;

          cb.ridgesH = subplot(2,1,2);
          image_h = image(cb.time_scale, cb.fkHz, ridge_spectrogram);
          colorData = (contrast_Pct/100) .* ridge_spectrogram + bright_dB;
          set(image_h, 'CData', colorData);
          
          set(gca,'YDir','normal');
          colormap(gray);
          hold on;
    
          all_ha = findobj( cb.currentFigureH, 'type', 'axes', 'tag', '' );
          linkaxes( all_ha, 'xy' );
      end % new_block
      
      function handle_non_ridge_peak(cb, frame_idx, p, ridge)
          if( size(ridge,1) > 1)
              plot(cb.ridgesH, cb.time_scale(round(ridge(:,1))), cb.fkHz(round(ridge(:,2))), 'y', 'LineWidth', 2);
              plot(cb.ridgesH, cb.time_scale(frame_idx), cb.fkHz(p), 'g', 'LineWidth', 3);
              plot(cb.ridgesH, cb.time_scale(round(ridge(end,1))), cb.fkHz(round(ridge(end,2))), 'r', 'LineWidth', 3);                   
              plot(cb.peaksH, cb.time_scale(frame_idx), cb.fkHz(p), 'g', 'LineWidth', 2);
          else
              plot(cb.ridgesH, cb.time_scale(frame_idx), cb.fkHz(p), 'c', 'LineWidth', 2, 'MarkerSize', 10);
              plot(cb.peaksH, cb.time_scale(frame_idx), cb.fkHz(p), 'c', 'LineWidth', 2);
          end
          drawnow;
      end % handle_non_ridge_peak
      
      function handle_ridge_peak(cb, frame_idx, p)
          plot(cb.peaksH, cb.time_scale(frame_idx), cb.fkHz(p), 'y', 'LineWidth', 2);
      end % handle_ridge_peak
   end% methods
end% classdef