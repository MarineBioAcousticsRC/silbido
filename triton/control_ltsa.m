function control_ltsa(action)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% control_ltsa.m
%
% toggle on/off control window pull-down menus and buttons
% set and implement newtime, newtseg, newstep,coordinate display
%
% stolen from triton v1.50 (control.m)
% smw 050117
%
% modified 060210 - 060227 smw for triton v1.60
%
% modified 060524 smw for v1.61
%
%
% Do not modify the following line, maintained by CVS
% $Id: control_ltsa.m,v 1.3 2007/11/27 19:14:48 mroch Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global HANDLES PARAMS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if strcmp(action,'buttoff')
    %
    % turn off buttons and menues (during picks)
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.ltsa.motioncontrols,'Enable','off');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'button')
    %
    % turn on buttons and menues (after picks)
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.ltsa.motioncontrols,'Enable','on');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'menuon')
    %
    % turn on  and menues (after picks)
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set([HANDLES.filemenu HANDLES.savejpg HANDLES.savefigureas ],...
        'Enable','on');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'menuoff')
    %
    % turn off buttons and menues (during picks)
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set([HANDLES.filemenu ],...
        'Enable','off');
    % time stuff in control window
elseif strcmp(action,'timeon')
    % turn on time controls
    set(HANDLES.ltsa.timecontrols,'Visible','on');
elseif strcmp(action,'timeoff')
    % turn off time controls
    set(HANDLES.ltsa.timecontrols,'Visible','off');
    % amp stuff in control window
elseif strcmp(action,'ampon')
    % turn on amplitude controls
    set(HANDLES.ltsa.ampcontrols,'Visible','on');
elseif strcmp(action,'ampoff')
    % turn off amplitude controls
    set(HANDLES.ltsa.ampcontrols,'Visible','off');
    % frequency stuff in control window
elseif strcmp(action,'freqon')
    % turn on frequency controls
    set(HANDLES.ltsa.freqcontrols,'Visible','on');
    %
elseif strcmp(action,'freqoff')
    % turn off frequency controls
    set(HANDLES.ltsa.freqcontrols,'Visible','off');
    % log stuff control window
elseif strcmp(action,'logon')
    % turn on logfile radiobuttons
    set(HANDLES.ltsa.logcontrols,'Visible','on');
    set(HANDLES.ltsa.logcontrols,'Value',0);
