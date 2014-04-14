detections_base = '/Users/michael/development/sdsu/silbido/silbido-hg-repo/testing/results/';


%stat_func1 = @(x) stat_avg_nth_wait_times(x,2);
%stat_func1 = @stat_tonal_length;
stat_func1 = @stat_num_peaks_over_time;
%stat_func1 = @stat_avg_peak_power;
%stat_func = @stat_time_freq_jerk;
stat_func2 = @stat_cumm_power_over_time;
%stat_func = @stat_tonal_power_a;
%stat_func = @stat_indiv_peak_power_jerk;
%stat_func = @stat_indiv_peak_snr;




[gd_stats1, fp_stats1] = calculate_tonal_stats(detections_base, stat_func1);
[gd_stats2, fp_stats2] = calculate_tonal_stats(detections_base, stat_func2);
%[gd_stats3, fp_stats3] = calculate_tonal_stats(detections_base, stat_func3);


figure
hold on;
plot(gd_stats1, gd_stats2,'g*');
plot(fp_stats1, fp_stats2,'r.');
%scatter3(gd_stats1, gd_stats2, gd_stats3,'g*');
%scatter3(fp_stats1, fp_stats2,fp_stats3,'r.');
hold off;