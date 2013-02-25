function h = stripplot(x,Fs,Options)
%STRIPPLOT  Strip plot.
%   stripplot(X) plots vector X in horizontal strips of length 250.
%   If X is a matrix, stripplot(X) plots each column of X in horizontal
%   strips.  The left-most column (column 1) is the top horizontal strip.
%
%   STRIPS(X,Fs) plots vector X in horizontal strips with appropriate
%	time axis.
%
%   If X is a matrix, stripplot will plot the different columns of X 
%	on the same strip plot.
%
%   STRIPS ignores the imaginary part of X if it is complex.
%
%   See also PLOT, STEM.

%   The Options argument is a record which supports the following
%   records:
%
%	.scale - scale all data by value
%	.bw - if non-zero, uses a single color and cycles through
%		the four line styles
%	.legend - Text for legend
%	.label - If non zero, add labels to the plot
%		Options.labels().*
%			These MUST be sorted by time.  This can
%			be done with the sortrecords command.
%			(devel:  Consider providing wrapper)
%			t - time
%			text - text to plot, the character | will
%				draw a vertical line on the current
%				strip.
%	.title - Graph title
%	.time - Time at which the this plot should start.  Useful
%		for data which does not begin at time 0.
%	.stripduration - Time length of each strip.
%	.timeperplot - Plots which cover too much time for a given
%		sampling rate are difficult to read as the data
%		becomes too squashed.  If timeperplot is specified 
%		mutliple plots are generated with the appropriate
%		amount of time.  
%		
%

%   Mark W. Reichelt and Thomas P. Krauss  7-23-93
%   Copyright (c) 1988-96 by The MathWorks, Inc.
%   $Revision: 1.1.1.1 $  $Date: 2000/09/22 14:45:23 $
%   Revised by Marie Roch, 1997/05/26

error(nargchk(1,3,nargin))

SetLineOrder = 0;
StartTime = 0;
Label = 0;
scale = 1;
TitleSet = 0;
LegendSet = 0;

if isempty(x), return, end
[len, num_sigs] = size(x);

if nargin == 1
  Fs = 1;
  scale = 1;
  [sd,c] = size(x);
  if min(sd,c) == 1
      sd = 250;
  end
  x = x(:);
else
  if nargin<2
    Fs = 1;
  else
    % Strip duration specified?
    if isfield(Options, 'stripduration')
      sd = Options.stripduration;
    else
      sd = 2;
    end
    % Scaling desired?
    if isfield(Options, 'scale')
      scale =  Options.scale;
    end
    % Single color plot to allow line order cycling?
    if isfield(Options, 'bw')
      if Options.bw
	SetLineOrder = 1;
      end
    end
    
    % Title?
    if isfield(Options, 'title')
      TitleSet = 1;
      TitleString = Options.title;
    end
    % Legend?
    if isfield(Options, 'legend')
      LegendSet = 1;
    end
    
    % Text labels
    if isfield(Options, 'label')
      if Options.label == 1
	Label = 1;
      end
    end
    
    % start time
    if isfield(Options, 'time')
      StartTime  = Options.time;
    end
    
    % per plot time limitations
    if isfield(Options, 'timeperplot')
      TimePerPlot = Options.timeperplot;
      if (len / Fs > TimePerPlot)
	MaxIdx = floor(TimePerPlot * Fs);
	Plots = ceil(len / Fs / TimePerPlot);
	stripplot(x(1:min(len,MaxIdx),:), Fs, Options);
	for k=2:Plots
	  figure;
	  Options.time = StartTime + (k-1)*TimePerPlot;
	  stripplot(x((k-1)*MaxIdx+1:min(len,k*MaxIdx),:), ...
	      Fs, Options);
	end
	return;
      end
    end % end if isfield
  end
end

if isempty(x), return, end
if min(size(x))==1, x = x(:); end   % turn vectors into columns

