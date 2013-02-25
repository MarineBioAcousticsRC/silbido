function pickxyz()
%
%
% gets called with each mouse button click
% ie. WindowButtonDownFcn callback for HANDLES.fig.main
%
% pulled out of toolpd
%
% 060221 - 060227 smw
%
% 060612 smw v1.61
%
% Do not modify the following line, maintained by CVS
% $Id: pickxyz.m,v 1.3 2007/09/15 17:04:19 mroch Exp $

global HANDLES PARAMS

selectiontype = get(HANDLES.fig.main,'SelectionType');
PARAMS.pick.button.value = get(HANDLES.pick.button,'Value');
PARAMS.zoomin.button.value = get(HANDLES.ltsa.zoomin.button,'Value');

% turn on/off cross hairs
if PARAMS.pick.button.value | PARAMS.zoomin.button.value
% if PARAMS.pick.button.value
    pointer = get(HANDLES.fig.main,'pointer');
    set(HANDLES.fig.main,'pointer','fullcrosshair');
else
    pointer = get(HANDLES.fig.main,'pointer');
    set(HANDLES.fig.main,'pointer','arrow');
end

% if strcmp(selectiontype,'normal' & ~PARAMS.zoomin.button.value) ...
% if strcmp(selectiontype,'normal') ...
%         | (strcmp(selectiontype,'alt') & ~PARAMS.pick.button.value) 
%     set(HANDLES.fig.main,'SelectionType','normal')
%     return
% elseif PARAMS.pick.button.value & strcmp(selectiontype,'alt')
%     set(HANDLES.fig.main,'SelectionType','normal')

