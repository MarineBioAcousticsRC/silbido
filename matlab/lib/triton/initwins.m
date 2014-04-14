function initwins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% initwins.m
% 
% initialize figure, control and command(display) windows
%
% 5/5/04 smw
%
% updated 060211 - 060227 smw for triton v1.60
%
% 060517 smw - ver 1.61
%%
% Do not modify the following line, maintained by CVS
% $Id: initwins.m,v 1.3 2007/01/29 05:29:49 mroch Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% figure window
%
global HANDLES PARAMS

% give user some info
disp(' ');
disp(' Clearing all windows to begin Triton');
disp(' Now loading Triton initial screen...');
disp(' ');
% use screen size to change plot control window layout 
PARAMS.scrnsz = get(0,'ScreenSize');
% window placement & size on screen
%	defaultPos=[0.333,0.1,0.65,0.80];
defaultPos=[0.335,0.05,0.65,0.875];

% open and setup figure window
HANDLES.fig.main =figure( ...
    'NumberTitle','off', ...
    'Name',['Plot - Triton '], ...
    'Units','normalized',...
    'Position',defaultPos);
%
set(gcf,'Units','pixels');
% Tools for editing and annotating plots
% plotedit on		
% put axis in bottom left, make it tiny,
% turn it off, and save location in variable axHndl1
%set(gca,'position',[0 0 1 1]);
axis off
axHndl1=gca;

if exist('Triton_logo.jpg')
    image(imread('Triton_logo.jpg'))
end

axis off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% initialize control window
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% window placement & size on screen
defaultPos=[0.025,0.35,0.3,0.6];
% open and setup figure window
HANDLES.fig.ctrl =figure( ...
    'NumberTitle','off', ...
    'Name',['Control - Triton '],...
    'Units','normalized',...
    'MenuBar','none',...
    'Position',defaultPos);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% initialize message display window
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% window placement & size on screen
defaultPos=[0.025,0.05,0.3,0.25];
% open and setup figure window
HANDLES.fig.msg =figure( ...
    'NumberTitle','off', ...
    'Name',['Message - Triton ',PARAMS.ver],...
    'Units','normalized',...
    'MenuBar','none',...
    'Position',defaultPos);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% initialize detectors options window
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% window placement & size on screen
defaultPos=[0.005,0.035,0.3,0.25];
% open and setup figure window
HANDLES.fig.dt =figure( ...
    'NumberTitle','off', ...
    'Name','Detector Control - Triton v1.61',...
    'Units','normalized',...
    'MenuBar','none',...
    'Position',defaultPos, ...
    'Visible', 'off');

