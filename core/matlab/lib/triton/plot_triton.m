function plot_triton
%
%
% This function checks to see which plots are to be plotted and plots them
%
% replaces plot_psds and plottseg....requires new functions to plot each
% individual plot type
%
% Using 4 possible plot types, there will be 14 possible combinations:
% 1,2,3,4,12,13,14,23,24,34,123,124,234,1234
%
% 060211 - 060227 smw
%
%
% Do not modify the following line, maintained by CVS
% $Id: plot_triton.m,v 1.2 2007/09/14 00:23:02 mroch Exp $

global HANDLES

% figure out how many subplots needed :
savalue = get(HANDLES.display.ltsa,'Value');
tsvalue = get(HANDLES.display.timeseries,'Value');
spvalue = get(HANDLES.display.spectra,'Value');
sgvalue = get(HANDLES.display.specgram,'Value');


m = savalue + tsvalue + spvalue + sgvalue ;  % total number of subplots

% save & disable callbacks
Callback = get(HANDLES.fig.main, 'WindowButtonMotionFcn');
set(HANDLES.fig.main, 'WindowButtonMotionFcn', '');
% make plot window active
figure(HANDLES.fig.main);

% clear previous plot handles

% make subplots with handles
if m == 0       % ie no buttons pushed
    clf
    if exist('Triton_logo.jpg')
        image(imread('Triton_logo.jpg'))
        axis off
    else
        disp_msg('no plot types selected')
    end
else
    for k = 1:m
       str = ['HANDLES.plot',num2str(k),'=subplot(',num2str(m),',1,',num2str(k),');'];
        eval(str);
    end
    p = 1;
    % long-term spectral average
    if savalue
        str = ['HANDLES.plot.now=HANDLES.plot',num2str(p),';'];
        eval(str);
        plot_ltsa
        p = p+1;
    end
    % spectrogram
    if sgvalue
        str = ['HANDLES.plot.now=HANDLES.plot',num2str(p),';'];
        eval(str);
        plot_specgram
        p = p+1;
    end
    % timeseries
    if tsvalue
        str = ['HANDLES.plot.now=HANDLES.plot',num2str(p),';'];
        eval(str);
        plot_timeseries
        p = p+1;
    end
    % spectra
    if spvalue
        str = ['HANDLES.plot.now=HANDLES.plot',num2str(p),';'];
        eval(str);
        plot_spectra
        p = p+1;
    end
    if p ~= m+1
        disp_msg('error : wrong number of subplots made')
    end
end

% Restore callbacks
set(HANDLES.fig.main, 'WindowButtonMotionFcn', Callback);