if (PARAMS.pick.button.value & ~strcmp(selectiontype,'alt') ...
        & ~PARAMS.zoomin.button.value) | ...
        get(HANDLES.ltsa.dt.NoiseEst, 'Value')
    currentaxispoint = get(get(HANDLES.fig.main,'CurrentAxes'),'CurrentPoint');
    x = currentaxispoint(1,1);
    y = currentaxispoint(1,2);

    % get value for active windows
    savalue = get(HANDLES.display.ltsa,'Value');
    tsvalue = get(HANDLES.display.timeseries,'Value');
    spvalue = get(HANDLES.display.spectra,'Value');
    sgvalue = get(HANDLES.display.specgram,'Value');

    if tsvalue  % time series
        if gco == HANDLES.subplt.timeseries | gco == HANDLES.plt.timeseries...
                | gco == HANDLES.delimit.tsline
            % time from beginning of plot to delimitor line [seconds]
            rtime = (PARAMS.raw.dnumEnd(PARAMS.raw.currentIndex) - PARAMS.plot.dnum)...
                * 60 *60 * 24;
            % convert x location into time for xwav
            if x < rtime
                ctime_dvec = datevec(PARAMS.plot.dnum) + [0 0 0 0 0 x];
            else
                dnum = PARAMS.raw.dnumStart(PARAMS.raw.currentIndex + 1);
                ctime_dvec = datevec(dnum) + [0 0 0 0 0 x-rtime];
            end
            HHMMSS = timestr(ctime_dvec,4);
            mmmuuu = timestr(ctime_dvec,5);

            disp_pick([HHMMSS,'.',mmmuuu,'    ',num2str(round(y))])
        end
    end
    if spvalue % spectra
        if gco == HANDLES.subplt.spectra | gco == HANDLES.plt.spectra
            ctime_dvec = datevec(PARAMS.plot.dnum);
            HHMMSS = timestr(ctime_dvec,4);
            freq = round(x);
            disp_pick([HHMMSS,'    ',num2str(freq),'Hz   ',num2str(y,'%0.2f'),'dB'])

        end
    end

    if sgvalue % spectrogram
        if gco == HANDLES.subplt.specgram | gco == HANDLES.plt.specgram...
                | gco == HANDLES.delimit.sgline
            % time from beginning of plot to delimitor line [seconds]
            rtime = (PARAMS.raw.dnumEnd(PARAMS.raw.currentIndex) - PARAMS.plot.dnum)...
                * 60 *60 * 24;
            % convert x location into time for xwav
            if x < rtime
                ctime_dvec = datevec(PARAMS.plot.dnum) + [0 0 0 0 0 x];
            else
                dnum = PARAMS.raw.dnumStart(PARAMS.raw.currentIndex + 1);
                ctime_dvec = datevec(dnum) + [0 0 0 0 0 x-rtime];
            end
            HHMMSS = timestr(ctime_dvec,4);
            mmmuuu = timestr(ctime_dvec,5);

            if length(PARAMS.t) > 1
                dt = PARAMS.t(2)-PARAMS.t(1);	%sec/pixel
                cp(1) = floor((x+dt/2)/dt) + 1 ;
            else
                cp(1) = 1;
            end
            df = PARAMS.f(2)-PARAMS.f(1);	%hz/pixel???
            cp(2) = floor((y - PARAMS.f(1) +df/2)/df)+1;
            szpwr = size(PARAMS.pwr);
            if (cp(1)>= 1 & cp(1) <= szpwr(2)) ...
                    & (cp(2) >= 1 & cp(2) <= szpwr(1))
                pwr = PARAMS.pwr(cp(2),cp(1));
            end

            disp_pick([HHMMSS,'.',mmmuuu,'   ',num2str(round(y)),...
                'Hz   ',num2str(pwr,'%0.1f'),'dB'])
        end
    end

    if savalue % long term spectral average (neptune)
        if gco == HANDLES.subplt.ltsa | gco == HANDLES.plt.ltsa
            % calc time

        % ctime_dnum = PARAMS.ltsa.start.dnum + x / 24;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
        %
        % new ltsa timing stuff 060514 smw:
        [rawIndex,tBin] = getIndexBin(x);
        % disp_msg([num2str(rawIndex),'  ',num2str(tBin)])

        tbinsz = PARAMS.ltsa.tave / (60*60);

        % cursor time in days (add one tBin to have 1st bin at zero
        ctime_dnum = PARAMS.ltsa.dnumStart(rawIndex) + (tBin - 0.5) * tbinsz /24;
        % disp_msg([num2str(ctime_dnum),'  ',num2str(tBin)])


            % get color power
            % Sean - Need to understand why 1 was added to cp.
            % cp contains [timeidx, freqidx].  When zooming in
            % to very small windows on LTSAs (e.g. ~ 8-10 pixels
            % across), it seems to be pretty easy to get the time
            % index to exceed the size of the power matrix.  I'm
            % suspecting that rounding errors were encountered which
            % rounded down to zero.  
            szpwr = size(PARAMS.ltsa.pwr);
            if length(PARAMS.ltsa.t) > 1
                dt = PARAMS.ltsa.t(2)-PARAMS.ltsa.t(1);	%sec/pixel
                cp(1) = max(1, min(szpwr(2), floor((x+dt/2)/dt)));
            else
                cp(1) = 1;
            end
            df = PARAMS.ltsa.f(2)-PARAMS.ltsa.f(1);	%hz/pixel???
            %   cp(2) = floor((cy+df/2)/df);
            cp(2) = max(1, min(szpwr(1), floor((y-PARAMS.ltsa.f(1)+df/2)/df)));
            % Unless there is a time ltsa.pwr isn't set, we shouldn't need
            % the tests anymore.
            %if (cp(1)>= 1 & cp(1) <= szpwr(2)) ...
            %        & (cp(2) >= 1 & cp(2) <= szpwr(1))
            %    pwr = PARAMS.ltsa.pwr(cp(2),cp(1));
            %end
            pwr = PARAMS.ltsa.pwr(cp(2),cp(1));

            disp_pick([timestr(ctime_dnum,6),'   ',num2str(round(y)),...
                'Hz   ',num2str(pwr,'%0.1f'),'dB'])
            
            if PARAMS.ltsa.dt.mean_selection
                % Redo interface later to have specific callbacks for
                % means selection
                nth = 3 - PARAMS.ltsa.dt.mean_selection;  % which pick?
                PARAMS.ltsa.dt.selections(nth) = cp(1);
                
                PARAMS.ltsa.dt.mean_selection = ...
                    PARAMS.ltsa.dt.mean_selection - 1;
                if nth == 2
                    % have both picks, compute mean
                    range = sort(PARAMS.ltsa.dt.selections);
                    PARAMS.ltsa.dt.pwr_mean = ...
                        mean(PARAMS.ltsa.pwr(:, range(1):range(2)), 2);
                    disp_msg('Noise selection complete.')
                    % reenabled disabled buttons
                    set(HANDLES.ltsa.zoomin.button, 'Enable', 'on');
                    set(HANDLES.fig.main,'pointer','arrow');
                    PARAMS.ltsa.dt.mean_enabled = 1;
                    set(HANDLES.ltsa.dt.NoiseEst, 'Value', 0)
                else
                    disp_msg('Select end of LTSA noise');
                    set(HANDLES.fig.main, 'pointer', 'fullcrosshair');
                end
            end

        end
    end
elseif PARAMS.zoomin.button.value & ~strcmp(selectiontype,'alt')
   % disp_msg('Right Click LTSA window to see coordinates of cursor')
    pickxwav
    % turn on channel changer to correct channel selection
    set(HANDLES.ch.pop,'Value',PARAMS.ch)

end     % end if PARAMS.pick.value
%     end %end while loop

