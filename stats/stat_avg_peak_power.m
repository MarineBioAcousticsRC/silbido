function [ peak_density ] = stat_avg_peak_power(tonal)
%Calculates the average number of peaks per unti of time
%
    times = tonal.get_time();
    snrs = tonal.get_snr();
    cumm_snr = sum(snrs);
    peak_density = cumm_snr / length(times);
end