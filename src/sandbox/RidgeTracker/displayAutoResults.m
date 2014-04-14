function displayAutoResults(S, T, F, D)

    for i=1:1:length(S)
        s = S{i};
        t = T{i};
        f = F{i};
        d = D{i};
        
        DisplaySpectrogram(s,t,max(f),d);
    end

% DisplaySpectrogram
%
% Displays the spectrogram as an image, using the time and frequency ranges
% supplied.
%
% Input (from globals):
%   I - Spectrogram as a scaled matrix [0-1]
%   T - Vector of time points (x-axis pixels)
%   maxF - Maximum frequency bin (y-axis limit)
%
function DisplaySpectrogram(I,T,maxF,D)

figure();

iptsetpref('ImshowAxesVisible','on');
% I don't know how to get the y-axis scaled in the correct direction! If
% someone knows how to do this, please fix!  In the mean time, the y-axis
% has to be marked as negative.
hold off
imagesc(I,'XData',[T(1) T(end)],'YData',[0 maxF]);
set(gca,'YDir','normal');
colormap(gray);
% Allow mouse inspection of pixel values
impixelinfo;

% Rotate the colours of the curves so that they can be distinguished
cc='gbcmy';
% Plot the curves
hold on
for n=1:length(D)
    t=D{n};
    plot(t(:,1),t(:,2),cc(mod(n,length(cc))+1),'LineWidth',3);
end
hold off