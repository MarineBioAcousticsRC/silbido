function [t_length] = stat_tonal_length(tonal)
    times = tonal.get_time();
    t_length = times(end) - times(1);
end