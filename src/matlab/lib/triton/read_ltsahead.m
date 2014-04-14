function read_ltsahead
%
% read LTSA header and directories 
%
% 060612 smw ver 1.61
%
% tic
%
% Do not modify the following line, maintained by CVS
% $Id: read_ltsahead.m,v 1.1.1.1 2006/09/23 22:31:55 msoldevilla Exp $

global PARAMS HANDLES

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Read long term spectral average header
hdr = ioReadLTSAHeader([PARAMS.ltsa.inpath,PARAMS.ltsa.infile]);

% Copy all of the header fields into PARAMS.ltsa
fields = fieldnames(hdr);
for idx=1:length(fields)
  subfields = fieldnames(hdr.(fields{idx}));
  for subidx = 1:length(subfields);
    PARAMS.(fields{idx}).(subfields{subidx}) = ...
        hdr.(fields{idx}).(subfields{subidx});
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

% t=toc;
% disp_msg(['Time to read ltsahead = ',num2str(t)])

