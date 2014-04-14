function displaybut(action)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% displaybut.m
%
% Display button operation
%
% 050512 smw
%
% 060211 - 060227 smw modified for triton v1.60
%
%
% Do not modify the following line, maintained by CVS
% $Id: displaybut.m,v 1.2 2007/02/12 20:56:43 swiggins Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global HANDLES PARAMS


% figure out how many subplots needed:
savalue = get(HANDLES.display.ltsa,'Value');
tsvalue = get(HANDLES.display.timeseries,'Value');
spvalue = get(HANDLES.display.spectra,'Value');
sgvalue = get(HANDLES.display.specgram,'Value');


m = savalue + tsvalue + spvalue + sgvalue ;  % total number of subplots

%
if strcmp(action,'timeseries')
    if tsvalue  % timeseries button on
        set(HANDLES.timeseriescontrol,'Visible','on')
    elseif ~tsvalue % ts button off
        if ~sgvalue % specgram button off
            set(HANDLES.sndcontrol,'Visible','off') % turn off sound control
            set(HANDLES.delimit.but,'Visible','off') % turn off delimit switch
            if ~spvalue % spectra button off
                set(HANDLES.allcontrol,'Visible','off') % turn off all XWAV control
                set(HANDLES.displaycontrol,'Visible','on') %turn on top row buttons
            end
        end
    end
    plot_triton
elseif strcmp(action,'spectra')
    if spvalue 
        set(HANDLES.spectracontrol,'Visible','on')
    elseif ~spvalue
        set(HANDLES.tfradios,'Visible','off')
        if ~sgvalue
            control('ampoff')
            control('freqoff')
            if ~tsvalue
                set(HANDLES.allcontrol,'Visible','off')
                set(HANDLES.displaycontrol,'Visible','on')
            end
        end
    end
    plot_triton
elseif strcmp(action,'specgram')
    if sgvalue
        set(HANDLES.specgramcontrol,'Visible','on')
    elseif ~sgvalue
        control('ampoff')
        set(HANDLES.sgequal,'Visible','off')
        set(HANDLES.dt.controls, 'Visible', 'off')
        if ~tsvalue
            set(HANDLES.sndcontrol,'Visible','off')
            set(HANDLES.delimit.but,'Visible','off') % turn off delimit switch
        end
        if ~spvalue
            control('freqoff')
                if ~tsvalue
                set(HANDLES.allcontrol,'Visible','off')
                set(HANDLES.displaycontrol,'Visible','on')
            end
        end
    end
    plot_triton
elseif strcmp(action,'ltsa')
    if savalue
        set(HANDLES.ltsa.allcontrol,'Visible','on')
    elseif ~savalue
        set(HANDLES.ltsa.allcontrol,'Visible','off')
    end
    plot_triton
end



if m == 0
    set(HANDLES.allcontrol,'Visible','off')
    set(HANDLES.ltsa.allcontrol,'Visible','off')
    % gotta keep the display control on to reactivate the plots without
    % re-opening the files
    if ~isempty(PARAMS.infile) 
        if ~isempty(PARAMS.ltsa.infile)
            set(HANDLES.displaycontrol,'Visible','on')
            set(HANDLES.display.ltsa,'Visible','on')
        else
            set(HANDLES.displaycontrol,'Visible','on')
        end
    else
        if ~isempty(PARAMS.ltsa.infile)
            set(HANDLES.display.ltsa,'Visible','on')
        end
    end           
end

