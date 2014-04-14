function [] = process_stats_for_tonals(loaded_tonals, output_file_base, stats )
%PROCESS_STATS_FOR_TONAL Summary of this function goes here
%   Detailed explanation goes here

[dir, ~, ~] = fileparts(output_file_base);

mkdir(dir);
peak_density = cell(1,loaded_tonals.size());

for idx=0:(loaded_tonals.size() - 1)
    tonal = loaded_tonals.get(idx);
 
    peak_density{idx + 1} = stat_peak_density(tonal);
end

stats_output_file = [output_file_base '_peak_density.mat'];
save(stats_output_file,'peak_density');
