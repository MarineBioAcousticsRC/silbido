function [peak] = consolidate_peaks(peak, smoothed_dB, min_bin_gap)
    
    peak_dist = diff(peak);
    too_close_idx = find(peak_dist < min_bin_gap);

    while(~isempty(too_close_idx))
        %fprintf('Consolidating peaks\n');
        to_close_vals = smoothed_dB(too_close_idx);
        [~, maxidx] = max(to_close_vals);
        max_freq_idx = too_close_idx(maxidx);
        
        [~, max_offset] = ...
               min(smoothed_dB(peak([max_freq_idx; max_freq_idx+1])));
           
        delete_idx = max_freq_idx - 1 + max_offset;
           
        peak(delete_idx) = [];

        peak_dist = diff(peak);
        too_close_idx = find(peak_dist < min_bin_gap);
    end
end