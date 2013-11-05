function [ wait_times ] = stat_nth_wait_times(tonal, n)
%TONAL_STATS Summary of this function goes here
%   Detailed explanation goes here
    times = tonal.get_time();
    
    samples = times / .002;
    
    loop_end = length(samples) - n;
    wait_times = zeros(1,loop_end);
    
    for idx=1:loop_end
       start_sample = samples(idx);
       nth_sample = samples(idx + n);
       
       wait_times(idx) = nth_sample - start_sample;
    end
end