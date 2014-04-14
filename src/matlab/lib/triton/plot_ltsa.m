function plot_ltsa
%
% plot_ltsa.m
%
% 060513 smw
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot psds in main figure window
% ripped off from plottseg.m
%
% smw 050117
%
% revised 051108 smw PARAMS.fax == 2 for kHz Y-axis
%
% modified 060211 - 060227 smw for triton v1.60
%
% 060612 smw v1.61
%
% Do not modify the following line, maintained by CVS
% $Id: plot_ltsa.m,v 1.8 2008/11/24 04:53:24 mroch Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global PARAMS HANDLES

% get which figures plotted
savalue = get(HANDLES.display.ltsa,'Value');
tsvalue = get(HANDLES.display.timeseries,'Value');
spvalue = get(HANDLES.display.spectra,'Value');
sgvalue = get(HANDLES.display.specgram,'Value');

% total number of plots in window
m = savalue + tsvalue + spvalue + sgvalue;

% get power
% pwr = PARAMS.ltsa.pwr(PARAMS.ltsa.fimin:PARAMS.ltsa.fimax,:);


% check and apply/remove ltsa equalization:
state1 = get(HANDLES.ltsa.eq.tog,'Value');
state2 = get(HANDLES.ltsa.eq.tog2,'Value');
eflag = 0;
if state1 == get(HANDLES.ltsa.eq.tog,'Max') & ...
        state2 == get(HANDLES.ltsa.eq.tog2,'Min')
    pwr = PARAMS.ltsa.pwr - mean(PARAMS.ltsa.pwr,2) * ones(1,length(PARAMS.ltsa.t));
    eflag = 1;
elseif state1 == get(HANDLES.ltsa.eq.tog,'Max') & ...
        state2 == get(HANDLES.ltsa.eq.tog2,'Max')
    pwr = PARAMS.ltsa.pwr - PARAMS.ltsa.mean.save* ones(1,length(PARAMS.ltsa.t));
    eflag = 2;
elseif state1 == get(HANDLES.ltsa.eq.tog,'Min')
    pwr = PARAMS.ltsa.pwr;
    eflag = 0;
end

% change plot freq axis
pwr = pwr(PARAMS.ltsa.fimin:PARAMS.ltsa.fimax,:);

c = (PARAMS.ltsa.contrast/100) .* pwr + PARAMS.ltsa.bright;

% plot specgram
HANDLES.subplt.ltsa = subplot(HANDLES.plot.now);
% set(HANDLES.subplt.ltsa,'FontUnits','normalized')

if PARAMS.ltsa.fax == 0
    HANDLES.plt.ltsa = image(PARAMS.ltsa.t,PARAMS.ltsa.f,c);
elseif PARAMS.ltsa.fax == 1
    flen = length(PARAMS.ltsa.f);
    [M,N] = logfmap(flen,4,flen);
    c = M*c;
    f = M*PARAMS.ltsa.f;
    HANDLES.ltsa.plt = image(PARAMS.ltsa.t,f,c);
    set(get(HANDLES.plt.ltsa,'Parent'),'YScale','log');
    set(gca,'TickDir','out')
elseif PARAMS.ltsa.fax == 2
    HANDLES.plt.ltsa = image(PARAMS.ltsa.t,PARAMS.ltsa.f/1000,c);
end

% interactive detection of regions of interest
varargin=[];
if PARAMS.ltsa.dt.ignore_periodic
    varargin={'LowPeriod_s', PARAMS.ltsa.dt.LowPeriod_s, 'HighPeriod_s', PARAMS.ltsa.dt.HighPeriod_s};
end
if PARAMS.ltsa.dt.Enabled
  [PARAMS.ltsa.dt.Candidates]= ...
      dtLT_signal(PARAMS.ltsa.pwr, ...
                  PARAMS.ltsa.dt.ignore_periodic,...
                  PARAMS.ltsa.dt.HzRange,...
                  PARAMS.ltsa.f, ...
                  PARAMS.ltsa.tave, ...
                  PARAMS.ltsa.dt.Threshold_dB,...
                  PARAMS.ltsa.dt.MeanAve_hr, ...
                  PARAMS.ltsa.dt.ifPlot, ...
                  varargin);
