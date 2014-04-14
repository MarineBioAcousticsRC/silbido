function toolpd(action)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% toolpd.m
%
% Tools pull-down menu operation
%
% 060525 smw v1.61
%
% 5/5/04 smw
%
% 060220 - 060227 smw modified for v1.60
%
% Do not modify the following line, maintained by CVS
% $Id: toolpd.m,v 1.8 2008/03/02 21:24:53 mroch Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global HANDLES PARAMS DATA

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if strcmp(action,'run_mat')
    disp_msg('This function is not available yet')
    % savepath = pwd;
    % % user interface retrieve file to open through a dialog box
    % boxTitle1 = 'Run MATLAB script';
    % filterSpec1 = '*.m';
    %
    % % cd to default directory (used for quick directory access
    % ipnamesave = PARAMS.inpath;
    % ifnamesave = PARAMS.infile;
    % cd2current_v140;
    %
    % [PARAMS.run_mat,PARAMS.matpath]=uigetfile(filterSpec1,boxTitle1);
    %
    % % if the cancel button is pushed, then no file is loaded so exit this script
    % if strcmp(num2str(PARAMS.infile),'0')
    %     return
    % else % give user some feedback
    %     disp('MATLAB script to run: ')
    %     disp([PARAMS.matpath,PARAMS.run_mat])
    %     disp(' ')
    % end
    %
    % eval(PARAMS.run_mat(1:length(PARAMS.run_mat)-2))
    % cd(savepath)



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box
elseif strcmp(action,'convert_multiHRP2XWAVS')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    %need a gui input here
    make_multixwav
    setpointers('arrow');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box
elseif strcmp(action,'convert_HRP2XWAVS')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    %need a gui input here
    write_hrp2xwavs
    setpointers('arrow');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box
elseif strcmp(action,'get_HRPhead')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    % need gui input here
    d = 1;      % d=1: display output to command window
    [fname,fpath]=uigetfile('*.hrp','Select HRP file to read disk Header');
    filename = [fpath,fname];
    % if the cancel button is pushed, then no file is loaded so exit this script
    if strcmp(num2str(fname),'0')
        return
    else % get raw HARP disk header
        read_rawHARPhead(filename,d)
    end
    setpointers('arrow');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box
elseif strcmp(action,'get_HRPdir')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    d = 1;      % d=1: display output to command window
    [fname,fpath]=uigetfile('*.hrp','Select HRP file to read disk Directory');
    filename = [fpath,fname];
    % if the cancel button is pushed, then no file is loaded so exit this script
    if strcmp(num2str(fname),'0')
        return
    else % get raw HARP disk directory
        read_rawHARPdir(filename,d)
    end
    setpointers('arrow');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box
elseif strcmp(action,'ck_dirlist_times')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    setpointers('watch');
    check_dirlist_times
    setpointers('arrow');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box edit header psds file
elseif strcmp(action,'editpsds')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    % editHeader_ltsa
    disp_msg('this function is not currently available')
    setpointers('arrow');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box edit header xwav file
elseif strcmp(action,'editxwav')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    editHeader_xwav
    setpointers('arrow');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box convertfile into a file
elseif strcmp(action,'convertfile')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    hrp2xwav
    setpointers('arrow');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % use output file from hrp2xwav for input to plot
    if ~exist(fullfile(PARAMS.outpath,PARAMS.outfile))
        setpointers('arrow');
        return
    end
    PARAMS.infile = PARAMS.outfile;
    PARAMS.inpath = PARAMS.outpath;
    % initialize the  PARAMS, read a segment, then plot it
    PARAMS.ftype = 2;   % XWAV file format
    initdata
    if isempty(DATA)
        set(HANDLES.display.timeseries,'Value',1);
    end
    readseg
    plot_triton

    control('timeon')   % was timecontrol(1)
    % turn on other menus now
    control('menuon')
    control('button')
    % turn some other buttons/pulldowns on/off
    set([HANDLES.motion.seekbof HANDLES.motion.back HANDLES.motion.autoback HANDLES.motion.stop],...
        'Enable','off');
    % set(HANDLES.pickxyz,'Enable','on')
    set(HANDLES.motioncontrols,'Visible','on')
    setpointers('arrow');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box convertARP into a file
elseif strcmp(action,'convertARP')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    bin2xwav
    setpointers('arrow');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box convertARP into a file
elseif strcmp(action,'convertOBS')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    obs2xwav
    setpointers('arrow');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box convertARP into a file
elseif strcmp(action,'convertMultiARP')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    multibin2xwav
    setpointers('arrow');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box decimatefile into a file
elseif strcmp(action,'decimatefile')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    decimatexwav
    setpointers('arrow');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box decimatefile into a file
elseif strcmp(action,'decimatefiledir')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    decimatexwav_dir
    setpointers('arrow');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box make ltsa file
elseif strcmp(action,'mkltsa')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    guCreateLTSA;
    setpointers('arrow');
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % enable label plots
elseif strcmp(action, 'label-toggle')
    if PARAMS.dt.class.ValidLabels
        % toggle plot status & flag
        if PARAMS.dt.class.PlotLabels
            set(HANDLES.labelplot, 'Checked', 'off');
        else
            set(HANDLES.labelplot, 'Checked', 'on');
        end
        PARAMS.dt.class.PlotLabels = ~ PARAMS.dt.class.PlotLabels;
        plot_triton;   % Replot with/without labels
    else
        toolpd('label-replace');        % No valid label set, ask for one
    end
elseif strcmp(action, 'label-replace')
    [basename, path] = uigetfile('*.tlab', 'Set detection label file');
    % if canceled button pushed:
    if strcmp(num2str(basename),'0')
        return
    end
    file = fullfile(path, basename);
    if ~ exist(file)
        disp_msg(sprintf('Detection file %s does not exist', file));
    else
        [Starts, Stops, Labels] = ioReadLabelFile(file, 'Binary', true);
        PARAMS.dt.class.starts = Starts;
        PARAMS.dt.class.stops = Stops;
        PARAMS.dt.class.labels = Labels;
        PARAMS.dt.class.files = {file}; % May want to add display
                                        % filename later on...
        PARAMS.dt.class.ValidLabels = true;
        PARAMS.dt.class.PlotLabels = true; % Assume they want to see them.
        set(HANDLES.labelplot, 'Checked', 'on');
        disp_msg(sprintf('Detection file %s read', file));
    end
    plot_triton;        % Replot showing labels

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box LTSA Batch Detector
elseif strcmp(action,'dtLTSABatch')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    dtLongTimeDetector;
    setpointers('arrow');
     
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box - short time spectrum detection
elseif strcmp(action,'dtShortTimeDetection')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    dtShortTimeDetector;
    setpointers('arrow');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box ST guided 3rd level search
    % Finds clicks with high resolution based upon coarse
    % location.
elseif strcmp(action,'dtST_GuidedHRClickDet')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    setpointers('watch');
    dtST_GuidedHiResDetector;
    %dtST_GuidedHRClickDet;
    setpointers('arrow');
end


function setpointers(icon)
global HANDLES
set(HANDLES.fig.ctrl, 'Pointer', icon);
set(HANDLES.fig.main, 'Pointer', icon);
set(HANDLES.fig.msg, 'Pointer', icon);
