function plot_specgram
%
%
% 060205 smw modified to include red line
% for RawFile boundaries
%
% 060211 - 060227 smw
%%
% Do not modify the following line, maintained by CVS
% $Id: plot_specgram.m,v 1.8 2008/11/24 04:53:24 mroch Exp $
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

% calculate delimiting line for RawFiles
rtime = (PARAMS.raw.dnumEnd(PARAMS.raw.currentIndex) - PARAMS.plot.dnum)...
    * 60 *60 * 24;
if rtime < PARAMS.tseg.sec
    rflag = 1;
    x = [rtime,rtime];
else
    rflag = 0;
end

% make spectrogram
mkspecgram

% check and apply/remove spectrogram equalization:
state1 = get(HANDLES.sgeq.tog,'Value');
state2 = get(HANDLES.sgeq.tog2,'Value');
eflag = 0;
if state1 == get(HANDLES.sgeq.tog,'Max') & ...
        state2 == get(HANDLES.sgeq.tog2,'Min')
    sg = PARAMS.pwr - mean(PARAMS.pwr,2) * ones(1,length(PARAMS.t));
    eflag = 1;
elseif state1 == get(HANDLES.sgeq.tog,'Max') & ...
        state2 == get(HANDLES.sgeq.tog2,'Max')
    sg = PARAMS.pwr - PARAMS.mean.save* ones(1,length(PARAMS.t));
    eflag = 2;
elseif state1 == get(HANDLES.sgeq.tog,'Min')
    sg = PARAMS.pwr;
    eflag = 0;
end

% apply brightness & contrast
%    c = (1 + PARAMS.contrast/100) .* PARAMS.pwr + PARAMS.bright;
%     c = (PARAMS.contrast/100) .* PARAMS.pwr + PARAMS.bright;
c = (PARAMS.contrast/100) .* sg + PARAMS.bright;
%         c = (PARAMS.contrast/100) .* (PARAMS.pwr + PARAMS.bright);

% plot specgram
HANDLES.subplt.specgram = subplot(HANDLES.plot.now);
if PARAMS.fax == 0
    HANDLES.plt.specgram = image(PARAMS.t,PARAMS.f,c);
elseif PARAMS.fax == 1
    %
    flen = length(PARAMS.f);
    [M,N] = logfmap(flen,4,flen);
    c = M*c;
    f = M*PARAMS.f;
    HANDLES.plt.specgram = image(PARAMS.t,f,c);
    set(get(HANDLES.plt.specgram,'Parent'),'YScale','log');
    set(gca,'TickDir','out')
end

% plot line for RawFile Boundary
if rflag & PARAMS.delimit.value
    y = [min(PARAMS.f),max(PARAMS.f)];
    HANDLES.delimit.sgline = line(x,y,'Color','k','LineWidth',4);
end

axis xy

% Run detection on current spectrogram plot
if PARAMS.dt.Enabled
    if ~ isempty(PARAMS.dt.Ranges)
        dtST_signal(PARAMS.pwr, PARAMS.fs, PARAMS.nfft, PARAMS.overlap, ...
            PARAMS.f, true, 'Ranges', PARAMS.dt.Ranges , ...
            'MinClickSaturation', PARAMS.dt.MinClickSaturation, ...
            'MaxClickSaturation', PARAMS.dt.MaxClickSaturation, ...
            'WhistleMinLength_s', PARAMS.dt.WhistleMinLength_s ,...
            'WhistleMinSep_s', PARAMS.dt.WhistleMinSep_s, ...
            'Thresholds', PARAMS.dt.Thresholds, ...
            'MeanAve_s', PARAMS.dt.MeanAve_s, ...
            'WhistlePos', PARAMS.dt.WhistlePos, ...
            'ClickPos', PARAMS.dt.ClickPos);
    end
end

% check for classification labels
if PARAMS.dt.class.PlotLabels
  dtPlotLabels('spectra', ...
               .9* PARAMS.f(PARAMS.fimax)-PARAMS.f(PARAMS.fimin));
end

% colorbar
PARAMS.cb = colorbar('vert');
v2 = get(PARAMS.cb,'Position');
set(PARAMS.cb,'Position',[0.925 v2(2) 0.01 v2(4)])
yl=get(PARAMS.cb,'YLabel');
set(yl,'String','Spectrum Level [dB re counts^2/Hz]')

% get freq axis label
ylim = get(get(HANDLES.plt.specgram,'Parent'),'YLim');
ytick = get(get(HANDLES.plt.specgram,'Parent'),'YTick');
if  ylim(2) < 10000
    set(get(HANDLES.plt.specgram,'Parent'),'YtickLabel',num2str(ytick'))
    ylabel('Frequency [Hz]')
else
    set(get(HANDLES.plt.specgram,'Parent'),'YtickLabel',num2str((ytick')./1000))
    ylabel('Frequency [kHz]')
end

% energy color bar - set range
minp = min(min(PARAMS.pwr));
maxp = max(max(PARAMS.pwr));
if minp == maxp
    maxp = minp+6;   % no range:  fake a 6 dB range
end
set(PARAMS.cb,'YLim',[minp maxp])

% image (child of colorbar)
PARAMS.cbb = get(PARAMS.cb,'Children');
minc = min(min(c));
maxc = max(max(c));
difc = 2;
set(PARAMS.cbb,'CData',[minc:difc:maxc]')
set(PARAMS.cbb,'YData',[minp maxp])

% define colormapping
if strcmp(PARAMS.cmap,'gray') % make negative colormap ie dark is big amp
    g = gray;
    szg = size(g);
    cmap = g(szg:-1:1,:);
    colormap(cmap)
else
    colormap(PARAMS.cmap)
end

if ~tsvalue
    % label
    xlabel('Time [seconds]')
end

% text positions
tx = [0 0.70 0.85];
ty = [-0.05 -0.125 -0.175 -0.25];
ty2 = [-0.075 -0.175 -0.25 -0.35];

% put window start time on bottom plot only:
if ~tsvalue & ~spvalue
    % put window start time on all plots:
    text('Position',[tx(1) ty(m)],'Units','normalized',...
        'String',timestr(PARAMS.plot.dnum,1));
end

% spectral parameters
text('Position',[tx(2) ty(m)],'Units','normalized',...
    'String',['Fs = ',num2str(PARAMS.fs),', NFFT = ',num2str(PARAMS.nfft),...
    ', %OL = ',num2str(PARAMS.overlap)]);

% brightness and contrast
HANDLES.BC = text('Position',[tx(3) ty2(m)],'Units','normalized',...
    'String',['B = ',num2str(PARAMS.bright),', C = ',num2str(PARAMS.contrast)]);

% Spectrogram Equalization:
if eflag == 1 | eflag == 2
   text('Position',[tx(2) ty2(m)],'Units','normalized',...
    'String',['SG Equal On'])
end

% title contains filename, channel, and if appropriate band pass info
titlestr = sprintf('%s CH=%d', PARAMS.infile, PARAMS.ch);
if PARAMS.filter == 1
  titlestr = sprintf('%s Band Pass %d-%d Hz', titlestr, PARAMS.ff1, PARAMS.ff2);
end
% always plot title - specgram always on top without LaTeX format codes
title(titlestr, 'Interpreter', 'none');



% update control window with time info
set(HANDLES.time.edtxt1,'String',timestr(PARAMS.plot.dnum,3));
set(HANDLES.time.edtxt2,'String',timestr(PARAMS.plot.dnum,4));
set(HANDLES.time.edtxt3,'String',timestr(PARAMS.plot.dnum,5));
set(HANDLES.time.edtxt4,'String',num2str(PARAMS.tseg.sec));



