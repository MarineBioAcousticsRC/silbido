function plot_timeseries
%
%
% 060205 smw modified to include red line
% for RawFile boundaries
%
% 060211-060227 smw individual plots for v1.60
%
%
% Do not modify the following line, maintained by CVS
% $Id: plot_timeseries.m,v 1.2 2007/05/12 01:25:05 mroch Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global DATA HANDLES PARAMS

% get which figures plotted
savalue = get(HANDLES.display.ltsa,'Value');
tsvalue = get(HANDLES.display.timeseries,'Value');
spvalue = get(HANDLES.display.spectra,'Value');
sgvalue = get(HANDLES.display.specgram,'Value');

% total number of plots in window
m = savalue + tsvalue + spvalue + sgvalue;

% ellipical filter
if PARAMS.filter
    [b,a] = ellip(4,0.1,40,[PARAMS.ff1 PARAMS.ff2]*2/PARAMS.fs);
    DATA = filter(b,a,DATA);
end

% DATA length
len = length(DATA);

% calculate delimiting line for RawFiles
rtime = (PARAMS.raw.dnumEnd(PARAMS.raw.currentIndex) - PARAMS.plot.dnum)...
    * 60 *60 * 24;
if rtime < PARAMS.tseg.sec
    rflag = 1;
    x = [rtime,rtime];
else
    rflag = 0;
end

% time series only
HANDLES.subplt.timeseries = subplot(HANDLES.plot.now);
HANDLES.plt.timeseries = plot((0:len-1)/PARAMS.fs,DATA);

% check to see if time series plot goes past end of data, if so,
% correct it
v = axis;
if v(2) > (len-1)/PARAMS.fs
    v(2) = (len-1)/PARAMS.fs;
    axis(v)
end
% plot red line if plot figure crosses RawFile boundary & delimit button on:
if rflag & PARAMS.delimit.value
    y = [v(3),v(4)];
    HANDLES.delimit.tsline = line(x,y,'Color','r','LineWidth',4);
end

%labels
ylabel('Amplitude [counts]')
xlabel('Time [seconds]')

% text positions
tx = [0 0.70 0.85];                 % x
ty = [-0.05 -0.125 -0.175 -0.25];  % y upper left&right
ty2 = [-0.075 -0.175 -0.25 -0.35];  % y lower right

if ~spvalue
    % put window start time on bottom plot only:
    text('Position',[0 ty(m)],'Units','normalized',...
        'String',timestr(PARAMS.plot.dnum,1));
end

% plot title on top plot
if ~sgvalue
    if PARAMS.filter == 1
        title([fullfile(PARAMS.inpath,PARAMS.infile),' CH=',num2str(PARAMS.ch),...
            '      Band Pass Filter ',num2str(PARAMS.ff1),' Hz to ',...
            num2str(PARAMS.ff2),' Hz'])
    else
        title([fullfile(PARAMS.inpath,PARAMS.infile),' CH=',num2str(PARAMS.ch)])
    end
end

% update control window with time info
set(HANDLES.time.edtxt1,'String',timestr(PARAMS.plot.dnum,3));
set(HANDLES.time.edtxt2,'String',timestr(PARAMS.plot.dnum,4));
set(HANDLES.time.edtxt3,'String',timestr(PARAMS.plot.dnum,5));
set(HANDLES.time.edtxt4,'String',num2str(PARAMS.tseg.sec));
