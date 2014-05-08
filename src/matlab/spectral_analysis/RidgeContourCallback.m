classdef RidgeContourCallback < handle
   properties
      currentFigureH;
      peaksH;
      ridgesH;
      time_scale;
      fkHz;
   end % properties
   methods
      function cb = RidgeContourCallback()

      end
      function cb = new_block(cb, peak_spectrogram, time_scale, ridge_spectrogram, derivatives)
          figure;
          bright_dB = 10;
          contrast_Pct = 200;
          
          fHz = 5000:125:50000;
          cb.fkHz = fHz / 1000;
          cb.time_scale = time_scale;
           
          
          I = ridge_spectrogram;
         
          dims = size(ridge_spectrogram);
          
          image_h = image(ridge_spectrogram);
          set(gca,'YDir','normal');
          colorData = (contrast_Pct/100) .* ridge_spectrogram + bright_dB;
          set(image_h, 'CData', colorData);

          colormap(gray);
          hold on;
          [~, cb.ridgesH] = contour(ridge_spectrogram,'c');

          % We are only going to plot a subset of points on the graph
          % set 'step_size' to x to plot every 'xth' point.
          step_size = 3;
          y_steps = 1:step_size:dims(1);
          x_steps = 1:step_size:dims(2);
          [X, Y] = meshgrid(x_steps, y_steps); 
        
         
          % Create containers to hold the gradient vectors and dominant
          % Eigen vectors of the Hessian matrix.
          gv_x = ones(dims) * NaN;
          gv_y = ones(dims) * NaN;

          ev_x = ones(dims) * NaN;
          ev_y = ones(dims) * NaN;

          % For each selected point in the x and y calculate the gv and
          % ev.
          for idx_x = 1:length(x_steps)
            for idx_y = 1:length(y_steps)
                x = x_steps(idx_x);
                y = y_steps(idx_y);

                [a, gv, ev] = HessianFunctional(derivatives, y, x, 0);   

                gv_x(y, x) = gv(1);
                gv_y(y, x) = gv(2);

                % The gv and ev can have vastly different magnitudes.
                % While less accurate, it is more visually inuitive to
                % scale the ev to the same length as the ev.
                gv_mag = norm([gv_x(y,x) gv_y(y,x)]);
                scaling = gv_mag / norm(ev);
                ev = ev * abs(scaling);

                ev_x(y, x) = ev(1);
                ev_y(y, x) = ev(2);

            end        
         end

         GV_X = gv_x(y_steps,x_steps);
         GV_Y = gv_y(y_steps,x_steps);
         quiver(X(:),Y(:),GV_X(:),GV_Y(:), 'g');

         EV_X = ev_x(y_steps,x_steps);
         EV_Y = ev_y(y_steps,x_steps);
         quiver(X(:),Y(:),EV_X(:),EV_Y(:), 'y');
         
         axis off

         % This uses the original ridge tracking code to plot all ridges in
         % red.
         [TT, A] = CalculateFunctionalsAndTrackNew(I,derivatives.guassian_width,zeros(size(I)),5);
         TT = SmoothCurves2(TT,2,1000);
        
         for n = 1:length(TT)
            T = TT{n};
            plot(T(:, 1), T(:, 2),'r', 'LineWidth', 3);
         end

      end % new_block
      
      function handle_non_ridge_peak(cb, frame_idx, p, ridge)
%          if( size(ridge,1) > 1)
%               plot(ridge(:,1), ridge(:,2), 'y', 'LineWidth', 3, 'MarkerSize',3);
%               plot(frame_idx, p, '.g', 'LineWidth', 3, 'MarkerSize',10);
%               plot(ridge(end,1), ridge(end,2), '.r', 'LineWidth', 3, 'MarkerSize',10);                   
%               
%          else
%               plot(frame_idx, p, '.c', 'LineWidth', 2, 'MarkerSize',10);
%           end
          
      end % handle_non_ridge_peak
      
      function handle_ridge_peak(cb, frame_idx, p)
%            plot(frame_idx, p, '.y', 'LineWidth', 3, 'MarkerSize',10);
      end % handle_ridge_peak
   end% methods
end% classdef