
load('matlab.mat');
figure(1);
imagesc(snr_dB);
set(gca, 'YDir', 'normal');

figure(2);

power_dB = medfilt2(snr_dB, [3,3]);
meanf_dB = mean(power_dB, 2);
% typically faster to subtract on a frame by frame basis than to
% build an entire matrix and subtract without a loop.
last_frame = size(power_dB, 2);
for frame_idx = 1:last_frame
    power_dB(:,frame_idx) = power_dB(:,frame_idx) - meanf_dB;
end

imagesc(power_dB);
set(gca, 'YDir', 'normal');

        
figure(3);
se = strel('ball',5,5);
imagesc(imerode(imdilate(power_dB,se),se));
set(gca, 'YDir', 'normal');