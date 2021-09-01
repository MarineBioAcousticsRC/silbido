function [predicted_blk, Indices] = dtDeepWhistle(handle, header,...
    channel, blkstart_s, blklength_s, Framing, Range)
%DTPREDICPLOT Given a start time and length in seconds, framing
% information in samples ([Length, Advance]), and any optional
% arguments, read in a data block and perform spectral processing.
%
% Returns a confidence map of detected whistles and framing information
%   



Length_s = Framing(1)/1000;
advance_s = Framing(2)/1000;
Length_samples = round(header.fs * Length_s)+1;
Advance_samples = round(header.fs * advance_s);
freq_res = 1000/Framing(1);
blkend_s = blkstart_s + blklength_s;

%energy normalization
max_clip = 6;
min_clip = 0;

%load Pu_Li's Pretrained Network
net = load('C:\Users\Peter\Current Projects\DeepWhistle\5.ToSilbido\DAGnet361x1500.mat');

start_frame = (blkstart_s * header.fs)+1;
end_frame = floor((round(blkend_s) + 1 / freq_res - Framing(2)/1000) * header.fs); %added round to blkend_s because there was an extra .00004 during testing

Signal = ioReadWav(handle, header, start_frame, end_frame, ...
    'Channels', channel, 'Normalize', 'unscaled');

Signal = Signal / 256;

frames_per_s = header.fs/Length_samples;

% Remove Shift samples from the length so that we have enough space to
% create a right shifted frame
Indices = spFrameIndices(length(Signal), Length_samples, ...
    Advance_samples, Length_samples, frames_per_s, 0);
last_frame = Indices.FrameLastComplete + 1;


% Figure out number of linear bins.
binHz = header.fs/Length_samples;
nyquistBin = floor(Length_samples);
highCutoffBin = min(ceil(Range(2)/binHz), nyquistBin);
lowCutoffBin= ceil(Range(1)/binHz);

% Compute dft for current block
audio = zeros(last_frame, Length_samples);

for frameidx = 1:last_frame
    frame = spFrameExtract(Signal,Indices,frameidx);
    audio(frameidx,:) = frame;
end

dftN = size(audio, 2);  % samples in frame & frequencies
fft_spec = abs(fft(audio, dftN,2));

%Entered by Marie
% Nyquist rate is half the sample rate.
% This signal is sampled at 192000, Fs/2 = 192000 / 2
% This translates into half of the frequency bins
NyquistN = ceil((dftN+1) / 2);
fft_spec(: ,NyquistN+1:end) = [];% Removes frequencie above Nyquist


fft_spec = transpose(fft_spec);
fft_spec([1:lowCutoffBin-1,highCutoffBin+1:end],:)=[];

normalized_blk = log10(fft_spec);

%normalize3_PuLi - a normalization function created for our model
normalized_blk(normalized_blk>max_clip)=max_clip;
normalized_blk(normalized_blk<min_clip)=min_clip;
normalized_blk = (normalized_blk - min_clip) / (max_clip - min_clip);

normalized_blk = flip(normalized_blk,1);

predicted_blk = predict(net.net1500,normalized_blk);

end

