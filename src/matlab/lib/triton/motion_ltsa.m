function motion_ltsa(action)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% motion_ltsa.m
%
% control motion of plot windown with push buttons in control window
%
%
% ripped off from triton v1.50 (motion.m)
% smw 050117 - 060227
%
% LTSA triton v1.61 smw 060524
%
%
% Do not modify the following line, maintained by CVS
% $Id: motion_ltsa.m,v 1.3 2007/11/30 00:18:11 mroch Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global PARAMS HANDLES

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if strcmp(action,'forward')
    %
    % forward button
    %
    % plot next frame
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PARAMS.ltsa.save.dnum = PARAMS.ltsa.plot.dnum;
    if PARAMS.ltsa.tseg.step ~= -1
        step_dnum = datenum([0 0 0 PARAMS.ltsa.tseg.step 0 0]);
    else
        step_dnum = datenum([0 0 0 PARAMS.ltsa.tseg.hr 0 0]);
    end
    [NewTime, RawIdx, Offset, Satisfied] = ...
        get_ltsatime(PARAMS.ltsa.plot.dnum, step_dnum, 'Relative');
    if ~ Satisfied
        disp_msg('LTSA at latest date.')
    end
    if NewTime ~= PARAMS.ltsa.plot.dnum
        PARAMS.ltsa.plot.dnum = NewTime;
        read_ltsadata
        plot_triton
    end

    %
elseif strcmp(action,'back')
    %
    % back button
    %
    % plot previous frame
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PARAMS.ltsa.save.dnum = PARAMS.ltsa.plot.dnum;
    % Determine how far back we need to go in terms of serialized
    % time.
    if PARAMS.ltsa.tseg.step ~= -1
        step_dnum = datenum([0 0 0 PARAMS.ltsa.tseg.step 0 0]);
    else
        step_dnum = datenum([0 0 0 PARAMS.ltsa.tseg.hr 0 0]);
    end
    [NewTime, RawIdx, Offset, Satisfied] = ...
        get_ltsatime(PARAMS.ltsa.plot.dnum, -step_dnum, 'Relative');
    if ~ Satisfied
        disp_msg('LTSA at earliest date.')
    end
    if NewTime ~= PARAMS.ltsa.plot.dnum
        PARAMS.ltsa.plot.dnum = NewTime;
        read_ltsadata
        plot_triton
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'autof') || strcmp(action, 'autob')
    %
    % autof button - plot next frame
    % or 
    % autob button - plot previous frame
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    switch action
     case 'autof'
      direction = 'forward';
     case 'autob'
      direction = 'back';
    end
    % turn off menus and buttons while autorunning
    control_ltsa('menuoff');
    control_ltsa('buttoff');
    
    % turn Stop button back on
    set(HANDLES.ltsa.motion.stop,'Userdata',1);	% turn on while loop condition
    set(HANDLES.ltsa.motion.stop,'Enable','on');	% turn on the Stop button
    while (get(HANDLES.ltsa.motion.stop,'Userdata') == 1)
        % timed update of the display
        tic
        motion_ltsa(direction)
        elapsed = toc;
        % delay for remaining time as specified by pause time
        remaining = PARAMS.ltsa.aptime - elapsed;
        if remaining > 0
            pause(PARAMS.ltsa.aptime);
        end
    end
    % turn buttons and menus back on
    control_ltsa('menuon')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'stop')
    %
    % stop button - keep current frame
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.ltsa.motion.stop,'Userdata',-1)
    control_ltsa('button')
    control_ltsa('menuon')
    set(HANDLES.ltsa.motion.stop,'Enable','off');	% turn off Stop button
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
elseif strcmp(action,'seekbof')
    %
    % goto beginning of file button - plot first frame
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    PARAMS.ltsa.plot.dnum = PARAMS.ltsa.start.dnum;
    read_ltsadata
    plot_triton
    set(HANDLES.ltsa.motion.seekbof,'Enable','off');
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(action,'seekeof')
    %
    % goto end of file button - plot last frame
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    [NewTime, RawIdx, Offset, Satisfied] = ...
        get_ltsatime(PARAMS.ltsa.end.dnum, ...
                     -datenum([0 0 0 PARAMS.ltsa.tseg.hr 0 0]), ...
                     'Relative');
%    PARAMS.ltsa.plot.dnum = PARAMS.ltsa.end.dnum ;
%     disp_msg(['plot.dnum= ',num2str(PARAMS.ltsa.plot.dnum)])
    PARAMS.ltsa.plot.dnum = NewTime;
    read_ltsadata
    plot_triton
    set(HANDLES.ltsa.motion.seekeof,'Enable','off');
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end;
