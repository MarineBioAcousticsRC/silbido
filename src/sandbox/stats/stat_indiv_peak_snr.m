function [ snrs ] = stat_individual_peak_snr(tonal, sourceGraph)
%Calculates the average number of peaks per unti of time
%
       snrs = tonal.get_snr();
       snrs = snrs';
end