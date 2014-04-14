function initpulldowns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% initpulldowns.m
%
% generate figure pulldown menus
%
% 5/5/04 smw
%
% 060224 - 060227 smw modified for v1.60
%%
% Do not modify the following line, maintained by CVS
% $Id: initpulldowns.m,v 1.6 2007/09/17 19:31:24 mroch Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global HANDLES
%
%%%%%%%%%%%%%%%%%%%%
%
% 'File' pulldown
%
%%%%%%%%%%%%%%%%%%%%
HANDLES.filemenu = uimenu(HANDLES.fig.ctrl,'Label','&File');
% 'Open long-term spectral average File (*.ltsa)'
% uimenu(HANDLES.filemenu,'Label','&Open PSDS File','Callback','filepd(''openltsa'')');
uimenu(HANDLES.filemenu,'Label','&Open LTSA File','Callback','filepd(''openltsa'')');
% 'Open Pseudo-Wav File (*.x.wav)'
uimenu(HANDLES.filemenu,'Label','Open &XWAV File','Callback','filepd(''openxwav'')');
% 'Open Wav File (*.wav)'
uimenu(HANDLES.filemenu,'Label','Open &WAV File','Callback','filepd(''openwav'')');
% Load Hydrophone Transfer Functions File
%
uimenu(HANDLES.filemenu,'Separator','on','Label','Load Transfer Function File',...
    'Enable','on','Callback','filepd(''loadTF'')');
       
%
% 'Save As Wav'
HANDLES.saveas = uimenu(HANDLES.filemenu,'Separator','on','Label','Save Plotted Data As &WAV',...
    'Enable','off','Callback','filepd(''savefileas'')');
% 'Save As XWav'
HANDLES.saveasxwav = uimenu(HANDLES.filemenu,'Separator','off','Label','Save Plotted Data As &XWAV',...
    'Enable','off','Callback','filepd(''savefileasxwav'')');
% 'Save JPG'
HANDLES.savejpg = uimenu(HANDLES.filemenu,'Label','Save Plotted Data As &JPG',...
    'Enable','off','Callback','filepd(''savejpg'')');
%
% 'Save Figure As'
HANDLES.savefigureas = uimenu(HANDLES.filemenu,'Separator','on',...
    'Label','Save Plotted Data As MATLAB &Figure',...
    'Visible','off',...
    'Enable','off','Callback','filepd(''savefigureas'')');
% 'Save Image As'
HANDLES.saveimageas = uimenu(HANDLES.filemenu,'Label','Save Spectrogram As &Image',...
    'Visible','off',...
    'Enable','off','Callback','filepd(''saveimageas'')');
%
% 'Exit'
uimenu(HANDLES.filemenu,'Separator','on','Label','E&xit',...
    'Callback','filepd(''exit'')');
%%%%%%%%%%%%%%%%%%
%
% 'Tools' pulldown
%
%%%%%%%%%%%%%%%%%%%
HANDLES.toolmenu = uimenu(HANDLES.fig.ctrl,'Label','&Tools',...
    'Enable','on');
%      uimenu(HANDLES.toolmenu,'Label','Run Matlab script',...
%          'Callback','toolpd(''run_mat'')');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% HRP file operations
%
HANDLES.hrpmenu = uimenu(HANDLES.toolmenu,'Label','HRP File Ops');
% 'Convert HRP disk file to XWAVS'
 uimenu(HANDLES.hrpmenu,'Label','Convert Multiple HRP Disk Files to XWAV Files',...
     'Callback','toolpd(''convert_multiHRP2XWAVS'')','Enable','off');
 uimenu(HANDLES.hrpmenu,'Label','Convert HRP Disk File to XWAV Files',...
     'Callback','toolpd(''convertHRP2XWAVS'')','Enable','off');
% % 'Read Disk HRP file header'
 uimenu(HANDLES.hrpmenu,'Label','Get HRP Disk File Header',...
     'Callback','toolpd(''get_HRPhead'')','Enable','on');
% % 'Read HRP Disk file directory listing of raw files'
uimenu(HANDLES.hrpmenu,'Label','Get HRP Disk File Directory',...
    'Enable','on','Callback','toolpd(''get_HRPdir'')','Enable','on');
% check directory listing times in HRP disk file Header
uimenu(HANDLES.hrpmenu,'Label','Check Directory List Times',...
    'Enable','on','Callback','toolpd(''ck_dirlist_times'')','Enable','on');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Convert Submenu:
%
HANDLES.convertmenu = uimenu(HANDLES.toolmenu,'Separator','on','Label','Convert');
%
uimenu(HANDLES.convertmenu,'Separator','on','Label','&Convert Single HARP FTP File to XWAV',...
    'Callback','toolpd(''convertfile'')');
% 'Convert ARP *.bin file'
uimenu(HANDLES.convertmenu,'Label','Convert Single &ARP BIN File to XWAV',...
    'Callback','toolpd(''convertARP'')');
% 'Convert OBS *.obs file'
uimenu(HANDLES.convertmenu,'Label','Convert Single &OBS File to XWAV',...
    'Callback','toolpd(''convertOBS'')');
% 'Convert ARP *.bin folder'
uimenu(HANDLES.convertmenu,'Separator','on','Label','Convert Directory of ARP BIN Files to XWAVs',...
    'Callback','toolpd(''convertMultiARP'')');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Header Ops