if any(imag(x)~=0), 
  disp('Warning: X vector complex.  I''m ignoring the imaginary part.')
  x = real(x);
end

perstrip = ceil(sd * Fs);	% strip duration * number of samples per second

if rem(len,perstrip) == 1	% leave off last point if it's a singleton
  len = len - 1;
  x = x(1:len,:);
end
num_strips = ceil(len/perstrip);

xmax = max(max( x(find(~isnan(x))) ));
xmin = min(min( x(find(~isnan(x))) ));
x0 = 0.5 * (xmin + xmax);

x = scale * x;

% add NaN's to the vector x
NaNind = len+1:perstrip*num_strips;
if ~isempty(NaNind)
    x(NaNind,:)=NaN*ones(length(NaNind),num_sigs);
end

% compute vertical deviation to add to x
del = 0.25 * (xmax-xmin);
del45 = 0.45 * (xmax - xmin);
sep = (xmax-xmin) + del;
if sep == 0, sep = 1; end
deviation = (num_strips-1:-1:0)*sep;

Y = zeros((perstrip+1)*num_strips,num_sigs);
for l = 1:num_sigs
    y = [reshape(x(:,l),perstrip,num_strips); NaN*ones(1,num_strips)];

    % add vertical deviation to x
    y = y - x0 + deviation(ones(perstrip+1,1),:);
    Y(:,l) = y(:);
end

% compute horizontal (time) axis
t = (0:perstrip-1)'/Fs;
t = t(:,ones(1,num_strips));
t(perstrip+1,:) = NaN + zeros(1,num_strips);
t = t(:);

% compute yticks and yticklabels
yt = (0:num_strips-1)*sep;   % ticks
width = 32;
s = setstr(ones(num_strips, width) * ' ');
col = width + 1;
for i = 1:num_strips
   str = num2str((i-1)*sd);
   s(i,width-length(str)+1:width) = str;
   col = min(col,width-length(str)+1);
end
s = flipud(s);
s = s(:,col:width);

% plot and set axes properties
handle = newplot;
HoldState = ishold;
if SetLineOrder
  % The only way I know to force cycling through line types
  % is draw in one color.  Better way?
  colorcube=get(handle,'ColorOrder');
  set(handle, 'ColorOrder', colorcube(1,:));
  set(handle, 'LineStyleOrder', '-|--|:');
  hold on;
end
plot(t+StartTime,Y)
set(gca,'xlim',[0 sd]+StartTime,'ylim',xmin-x0+[-del ...
      sep*num_strips],'ytick',yt,'yticklabel',s,'ygrid','on')
if TitleSet
  title(TitleString);
end
if LegendSet
  legend(Options.legend)
end

if Label
  hold on
  EndTime = StartTime + len/Fs;
  idx = 1;
  % Move to first label
  lastidx = length(Options.labels);
  done = 0;
  while (~ done)
    if idx > lastidx
      done = 1;
    else
      if Options.labels(idx).t <= StartTime
	idx = idx + 1;
      else
	done = 1;
      end
    end
  end
  done = 0;
  while (~ done)
    if idx > lastidx
      done = 1;
    else
      if Options.labels(idx).t <= EndTime
	% Locate time on x axis
	sampleidx = (Options.labels(idx).t - StartTime) * Fs; 
	time = rem((Options.labels(idx).t - StartTime), sd) + StartTime;
	%rem(sampleidx, perstrip);
	vert = deviation(...
	    min(num_strips,max(1,ceil(sampleidx / perstrip)))) + del45;
	if strcmp(Options.labels(idx).text, '|')
	  % text is special character |, draw line
	  plot([time, time], [vert, vert - 2* del45], 'w:');
	else
	  text('Position', [time, vert], ...
	      'FontSize', 6, 'HorizontalAlignment', 'Center', ...
	      'String', Options.labels(idx).text);
	end
	idx = idx + 1;
      else
	done = 1;
      end
    end
  end
end
  
if ~ HoldState
  hold off
end
