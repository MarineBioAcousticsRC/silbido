function [ power_jerk ] = stat_indiv_peak_power_jerk(tonal, sourceGraph)
%stat_tonal_jerk Summary of this function goes here
%   Detailed explanation goes here
times = tonal.get_time();
snrs = tonal.get_snr();
    
[~, power_jerk] = finite_difference(times, snrs, 2);

power_jerk = abs(power_jerk);
power_jerk = power_jerk';
power_jerk = power_jerk(power_jerk ~= Inf);
power_jerk = power_jerk(~isnan(power_jerk));
end