function [snr_dB, Indices, dft, clickP] = ...
    dtSpecAnal(Signal, Fs, Length, Advance, Shift, Range, ...
        BroadbandThrN, ClickThr_dB, NoiseComp)
% [snr_dB, Indices, dft, clickP] = dtSpecAnal(
%       Signal, Fs, Length, Advance, Shift, Range, ...
%        BroadbandThrN, ClickThr_dB, NoiseComp)
% Perform spectral analysis
%
% Signal - 1D signal of interest
% Fs - signal sample rate
% Length - frame length in samples
% Advance - frame advance in samples
% Shift - Shift start of frame by N samples
% Range - Frequency bins to retain
% BroadbandThrN - N Frequency bins > ClickThr_dB --> broadband energy
% ClickThr_dB - bin N dB above bg noise might be part of a click
% NoiseComp - noise compensation method (see dtSpectrogramNoiseComp)

frames_per_s = Fs/Advance;
% Remove Shift samples from the length so that we have enough space to
% create a right shifted frame
Indices = spFrameIndices(length(Signal)-Shift, Length, Advance, Length, frames_per_s, ...
                         Shift);
last_frame = Indices.FrameLastComplete;
range_binsN = length(Range);

% click present predicate - Indicator fn for whether or not each
% frame contains a click
clickP = zeros(1, last_frame);
% Compute dft for current block
dft = zeros(range_binsN, last_frame);
power_dB = zeros(range_binsN, last_frame);

window = hamming(Length);
for frameidx = 1:last_frame
  dft_frame = fft(spFrameExtract(Signal,Indices,frameidx).*window);
  dft(:,frameidx) = dft_frame(Range);
  power_dB(:,frameidx) = 20*log10(abs(dft(:,frameidx)));
end

meanf_dB = mean(power_dB, 2);
for frameidx = 1:last_frame
  clickP(frameidx) = ...
      sum((power_dB(:,frameidx) - meanf_dB) > ClickThr_dB) ...
      > BroadbandThrN;
end

% Estimate noise and remove via spectral means subtraction
% we may want to move to a better way of doing this
snr_dB = dtSpectrogramNoiseComp(power_dB, NoiseComp, ~clickP);

