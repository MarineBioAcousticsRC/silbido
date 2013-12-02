function filepd(action)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% filepd.m
%
% File pull-down menu options/operation
%
% 5/5/04 smw
%
% 060211 - 060227 smw modification for triton v1.60
% 060329 smw - wav file write normalized to 2^15
% 060525 smw - ltsa stuff
%
%
% Do not modify the following line, maintained by CVS
% $Id: filepd.m,v 1.11 2008/09/29 21:33:50 mroch Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global PARAMS HANDLES DATA
%
if strcmp(action,'openltsa')
    PARAMS.ltsa.ftype = 1;
    % check for and close already opened FILES
    if exist('PARAMS.ltsa.infid')
        fclose(PARAMS.ltsa.infid);
    end

    % save previous values incase of cancel button
    ipnamesave = PARAMS.ltsa.inpath;
    ifnamesave = PARAMS.ltsa.infile;
    % user interface retrieve file to open through a dialog box
    % boxTitle1 = 'Open PSDS File';   % psds is old neptune format
    boxTitle1 = 'Open LTSA File';
    %     filterSpec1 = '*.psds';
    filterSpec1 = '*.ltsa';
    [PARAMS.ltsa.infile,PARAMS.ltsa.inpath]=uigetfile(filterSpec1,boxTitle1);

    % if the cancel button is pushed, then no file is loaded so exit this script
    if strcmp(num2str(PARAMS.ltsa.infile),'0')
        PARAMS.ltsa.inpath = ipnamesave;
        PARAMS.ltsa.infile = ifnamesave;
        return
    else % give user some feedback
        disp_msg('Opened File: ')
        disp_msg([PARAMS.ltsa.inpath,PARAMS.ltsa.infile])
        cd(PARAMS.ltsa.inpath)
    end
    % calculate the number of blocks in the opened file
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    filesize=getfield(dir([PARAMS.ltsa.inpath,PARAMS.ltsa.infile]),'bytes');
    % initialize data format
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.display.ltsa,'Visible','on')
    set(HANDLES.display.ltsa,'Value',1);
    control_ltsa('button')
    set([HANDLES.ltsa.motion.seekbof HANDLES.ltsa.motion.back HANDLES.ltsa.motion.autoback HANDLES.ltsa.motion.stop],...
        'Enable','off');
    init_ltsadata
    read_ltsadata
    plot_triton
    control_ltsa('timeon')   % was timecontrol(1)
    % turn on other menus now
    control_ltsa('menuon')
    control_ltsa('ampon')
    control_ltsa('freqon')
    set(HANDLES.ltsa.dt.controls, 'Visible', 'on');
    set(HANDLES.ltsa.motioncontrols,'Visible','on')
    set(HANDLES.ltsa.equal,'Visible','on')
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');

