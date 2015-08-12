function output_txt = datatip_tfnode(obj,event_obj)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).

timefreq = get(event_obj,'Position');

% Find frequency range over which we plotted.
yrange = get(get(event_obj, 'Target'), 'YData');
% Determine resolution for frequency display
index = find(max(yrange) < [5, Inf], 1, 'first');
switch index
    case 1
        output_txt{1} = sprintf('%.3f s X %.1f Hz', timefreq(1), timefreq(2)*1000);
    case 2
        output_txt{1} = sprintf('%.3f s X %.4f kHz', timefreq(1), timefreq(2));
end
    



% grab associated object and its properties
target = get(event_obj, 'Target');
properties = get(target);

if isfield(properties, 'CData')
    % User clicked on image
    
    colordata = get(target, 'CData');  % energies at time/freq
    
    % Find index into pcolor data.  
    % Not fully documented.  For line objects, datacursormode documentation
    % indicates that this is an index to the closest point.  It appears
    % that there is something similar for images.  
    % Matlab 2013b returns row/colum and Matlab 2014b returns a single
    % index.  
    tfidx = get(event_obj, 'DataIndex');   % time x frequency indiceif length(tfidx) > 1
    if length(tfidx) > 1
        tidx = tfidx(1);  % older Matlab
        fidx = tfidx(2);
    else
        % Newer Matlab gives a single index into the matrix, convert
        [fidx, tidx] = ind2sub(size(colordata), tfidx);
    end
            
    raw_cdata_value = colordata(fidx, tidx);

    % Non-double types are 0 based
    if isa(raw_cdata_value,'double')
        cdata_value = raw_cdata_value;
    elseif isa(raw_cdata_value,'logical')
        cdata_value = raw_cdata_value;
    else
        cdata_value = double(raw_cdata_value) + 1;
    end
    userdata = get(target, 'UserData');
    raw_dB = userdata.snr_dB(fidx, tidx);
    output_txt{end+1} = sprintf('actual %.1f dB', raw_dB);
    output_txt{end+1} = sprintf('effective %.1f dB', cdata_value);
end
