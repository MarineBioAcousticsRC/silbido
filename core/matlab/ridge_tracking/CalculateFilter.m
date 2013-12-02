% CalculateFilter
%
% Filters the spectrogram image according to the selections in the GUI
% (passed to the function via the 'handles' structure).
%
% Input (as members of 'handles'):
%   editHPF - High pass filter (in PIXELS).  How many pixels to exclude
%             from the bottom of the spectrogram.
%   editLPF - Low pass filter (in PIXELS).  How many pixels to exclude from
%             the top of the spectrogram.
%   editISD - Interest standard deviation.  How many standard deviations
%             above the mean should be considered "interesting".
%   togglebuttonAdapt - Whether to use the adaptive histogram equalisation.
%   togglebuttonClick - Whether to use the Mallawaarachchi click filter.
%   togglebuttonBpass - Whether to use the Grier bandpass filter.
%   togglebuttonMask - Whether to use the ISD/HPF/LPF masking.
%
% Output:
%   I - Filtered image (with mask already applied)
%   mask - Interest mask - note that _zero_ indicates "interesting"!!
%
function [spectrogram,mask]=CalculateFilter(spectrogram, hp_thresh, lp_thresh, isd, adaptive, bandpass, click, usemask)

beta=10;%15;

% Apply adaptive histogram equalisation (Matlab function)
if (adaptive)
    spectrogram=double(adapthisteq(uint8(spectrogram)));
end

% Apply Mallawaarachchi-like click filter
if (click)
    [~,spectrogram]=MallawaarachchiFilter(spectrogram,1,1,beta);
end

% Apply Grieger bandpass filter
if (bandpass)
    % Need to pad the image to prevent edge artefacts
    pad=10;
    spectrogram=padarray(spectrogram,[pad pad],mean(spectrogram(:)));
    spectrogram = bpass(spectrogram,1,10);
    % Remove padding
    spectrogram=spectrogram(pad+1:end-pad,pad+1:end-pad);
end

% Replace high and low stopped frequencies with the overall mean
spectrogram([1:lp_thresh end-hp_thresh:end],:)=mean(spectrogram(:));

% Apply the interest mask
if (usemask)
    mask=MakeMask2(spectrogram,isd,hp_thresh,lp_thresh);
    spectrogram(find(mask))=0;
else
    mask=zeros(size(spectrogram));
end

% Remove NaNs if they've crept in
spectrogram(isnan(spectrogram))=0;