elseif strcmp(action,'openwav')
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    PARAMS.ftype = 1;
    % check for and close already opened FILES
    if exist('PARAMS.infid')
        fclose(PARAMS.infid);
    end
    % save previous values incase of cancel button
    ipnamesave = PARAMS.inpath;
    ifnamesave = PARAMS.infile;
    % user interface retrieve file to open through a dialog box
    boxTitle1 = 'Open Wav File';
    filterSpec1 = '*.wav';
    [PARAMS.infile,PARAMS.inpath]=uigetfile(filterSpec1,boxTitle1);

    % if the cancel button is pushed, then no file is loaded so exit this script
    if strcmp(num2str(PARAMS.infile),'0')
        PARAMS.inpath = ipnamesave;
        PARAMS.infile = ifnamesave;
        return
    else % give user some feedback
        disp_msg('Opened File: ')
        disp_msg(fullfile(PARAMS.inpath,PARAMS.infile))
        cd(PARAMS.inpath)
    end
    % attempt to determine start date from file name 
    PARAMS.start.dnum = dateregexp(PARAMS.infile, PARAMS.fnameTimeRegExp, ...
                                   datenum([0 1 1 0 0 0]), ...  % default
                                   dateoffset());  % offset from
    % enter start date and time
    prompt={'Enter Start Date and Time'};
    def={timestr(PARAMS.start.dnum,6)};
    dlgTitle=['Set Start for File : ',PARAMS.infile];
    lineNo=1;
    AddOpts.Resize='on';
    AddOpts.WindowStyle='normal';
    AddOpts.Interpreter='tex';
    in=inputdlg(prompt,dlgTitle,lineNo,def,AddOpts);
    if length(in) == 0	% if cancel button pushed
        PARAMS.cancel = 1;
        return
    end
    % time delay between Auto Display
    PARAMS.start.dnum=timenum(deal(in{1}),6);
    % calculate the number of blocks in the opened file

    filesize=getfield(dir(fullfile(PARAMS.inpath,PARAMS.infile)),'bytes');
    % initialize data format
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    set([HANDLES.motion.seekbof HANDLES.motion.back HANDLES.motion.autoback HANDLES.motion.stop],...
        'Enable','off');

    set(HANDLES.motioncontrols,'Visible','on')
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box openxwav - open pseudo-wav file
elseif strcmp(action,'openxwav')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PARAMS.ftype = 2;
    % check for and close already opened FILES
    if exist('PARAMS.infid')
        fclose(PARAMS.infid);
    end
    % save previous values incase of cancel button
    ipnamesave = PARAMS.inpath;
    ifnamesave = PARAMS.infile;
    % user interface retrieve file to open through a dialog box
    boxTitle1 = 'Open XWAV File';
    filterSpec1 = '*.x.wav';
    [PARAMS.infile,PARAMS.inpath]=uigetfile(filterSpec1,boxTitle1);
    % if the cancel button is pushed, then no file is loaded so exit this script
    if strcmp(num2str(PARAMS.infile),'0')
        PARAMS.inpath = ipnamesave;
        PARAMS.infile = ifnamesave;
        return
    else % give user some feedback
        disp_msg('Opened File: ')
        disp_msg(fullfile(PARAMS.inpath,PARAMS.infile))
        cd(PARAMS.inpath)
    end
    % calculate the number of blocks in the opened file
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    filesize=getfield(dir(fullfile(PARAMS.inpath,PARAMS.infile)),'bytes');
    % initialize data format
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    set([HANDLES.motion.seekbof HANDLES.motion.back HANDLES.motion.autoback HANDLES.motion.stop],...
        'Enable','off');
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    set(HANDLES.motioncontrols,'Visible','on')
    set(HANDLES.delimit.but,'Visible','on')

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box to load hydrophone transfer function file
elseif strcmp(action,'loadTF')
    [fname, path] = uigetfile('*.tf','Load Transfer Function File');
    % if canceled button pushed:
    if strcmp(num2str(fname),'0')
        return
    end
    filename = fullfile(path, fname);
    if ~ exist(filename)
        disp_msg(sprintf('Transfer Function File %s does not exist', filename));
    else
        loadTF(filename);
        disp_msg(sprintf('Loaded Transfer Function File: %s', filename));
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box saveas into a file
elseif strcmp(action,'savefileas')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % user interface retrieve file to open through a dialog box
    boxTitle1 = 'Windowed Data Save As WAV';
    outfiletype = '.wav';
    len = length(PARAMS.infile); % get input data file name
    fileName = 'data';
    [PARAMS.outfile,PARAMS.outpath]=uiputfile([fileName,outfiletype],boxTitle1);
    len = length(PARAMS.outfile);
    if len > 4 & ~strcmp(PARAMS.outfile(len-3:len),outfiletype)
        PARAMS.outfile = [PARAMS.outfile,outfiletype];
    end
    % if the cancel button is pushed, then no file is loaded so exit this script
    if strcmp(num2str(PARAMS.outfile),'0')
        return
    else % give user some feedback
        disp_msg('Write File: ')
        disp_msg([PARAMS.outpath,PARAMS.outfile])
    end
    % MATLAB wavwrite requires input vector to be max +/- 1
    %
    % max of dat so not to clip
    % this mode is for normalizes to maximum amplitude (volume)
    % dmx = max(abs(DATA));
    %
    % normalize to max count (16-bit => +/- 2^15 (32768))
    dmx = 2^15;

    % write wave file
    wavwrite(DATA./dmx,PARAMS.fs,[PARAMS.outpath,PARAMS.outfile]);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box saveas into a xwav file
