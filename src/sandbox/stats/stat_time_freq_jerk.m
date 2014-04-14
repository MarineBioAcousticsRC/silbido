function [ freq_jerk ] = stat_time_freq_jerk( tonal )
%stat_tonal_jerk Summary of this function goes here
%   Detailed explanation goes here
times = tonal.get_time();
freqs = tonal.get_freq();
    
samples = times / 0.002;
freq_bins = freqs / 125;

[~, freq_jerk] = finite_difference(samples, freq_bins, 3);
%[~, freq_jerk] = finite_difference(times, freqs, 3);

freq_jerk = abs(freq_jerk);
freq_jerk = freq_jerk';
freq_jerk = freq_jerk(freq_jerk ~= Inf);
freq_jerk = freq_jerk(~isnan(freq_jerk));
end

