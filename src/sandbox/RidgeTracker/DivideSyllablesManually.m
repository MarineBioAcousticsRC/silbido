function SY=DivideSyllablesManually(P,A,params)
% Inputs:
% P: spectrogram
% A: audio
% Outputs:
% SY: structure holding the spectrograms and audio of the marked syllables

fs=params.fs;
window=params.window;
noverlap=params.noverlap;

% calculate size of window to be displayed each time
winSize=round(1000/44100*fs);
% calculate number of such windows in the whole file
N=ceil(size(P,2)/winSize);

startS=[];
endS=[];
type=0;

% display the windows one after another
for n=1:N
    % find the start and end points of both the spectrogram and the audio
    if n==N
        % the last window is shorter than the nominal size
        r=((n-1)*winSize+1):size(P,2);
        ra=((n-1)*winSize*50+1):size(A,2);
    else
        r=((n-1)*winSize+1):(n*winSize);
        ra=((n-1)*winSize*50+1):(n*winSize*50);
    end
    % extract the relevant range of the spectrogram and audio
    Q=P(:,r);
    AQ=A(ra);
    
    % display the spectrogram and (try to) play the audio
    imshow(flipud(log(Q)),[]);
    title(sprintf('%d / %d',n,N));
    pause(0.1);
    try
        wavplay(AQ,fs);
    catch
        % wavplay fails on linux: write a temporary file and play it with cvlc
        wavwrite(AQ,fs,'tmp.wav');
        system(sprintf('cvlc tmp.wav --play-and-exit\n'));
    end
    
    % set up to display the markers
    hold on;
    while 1
        % accept mouse button input
        [x,y,button]=ginput(1);
        
        % RIGHT mouse button moves to next window
        if button~=1
            break;
        end
        
        % LEFT mouse button marks start or end of syllable
        if type==0
            startS=[startS x+(n-1)*winSize];
            c='g';
        else
            endS=[endS x+(n-1)*winSize];
            c='r';
        end
        type=1-type;
        
        plot([x x],[0 size(Q,1)],c);
    end
    hold off
end

% when all the windows have been processed, extract the syllables from the
% start/end information

wnl=window-noverlap;

SY=[];
k=1;
% go over all the start/end pairs
for n=1:length(startS)
    p=P(:,startS(n):endS(n));
    SY{k}.data=p;
    SY{k}.fs=fs;
    SY{k}.start=startS(n);
    try
        SY{k}.audio=A(((startS(n)*wnl)):(endS(n)*wnl));
    catch
        SY(k).audio=[];
    end
    k=k+1;
end