elseif strcmp(action,'savefileasxwav')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % cd2current;
    % user interface retrieve file to open through a dialog box
    boxTitle1 = 'Windowed Data Save As XWAV';
    outfiletype = '.x.wav';
    len = length(PARAMS.infile); % get input data file name
    fileName = 'data';
    [PARAMS.outfile,PARAMS.outpath]=uiputfile([fileName,outfiletype],boxTitle1);
    len = length(PARAMS.outfile);
    if len > 4 & ~strcmp(PARAMS.outfile(len-5:len),outfiletype)
        PARAMS.outfile = [PARAMS.outfile,outfiletype];
    end
    % if the cancel button is pushed, then no file is loaded so exit this script
    if strcmp(num2str(PARAMS.outfile),'0')
        return
    else % give user some feedback
        disp_msg('Write File: ')
        disp_msg([PARAMS.outpath,PARAMS.outfile])
    end
    % write xwav header into output file
    wrxwavhd(1)
    % dump data to output file
    % open output file
    fod = fopen([PARAMS.outpath,PARAMS.outfile],'a');
    %fseek(fod,PARAMS.xhd.byte_loc,'bof');
    if PARAMS.nBits == 16
        dtype = 'int16';
    elseif PARAMS.nBits == 32
        dtype = 'int32';
    else
        disp_msg('PARAMS.nBits = ')
        disp_msg(PARAMS.nBits)
        disp_msg('not supported')
        return
    end
    fwrite(fod,DATA,dtype);
    fclose(fod);
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box save plotted data to jpg file
elseif strcmp(action,'savejpg')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % cd2current;
    % user interface retrieve file to open through a dialog box
    boxTitle1 = 'Save Plotted Data to JPG File';
    outfiletype = '.jpg';
    len = length(PARAMS.infile); % get input data file name
    [PARAMS.outfile,PARAMS.outpath]=uiputfile([PARAMS.infile(1:len-4),outfiletype],boxTitle1);
    len = length(PARAMS.outfile);
    if len > 4 & ~strcmp(PARAMS.outfile(len-3:len),outfiletype)
        PARAMS.outfile = [PARAMS.outfile,outfiletype];
    end
    % if the cancel button is pushed, then no file is loaded so exit this script
    if strcmp(num2str(PARAMS.outfile),'0')
        return
    else % give user some feedback
        disp_msg('Write File: ')
        disp_msg([PARAMS.outpath,PARAMS.outfile])
    end
    %
    print (HANDLES.fig.main, '-djpeg100','-r150', [PARAMS.outpath,PARAMS.outfile])
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box saveas into a figure file
elseif strcmp(action,'savefigureas')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % cd2current;
    %Dialog Box Setup
    boxTitle1 = 'Save Figure As';
    outfiletype = ['.fig'];
    len = length(PARAMS.infile); % get input data file name
    fname = [PARAMS.infile(1:len-4) '@' strrep(strrep(PARAMS.start.str,':','-'),'.','_')];
    [PARAMS.outfile,PARAMS.outpath] = uiputfile( [fname,outfiletype], boxTitle1 );
    len = length(PARAMS.outfile);
    % Check for file extension
    if len > 4 & ~strcmp(PARAMS.outfile(len-3:len),outfiletype)
        PARAMS.outfile = [PARAMS.outfile,outfiletype];
    end
    % Display what we are going to write out
    disp_msg(['Write ' PARAMS.ioft ' File: '])
    disp_msg([PARAMS.outpath,PARAMS.outfile])
    % Check to see if the user hit the cancel button
    if strcmp(num2str(PARAMS.outfile),'0')
        return
    end
    % The name of the file
    name = [PARAMS.outpath,PARAMS.outfile];
    hgsave(HANDLES.fig.main,name);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box saveas into a jpeg file
