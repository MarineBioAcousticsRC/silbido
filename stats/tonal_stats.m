function [ stats ] = tonal_stats(tonal, varargin)
%TONAL_STATS Summary of this function goes here
%   Detailed explanation goes here
    stats = zeros(1,length(varargin));
    for k=1:length(varargin)
        
        stat_params = varargin{k};
        stat_name = stat_params{1};
        
        switch stat_name
            case 'mean_jerk'
                stats(k) = mean_jerk(tonal);
            case 'mean_wait_time'
                span = stat_params{2};
                stats(k) = average_wait_time(tonal, span);
            case 'tonal_length'
                stats(k) = tonal_length(tonal);
            otherwise
                error('Silbido:Arguments', 'Detector:%s', stat_name);
        end;
    end 
end