elseif strcmp(action,'logoff')
    % turn off logfile radiobuttons
    set(HANDLES.ltsa.logcontrols,'Visible','off');
    set(HANDLES.ltsa.logcontrols,'Value',0);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'newtime1')
    %
    % plot with new time
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    PARAMS.ltsa.save.dnum = PARAMS.ltsa.plot.dnum;
    PARAMS.ltsa.plot.dnum = timenum(get(HANDLES.ltsa.time.edtxt1,'String'),6);
    % readpsds
    read_ltsadata
    plot_triton
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'newtseg')
    %
    % plot with new time segment
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    PARAMS.ltsa.save.dnum = PARAMS.ltsa.plot.dnum;
    tseg = str2num(get(HANDLES.ltsa.time.edtxt3,'String'));

    if tseg < PARAMS.ltsa.tave/(60 * 60); % if less than one psd bin size in hours
        disp_msg('Duration too small')
        set(HANDLES.ltsa.time.edtxt3,'String',num2str(PARAMS.ltsa.tseg.hr));
    else
        PARAMS.ltsa.tseg.hr = tseg;
        PARAMS.ltsa.tseg.sec = tseg * (60 * 60);  % convert from hours to seconds
    end
    %     readpsds
    read_ltsadata
    plot_triton
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'newtstep')
    %
    % plot with new time step
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PARAMS.ltsa.tseg.step = str2num(get(HANDLES.ltsa.time.edtxt4,'String'));
    if PARAMS.ltsa.tseg.step < -1
        PARAMS.ltsa.tseg.step = -1;
        set(HANDLES.ltsa.time.edtxt4,'String',num2str(PARAMS.ltsa.tseg.step));
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'delay')
    %
    % delay between auto displays
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % time delay between Auto Display
    delay= str2num(get(HANDLES.ltsa.time.edtxt6,'String'));
    maxdelay = 10;
    mindelay = 0;
    if maxdelay < delay
        disp_msg(['Error: Delay greater than ' num2str(maxdelay) ' seconds!'])
        %         disp(' ')
        PARAMS.ltsa.cancel = 1;
        return
    elseif delay < mindelay
        disp_msg(['Error: Delay shorter than ' num2str(mindelay) ' seconds?'])
        %         disp(' ')
        PARAMS.ltsa.cancel = 1;
        return
    elseif delay <= maxdelay & delay >= mindelay
        PARAMS.ltsa.aptime = delay;
    else
        PARAMS.ltsa.cancel = 1;
        disp_msg('Error: Unknown amount')
        %         disp(' ')
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'setcmapjet')
    %
    % set color map to jet
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PARAMS.ltsa.cmap = 'jet';
    figure(HANDLES.fig.main)
    colormap(PARAMS.ltsa.cmap)
    figure(HANDLES.fig.ctrl)
    set(HANDLES.ltsa.amp.cmapcontrol,'Value',0)
    set(HANDLES.ltsa.amp.cmapjet,'Value',1)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'setcmapgray')
    %
    % set color map to gray
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PARAMS.ltsa.cmap = 'gray';
    figure(HANDLES.fig.main)
    % make negative colormap ie dark is big amp
    g = gray;
    szg = size(g);
    cmap = g(szg:-1:1,:);
    colormap(cmap)
    figure(HANDLES.fig.ctrl)
    set(HANDLES.ltsa.amp.cmapcontrol,'Value',0)
    set(HANDLES.ltsa.amp.cmapgray,'Value',1)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'setcmapcool')
    %
    % set color map to cool
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PARAMS.ltsa.cmap = 'blue';
    figure(HANDLES.fig.main)
    colormap(PARAMS.ltsa.cmap)
    figure(HANDLES.fig.ctrl)
    set(HANDLES.ltsa.amp.cmapcontrol,'Value',0)
    set(HANDLES.ltsa.amp.cmapcool,'Value',1)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'setcmaphot')
    %
    % set color map to hot
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PARAMS.ltsa.cmap = 'hot';
    figure(HANDLES.fig.main)
    colormap(PARAMS.ltsa.cmap)
    figure(HANDLES.fig.ctrl)
    set(HANDLES.ltsa.amp.cmapcontrol,'Value',0)
    set(HANDLES.ltsa.amp.cmaphot,'Value',1)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'toggleEqual')
    %
    % Push button Pick time to average spectrogram equalization
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    state1 = get(HANDLES.ltsa.eq.tog,'Value');
    if state1 == get(HANDLES.ltsa.eq.tog,'Max')
        set(HANDLES.ltsa.eq.tog,'String','ON')
    elseif state1 == get(HANDLES.ltsa.eq.tog,'Min')
        set(HANDLES.ltsa.eq.tog,'String','OFF')
    end
    plot_triton
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'toggleMean')
    %
    % Toggle Spectrogram Equalization Pick and Full Mean
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    state1 = get(HANDLES.ltsa.eq.tog,'Value');
    state2 = get(HANDLES.ltsa.eq.tog2,'Value');
    if state2 == get(HANDLES.ltsa.eq.tog2,'Max') & ...
            state1 == get(HANDLES.ltsa.eq.tog,'Max')
        set(HANDLES.ltsa.eq.tog2,'String','Pick')
        figure(HANDLES.fig.main)
        [t,f] = ginput(2);
        dt = PARAMS.ltsa.t(2)-PARAMS.ltsa.t(1);	%sec/pixel
        x = floor((t+dt/2)./dt) + 1;
        if x(1) > x(2)
            xs = x(1);
            x(1) = x(2);
            x(2) = xs;
        elseif x(1) == x(2)
            x(2) = x(1) + 1;
        end
        PARAMS.ltsa.mean.save = mean(PARAMS.ltsa.pwr(:,x(1):x(2)),2) ;
    elseif state2 == get(HANDLES.ltsa.eq.tog2,'Min')
        set(HANDLES.ltsa.eq.tog2,'String','Full')
    end
    plot_triton
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'ampadj')
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    brsld = get(HANDLES.ltsa.amp.brsld,'Value');
    bredt = str2num(get(HANDLES.ltsa.amp.bredt,'String'));
    consld = get(HANDLES.ltsa.amp.consld,'Value');
    conedt = str2num(get(HANDLES.ltsa.amp.conedt,'String'));
    if bredt ~= PARAMS.ltsa.bright
        PARAMS.ltsa.bright = bredt;
    elseif brsld ~= PARAMS.ltsa.bright
        PARAMS.ltsa.bright = round(brsld);
    end
    set(HANDLES.ltsa.amp.bredt,'String',num2str(PARAMS.ltsa.bright));
    set(HANDLES.ltsa.amp.brsld,'Value',PARAMS.ltsa.bright);
    if conedt ~= PARAMS.ltsa.contrast
        PARAMS.ltsa.contrast = conedt;
    elseif consld ~= PARAMS.ltsa.contrast
        PARAMS.ltsa.contrast = round(consld);
    end
    set(HANDLES.ltsa.amp.consld,'Value',PARAMS.ltsa.contrast)
    set(HANDLES.ltsa.amp.conedt,'String',num2str(PARAMS.ltsa.contrast))

    % check and apply/remove spectrogram equalization:
    state = get(HANDLES.ltsa.eq.tog,'Value');
    if state == get(HANDLES.ltsa.eq.tog,'Max')
        set(HANDLES.ltsa.eq.tog,'String','ON')
        pwr = PARAMS.ltsa.pwr - mean(PARAMS.ltsa.pwr,2) * ones(1,length(PARAMS.ltsa.t));
    elseif state == get(HANDLES.ltsa.eq.tog,'Min')
        set(HANDLES.ltsa.eq.tog,'String','OFF')
        pwr = PARAMS.ltsa.pwr;
    end


    %c = (1 + PARAMS.ltsa.contrast/100).* PARAMS.ltsa.pwr + PARAMS.ltsa.bright;
    % pwr = PARAMS.ltsa.pwr(PARAMS.ltsa.fimin:PARAMS.ltsa.fimax,:);
    %     c = (PARAMS.ltsa.contrast/100) .* PARAMS.ltsa.pwr + PARAMS.ltsa.bright;
    c = (PARAMS.ltsa.contrast/100) .* pwr + PARAMS.ltsa.bright;
    set(HANDLES.ltsa.BC,'String',['B = ',num2str(PARAMS.ltsa.bright),', C = ',num2str(PARAMS.ltsa.contrast)]);

    if PARAMS.ltsa.fax == 0
        set(HANDLES.plt.ltsa,'CData',c)
    elseif PARAMS.ltsa.fax == 1
        flen = length(PARAMS.ltsa.f);
        [M,N] = logfmap(flen,4,flen);
        c = M*c;
        %         f = M*PARAMS.f;
        %         HANDLES.plt = image(PARAMS.t,f,c);
        %         set(get(HANDLES.plt,'Parent'),'YScale','log');
        set(HANDLES.plt.ltsa,'CData',c)
    end

    % adjust colorbar
    minc = min(min(c));
    maxc = max(max(c));
    %difc = floor(maxc-minc / 100);
    difc = 2;

    minp = min(min(PARAMS.ltsa.pwr));
    maxp = max(max(PARAMS.ltsa.pwr));

    set(PARAMS.ltsa.cb,'YLim',[minp maxp])

    % Get image associated with colorbar and adjust
    img_h = get(PARAMS.ltsa.cb, 'Children');
    set(img_h,'CData',[minc:difc:maxc]')
    set(img_h,'YData',[minp maxp])

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'newstfreq')
    %
    % Start Frequency
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    f0 = str2num(get(HANDLES.ltsa.stfreq.edtxt,'String'));
    if f0 >= PARAMS.ltsa.freq1
        disp_msg('Freq larger than End Freq :')
        disp_msg(num2str(PARAMS.ltsa.freq1))
        PARAMS.ltsa.cancel = 1;
        set(HANDLES.ltsa.stfreq.edtxt,'String',PARAMS.ltsa.freq0);
        return
    elseif f0 < 0
        disp_msg('Freq smaller than Min Freq :')
        disp_msg('0')
        PARAMS.ltsa.cancel = 1;
        set(HANDLES.ltsa.stfreq.edtxt,'String',PARAMS.ltsa.freq0);
        return
    elseif length(f0) == 0
        disp_msg('Wrong format')
        PARAMS.ltsa.cancel = 1;
        set(HANDLES.ltsa.stfreq.edtxt,'String',PARAMS.ltsa.freq0);
        return
    else
        PARAMS.ltsa.freq0 = f0;
        if PARAMS.ltsa.cancel ~= 1
            % change plot freq axis
            PARAMS.ltsa.fimin = ceil(PARAMS.ltsa.freq0 / PARAMS.ltsa.freq(2))+1;
            PARAMS.ltsa.f = PARAMS.ltsa.freq(PARAMS.ltsa.fimin:PARAMS.ltsa.fimax);
            plot_triton;
        else
            PARAMS.ltsa.cancel = 0;
        end
    end
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'newendfreq')
    %
    % End Frequency
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    f1 = str2num(get(HANDLES.ltsa.endfreq.edtxt,'String'));
    if f1 <= PARAMS.ltsa.freq0
        disp_msg('Freq smaller than Start Freq :')
        disp_msg(num2str(PARAMS.ltsa.freq0))
        PARAMS.ltsa.cancel = 1;
        set(HANDLES.ltsa.endfreq.edtxt,'String',PARAMS.ltsa.freq1);
        return
    elseif f1 > PARAMS.ltsa.fmax
        disp_msg('Freq greater than Max Freq :')
        disp_msg(num2str(PARAMS.ltsa.fmax))
        PARAMS.ltsa.cancel = 1;
        set(HANDLES.ltsa.endfreq.edtxt,'String',PARAMS.ltsa.freq1);
        return
    elseif length(f1) == 0
        disp_msg('Wrong format')
        PARAMS.ltsa.cancel = 1;
        set(HANDLES.ltsa.endfreq.edtxt,'String',PARAMS.ltsa.freq1);
        return
    else
        PARAMS.ltsa.freq1 = f1;
        if PARAMS.ltsa.cancel ~= 1
            % change plot freq axis
            PARAMS.ltsa.fimax = ceil(PARAMS.ltsa.freq1 / PARAMS.ltsa.freq(2));
            PARAMS.ltsa.f = PARAMS.ltsa.freq(PARAMS.ltsa.fimin:PARAMS.ltsa.fimax);
            plot_triton;
        else
            PARAMS.ltsa.cancel = 0;
        end
    end
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'setspec')
    %
    % Set Spectral Parameters
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % FFT length
    PARAMS.ltsa.nfft=str2num(get(HANDLES.ltsa.specnfft.edtxt,'String'));
    % FFT overlap
    PARAMS.ltsa.overlap=str2num(get(HANDLES.ltsa.specol.edtxt,'String'));
    if PARAMS.ltsa.cancel ~= 1
        plot_triton;
    else
        PARAMS.ltsa.cancel = 0;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'filtdata')
    %
    % Filter Data
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    tog = get(HANDLES.ltsa.filt.tog,'Value');

    if PARAMS.ltsa.filter == 0 & tog == 0
        pflag = 0;
    else
        pflag = 1;
    end

    PARAMS.ltsa.filter = tog;

    if PARAMS.ltsa.filter ~= 0 & PARAMS.ltsa.filter ~= 1
        disp_msg(['Value must be 1 or 0 : ' num2str(PARAMS.ltsa.filter) ' was entered'])
        PARAMS.ltsa.cancel = 1;
        return
    end

    if PARAMS.ltsa.filter == 0
        set([HANDLES.ltsa.filtlow.txt HANDLES.ltsa.filthigh.txt ...
            HANDLES.ltsa.filt.edtxt1 HANDLES.ltsa.filt.edtxt2],...
            'Visible','off');
    elseif PARAMS.ltsa.filter == 1
        set([HANDLES.ltsa.filtlow.txt HANDLES.ltsa.filthigh.txt ...
            HANDLES.ltsa.filt.edtxt1 HANDLES.ltsa.filt.edtxt2],...
            'Visible','on');
    end

    if PARAMS.ltsa.filter == 1
        % start Frequency
        f0 = str2num(get(HANDLES.ltsa.filt.edtxt1,'String'));
        if f0 >= PARAMS.ltsa.freq1
            disp_msg('Freq larger than End Freq :')
            disp_msg(num2str(PARAMS.ltsa.freq1))
            PARAMS.ltsa.cancel = 1;
            return
        elseif f0 < 0
            disp_msg('Freq smaller than Min Freq :')
            disp_msg('0')
            PARAMS.ltsa.cancel = 1;
            return
        elseif length(f0) == 0
            disp_msg('Wrong format')
            PARAMS.ltsa.cancel = 1;
            return
        else
            PARAMS.ltsa.ff1 = f0;
        end
        % End Freq
        f1 = str2num(get(HANDLES.ltsa.filt.edtxt2,'String'));
        if f1 <= PARAMS.ltsa.freq0
            disp_msg('Freq smaller than Start Freq :')
            disp_msg(num2str(PARAMS.ltsa.freq0))
            PARAMS.ltsa.cancel = 1;
            return
        elseif f1 > PARAMS.ltsa.fmax
            disp_msg('Freq greater than Max Freq :')
            disp_msg(num2str(PARAMS.ltsa.fmax))
            PARAMS.ltsa.cancel = 1;
            return
        elseif length(f1) == 0
            disp_msg('Wrong format')
            PARAMS.ltsa.cancel = 1;
            return
        else
            PARAMS.ltsa.ff2 = f1;
        end

    end

    if pflag == 1
        readpsds
        plot_triton;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'faxlinear')
    %
    % Freq Axis linear
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.ltsa.faxcontrol,'Value',0);
    set(HANDLES.ltsa.fax.linear,'Value',1);
    PARAMS.ltsa.fax = 0;
    plot_triton;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'faxlog')
    %
    % Freq Axis log
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.ltsa.faxcontrol,'Value',0);
    set(HANDLES.ltsa.fax.log,'Value',1);
    PARAMS.ltsa.fax = 1;
    plot_triton;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'setchan')
    %
    % Set Channel number
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ch = get(HANDLES.ltsa.ch.pop,'Value');
    PARAMS.ltsa.ch = ch;
    readpsds
    plot_triton
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action, 'detection_toggle')
    %
    % Detector toggle
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PARAMS.ltsa.dt.Enabled = get(HANDLES.ltsa.dt.Enabled, 'Value');
    PARAMS.ltsa.dt.ifPlot = PARAMS.ltsa.dt.Enabled;
    % Melissa, we need to revisit this and add some more comments.
    % What's the difference between Enabled and ifPlot? - Marie
    if PARAMS.ltsa.dt.Enabled
        set(HANDLES.fig.dt, 'Visible','on')
        set(HANDLES.ltsa.dt.AllControls, 'Visible', 'On')
    elseif ~ PARAMS.ltsa.dt.Enabled | ~ get(HANDLES.display.specgram,'Value')
        set(HANDLES.fig.dt, 'Visible','off')
        PARAMS.ltsa.dt.ifPlot = 0;
    else 
        set(HANDLES.ltsa.dt.AllControls, 'Visible', 'Off')
        PARAMS.ltsa.dt.ifPlot = 0;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
% elseif strcmp(action, 'detection_noise')
%     %
%     % Noise selection for mean subtraction
%     %
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     if get(HANDLES.ltsa.dt.NoiseEst, 'Value')
%         % User wants to pick means
%         PARAMS.ltsa.dt.mean_selection = 2;
%         set(HANDLES.ltsa.zoomin.button, 'Enable', 'off');
%         set(HANDLES.ltsa.zoomin.button, 'Value', false);
%         set(HANDLES.fig.main,'pointer','fullcrosshair');
%         disp_msg('Select start of LTSA noise')
%     else
%         % User cancels selection of means
%         PARAMS.ltsa.dt.mean_selection = 0;
%         set(HANDLES.fig.main,'pointer','arrow');
%         disp_msg('LTSA noise selection cancelled, reverting to running mean');
%         PARAMS.ltsa.dt.mean_enabled = 0;
%         set(HANDLES.ltsa.zoomin.button, 'Enable', 'on');
%         set(HANDLES.ltsa.dt.NoiseEst, 'Value', 0)
%     end

end;
