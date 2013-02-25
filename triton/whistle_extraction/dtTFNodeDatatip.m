function output_txt = datatip_tfnode(obj,event_obj)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).

timefreq = get(event_obj,'Position');
output_txt = {sprintf('%.3f s', timefreq(1)), ...
    sprintf('%.1f kHz', timefreq(2))};

% index in graphics obj (only partially documented)
tfidx = get(event_obj, 'DataIndex');   % time x frequency indices
if length(tfidx) > 1
    % clicked on image
    
    % colormap access code derived from Mathworks
    % default_getDatatipText.m
    
    tidx = tfidx(1);
    fidx = tfidx(2);
    
    % grab associated object
    target = get(event_obj, 'Target');
    % test if graphics object, how?
    if 1
        cdatamapping = get(target, 'CDataMapping');
        colordata = get(target, 'cdata');
        
        raw_cdata_value = colordata(fidx, tidx);
        % Non-double types are 0 based
        if isa(raw_cdata_value,'double')
            cdata_value = raw_cdata_value;
        elseif isa(raw_cdata_value,'logical')
            cdata_value = raw_cdata_value;
        else
            cdata_value = double(raw_cdata_value) + 1;
        end
        output_txt{end+1} = sprintf('%.1f dB', cdata_value);
    end
else
    1;
end
