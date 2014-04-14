function mk_ltsa(ltsainfo)
%
% make long-term spectral averages from WAV/XWAV files.  Files
% and LTSA creation parameters are specified by the ltasinfo
% structure which contains substructures ltsa and ltsahd, which
% mirror the global LTSA structures PARAMS.ltsa and PARAMS.ltsahd.
%
% 060612 smw
%
%
% Do not modify the following line, maintained by CVS
% $Id: mk_ltsa.m,v 1.8 2008/11/15 17:08:06 mroch Exp $

global PARAMS HANDLES

% read data file headers
[ltsainfo, success] = get_headers(ltsainfo);
if ~ success
  disp_msg('LTSA Generation failed reading audio descriptors');
  errordlg(['Unable to read audio descriptors (headers).  ', ...
            'Was format specified correctly?'], ...
           'LTSA Generation failed');
  return
end

% check some ltsa parameter and other stuff:
[ltsainfo, success] = ck_ltsaparams(ltsainfo);
if ~ success
  disp_msg('LTSA Generation failed parameter check');
  errordlg(['LTSA Generation - problem with parameters, see Message log ' ...
            'for details.']);
  return
end
  
% Request file name to save as
DefaultName = fullfile(ltsainfo.ltsa.indir, 'LTSAout.ltsa');
[filename, dir] = uiputfile('*.ltsa', 'Save LTSA File', DefaultName);
if ~ isstr(filename)
  return;       % User cancelled
end
% setup lsta file header + directory listing
[ltsainfo.ltsa, ltsainfo.ltsahd, success] = ...
    ioWriteLTSAHeader(ltsainfo.ltsa, ltsainfo.ltsahd, dir, filename);
if ~ success
  disp_msg('LTSA unable to write LTSA descriptor');
  return        % failure cause written in ioWriteLTSAHeader
end

% Preserve detection paramers if present
% if isfield(PARAMS.ltsa, 'dt')
%   ltsa.dt = PARAMS.ltsa.dt;
% end

% Point of no return.  At this point we copy the temporary ones
% into the global data structure.  If we fail after this point
% the global data structure may be inconsistent.
disp_msg('LTSA:  Starting computation.');
drawnow expose

PARAMS.ltsa = ltsainfo.ltsa;
PARAMS.ltsahd = ltsainfo.ltsahd;

% calculated averaged spectra

success = calc_ltsa;
if ~ success
  disp_msg('LTSA:  Computation failed.');
  return;
end

% might as well plot it up:
% used to call initparams, but resets all the parameters which
% is not what we want here.
ltsainfo = init_ltsaparams;     % Initialize LTSA parameter data
PARAMS.ltsa = ltsainfo.ltsa;
PARAMS.ltsahd = ltsainfo.ltsahd;
PARAMS.ltsa.infile = filename;
PARAMS.ltsa.inpath = dir;

set(HANDLES.display.ltsa,'Visible','on')
set(HANDLES.display.ltsa,'Value',1);
set(HANDLES.ltsa.equal,'Visible','on')
control_ltsa('button')
set([HANDLES.ltsa.motion.seekbof HANDLES.ltsa.motion.back ...
     HANDLES.ltsa.motion.autoback HANDLES.ltsa.motion.stop], ...
    'Enable','off');
init_ltsadata
read_ltsadata
%
% need some sort of reset here on graphics and opened xwav file
% 060802smw
%
plot_triton
control_ltsa('timeon')   % was timecontrol(1)
                         % turn on other menus now
control_ltsa('menuon')
%control_ltsa('button')
control_ltsa('ampon')
control_ltsa('freqon')

set(HANDLES.ltsa.motioncontrols,'Visible','on')
% turns on radio button
set(HANDLES.fig.ctrl, 'Pointer', 'arrow');

%
% disp(PARAMS.ltsa)

disp('done - go home now')