end

% check for classification labels
if PARAMS.dt.class.PlotLabels
  dtPlotLabels('ltsa', ...
               .9 * PARAMS.ltsa.f(PARAMS.ltsa.fimax)-PARAMS.ltsa.f(PARAMS.ltsa.fimin));
end

% shift and shrink plot by dv
dv = 0.075;
v = get(get(HANDLES.plt.ltsa,'Parent'),'Position');

axis xy

Pos = get(HANDLES.fig.main,'Position');

% colorbar
PARAMS.ltsa.cb = colorbar('vert');
% set(PARAMS.ltsa.cb,'FontUnits','normalized')

v2 = get(PARAMS.ltsa.cb,'Position');
set(PARAMS.ltsa.cb,'Position',[0.925 v2(2) 0.01 v2(4)])
yl=get(PARAMS.ltsa.cb,'YLabel');
set(yl,'String','Spectrum Level [dB re counts^2/Hz]')

% set color bar xlimit
minp = min(min(PARAMS.ltsa.pwr));
maxp = max(max(PARAMS.ltsa.pwr));
if minp == maxp
    maxp = minp+6;   % no range:  fake a 6 dB range
end
set(PARAMS.ltsa.cb,'YLim',[minp maxp])

% image (child of colorbar)
img_h = get(PARAMS.ltsa.cb,'Children');
minc = min(min(c));
maxc = max(max(c));
difc = 2;
set(img_h,'CData',[minc:difc:maxc]')
set(img_h,'YData',[minp maxp])
%set(img_h,'FontUnits','normalized')

% define colormapping
if strcmp(PARAMS.ltsa.cmap,'gray') % make negative colormap ie dark is big amp
    g = gray;
    szg = size(g);
    cmap = g(szg:-1:1,:);
    colormap(cmap)
else
    colormap(PARAMS.ltsa.cmap)
end

% labels
xlabel('Time [hours]')

% get freq axis label
ylim = get(get(HANDLES.plt.ltsa,'Parent'),'YLim');
ytick = get(get(HANDLES.plt.ltsa,'Parent'),'YTick');
if  ylim(2) < 10000
    set(get(HANDLES.plt.ltsa,'Parent'),'YtickLabel',num2str(ytick'))
    ylabel('Frequency [Hz]')
else
    set(get(HANDLES.plt.ltsa,'Parent'),'YtickLabel',num2str((ytick')./1000))
    ylabel('Frequency [kHz]')
end


% title - always displayed without LaTeX super/sub-script codes
title(fullfile(PARAMS.ltsa.inpath,PARAMS.ltsa.infile), 'Interpreter', 'none')

% text positions
tx = [0 0.70 0.85];                 % x
ty = [-0.05 -0.125 -0.175 -0.25];  % y upper left&right
ty2 = [-0.075 -0.175 -0.25 -0.35];  % y lower right

text('Position',[tx(1) ty(m)],'Units','normalized',...
    'String',timestr(PARAMS.ltsa.plot.dnum,6));
%     'String',[num2str(PARAMS.ltsa.start.yr),':',PARAMS.ltsa.start.str]);
text('Position',[tx(2) ty(m)],'Units','normalized',...
    'String',['Fs = ',num2str(PARAMS.ltsa.fs),', Tave = ',...
    num2str(PARAMS.ltsa.tave),'s, NFFT = ',num2str(PARAMS.ltsa.nfft)]);
HANDLES.ltsa.BC = text('Position',[tx(3) ty2(m)],'Units','normalized',...
    'String',['B = ',num2str(PARAMS.ltsa.bright),', C = ',num2str(PARAMS.ltsa.contrast)]);

% Spectrogram Equalization:
if eflag == 1 | eflag == 2
   text('Position',[tx(2) ty2(m)],'Units','normalized',...
    'String',['SG Equal On'])
end


% change time in control window to data time in plot window
set(HANDLES.ltsa.time.edtxt1,'String',timestr(PARAMS.ltsa.plot.dnum,6));


