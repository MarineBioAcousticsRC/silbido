function [ snrs ] = stat_individual_peak_snr(tonal)
%Calculates the average number of peaks per unti of time
%
       snrs = tonal.get_snr();
       snrs = snrs';
end