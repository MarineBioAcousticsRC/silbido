function plot_spectra
%
%
% 060205-060227 smw modified for triton v1.60
%
%%
% Do not modify the following line, maintained by CVS
% $Id: plot_spectra.m,v 1.3 2007/05/12 01:25:05 mroch Exp $
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

% remove dc offset (mean)
dtdata = detrend(DATA,'constant');
%window = triton_hanning_v140(PARAMS.nfft);
window = hanning(PARAMS.nfft);
noverlap = round((PARAMS.overlap/100)*PARAMS.nfft);
% calc power spectral density (need signal toolbox)
%[Pxx,F] = psd(dtdata,PARAMS.nfft,fs,window,noverlap);
[Pxx,F] = pwelch(dtdata,window,noverlap,PARAMS.nfft,PARAMS.fs);
%[Pxx,F] = PERIODOGRAM(X,WINDOW,NFFT,Fs)


% calc RMS (ie average power)
n = length(dtdata);
% rms = norm(y)/sqrt(n)
% rmsdB = 20*log10(rms)
% or
rmsdB = 20*log10( sqrt(sum(dtdata .* dtdata)/n));

Pxx = 10*log10(Pxx);

% apply transfer function
if PARAMS.tf.flag == 1
    Ptf = interp1(PARAMS.tf.freq,PARAMS.tf.uppc,F,'linear','extrap');
    Pxx = Ptf + Pxx;
    %Pxx = ones(size(Pxx));
elseif PARAMS.tf.flag == 0  % do not apply transfer function
    Pxx = Pxx;
end

Pmax = max(Pxx);
% plot spectra
% Pxx = 10*log10(Pxx) ...				% counts^2/Hz
%     + 10*log10((norm(window)^2)/(sum(window)^2))... % undo normalizing factor
%     + 3;      % add in the other side that matlab doesn't do
HANDLES.subplt.spectra = subplot(HANDLES.plot.now);

% linear or log axis
if PARAMS.fax == 0
    HANDLES.plt.spectra = plot(F,Pxx);
elseif PARAMS.fax == 1
    HANDLES.plt.spectra = semilogx(F,Pxx);
    grid on
end

% % xlabel
xlabel('Frequency [Hz]')

% get freq axis label
% xlim = get(get(HANDLES.plt.spectra,'Parent'),'XLim');
% xtick = get(get(HANDLES.plt.spectra,'Parent'),'XTick');
% if  xlim(2) < 10000
% % if  PARAMS.freq1 < 10000
%     set(get(HANDLES.plt.spectra,'Parent'),'XtickLabel',num2str(xtick'))
%     xlabel('Frequency [Hz]')
% else
%     set(get(HANDLES.plt.spectra,'Parent'),'XtickLabel',num2str((xtick')./1000))
%     xlabel('Frequency [kHz]')
% end

% ylabel
if PARAMS.tf.flag == 0
    ylabel('Spectrum Level [dB re counts^2/Hz]')
elseif PARAMS.tf.flag == 1
    ylabel('Spectrum Level [dB re uPa^2/Hz]')
end
% get axis limits and change
v=axis;
axis([PARAMS.freq0 PARAMS.freq1 v(3) v(4) ]);

% time info
len = length(DATA);
dT1 = len/PARAMS.fs;

% text positions
tx = [0 0.70 0.85];                 % x
ty = [-0.05 -0.125 -0.175 -0.25];  % y upper left&right
ty2 = [-0.075 -0.175 -0.25 -0.35];  % y lower right

% time - always on spectra plot
text('Position',[tx(1) ty(m)],'Units','normalized',...
    'String',timestr(PARAMS.plot.dnum,1));

% spectral parameters - always plotted
text('Position',[tx(2) ty(m)],'Units','normalized',...
    'String',['Fs = ',num2str(PARAMS.fs),', NFFT = ',num2str(PARAMS.nfft),...
    ', %OL = ',num2str(PARAMS.overlap)]);
text('Position',[tx(3) ty2(m)],'Units','normalized',...
    'String',['Time Window = ',num2str(dT1),' secs']);

if PARAMS.tf.flag == 1
    if ~isempty(PARAMS.tf.filename)
        text('Position',[tx(1) ty2(m)],'Units','normalized',...
            'String',['TF File: ',PARAMS.tf.filename]);
    else
        text('Position',[tx(1) ty2(m)],'Units','normalized',...
            'String',['TF File: Not Loaded']);
    end
end

% title if only spectra plot
if ~tsvalue & ~sgvalue
    if PARAMS.filter == 1
        title([fullfile(PARAMS.inpath,PARAMS.infile),' CH=',num2str(PARAMS.ch),...
            '      Band Pass Filter ',num2str(PARAMS.ff1),' Hz to ',...
            num2str(PARAMS.ff2),' Hz'])
    else
        title([fullfile(PARAMS.inpath,PARAMS.infile),' CH=',num2str(PARAMS.ch)])
    end
end

% set time in control window to current plot time
set(HANDLES.time.edtxt1,'String',timestr(PARAMS.plot.dnum,3));
set(HANDLES.time.edtxt2,'String',timestr(PARAMS.plot.dnum,4));
set(HANDLES.time.edtxt3,'String',timestr(PARAMS.plot.dnum,5));
set(HANDLES.time.edtxt4,'String',num2str(PARAMS.tseg.sec));

