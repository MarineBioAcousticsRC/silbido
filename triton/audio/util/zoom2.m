function zoom2(varargin)
% Fixed version of zoom, handles user generated labels correctly.

switch nargin
  case 0
    fig=get(0,'currentfigure');
  case 1
    if isstr(varargin{1}),
      fig=get(0,'currentfigure');
      if isempty(fig), return, end
    else
      fig=get(0,'currentfigure');
    end
  case 2
    fig=varargin{1};
end

if isempty(fig), return, end
cax = get(fig,'currentaxes');

if strcmp(get(cax, 'YTickLabelMode'), 'manual')
  set(cax, 'YTickMode', 'manual');
end

if strcmp(get(cax, 'XTickLabelMode'), 'manual')
  set(cax, 'XTickMode', 'manual');
end

zoom(varargin{:})
