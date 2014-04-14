function [spectrograms, timeScale, freqBins, detections] = auto_tracker()
    fprintf('\nExecuting automated ridge tracking.\n');
    totalTic = tic;
    warning off;
    
    global FRAME W fs
    global I I0 mask T maxF HS RS
    global FN PathName F  TT R currentFrame  frameTime
    
    openTime = 0;
    spectrogramTime = 0;
    filterTime = 0;
    hessianTime = 0;
    joiningTime = 0;
    
    % Phase 1: Opening and Framing
    FileName = '/Users/michael/development/sdsu/silbido/RidgeTracker/FB272_3_04.wav';
    
    fprintf('Opening and framing file: %s\n', FileName);
    openTick = tic();
    openFile(FileName);
    openTime = toc(openTick);
    fprintf('Completed(%4.2fs)\n', openTime);
    
    spectrograms = {length(FRAME)};
    detections = {length(FRAME)};
    timeScale = {length(FRAME)};
    freqBins = {length(FRAME)};
    
    fprintf('Beginning processing %d frames.\n\n', length(FRAME));
    for currentFrame=1:length(FRAME)
        fprintf('Processing Frame: %d\n', currentFrame);

        frameTic = tic();
        spectrogramTic = tic();
        
        % FIXME - Provide Input Paramerters.
        window = 100;
        
        % Phase 2: Create Spectrogram.
        fprintf('\tCreating spectrogram...');
        [I,T,F,mask]=CalculateSpectrogram(FRAME{currentFrame},fs,window);
        I0=I;
        timeScale{currentFrame} = T;
        freqBins{currentFrame} = F;
        
        currentTime = toc(spectrogramTic);
        spectrogramTime = spectrogramTime + currentTime;
        fprintf('Completed(%4.2fs)\n', currentTime);

        % Phase 3: Filtering
        fprintf('\tPerforming filtering...');
        filterTic = tic();
        HS=[];
        RS=[];
        [I,mask]=CalculateFilter(I0);
        spectrograms{currentFrame} = I;
        
        currentTime = toc(filterTic);
        filterTime = filterTime + currentTime;
        fprintf('Completed(%4.2fs)\n', currentTime);

        % Phase 4: Hessian / Raw Ridges
        fprintf('\tComputing Hessian and Creating Ridges...');
        hessianTic = tic();
        HS=CalculateHessian(I,mask);
        currentTime = toc(hessianTic);
        hessianTime = hessianTime + currentTime;
        fprintf('Completed(%4.2fs)\n', currentTime);

        
        % Phase 5: Ridge Joining
        fprintf('\tJoining Ridges...');
        joiningTic = tic();
        
        % FIXME - Provide Input Paramerters.
        terminalSmoothing=100;
        maxGap=10;
        minLenFinal=40;
        maxTurn=25;
        type = 2;
        
        % Call the joining algorithm and display the result
        HP=ConvertSpectralCoordsToPixels(HS,T,F);
        RP=TrackCurves(HP,type,I,maxGap,terminalSmoothing,minLenFinal,maxTurn);
        RS=ConvertPixelsToSpectralCoords(RP,T,F);

        detections{currentFrame} = RS;
        
        currentTime = toc(joiningTic);
        joiningTime = joiningTime + currentTime;
        fprintf('Completed(%4.2fs)\n', currentTime);
        
        currentTime = toc(frameTic);
        fprintf('Total time for frame %d: %4.2fs\n\n', currentFrame, currentTime);
    end
    totalTime = toc(totalTic);
   
    fprintf('Total time to open and frame: \t\t%6.2fs\n', openTime);
    fprintf('Total time to create spectrograms:\t%6.2fs\n', spectrogramTime);
    fprintf('Total time to filter spectrograms:\t%6.2fs\n', filterTime);
    fprintf('Total time to generate raw ridges:\t%6.2fs\n', hessianTime);
    fprintf('Total time to join ridges:\t\t%6.2fs\n\n', joiningTime);
    
    fprintf('Total time for all processing: \t\t%6.2fs\n', totalTime);
    fileTime = length(W) / fs;
    fprintf('Total File Length (Time): \t\t%6.2fs\n',fileTime );
    processingSpeed = (fileTime / totalTime);
    fprintf('Speed compared to real time:\t\t%6.4fx\n', processingSpeed );
    
    

function openFile(FileName)
global FN FRAME W fs frameTime

frameTime=3; % Frame length is 3 seconds
if ~isempty(FileName) && length(FileName)>1
    FN=FileName;
    [W,fs]=wavread(FN);    
    frameLength=frameTime * fs; % frame length in samples
    
    % Split the wave W into 3 second frames
    FRAME=[];
    k=0;
    for n=1:round(frameLength/2):length(W)
        k=k+1;
        FRAME{k}=W(n:min(n+frameLength,length(W)));
    end
    
    TT=[];
    R=[];
end

function [I,T,F,mask,P]=CalculateSpectrogram(W,fs,window)

global maxF currentFrame frameTime

% Number of FFT bins is hard-coded, but could be changed
nfft=256;

% If a maximum frequency is specified, use it
% P is the raw power spectrum, F is the vector of frequency bins
if maxF>0
    [P,F]=MakeSpectrogram(W,fs,nfft,window,maxF);
else
    [P,F]=MakeSpectrogram(W,fs,nfft,window);
    maxF=max(F);
end

% Create a matrix I ranged [0-1] suitable for display as an image
I=Standardise(log(P));
% Create a vector of time points
T=(1:size(I,2))/size(I,2)*length(W)/fs+(currentFrame-1)*frameTime/2;
% Create an empty interest mask (doesn't need to be done here, but helpful
% in case we forget)
mask=zeros(size(I));


function [I,mask]=CalculateFilter(I)

% FIXME
HPF=10;
LPF=10;
isd=1;

beta=10;%15;

% Apply adaptive histogram equalisation (Matlab function)
if (1)
    I=double(adapthisteq(uint8(I)));
end

% Apply Mallawaarachchi-like click filter
if (1)
    [~,I]=MallawaarachchiFilter(I,1,1,beta);
end

% Apply Grieger bandpass filter
if (1)
    % Need to pad the image to prevent edge artefacts
    pad=10;
    I=padarray(I,[pad pad],mean(I(:)));
    I = bpass(I,1,10);
    % Remove padding
    I=I(pad+1:end-pad,pad+1:end-pad);
end

% Replace high and low stopped frequencies with the overall mean
I([1:LPF end-HPF:end],:)=mean(I(:));

% Apply the interest mask
if (1)
    mask=MakeMask2(I,isd,HPF,LPF);
    I(find(mask))=0;
else
    mask=zeros(size(I));
end

% Remove NaNs if they've crept in
I(isnan(I))=0;

function HS=CalculateHessian(I,mask)

global T F

% FIXME
K=5;
minLen=10;
HPF=10;
LPF=10;
horizPriority=1;

% Remove NaNs if they've crept in
I(isnan(I))=0;

% Track the ridges
HS=CalculateFunctionalsAndTrackNew(I,K,mask,minLen,HPF,LPF,horizPriority);
HS=ConvertPixelsToSpectralCoords(HS,T,F);
