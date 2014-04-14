function helppd(action)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% helppd.m
%
% smw 12/13/04
%
% updated 060203-060227 smw
%
% 060525 smw ver 1.61
%
%
% Do not modify the following line, maintained by CVS
% $Id: helppd.m,v 1.3 2007/02/12 20:56:43 swiggins Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global PARAMS HANDLES

if strcmp(action,'dispAbout')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % initialize help window
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % window placement & size on screen
    defaultPos=[0.35,0.125,0.25,0.313];
    % open and setup figure window
    HANDLES.fig.help =figure( ...
        'NumberTitle','off', ...
        'MenuBar','none',...
        'Name',['Help - Triton ',PARAMS.ver],...
        'Units','normalized',...
        'Position',defaultPos);

    str1 = {['Triton Version ',PARAMS.ver]};

    str2(1) = {'ftp://cetus.ucsd.edu/outbox/Triton/'};
    str2(2) = {'email: cetus@ucsd.edu'};
    strPos= [0.025 0.05 0.95 0.90];

    if exist('Triton_logo.jpg')
        image(imread('Triton_logo.jpg'))
        axis off
    end
    
    FS = 8;
    text(50,50,str1,'FontSize',FS)
    text(0,750,str2,'FontSize',FS)

    % user clicks x which kills the figure, so HANDLES.fig.help doesn't
    % exist outside of this routine
    
elseif strcmp(action,'openManual')
    if exist('TritonHelp.pdf')
        open('TritonHelp.pdf')
    end
    
end

