function [peak] = consolidate_peaks(peak, smoothed_dB, min_bin_gap)
    
    % find the indices where peaks are too close
    peak_dist = diff(peak);
    too_close_idx = find(peak_dist < min_bin_gap);
    
    % if there are peaks that are too close, consolidate them by merging
    % the largest dB valued peaks first then repeat till there are no more
    % peaks that are close
    while(~isempty(too_close_idx))

        % get the dB values of all the too close peaks
        too_close_vals = smoothed_dB(peak(too_close_idx));
        
        % find the index to the peak with the max dB value
        [~, maxidx] = max(too_close_vals);
        % get the index of the peak diffs that corresponds to the max dB 
        % value from the too close indices
        max_freq_idx = too_close_idx(maxidx);
        
        % set the max_offset by finding the smaller dB value between the
        % too close peaks (want to delete the smaller dB value)
        [~, max_offset] = ...
               min(smoothed_dB(peak([max_freq_idx; max_freq_idx+1])));
        
        % set the index to delete from the peak array
        delete_idx = max_freq_idx - 1 + max_offset;
        peak(delete_idx) = [];
        
        % recalculate diffs and find if there are more peaks that are too
        % close
        peak_dist = diff(peak);
        too_close_idx = find(peak_dist < min_bin_gap);
    end
end




