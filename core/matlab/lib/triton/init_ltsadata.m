function init_ltsadata
%
% initialize ltsa data stuff
%
% 060525 smw ver 1.61
%
% Do not modify the following line, maintained by CVS
% $Id: init_ltsadata.m,v 1.4 2007/06/30 01:58:01 mroch Exp $
global PARAMS HANDLES

hdr = ioReadLTSAHeader(...
    fullfile(PARAMS.ltsa.inpath, PARAMS.ltsa.infile));
PARAMS.ltsa = hdr.ltsa;
PARAMS.ltsahd = hdr.ltsahd;

% If a regular expression for parsing filenames exists, 
% update the global parameters.
if isfield(PARAMS.ltsa, 'fnameTimeRegExp')
  PARAMS.fnameTimeRegExp = PARAMS.ltsa.fnameTimeRegExp;
end

% Determine which channel should be used by default in xwav/wav
if PARAMS.ltsa.ch == 0
  PARAMS.ch = 1;        % handle older LTSAs that did not save channel
else
  PARAMS.ch = PARAMS.ltsa.ch;
end
set(HANDLES.ch.pop,'Value',PARAMS.ch);

% plot initial start time
PARAMS.ltsa.plot.dvec = PARAMS.ltsa.start.dvec;
PARAMS.ltsa.plot.dnum = PARAMS.ltsa.start.dnum;

% Initial times for both formats:
PARAMS.ltsa.save.dnum = PARAMS.ltsa.start.dnum;
PARAMS.ltsa.start.dvec = datevec(PARAMS.ltsa.start.dnum);

if isfield(PARAMS.ltsa, 'dt') && ~ isfield(PARAMS.ltsa.dt, 'Enabled')
    % set default detection if not already done
    PARAMS.ltsa.dt.Enabled = get(HANDLES.ltsa.dt.Enabled, 'Value');
end

% turn on zoomin toggle button
set(HANDLES.ltsa.zoomin.button,'Visible','on')

% initialize controls

set(HANDLES.ltsa.endfreq.edtxt,'String',num2str(PARAMS.ltsa.fmax))

% turn on mouse coordinate display
set(HANDLES.fig.main,'WindowButtonMotionFcn','control(''coorddisp'')');
set(HANDLES.fig.main,'WindowButtonDownFcn','pickxyz');

% turn on msg window edit text box for pickxyz display
set(HANDLES.pick.disp,'Visible','on')
% turn on pickxyz toggle button
set(HANDLES.pick.button,'Visible','on')
% enable msg window File pulldown save pickxyz
set(HANDLES.savepicks,'Enable','on')




