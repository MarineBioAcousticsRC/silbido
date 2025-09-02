function [power_dB, snr_dB, Indices, dft, clickP] = ...
    dtSpecAnal(Signal, Fs, Length, Advance, Shift, Range, ...
        BroadbandThrPercent, ClickThr_dB, NoiseComp, FilterBank, constantQ)
% Perform spectral analysis
%
% Signal - 1D signal of interest.
% Fs - signal sample rate.
% Length - frame length in samples.
% Advance - frame advance in samples.
% Shift - Shift start of frame by N samples.
% Range - [lowHz highHz]: Frequency range of signal to be analyzed.
% BroadbandThrN - percentage of frequency bins that must be above ClickThr_dB
% such that the signal block can be considered broadband energy.
% ClickThr_dB - bin N dB above bg noise might be part of a click.
% NoiseComp - noise compensation method (see dtSpectrogramNoiseComp).
% FilterBank - 'linear' or 'constantQ'.


if (strcmp(FilterBank, 'linear'))
    frames_per_s = Fs/Advance;
    
    % Remove Shift samples from the length so that we have enough space to
    % create a right shifted frame
    Indices = spFrameIndices(length(Signal)-Shift, Length, Advance, Length, ...
        frames_per_s, Shift);
    last_frame = Indices.FrameLastComplete;
    
    % Click present predicate - Indicator fn for whether or not each
    % frame contains a click.
    clickP = zeros(1, last_frame);
    
    
    % Figure out number of linear bins.
    binHz = Fs/Length;
    nyquistBin = floor(Length/2);
    % Shouldn't these use floor() instead of ceil()?
    highCutoffBin = min(ceil(Range(2)/binHz)+1, nyquistBin);
    lowCutoffBin= ceil(Range(1)/binHz)+1;
    rangeBins =lowCutoffBin:highCutoffBin;
    rangeBinsN = length(rangeBins);
    
    % Compute dft for current block
    dft = zeros(rangeBinsN, last_frame);
    power_dB = zeros(rangeBinsN, last_frame);
    
    window = hamming(Length);
    %TODO: Why no normalizing here?
    %window = window/sum(window);
    
    for frameidx = 1:last_frame
        frame = spFrameExtract(Signal,Indices,frameidx);
        
        dft_frame = fft(frame.*window);
        dft(:,frameidx) = dft_frame(rangeBins);
        
        frame_mag = abs(dft(:,frameidx));
        %frame_mag(frame_mag <= eps) = 10*eps;
        
        power_dB(:,frameidx) = 20*log10(frame_mag);
        1;
    end
    
    numBins = rangeBinsN;
    
elseif (strcmp(FilterBank, 'constantQ'))
%     %Temp fix: override advance as we don't want overlapping frames.
%     Advance = Length;
    frames_per_s = Fs/Advance;
    
    % Remove Shift samples from the length so that we have enough space to
    % create a right shifted frame. Don't overlap frames when using
    % constantQ.
    Indices = spFrameIndices(length(Signal)-Shift, Length, Advance, Length, ...
        frames_per_s, Shift);
    last_frame = Indices.FrameLastComplete;
    
    % Click present predicate - Indicator fn for whether or not each
    % frame contains a click.
    clickP = zeros(1, last_frame);
    
    % Determine frame size.
    frameSize = size(spFrameExtract(Signal,Indices,1),1);
    %constantQ = ConstantQ(Range(1), Range(2), Fs,frameSize);
    numBins = size(constantQ.getCenterFreqs,1);
    dft = zeros(numBins, last_frame); % Unused.
    power_dB = zeros(numBins, last_frame);
      
    for frameidx = 1:last_frame
        frame = spFrameExtract(Signal,Indices,frameidx);
        [~, outputEstimations] = constantQ.processFrame(frame);      
        frame_mag = outputEstimations;
        power_dB(:,frameidx) = frame_mag;
    end
end

meanf_dB = mean(power_dB, 2);
for frameidx = 1:last_frame
  % Calculate how many frequency bins are greater than ClickThr_dB
  % above the mean of the frame.  If this count is greater than
  % BroadbandThrN, mark the frame as a click.
  clickP(frameidx) = ...
      sum((power_dB(:,frameidx) - meanf_dB) > ClickThr_dB) ...
      > (BroadbandThrPercent * numBins);
  % add an or for detecting signifigant troughs.
end

% Estimate noise and remove via spectral means subtraction
% we may want to move to a better way of doing this
if ~ iscell(NoiseComp)
    NoiseComp = {NoiseComp};
end

% For many of the noise compensation algorithms, noise estimation
% ignores bins with click energy as these will boost the noise level
% considerably and we are no longer measuring background noise. When
% animals are clicking heavily, it is possible that all bins have
% click energy and we cannot do this.
if all(clickP)
    noiseP = ones(size(clickP));
else
    noiseP = ~clickP;
end
snr_dB = dtSpectrogramNoiseComp(power_dB, NoiseComp{:}, noiseP);

% Linear addition as the frequency of each constantQ "bin" increases.
if (strcmp(FilterBank, 'constantQ'))
%     dBAddition = 1;
%     numOctaves = size(constantQ.octaveSet,1);
%     numFilters =  constantQ.filtersPerOctave;
%     slope = (dBAddition/numFilters);
%     p = [slope 0];
%     additionPerFilter = arrayfun(@(x) polyval(p,x), [1:numFilters*numOctaves]);
%     additionPerFilter = max(additionPerFilter,0);
% 
%     for i=1:size(snr_dB,1)
%        snr_dB(i,:) = snr_dB(i,:) + additionPerFilter(i); 
%     end

    snr_dB = snr_dB + 3;
end

end