%
HANDLES.headmenu = uimenu(HANDLES.toolmenu,'Label','Headers');
HANDLES.editltsa = uimenu(HANDLES.headmenu,'Separator','on','Label','&Edit Header - LTSA File',...
    'Enable','off','Callback','toolpd(''editltsa'')');
% modify XWAV file
HANDLES.editxwav = uimenu(HANDLES.headmenu,'Label','&Edit Header - XWAV File',...
    'Enable','on','Callback','toolpd(''editxwav'')');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Decimate ops
%
HANDLES.decimenu = uimenu(HANDLES.toolmenu,'Label','Decimate');
%
% 'decimate xwav file'
uimenu(HANDLES.decimenu,'Separator','on','Label','&Decimate Single XWAV File',...
    'Enable','on','Callback','toolpd(''decimatefile'')');
% 'decimate xwav file directory'
uimenu(HANDLES.decimenu,'Label','&Decimate All XWAV Files in Directory',...
    'Enable','on','Callback','toolpd(''decimatefiledir'')');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Labels
%
HANDLES.labelmenu = uimenu(HANDLES.toolmenu, 'Label', 'Labels');
HANDLES.labelplot = uimenu(HANDLES.labelmenu, 'Separator','off','Label', ...
       'Display? ', 'Checked', 'off', ...
       'Enable', 'on', 'Callback', 'toolpd(''label-toggle'')');
uimenu(HANDLES.labelmenu, 'Separator','off','Label', ...
       'New label set', 'Enable', 'on', ...
       'Callback', 'toolpd(''label-replace'')');
uimenu(HANDLES.labelmenu, 'Separator','off','Label', ...
       'Add label set', 'Enable', 'off', ...
       'Callback', 'toolpd(''label-add'')');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Detect
%
HANDLES.detectmenu = uimenu(HANDLES.toolmenu,'Label','Detection (batch)');

% 'Long Term Spectral Avg
uimenu(HANDLES.detectmenu,'Separator','on','Label',...
       '&Long Term Spectral Avg (LTSA)', 'Enable', 'on', ...
       'Callback','toolpd(''dtLTSABatch'')');
% Short Time
uimenu(HANDLES.detectmenu, 'Separator','off', ...
       'Label', '&Short Time Spectrum (STS)', ...
       'Enable', 'on', 'Callback', 'toolpd(''dtShortTimeDetection'')');
% High resolution click detection (guided by STS detection)
uimenu(HANDLES.detectmenu,'Label','&High Res Click (STS Guided)',...
    'Enable','on','Callback','toolpd(''dtST_GuidedHRClickDet'')');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% generate LTSAs
%
uimenu(HANDLES.toolmenu,'Separator','on','Label','&Create LTSA',...
    'Enable','on','Callback','toolpd(''mkltsa'')');



%
%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 'Parameters' pulldown
%
%%%%%%%%%%%%%%%%%%%%%%%%%
HANDLES.parametersmenu = uimenu(HANDLES.fig.ctrl,'Label','&Parameters',...
    'Enable','off','Visible','off');
% set parameters
% load parameter file
uimenu(HANDLES.parametersmenu,'Label','&Load ParamFile',...
    'Callback','paramspd(''paramload'')');
% save parameter file
uimenu(HANDLES.parametersmenu,'Label','&Save ParamFile',...
    'Callback','paramspd(''paramsave'')');
%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 'Help' pulldown
%
%%%%%%%%%%%%%%%%%%%%%%%%%
HANDLES.helpmenu = uimenu(HANDLES.fig.ctrl,'Label','&Help',...
    'Enable','on');
% set parameters
uimenu(HANDLES.helpmenu,'Label','&About',...
    'Callback','helppd(''dispAbout'')');
uimenu(HANDLES.helpmenu,'Label','&Manual',...
    'Callback','helppd(''openManual'')');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Message window pulldown
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
HANDLES.msgmenu = uimenu(HANDLES.fig.msg,'Label','&File');
% 'Save messages'
HANDLES.savemsgs = uimenu(HANDLES.msgmenu,'Separator','off','Label','Save &Messages',...
    'Enable','on','Callback','filepd(''savemsgs'')');
HANDLES.clrmsgs = uimenu(HANDLES.msgmenu,'Separator','off','Label','Clear Messages',...
    'Enable','on','Callback','filepd(''clrmsgs'')');
% 'Save picks'
HANDLES.savepicks = uimenu(HANDLES.msgmenu,'Separator','off','Label','Save &Picks',...
    'Enable','off','Callback','filepd(''savepicks'')');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% some window stuff?
set(gcf,'Units','pixels');
axis off
axHndl1=gca;


%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Detection Parameters pulldown
%
%%%%%%%%%%%%%%%%%%%%%%%%%
HANDLES.dt.filemenu = uimenu(HANDLES.fig.dt,'Label','&File',...
    'Enable','on','Visible','on');
% load LTSA parameter file
uimenu(HANDLES.dt.filemenu,'Label','&Load LTSA ParamFile',...
    'Callback','dt_paramspd(''LTSAparamload'')');
% load spectrogram parameter file
uimenu(HANDLES.dt.filemenu,'Label','&Load Specgram ParamFile',...
    'Callback','dt_paramspd(''STparamload'')');

% save LTSA parameter file
uimenu(HANDLES.dt.filemenu,'Separator','on','Label','&Save LTSA ParamFile',...
    'Callback','dt_paramspd(''LTSAparamsave'')');
% save spectrogram parameter file
uimenu(HANDLES.dt.filemenu,'Label','&Save Specgram ParamFile',...
    'Callback','dt_paramspd(''STparamsave'')');