elseif strcmp(action,'saveimageas')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Dialog Box Setup
    boxTitle1 = 'Save Spectrogram Image As';
    outfiletype = ['.',PARAMS.ioft];
    len = length(PARAMS.infile); % get input data file name
    fname = [PARAMS.infile(1:len-4) '@' strrep(strrep(PARAMS.start.str,':','-'),'.','_')];
    [PARAMS.outfile,PARAMS.outpath] = uiputfile( [fname,outfiletype], boxTitle1 );
    len = length(PARAMS.outfile);
    % Check for file extension
    if len > 4 & ~strcmp(PARAMS.outfile(len-3:len),outfiletype)
        PARAMS.outfile = [PARAMS.outfile,outfiletype];
    end
    % Display what we are going to write out
    disp_msg(['Write ' PARAMS.ioft ' File: '])
    disp_msg([PARAMS.outpath,PARAMS.outfile])
    %     disp(' ')
    % Check to see if the user hit the cancel button
    if strcmp(num2str(PARAMS.outfile),'0')
        return
    end
    % Set the colormap
    if strcmp(PARAMS.cmap,'gray') % make negative colormap ie dark is big amp
        g = gray;
        szg = size(g);
        cmap = g(szg:-1:1,:);
        colormap(cmap)
    else
        colormap(PARAMS.cmap)
    end
    % Get the current colormap
    mapping = colormap;
    % Refresh the spectrogram
    mkspecgram
    % Get the image, flip it so it writes out in the right orientation
    %sg = (1 + PARAMS.contrast/100) .* PARAMS.pwr + PARAMS.bright;
    sg = (PARAMS.contrast/100) .* PARAMS.pwr + PARAMS.bright;
    sg = flipud(sg);
    % The name of the file
    name = [PARAMS.outpath,PARAMS.outfile];
    % Convert to true-color (IE do map lookup by hand)
    [a,b] = size(sg)
    sg = reshape(sg,1,a*b);
    sg( find(sg>length(mapping)) ) = length(mapping);
    sg( find(sg<1) ) = 1;
    % added round to provide integer access to mapping array smw 8/10/04
    sg=round(sg);
    sg = mapping(sg,:);
    tc = reshape(sg,a,b,3);
    % Write out the image
    if PARAMS.ioft == 'jpg'
        imwrite( tc, name, PARAMS.ioft, 'Quality', PARAMS.iocq );
    elseif PARAMS.ioft == 'tif'
        imwrite( tc, name, PARAMS.ioft, 'Compression', PARAMS.ioct );
    elseif PARAMS.ioft == 'hdf'
        if( strcmp(PARAMS.ioct,'jpeg') )
            imwrite( tc, name, PARAMS.ioft, 'Compression', PARAMS.ioct, 'Quality', PARAMS.iocq );
        else
            imwrite( tc, name, PARAMS.ioft, 'Compression', PARAMS.ioct );
        end
    elseif PARAMS.ioft == 'png'
        imwrite( tc, name, PARAMS.ioft, 'BitDepth', PARAMS.iobd );
    else
        imwrite( tc, name, PARAMS.ioft );
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Save messages into file
elseif strcmp(action,'savemsgs')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % user interface retrieve file to open through a dialog box
    boxTitle1 = 'Save Messages to File';
    filterSpec1 = '*.msg.txt';
    [infile,inpath]=uiputfile(filterSpec1,boxTitle1);
    % if the cancel button is pushed, then no file is loaded so exit this script
    if strcmp(num2str(infile),'0')
        return
    else % give user some feedback
        disp_msg('Message File: ')
        disp_msg(fullfile(inpath,infile))
        msgs = char(get(HANDLES.msg,'String'));
        [mr,mc] = size(msgs);
        fid = fopen(fullfile(inpath,infile),'w');
        for k = 1:mr
            fprintf(fid,'%s\r\n',msgs(k,:));
        end
        fclose(fid);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Clear messages from display
elseif strcmp(action,'clrmsgs')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    lStr(1) = {['Triton ',PARAMS.ver]};
    lStr(2) = {'messages displayed here' };
    set(HANDLES.msg,'String',lStr,'Value',2);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Save Pick xyz into file
elseif strcmp(action,'savepicks')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    boxTitle1 = 'Log Picks File';
    filterSpec1 = '*.pik.txt';
    [infile,inpath]=uiputfile(filterSpec1,boxTitle1);
    % if the cancel button is pushed, then no file is loaded so exit this script
    if strcmp(num2str(infile),'0')
        return
    else % give user some feedback
        disp_msg('Log Picks File: ')
        disp_msg(fullfile(inpath,infile))
        pick = char(get(HANDLES.pick.disp,'String'));
        [pr,pc] = size(pick);
        fid = fopen(fullfile(inpath,infile),'w');
        for k = 1:pr
            fprintf(fid,'%s\r\n',pick(k,:));
        end
        fclose(fid);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(action,'exit')
    close(HANDLES.fig.main)
    close(HANDLES.fig.ctrl)
    close(HANDLES.fig.msg)
    close(HANDLES.fig.dt)
end;


