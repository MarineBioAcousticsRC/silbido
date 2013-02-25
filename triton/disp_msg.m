function disp_msg(msg)
%
% display message in window
%
% 060219 smw
%
%
% Do not modify the following line, maintained by CVS
% $Id: disp_msg.m,v 1.1.1.1 2006/09/23 22:31:50 msoldevilla Exp $

global HANDLES

x = get(HANDLES.msg,'String');

lx = length(x);

x(lx+1) = {msg};

set(HANDLES.msg,'String',x,'Value',lx+1)

