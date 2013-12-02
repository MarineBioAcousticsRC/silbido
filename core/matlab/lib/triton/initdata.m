function initdata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% initdata.m
%
% initializes data and timing info
%
% 5/5/04 smw
%
% 060211 060227 smw updated for v1.60
%%
% Do not modify the following line, maintained by CVS
% $Id: initdata.m,v 1.5 2008/01/11 21:31:49 msoldevilla Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global HANDLES PARAMS DATA

set(HANDLES.fig.ctrl, 'Pointer', 'watch');

% Initialize PARAMS.xhd and PARAMS.raw
PARAMS.xhd = [];    % cleans out previous xwav file header params
PARAMS.raw = [];

% Initial times for both formats:
PARAMS.save.dnum = PARAMS.start.dnum;
PARAMS.start.dvec = datevec(PARAMS.start.dnum);

% Harp Chunk stuff incase it doesn't get set some other way ie wav file
% read
PARAMS.xhd.WavVersionNumber = 0;            % harp wav header version number
PARAMS.xhd.FirmwareVersionNuumber = '1.xxxyyyzz';   % arp firmware version number, 10 chars
PARAMS.xhd.InstrumentID = '01  ';       % harp instrument number
PARAMS.xhd.SiteName = 'ABCD';             % site name
PARAMS.xhd.ExperimentName = 'EXP12345';   % experiment name
PARAMS.xhd.DiskSequenceNumber = 1;             % disk sequence number
PARAMS.xhd.DiskSerialNumber = '12345678'; % disk serial number
PARAMS.xhd.NumOfRawFiles = 1;
PARAMS.xhd.Longitude = -17912345;
PARAMS.xhd.Latitude = 8912345;
PARAMS.xhd.Depth = 6666;

fname = fullfile(PARAMS.inpath, PARAMS.infile);
if PARAMS.ftype == 1
    % initialize data format
    m = [];
    [m d] = wavfinfo(fname);
    if isempty(m)
        disp_msg(d)
        disp_msg('Try running wavDirTestFix.m on this directory to fix wav files')
        return
    end
    [y, Fs, PARAMS.nBits, OPTS] = wavread(fname,10);
    siz = wavread(fname, 'size' );
    PARAMS.samp.data = siz(1);
    PARAMS.nch = siz(2);
    PARAMS.samp.byte = floor(PARAMS.nBits/8);
    PARAMS.fs = Fs; % sample rate
    % just in case making xwav file out of wav file
    PARAMS.xhd.BitsPerSample = PARAMS.nch * PARAMS.samp.byte;
    PARAMS.xhd.ByteRate = PARAMS.fs*PARAMS.xhd.BitsPerSample;
    PARAMS.end.sample = PARAMS.samp.data;       % last sample of file
    PARAMS.end.dnum = PARAMS.start.dnum + datenum([0 0 0 0 0 PARAMS.end.sample/PARAMS.fs]);

elseif PARAMS.ftype == 2
    rdxwavhd
end
%
% data block set up
PARAMS.samp.head = 0;
PARAMS.samp.null = 0;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% set up time stuff
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if PARAMS.freq1 == -1 | PARAMS.freq1 > PARAMS.fs/2
    PARAMS.freq1 = PARAMS.fs/2;
    set(HANDLES.endfreq.edtxt,'String',PARAMS.freq1);
    PARAMS.freq0 = 0;
end
PARAMS.fmax = PARAMS.fs/2;
%
PARAMS.freq1 = PARAMS.fmax;  % always display full scale when opening new file
set(HANDLES.endfreq.edtxt,'String',PARAMS.freq1);   % update editable text control
%
if PARAMS.ftype == 1
    PARAMS.plot.dvec = PARAMS.start.dvec;
    PARAMS.plot.dnum = PARAMS.start.dnum;
    % new stuff needed v1.60
        PARAMS.raw.dnumStart = PARAMS.start.dnum;
        PARAMS.raw.dvecStart = PARAMS.start.dvec;
        PARAMS.raw.dnumEnd = PARAMS.end.dnum;
        PARAMS.raw.dvecEnd = datevec(PARAMS.end.dnum);
elseif PARAMS.ftype == 2
    % plot initial start time
    PARAMS.plot.dvec = PARAMS.start.dvec;
    PARAMS.plot.dnum = PARAMS.start.dnum;
end
%
set(HANDLES.chan,'Visible','on');
if PARAMS.nch >= 1 && PARAMS.nch < 10
    % Create channel menu entries 1|2|3|...
    MenuEntries = sprintf('%d|', 1:PARAMS.nch);
    set(HANDLES.ch.pop,'String',MenuEntries(1:end-1));   % don't use last '|'
elseif PARAMS.nch >= 10
    disp_msg(['Too many channels - should be less than 10'])
    disp_msg(sprintf('Total number of channels is :  %d',PARAMS.nch))
end
% Previous channel may have been > currently available
if PARAMS.ch > PARAMS.nch
    DefaultChannel = 1;
    disp_msg(sprintf(...
        'Channel %d does not exist in this data, setting to %d', ...
        PARAMS.ch, DefaultChannel));
    % Set current channel to default and update GUI
    PARAMS.ch = DefaultChannel;
    set(HANDLES.ch.pop,'Value', PARAMS.ch);
end
%
% turn on mouse movement display
set(HANDLES.fig.main,'WindowButtonMotionFcn','control(''coorddisp'')');

set(HANDLES.fig.main,'WindowButtonDownFcn',...
    'pickxyz');

% turn on msg window edit text box for pickxyz display
set(HANDLES.pick.disp,'Visible','on')
% turn on pickxyz toggle button
set(HANDLES.pick.button,'Visible','on')
% enable msg window File pulldown save pickxyz
set(HANDLES.savepicks,'Enable','on')

set(HANDLES.filtcontrol,'Visible','on')
set(HANDLES.displaycontrol,'Visible','on')
% if isempty(DATA)
%     set(HANDLES.display.timeseries,'Value',1);
% end
% turn on tools
% turn on sound control
if( exist('audioplayer') )
    %audvidplayer
    set(HANDLES.sndcontrol,'Visible','on')
else
    disp_msg('no audioplayer')
    % snd_v140
end

% Detection parameters
if ~ isfield(PARAMS, 'dt') || ~ isfield(PARAMS.dt, 'Enabled') 
    % set default detection if not already done
    PARAMS.dt.Enabled = get(HANDLES.dt.Enabled, 'Value');
end

