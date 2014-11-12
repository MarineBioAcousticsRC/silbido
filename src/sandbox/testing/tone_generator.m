%close all;

% ±2 secs @ 1kHz sample rate
%t = 0:0.001:10;    

% Start @ 100Hz, cross 200Hz at t=1 sec 
%y = chirp(t,100,10,200,'quadratic'); 

%size(y);



%y = [zeros(1, 1000) y];

%spectrogram(y,128,120,128,1E3,'yaxis');

%colorbar();


%% Time specifications:
   Fs = 8000;                   % samples per second
   dt = 1/Fs;                   % seconds per sample
   StopTime = 3;             % seconds
   t = (0:dt:StopTime-dt)';     % seconds
   
   %% Sine wave:
   Fc = 2000;                     % hertz
   x = cos(2*pi*Fc*t);
   
   spectrogram(x,128,120,128,Fs,'yaxis');