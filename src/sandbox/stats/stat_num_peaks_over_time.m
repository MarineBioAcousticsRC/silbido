function [ peak_density ] = stat_num_peaks_over_time(tonal, sourceGraph)
%Calculates the average number of peaks per unti of time
%
    times = tonal.get_time();
    start_time = times(1);
    end_time = times(end);
    dt = end_time - start_time;
    
    num_peaks = length(times);
    peak_density = num_peaks / dt;
end