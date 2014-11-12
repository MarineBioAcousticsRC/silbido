function [ peak_density ] = stat_cumm_power_over_time(tonal, sourceGraph)
%Calculates the average number of peaks per unti of time
%
    times = tonal.get_time();
    start_time = times(1);
    end_time = times(end);
    dt = end_time - start_time;
    
    snrs = tonal.get_snr();
    cumm_snr = sum(snrs);
    peak_density = cumm_snr / dt;
end