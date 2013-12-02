function disp_pick(pick)
%
% display message in window
%
% 060219 smw
%
%
% Do not modify the following line, maintained by CVS
% $Id: disp_pick.m,v 1.1.1.1 2006/09/23 22:31:50 msoldevilla Exp $

global HANDLES

x = get(HANDLES.pick.disp,'String');

lx = length(x);

x(lx+1) = {pick};

set(HANDLES.pick.disp,'String',x,'Value',lx+1)

