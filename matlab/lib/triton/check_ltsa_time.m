function check_ltsa_time(void)
%
%
% check to see if plot time is within file limits
%
% 060224 - 060227 smw
%
% 0602525 smw ver 1.61
%
%
% Do not modify the following line, maintained by CVS
% $Id: check_ltsa_time.m,v 1.2 2006/10/05 23:14:53 msoldevilla Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
global PARAMS HANDLES


%plot start time less than data start time
if PARAMS.ltsa.plot.dnum < PARAMS.ltsa.start.dnum
    disp_msg('Too early - Stay at current time')
    PARAMS.ltsa.plot.dnum = PARAMS.ltsa.save.dnum;
    set(HANDLES.ltsa.motion.stop,'Userdata',0);	% turn off while loop in autoback/fwd
    set([HANDLES.ltsa.motion.seekbof HANDLES.ltsa.motion.back HANDLES.ltsa.motion.autoback HANDLES.ltsa.motion.stop],'Enable','off');
    set([HANDLES.ltsa.motion.seekeof HANDLES.ltsa.motion.fwd HANDLES.ltsa.motion.autofwd],'Enable','on');
    return
% plot start time same as data start time    
elseif PARAMS.ltsa.plot.dnum == PARAMS.ltsa.start.dnum
    set([HANDLES.ltsa.motion.seekbof HANDLES.ltsa.motion.back HANDLES.ltsa.motion.autoback HANDLES.ltsa.motion.stop],'Enable','off');
    set([HANDLES.ltsa.motion.seekeof HANDLES.ltsa.motion.fwd HANDLES.ltsa.motion.autofwd],'Enable','on');
    set(HANDLES.ltsa.motion.stop,'Userdata',0);	% turn off while loop in autoback/fwd
% plot start time + plot duration greater than end of data time
% bogus for scheduled data
elseif PARAMS.ltsa.plot.dnum + datenum([0 0 0 PARAMS.ltsa.tseg.hr 0 0]) > PARAMS.ltsa.end.dnum
    disp_msg('Too late - Stay at current time')
    PARAMS.ltsa.plot.dnum = PARAMS.ltsa.save.dnum;
    set(HANDLES.ltsa.motion.stop,'Userdata',0);	% turn off while loop in autoback/fwd
    set([HANDLES.ltsa.motion.seekeof HANDLES.ltsa.motion.fwd HANDLES.ltsa.motion.autofwd HANDLES.ltsa.motion.stop],'Enable','off');
    set([HANDLES.ltsa.motion.seekbof HANDLES.ltsa.motion.back HANDLES.ltsa.motion.autoback],'Enable','on');
    return
% plot start time + plot duration same as data end time
% bogus for scheduled data
% turn on backs, off fwds and stop
elseif PARAMS.ltsa.plot.dnum + datenum([0 0 0 PARAMS.ltsa.tseg.hr 0 0]) == PARAMS.ltsa.end.dnum
    set([HANDLES.ltsa.motion.seekeof HANDLES.ltsa.motion.fwd HANDLES.ltsa.motion.autofwd HANDLES.ltsa.motion.stop],'Enable','off');
    set([HANDLES.ltsa.motion.seekbof HANDLES.ltsa.motion.back HANDLES.ltsa.motion.autoback],'Enable','on');
    set(HANDLES.ltsa.motion.stop,'Userdata',0);	% turn off while loop in autoback/fwd
%     disp_msg(['end.dnum= ',num2str(PARAMS.ltsa.plot.dnum)])
% not auto back and not auto forward
% turn all on except stop
else
    if ~get(HANDLES.ltsa.motion.autoback,'Value') & ~get(HANDLES.ltsa.motion.autofwd,'Value')
        set([HANDLES.ltsa.motion.seekbof HANDLES.ltsa.motion.back HANDLES.ltsa.motion.autoback...
         HANDLES.ltsa.motion.seekeof HANDLES.ltsa.motion.fwd HANDLES.ltsa.motion.autofwd],'Enable','on')
    end
end

% check to see if too large of a time segment to display
if PARAMS.ltsa.tseg.hr * 60 *60  > PARAMS.ltsa.durtot
    PARAMS.ltsa.tseg.hr = PARAMS.ltsa.durtot / (60 * 60);
    PARAMS.ltsa.tseg.sec = PARAMS.ltsa.durtot;
    disp_msg('Time segment too Large, set to full file')
    set(HANDLES.ltsa.time.edtxt3,'String',num2str(PARAMS.ltsa.tseg.hr));
    set([HANDLES.ltsa.motion.seekbof HANDLES.ltsa.motion.back HANDLES.ltsa.motion.autoback...
         HANDLES.ltsa.motion.seekeof HANDLES.ltsa.motion.fwd HANDLES.ltsa.motion.autofwd],'Enable','off')    
end

