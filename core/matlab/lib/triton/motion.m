function motion(action)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% motion.m
%
% control motion of plot windown with push buttons in control window
%
% 5/5/04 smw
%
% 060211 - 060227 smw modified for v1.60
%%
% Do not modify the following line, maintained by CVS
% $Id: motion.m,v 1.1.1.1 2006/09/23 22:31:54 msoldevilla Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global PARAMS HANDLES
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
if strcmp(action,'forward')
    %
    % forward button
    %
    % plot next frame
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if PARAMS.tseg.step ~= -1
        PARAMS.plot.dnum = PARAMS.plot.dnum + datenum([0 0 0 0 0 PARAMS.tseg.step]);
    else
        PARAMS.plot.dnum = PARAMS.plot.dnum + datenum([0 0 0 0 0 PARAMS.tseg.sec]);
    end
    PARAMS.plot.dvec = datevec(PARAMS.plot.dnum);
     set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    readseg
    plot_triton
     set(HANDLES.fig.ctrl, 'Pointer', 'arrow'); % put pointer back
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 
elseif strcmp(action,'back')
    %
    % back button
    %
    % plot previous frame
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if PARAMS.tseg.step ~= -1
        PARAMS.plot.dnum = PARAMS.plot.dnum - datenum([0 0 0 0 0 PARAMS.tseg.step]);
    else
        PARAMS.plot.dnum = PARAMS.plot.dnum - datenum([0 0 0 0 0 PARAMS.tseg.sec]);
    end
    PARAMS.plot.dvec = datevec(PARAMS.plot.dnum);
    readseg
    plot_triton
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 
elseif strcmp(action,'autof')
    %
    % autof button - plot next frame
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % turn off menus and buttons while autorunning
    control('menuoff');
    control('buttoff');
    %
    % turn Stop button back on
    set(HANDLES.motion.stop,'Userdata',1);	% turn on while loop condition
    set(HANDLES.motion.stop,'Enable','on');	% turn on the Stop button
    while (get(HANDLES.motion.stop,'Userdata') == 1)
        motion('forward')
        pause(PARAMS.aptime);
    end
    % turn buttons and menus back on
    control('menuon')
        figure(HANDLES.fig.ctrl)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'autob')
    %
    % autob button - plot previous frame
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % turn off menus and buttons while autorunning
    control('menuoff');
    control('buttoff');
    % turn Stop button back on
    set(HANDLES.motion.stop,'Userdata',1);	% turn on while loop condition
    set(HANDLES.motion.stop,'Enable','on');	% turn on the Stop button
    while (get(HANDLES.motion.stop,'Userdata') == 1)
        motion('back')	% step back one frame
        pause(PARAMS.aptime);				% wait (needed on fast machines)
    end
    % turn menus back on
    control('menuon')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'stop')
    %
    % stop button - keep current frame
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.motion.stop,'Userdata',-1)
    control('button')
    control('menuon')
    set(HANDLES.motion.stop,'Enable','off');	% turn off Stop button
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'seekbof')
    %
    % goto beginning of file button - plot first frame
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    PARAMS.plot.dnum = PARAMS.start.dnum;
    PARAMS.plot.dvec = datevec(PARAMS.plot.dnum);
    readseg
    plot_triton
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(action,'seekeof')
    %
    % goto end of file button - plot last frame
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    PARAMS.plot.dnum = PARAMS.end.dnum - datenum([0 0 0 0 0 PARAMS.tseg.sec]);
        PARAMS.plot.dvec = datevec(PARAMS.plot.dnum);
    readseg
    plot_triton
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end;
