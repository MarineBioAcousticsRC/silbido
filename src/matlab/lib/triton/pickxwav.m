function pickxwav
%
% turn on picking time in ltsa file and open corresponding xwav file
%
% 060612 smw
%%
% Do not modify the following line, maintained by CVS
% $Id: pickxwav.m,v 1.9 2007/07/14 03:16:56 mroch Exp $

global PARAMS HANDLES DATA


%PARAMS.zoomin.button.value = get(HANDLES.ltsa.zoomin.button,'Value');

% % if PARAMS.pick.button.value | PARAMS.zoomin.button.value
% if PARAMS.zoomin.button.value
%     pointer = get(HANDLES.fig.main,'pointer');
%     set(HANDLES.fig.main,'pointer','fullcrosshair');
% else
%     pointer = get(HANDLES.fig.main,'pointer');
%     set(HANDLES.fig.main,'pointer','arrow');
% end

currentaxispoint = get(get(HANDLES.fig.main,'CurrentAxes'),'CurrentPoint');
x = currentaxispoint(1,1);
y = currentaxispoint(1,2);

% get value for active windows
savalue = get(HANDLES.display.ltsa,'Value');

if gco == HANDLES.subplt.ltsa | gco == HANDLES.plt.ltsa
    % calc time
    [rawIndex,tBin] = getIndexBin(x);
    fname = PARAMS.ltsahd.fname{rawIndex};
    rfileid = PARAMS.ltsahd.rfileid(rawIndex);

    disp_msg([fname,'  ',num2str(rfileid),'  ',num2str(tBin)])

    %--------------------------------------------------------------

    % calculate the number of blocks in the opened file
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    %filesize=getfield(dir([PARAMS.inpath,PARAMS.infile]),'bytes');
    PARAMS.inpath = PARAMS.ltsa.inpath;
    PARAMS.infile= fname;
    fullfname = fullfile(PARAMS.inpath,PARAMS.infile);
    if ~exist(fullfname, 'file')
        disp_msg(sprintf('%s does not exist', fullfname));
        disp_msg('Select correct directory & file')
        %pause(1)
        % get file name
        %
        filterSpec1 = '*.x.wav';
        boxTitle1 = 'Open XWAV based on LTSA';
        % user interface retrieve file to open through a dialog box
        DefaultName = PARAMS.inpath;
        [PARAMS.infile,PARAMS.inpath]=uigetfile(filterSpec1,boxTitle1,DefaultName);
        if isscalar(PARAMS.infile) | ...
              ~exist(fullfile(PARAMS.inpath,PARAMS.infile),'file')
          % Returned scalar 0 - cancel button
            disp_msg('Canceled file opening')
            return
        else
            disp_msg('Opened File: ')
            disp_msg(fullfile(PARAMS.inpath,PARAMS.infile))
            %     disp(' ')
            cd(PARAMS.inpath)
        end
    end

    fstr = [];
    fstr = regexp(char(fname),'.x.wav','match');
    if ~isempty(fstr)
        PARAMS.ftype = 2;       % xwav format
    else
        PARAMS.ftype = 1;       % wav format
        PARAMS.start.dnum = PARAMS.ltsa.dnumStart(rawIndex);
        PARAMS.start.dvec = PARAMS.ltsa.dvecStart(rawIndex);
    end

    % initialize data format
    initdata
    %---------------------------------------------------------
    % data start time
    %  ctime_dnum = PARAMS.ltsa.dnumStart(rawIndex) + (tBin - 0.5) * tbinsz /24;

    PARAMS.plot.dnum = PARAMS.ltsa.dnumStart(rawIndex) + (tBin - 0.5) * PARAMS.ltsa.tave / (60*60*24);
    PARAMS.plot.dvec = datevec(PARAMS.plot.dnum);

    if isempty(DATA) |...
            (get(HANDLES.display.timeseries,'Value') == 0 & ...
            get(HANDLES.display.spectra,'Value') == 0 & ...
            get(HANDLES.display.specgram,'Value') == 0)

        set(HANDLES.display.specgram,'Value',1);    % turn on spectrogram
    end
    readseg

    if get(HANDLES.display.timeseries,'Value') == 0 & ...
            get(HANDLES.display.spectra,'Value') == 0 & ...
            get(HANDLES.display.specgram,'Value') == 1

        displaybut('specgram')
    else
        plot_triton
    end

    control('timeon')   % was timecontrol(1)
    % turn on other menus now
    control('menuon')
    control('button')
    if PARAMS.plot.dnum == PARAMS.start.dnum
        set([HANDLES.motion.seekbof HANDLES.motion.back HANDLES.motion.autoback HANDLES.motion.stop],...
            'Enable','off');
    elseif PARAMS.plot.dnum + PARAMS.tseg.sec/(60*60*24) == PARAMS.end.dnum
        set([HANDLES.motion.seekeof HANDLES.motion.forward HANDLES.motion.autoforward HANDLES.motion.stop],...
            'Enable','off');
    elseif PARAMS.plot.dnum < PARAMS.start.dnum | PARAMS.plot.dnum + PARAMS.tseg.sec/(60*60*24) > PARAMS.end.dnum
        disp_msg('Error: Plot start time after or before file times')
    else
        set(HANDLES.motion.stop,'Enable','off');
    end
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    set(HANDLES.motioncontrols,'Visible','on')
    set(HANDLES.delimit.but,'Visible','on')

    %   ctime_dnum = PARAMS.ltsa.plot.dnum + x / 24;

    %disp_msg(num2str(ctime_dnum))

    PARAMS.zoomin.button.value = 0;
    set(HANDLES.ltsa.zoomin.button,'Value',PARAMS.zoomin.button.value);
    set(HANDLES.fig.main,'pointer','arrow');
end
