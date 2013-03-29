function dtBrightContrast(ImageH, Bright_dB, Contrast_dB)
% dtBrightContrast(ImageH, Bright_dB, Contrast_dB)
% Change the brightness/contrast of the image.
%
% ImageH - Image handle
% Bright_dB - Brightness
% Contrast_dB - Contrast

for hidx = 1: length(ImageH)
    
    % Get the original structure associated with image
    pwr_brt_cont = get(ImageH(hidx), 'UserData');
    
    if pwr_brt_cont.bright_dB ~= Bright_dB ||...
            pwr_brt_cont.contrast_dB ~= Contrast_dB;
        % Update the color data
        colorData = (Contrast_dB/100) .* pwr_brt_cont.snr_dB + Bright_dB;
        set(ImageH(hidx), 'CData', colorData);
        % Update the structure associated with image
        pwr_brt_cont.bright_dB = Bright_dB;
        pwr_brt_cont.contrast_dB = Contrast_dB;
        set(ImageH(hidx), 'UserData', pwr_brt_cont);
    end
end