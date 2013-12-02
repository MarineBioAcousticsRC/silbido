function initparams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% initparams.m
% 
% initialize parameters
%
% 5/5/04 smw
% updated 060203 - 060227 smw
%
% Do not modify the following line, maintained by CVS
% $Id: initparams.m,v 1.9 2008/01/11 21:31:49 msoldevilla Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global PARAMS HANDLES

if ispc
  rootdir = 'c:';
else
  rootdir = '/';
end
defaultparamfile = fullfile(rootdir,'default.prm');


% get matlab version for differences and backwards capatibility
PARAMS.mver = version;

% Set the defaults first
PARAMS.inpath = rootdir;    % default dir
PARAMS.infile='';           % no default file
PARAMS.netpath=[];          % no netpath
PARAMS.run_mat='';        % matlab script to run
PARAMS.ptype = 1;				% first display type 
PARAMS.fax = 0;                  % linear or log freq axis
PARAMS.aptime = 0;			%  pause time (typically CPU speed dependent?
PARAMS.bright = 10;				% shift in dB
PARAMS.contrast = 100;			% amplify in % dB
PARAMS.freq0 = 0;				% set frequency PARAMS lower limit
PARAMS.freq1 = -1;         % set frequency PARAMS upper limit
PARAMS.nfft = 1000;			% length of fft
PARAMS.overlap = 50;			% %overlap
PARAMS.cmap = 'jet';			% color map for spectrogramn
PARAMS.tseg.step = -1;      % Step size (== dur by default)
PARAMS.ttype = 'seg';        % Time reference type
PARAMS.pspeed = 1;         % Playback speed factor
PARAMS.fPARAMS = 1;         % At first, automatically try to load PARAMS when over
PARAMS.last.sec = -1;       % To stop infinite recursion on unavailable PARAMS

PARAMS.hT = 'x';            % User defined transfer function for time series

PARAMS.ch = 1;               % channel number for wav PARAMS
PARAMS.nch = 1;              % total number of channels in wav file

% Values for Image Output
PARAMS.ioft = 'tif';			% TIF default filetype
PARAMS.iobd = 8;				% 8 bits per pixel default bit depth
PARAMS.iocq = 80;				% 80% default quality on compression
PARAMS.ioct = 'packbits';	% packbits default compression type

% filter parameters
PARAMS.filter = 0;
PARAMS.ff1 = 2000;
PARAMS.ff2 = 10000;

PARAMS.gainflag = 1;         % do pre amp gain on obs data (1=yes,0=no)

PARAMS.tseg.sec = 1;         % initial window time segment duration

PARAMS.blk.max = 1;          % max number of blocks (not used anymore?)

% Overwrite any defaults with those in the user's file
if exist(defaultparamfile) == 2
    % open data file
    PARAMS.paramfid = fopen(defaultparamfile,'r');
    if PARAMS.paramfid == -1
        disp_msg('Error: no such file')
        return
    end
    nparam = str2num(fgets(PARAMS.paramfid));
    if nparam < 1
        disp_msg('Error: no data in defaults file')
    else
        for i = 1 : nparam
            line = fgets(PARAMS.paramfid);
            %  junk=evalc(line);
        end
        %    echo on
    end
    fclose(PARAMS.paramfid);
end

PARAMS.c2p.db = 63.4;
PARAMS.c2p.lin = 1.491e-3;
PARAMS.secday = 24*60*60;	% seconds per day

% Regular expression to parse dates in (YY)YYMMDD-HHMMSS format.
PARAMS.fnameTimeRegExp{1} = ...
    '(?<yr>(\d\d)?\d\d)(?<mon>\d\d)(?<day>\d\d)-(?<hr>\d\d)(?<min>\d\d)(?<s>\d\d)';
PARAMS.start.dnum = datenum([0 1 1 0 0 0]);

PARAMS.cancel = 0;

PARAMS.window = 'hanning';

PARAMS.xgain = 2;

PARAMS.speedFactor = 1;
PARAMS.sndVol = 0.25;

PARAMS.delimit.value = 1;
HANDLES.delimit.tsline = 0;
HANDLES.delimit.sgline = 0;
PARAMS.pick.button.value = 0;
PARAMS.zoomin.button.value = 0;
PARAMS.button.down = 0;

PARAMS.tf.freq = [10 100000];   % freq [Hz]
PARAMS.tf.uppc = [0 0];   % uPa/count [dB]
PARAMS.tf.flag = 0;
PARAMS.tf.filename = [];    % start with an empty filename

ltsainfo = init_ltsaparams;     % Initialize LTSA parameter data
PARAMS.ltsa = ltsainfo.ltsa;
PARAMS.ltsahd = ltsainfo.ltsahd;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% initialize recording params
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.rec.sr = 200;
PARAMS.rec.int = 0;
PARAMS.rec.dur = 0;

% Default spectrogram detection parameters
PARAMS.dt.WhistlePos = 1;
PARAMS.dt.ClickPos = 2;
PARAMS.dt.Ranges = [5500 22000          % whistles
    10000 100000];      % clicks
PARAMS.dt.MinClickSaturation = 10000; 
PARAMS.dt.MaxClickSaturation = diff(PARAMS.dt.Ranges(PARAMS.dt.ClickPos,:));
PARAMS.dt.WhistleMinLength_s = .25;
PARAMS.dt.WhistleMinSep_s = .0256;
PARAMS.dt.Thresholds = [12,12];
PARAMS.dt.MeanAve_s = Inf;

% Default label parameters
PARAMS.dt.class.ValidLabels = false;  % available labels to plot?
PARAMS.dt.class.PlotLabels = false;   % plot control
