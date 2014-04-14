detections_base = '/Users/michael/development/sdsu/silbido/silbido-hg-repo/testing/results/';


% These return mulitple points per tonal.
%stat_func = @(x) stat_nth_wait_times(x,2);
%stat_func = @(x) stat_nth_wait_times(x,5);
%stat_func = @stat_time_freq_jerk;
stat_func = @stat_indiv_peak_power_jerk;
%stat_func = @stat_indiv_peak_snr;


% These return one stat per tonal
%stat_func = @(x) stat_avg_nth_wait_times(x,9);
%stat_func = @stat_tonal_length;
%stat_func = @stat_cumm_power_over_time;
%stat_func = @stat_avg_peak_power;
%stat_func = @stat_num_peaks_over_time;


[gd_stats, fp_stats] = calculate_tonal_stats(detections_base, stat_func);
plot_cdf(gd_stats, fp_stats);