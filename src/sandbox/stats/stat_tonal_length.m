function [t_length] = stat_tonal_length(tonal, sourceGraph)
    times = tonal.get_time();
    t_length = times(end) - times(1);
end