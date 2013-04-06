function dtBrightContrast(ImageH, Bright_dB, Contrast_Pct, thresh_dB, ColorbarH)
% dtBrightContrast(ImageH, Bright_dB, Contrast_Pct)
% Change the brightness/contrast and threshold of the image.
%
% ImageH - Image handle
% Bright_dB - Brightness
% Contrast_Pct - Contrast
% thresh_dB (optional) - Set all values < threshold to 0

if nargin < 4
    thresh_dB = -Inf;
end
for hidx = 1: length(ImageH)
    
    % Get the original structure associated with image
    pwr_brt_cont = get(ImageH(hidx), 'UserData');
    if pwr_brt_cont.bright_dB ~= Bright_dB ||...
            pwr_brt_cont.contrast_Pct ~= Contrast_Pct || ...
            pwr_brt_cont.threshold_dB ~= thresh_dB;
        % Update the color data
        colorData = (Contrast_Pct/100) .* pwr_brt_cont.snr_dB + Bright_dB;
        if thresh_dB > 0
            colorData(pwr_brt_cont.snr_dB < thresh_dB) = 0;
        end
        set(ImageH(hidx), 'CData', colorData);
        % Update the structure associated with image
        pwr_brt_cont.threshold_dB = thresh_dB;
        pwr_brt_cont.bright_dB = Bright_dB;
        pwr_brt_cont.Contrast_Pct = Contrast_Pct;
        set(ImageH(hidx), 'UserData', pwr_brt_cont);
    end
end