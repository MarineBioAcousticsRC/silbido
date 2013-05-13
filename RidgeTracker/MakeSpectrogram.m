function [P,F,params]=MakeSpectrogram(A,fs,nfft,window,maxFreq)
if nargin<3
    nfft=256;
end
if nargin<4
    window=100;
end

% calculate spectrogram (window, noverlap & nfft are arbitraty at the
% moment)
if nargin<5
    olap=round(window/2);
    [S,F,T,P] = spectrogram(A,window,olap,nfft,fs);
    maxFreq=max(F);
else
%    window=window/maxFreq*fs;
    olap=round(window/2);
    [S,F,T,P] = spectrogram(A,window,olap,0:(maxFreq/nfft):maxFreq,fs);
end

params.fs=fs;
params.nfft=nfft;
params.window=window;
params.noverlap=olap;
params.maxFreq=maxFreq;
