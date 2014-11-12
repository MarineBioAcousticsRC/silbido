detections_base = '/Users/michael/development/silbido/silbido-hg-repo/src/sandbox/testing/results/';


% These return mulitple points per tonal.
%stat_func = @(tonal, graph) stat_nth_wait_times(tonal,2);
%stat_func = @(tonal, graph) stat_nth_wait_times(tonal,5);
%stat_func = @stat_time_freq_jerk;
%stat_func = @stat_indiv_peak_power_jerk;
%stat_func = @stat_indiv_peak_snr;


% These return one stat per tonal
%stat_func = @(tonal, graph) stat_avg_nth_wait_times(tonal,2); % has potential
%stat_func = @stat_tonal_length;
%stat_func = @stat_cumm_power_over_time;
%stat_func = @stat_avg_peak_power;
%stat_func = @stat_num_peaks_over_time;



%
% Source Graph Stats
%


%stat_func = @stat_graph_cycles_per_second;
%stat_func = @stat_graph_cycles_per_area;
%stat_func = @stat_graph_cycles_per_node;

stat_func = @stat_graph_candidate_joins_per_second;
%stat_func = @stat_graph_candidate_joins_per_area;
%stat_func = @stat_graph_candidate_joins_per_node;

%stat_func = @stat_graph_junctions;
%stat_func = @stat_graph_junctions_per_area;
%stat_func = @stat_graph_junctions_per_second;
%stat_func = @stat_graph_junctions_per_node;


%stat_func = @stat_graph_nodes_per_area;
%stat_func = @stat_graph_nodes_per_second;


[gd_stats, fp_stats] = calculate_tonal_stats(detections_base, stat_func);
plot_cdf(gd_stats, fp_stats);