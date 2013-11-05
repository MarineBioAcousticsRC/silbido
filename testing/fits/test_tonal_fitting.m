close all; clear all;

import tonals.*;

load('fits/test-tonals.mat');

tonal = tonals{1};

times = tonal.times;
freqs = tonal.freqs;

figure(1);
plot(times,freqs, 'LineWidth', 3);
hold on;


how_far_back_s = 0.025;
max_gap_start_hz = 1000;
max_gap_hz = 200;
max_gap_s = 50 / 1000;

% Seed the fit with the initial point in the tonal.
t_fit = times(1);
f_fit = freqs(1);

% Iteratively feed each time slice in.  Basically we start from
% the first point and start doing the prediction.  If we "find"
% the next tonal point withing the "max_gap_hz" of where we 
% predicted it, we count that as a hit and add that as if it were
% a peak.
for idx=1:length(times) - 1
    % The time of the current peak.
    cur_time = times(idx);
    
    % Have we gone to long without a peak?
    if (cur_time - t_fit(end) > max_gap_s)
       
        break;
    end
    
    % Get the next time we will predict for.
    next_time = times(idx + 1);
    
    % Figure out how far back in the current path we are going
    % to go.  Only go as far back as the 'how_far_back_s' variable
    tail_idx = length(t_fit);
    while (1)
        tail_time = t_fit(tail_idx);
        tail_len_s = cur_time - tail_time;
        
        if (tail_idx == 1 || tail_len_s > how_far_back_s)
            break;
        end
        
        tail_idx = tail_idx - 1;
    end
    
    % Construct the tail of the tonal that we will use for the fit.
    t_fit_tail = t_fit(tail_idx:end);
    f_fit_tail = f_fit(tail_idx:end);
    
    % Compute the fit.
    degree = 5;
    fit_thresh = 0.7;
    resolutionHz = 125;
    fit = FitPolyJama(degree, t_fit_tail, f_fit_tail);
    
    fprintf('Fit Adjusted R2: %f\n', fit.getAdjustedR2());
    
    while (fit.getAdjustedR2() < fit_thresh && fit.getStdDevOfResiduals() > 2 * resolutionHz && length(t_fit_tail) > degree *3)
        degree = degree + 1;
        new_fit = FitPolyJama(degree, t_fit_tail, f_fit_tail);
        
        if (new_fit.getAdjustedR2() > fit.getAdjustedR2())
            fit = new_fit;
        end
    end
    pr_freq = fit.predict(next_time);
    
    % Get the ground truth value that will simulate a peak.
    gt_freq = freqs(idx + 1);
    
    freq_error = abs(pr_freq - gt_freq);
    
    if (length(t_fit) < 3 && freq_error < max_gap_start_hz || ...
        freq_error < max_gap_hz)
        % simulate the join.
        t_fit = [t_fit next_time];
        f_fit = [f_fit gt_freq];
    else
         % This just shows how we got off track.
        fprintf('Predicted Freq: %f, Ground Truth Freq %f\n', pr_freq, gt_freq);
         
        first_fit = max(1, idx - 20);
        last_fit = min(length(times), idx + 20);
         
        fit_line_x = times(first_fit:last_fit);
        fit_line_y = zeros(size(fit_line_x));
        for fit_idx=1:length(fit_line_x)
            fit_line_y(fit_idx) = fit.predict(fit_line_x(fit_idx));
        end
         
        plot(fit_line_x,fit_line_y,'g');
        scatter(next_time, pr_freq, 'gx');
        
        break;
    end
end

% Plot the fit
plot(t_fit,f_fit, 'r', 'LineWidth', 1);