function varargout = Tracker4(varargin)
% TRACKER4 MATLAB code for Tracker4.fig
%      TRACKER4 runs the interactive ridge tracking software.
%      See documentation, or choose Help for details.
%
% This software is made available through the Creative Commons
% Attribution-ShareAlike (CC BY-SA) license
% (http://en.wikipedia.org/wiki/Share-alike).  Content may be freely used
% and altered providing that derivative work is licenced in the same way.
%
% Arik Kershenbaum (arik@nimbios.org)
% National Institute for Mathematical and Biological Synthesis

% Last Modified by GUIDE v2.5 12-Feb-2013 12:06:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Tracker4_OpeningFcn, ...
    'gui_OutputFcn',  @Tracker4_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Tracker4 is made visible.
function Tracker4_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Tracker4 (see VARARGIN)

% Choose default command line output for Tracker4
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% Initialise with default values
set(handles.editWindow,'String',num2str(100));
set(handles.editWidth,'String',num2str(5));
set(handles.editMinLen,'String',num2str(10));
set(handles.editMaxGap,'String',num2str(10));
set(handles.editMinLenFinal,'String',num2str(40));
set(handles.editMaxTurn,'String',num2str(25));
set(handles.editHPF,'String',num2str(10));
set(handles.editLPF,'String',num2str(0));
set(handles.editISD,'String',num2str(1));
set(handles.editMaxF,'String',num2str(40000));
set(handles.editPower,'String',num2str(0));
set(handles.checkboxHoriz,'Value',0);

set(handles.pushbuttonFilter,'enable','off');
set(handles.pushbuttonReset,'enable','off');
set(handles.pushbuttonHessian,'enable','off');
set(handles.pushbuttonTrack,'enable','off');
set(handles.pushbuttonSave,'enable','off');
set(handles.pushbuttonNextFrame,'enable','off');
set(handles.pushbuttonPrevFrame,'enable','off');
set(handles.pushbuttonPlay,'enable','off');
set(handles.pushbuttonPlayAll,'enable','off');
set(handles.pushbuttonPlayHighPower,'enable','off');
set(handles.pushbuttonPlayDominants,'enable','off');
set(handles.pushbuttonZoom,'enable','off');
set(handles.pushbuttonUnzoom,'enable','off');

set(handles.textBusy,'BackgroundColor','g');

global PathName
PathName=[];
axes(handles.axesI);


% UIWAIT makes Tracker4 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Tracker4_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonOpen.
%
% Prompts the user to open a WAV file, divides it into frames (if it is
% longer than 3 seconds), and calculates the first spectrogram.
%
function pushbuttonOpen_Callback(~, ~, handles)
% hObject    handle to pushbuttonOpen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global  FN PathName W fs TT R currentFrame FRAME frameTime

frameTime=3; % Frame length is 3 seconds

% Open file dialog box
[FileName,PathName] = uigetfile([PathName '*.wav'],'Open image file...');
if ~isempty(FileName) && length(FileName)>1
    FN=FileName;
    set(handles.textBusy,'BackgroundColor','r');drawnow;
    [W,fs]=wavread([PathName '/' FN]);
    set(handles.textBusy,'BackgroundColor','g');
    
    frameLength=frameTime * fs; % frame length in samples
    
    % Split the wave W into 3 second frames
    FRAME=[];
    k=0;
    for n=1:round(frameLength/2):length(W)
        k=k+1;
        FRAME{k}=W(n:min(n+frameLength,length(W)));
    end
    
    s=get(handles.editMaxF,'String');
    maxF=str2double(s);
    
    % Display the first frame
    currentFrame=1;
    CalculateAndDisplaySpectrogram(FRAME{currentFrame},fs,handles);
    
    % Set GUI elements (enable frame scrolling if there is more than one)
    set(handles.textFileName,'String',FileName);
    set(handles.textFrameNo,'String',sprintf('(%d/%d)',currentFrame,length(FRAME)));
    if length(FRAME)>1
        set(handles.pushbuttonNextFrame,'enable','on');
    end
    
    TT=[];
    R=[];
    
    set(handles.pushbuttonZoom,'enable','on');
    
end



% CalculateSpectrogram
%
% Calculates the spectrogram of the current frame (or whatever is passed to
% it), using the maxF and window parameters.  Also clears the interest
% mask.  This function is independent of the GUI so that it can be called
% from a button press, or by batch processing.
%
% Input:
%   W - The waveform vector
%   fs - The sampling frequency
%   window - The FFT window size (set from the GUI)
%   maxF - The maximum frequency bin (set from the GUI)
%
% Output:
%   I - The spectrogram as a standardised [0-1] raster
%   T - The time vector (x-axis pixels)
%   F - The frequency bins (y-axis pixels)
%   mask - The (empty) interest mask
%   P - The original power spectrum (for debugging)
%
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


% CalculateAndDisplaySpectrogram
%
% Calls the functions necessary to calculate the spectrogram and display
% it, as well as loading the relevant global variables to hold the image
% and its associated information.
%
% Input:
%   W - The waveform vector
%   fs - The sampling frequency
%   handles - Handles to the GUI objects (for reading parameters)
% Output: (i.e. globals, set within the function)
%   I - The spectrogram as a scaled image
%   I0 - A copy of the spectrogram, for resetting I without having to
%   recalculate it.
%   T - The time vector (x-axis pixels)
%   F - The frequency bins (y-axis pixels)
%   mask - The (empty) interest mask
%
function CalculateAndDisplaySpectrogram(W,fs,handles)

global I I0 mask T F maxF

% Read parameters from the GUI
s=get(handles.editWindow,'String');
window=str2double(s);

% Set the busy indicator
set(handles.textBusy,'BackgroundColor','r');drawnow;

% Calculate the spectrogram, reset I0, and display the spectrogram
[I,T,F,mask]=CalculateSpectrogram(W,fs,window);
I0=I;
DisplaySpectrogram;

% Release the busy indicator
set(handles.textBusy,'BackgroundColor','g');

% Set the active status of GUI elements
set(handles.pushbuttonFilter,'enable','on');
set(handles.pushbuttonReset,'enable','on');
set(handles.pushbuttonHessian,'enable','on');
set(handles.pushbuttonTrack,'enable','off');
set(handles.pushbuttonSave,'enable','off');
set(handles.pushbuttonPlay,'enable','on');
set(handles.pushbuttonPlayAll,'enable','on');
set(handles.pushbuttonPlayHighPower,'enable','on');
set(handles.pushbuttonPlayDominants,'enable','on');


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
function DisplaySpectrogram

global I T maxF

iptsetpref('ImshowAxesVisible','on');
% I don't know how to get the y-axis scaled in the correct direction! If
% someone knows how to do this, please fix!  In the mean time, the y-axis
% has to be marked as negative.
hold off
imagesc(I,'XData',[T(1) T(end)],'YData',[0 maxF]);
set(gca,'YDir','normal');
colormap(gray)
% Allow mouse inspection of pixel values
impixelinfo



% --- Executes on button press in pushbuttonCalcSpect.
%
% Recalculates the spectrogram based on the GUI parameters of window size
% and maximum frequency.
%
function pushbuttonCalcSpect_Callback(~, ~, handles)
% hObject    handle to pushbuttonCalcSpect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global fs currentFrame FRAME maxF

s=get(handles.editMaxF,'String');
maxF=str2double(s);

% Recalculate and display the current frame of the spectrogram
CalculateAndDisplaySpectrogram(FRAME{currentFrame},fs,handles);


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
function [I,mask]=CalculateFilter(I,handles)


% Get the parameters from the GUI
s=get(handles.editHPF,'String');
HPF=str2double(s);
s=get(handles.editLPF,'String');
LPF=str2double(s);
s=get(handles.editISD,'String');
isd=str2double(s);

beta=10;%15;

% Apply adaptive histogram equalisation (Matlab function)
if get(handles.togglebuttonAdapt,'Value')
    I=double(adapthisteq(uint8(I)));
end

% Apply Mallawaarachchi-like click filter
if get(handles.togglebuttonClick,'Value')
    [~,I]=MallawaarachchiFilter(I,1,1,beta);
end

% Apply Grieger bandpass filter
if get(handles.togglebuttonBpass,'Value')
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
if get(handles.togglebuttonMask,'Value')
    mask=MakeMask2(I,isd,HPF,LPF);
    I(find(mask))=0;
else
    mask=zeros(size(I));
end

% Remove NaNs if they've crept in
I(isnan(I))=0;


% --- Executes on button press in pushbuttonFilter.
%
% Applies the various image filters to the spectrogram by calling
% CalculateFilter, then displays the filtered image.
%
function pushbuttonFilter_Callback(~, ~, handles)
% hObject    handle to pushbuttonFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global I I0 mask T maxF HS RS

set(handles.textBusy,'BackgroundColor','r');drawnow;

% Remove the detections - they're no longer relevant
HS=[];
RS=[];

% Applies the filters, using the _original_ image I0 (i.e. not the
% previously filtered version), and the parameters set in the GUI (via
% 'handles').
[I,mask]=CalculateFilter(I0,handles);
DisplaySpectrogram;

set(handles.textBusy,'BackgroundColor','g');


set(handles.pushbuttonFilter,'enable','on');
set(handles.pushbuttonReset,'enable','on');
set(handles.pushbuttonHessian,'enable','on');
set(handles.pushbuttonTrack,'enable','off');
set(handles.pushbuttonSave,'enable','off');


% CalculateHessian
%
% This is the heart of the ridge tracker.  Calculates the angle between the
% principal eigenvector of the Hessian matrix, and the gradient vector, for
% every pixel in the image, then tracks the zero crossing of this
% functional to find a set of candidate ridges.  This function first
% extracts the algorithm parameters from the GUI via 'handles', and then
% calls the calculation function itself.
%
% Input (separately, or as members of 'handles'):
%   I - The spectrogram image, filtered.
%   mask - Interest mask.  Greatly reduces processing time by skipping
%          pixels not considered "interesting".
%   editWidth - Gaussian kernel standard deviation (in pixels) for
%               calculating the gradients.
%   editMinLen - Minimum length of ridge to accept (in pixels).
%   editHPF - High pass filter (in PIXELS).  How many pixels to exclude
%             from the bottom of the spectrogram.
%   editLPF - Low pass filter (in PIXELS).  How many pixels to exclude from
%             the top of the spectrogram.
%   checkboxHoriz - Whether to give priority to the detection of horizontal
%                   ridges.  See CalculateFunctionalsAndTrackNew for
%                   details.
%
% Output:
%   TT - Cell array of ridges.
%
function HS=CalculateHessian(I,mask,handles)

global T F

% Extract parameters from the GUI
s=get(handles.editWidth,'String');
K=str2double(s);
s=get(handles.editMinLen,'String');
minLen=str2double(s);
s=get(handles.editHPF,'String');
HPF=str2double(s);
s=get(handles.editLPF,'String');
LPF=str2double(s);
s=get(handles.checkboxHoriz,'Value');
horizPriority=s;

% Remove NaNs if they've crept in
I(isnan(I))=0;

% Track the ridges
HS=CalculateFunctionalsAndTrackNew(I,K,mask,minLen,HPF,LPF,horizPriority);
HS=ConvertPixelsToSpectralCoords(HS,T,F);


% --- Executes on button press in pushbuttonHessian.
%
% Performs the Hessian calculation and initial ridge tracking.
%
function pushbuttonHessian_Callback(~, ~, handles)
% hObject    handle to pushbuttonHessian (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global I HS mask

set(handles.textBusy,'BackgroundColor','r');drawnow;

% Get the ridges 'HS' by tracking the zero-crossing of the functional
HS=CalculateHessian(I,mask,handles);
% Re-display the spectrogram and draw the ridges on top
DisplaySpectrogram;
DisplayHessians(HS);

set(handles.textBusy,'BackgroundColor','g');


set(handles.pushbuttonFilter,'enable','on');
set(handles.pushbuttonReset,'enable','on');
set(handles.pushbuttonHessian,'enable','on');
set(handles.pushbuttonTrack,'enable','on');
set(handles.pushbuttonSave,'enable','off');



% DisplayHessians
%
% Draws red lines on the spectrogram to indicate the detected ridges.  Also
% labels them with numbers for debugging purposes (but this could be
% removed if desired).
%
% Input:
%   HS - List of ridges (cell array).
%
function DisplayHessians(H)

global HS

if nargin==0
    H=HS;
end

% Plot the lines
hold on
for n=1:length(H)
    t=H{n};
    plot(t(:,1),t(:,2),'r');
    text(t(1,1),t(1,2),num2str(n));
end
hold off


% --- Executes on button press in pushbuttonTrack.
%
% Takes the ridge list and joins them together as appropriate.
%
% Input (as 'handles'):
%   editMaxGap - Maximum gap (in pixels) to bridge when joining ridges.
%   editMinLenFinal - Minimum length of ridge (in pixels) to be accepted.
%
function pushbuttonTrack_Callback(~, ~, handles)
% hObject    handle to pushbuttonTrack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global HS RS T F I

% This parameter could be in the GUI.  It is the number of pixels from the
% end of the ridge which should be considered when matching candidates for
% merging
terminalSmoothing=100;

% Get the parameters from the GUI
s=get(handles.editMaxGap,'String');
maxGap=str2double(s);
s=get(handles.editMinLenFinal,'String');
minLenFinal=str2double(s);
s=get(handles.editMaxTurn,'String');
maxTurn=str2double(s);
s=get(handles.checkboxRochJoiner,'Value');
if s==1
    type=2;
else
    type=1;
end

set(handles.textBusy,'BackgroundColor','r');drawnow;

% Call the joining algorithm and display the result
HP=ConvertSpectralCoordsToPixels(HS,T,F);
RP=TrackCurves(HP,type,I,maxGap,terminalSmoothing,minLenFinal,maxTurn);
RS=ConvertPixelsToSpectralCoords(RP,T,F);
DisplaySpectrogram;
ShowCurves(RS);

set(handles.textBusy,'BackgroundColor','g');


set(handles.pushbuttonFilter,'enable','on');
set(handles.pushbuttonReset,'enable','on');
set(handles.pushbuttonHessian,'enable','on');
set(handles.pushbuttonTrack,'enable','on');
set(handles.pushbuttonSave,'enable','on');

% ShowCurves
%
% Draws the detected ridges on the spectrogram.
%
% Input:
%   R - List of curves to display (cell array)
%
function ShowCurves(R)

% Rotate the colours of the curves so that they can be distinguished
cc='gbcmy';
% Plot the curves
DisplaySpectrogram;
hold on
for n=1:length(R)
    t=R{n};
    plot(t(:,1),t(:,2),cc(mod(n,length(cc))+1),'LineWidth',3);
end
hold off

% Plot the original ridge detections on top of these
DisplayHessians;


% --- Executes on button press in pushbuttonSave.
%
% Saves the calculated curves in a MAT file named to identify (hopefully)
% the origin of the file and its contents.
%
function pushbuttonSave_Callback(~, ~, ~)
% hObject    handle to pushbuttonSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global FN PathName currentFrame RS I0 T F

R=RS;
I=I0;
save(sprintf('%s/%s-%03d-tracked.mat',PathName,FN,currentFrame),'R','I','T','F');


%
% These are various display functions for manipulating the GUI, such as
% displaying selected curves.
%


% --- Executes on button press in pushbuttonShowAll.
%
% Show all curves (in case we previously just showed a selection).
%
function pushbuttonShowAll_Callback(~, ~, handles)
% hObject    handle to pushbuttonShowAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global RS

ShowCurves(RS);

% --- Executes on button press in pushbuttonShowDominants.
%
% Only show those curves which are the strongest curves at _any_ time
% point.
%
function pushbuttonShowDominants_Callback(~, ~, handles)
% hObject    handle to pushbuttonShowDominants (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global I RS T F

% See the function description for an explanation of the third parameter,
% i.e. type 1 "dominants".
r=FindDominantRidges3(I,ConvertSpectralCoordsToPixels(RS,T,F),1);

ShowCurves(ConvertPixelsToSpectralCoords(r,T,F));


% --- Executes on button press in pushbuttonShowPower.
%
% Only show those curves with a power greater than the value specified in
% the GUI.
%
function pushbuttonShowPower_Callback(~, ~, handles)
% hObject    handle to pushbuttonShowPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global I RS T F

% Get the power threshold from the GUI
s=get(handles.editPower,'String');
minPow=str2double(s);

R=ConvertSpectralCoordsToPixels(RS,T,F);

% Build a set (r) of curves that meet the criterion
k=0;
r=[];
pp=zeros(1,length(R));
for n=1:length(R)
    t=R{n};
    if ~isempty(t)
        % p indicates the spectral power _per pixel_ (see RidgeLength for a
        % description of why)
        p=RidgeLength(t,I)/RidgeLength(t);
        pp(n)=exp(p);
        if pp(n)>=minPow
            k=k+1;
            r{k}=t;
        end
    end
end

set(handles.textHighestPower,'String',sprintf('%.2f',max(pp)));

ShowCurves(ConvertPixelsToSpectralCoords(r,T,F));

% --- Executes on button press in pushbuttonHighestPower.
%
% Show only the curve with the very highest power.
%
function pushbuttonHighestPower_Callback(~, ~, handles)
% hObject    handle to pushbuttonHighestPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global I RS T F

R=ConvertSpectralCoordsToPixels(RS,T,F);

% See the function description for an explanation of the third parameter,
% i.e. type 3 "dominants".
r=FindDominantRidges3(I,R,3);

ShowCurves(ConvertPixelsToSpectralCoords(r,T,F));



% --- Executes on button press in pushbuttonReset.
%
% Resets the spectrogram image to be unfiltered.
%
function pushbuttonReset_Callback(~, ~, handles)
% hObject    handle to pushbuttonReset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global I I0 mask T F HS RS

% I0 stored the original image without filtering
I=I0;
mask=zeros(size(I));

% Remove the detections - they're no longer relevant
HS=[];
RS=[];

% Reset maxF
s=get(handles.editMaxF,'String');
maxF=str2double(s);

ShowCurves([]);

set(handles.pushbuttonFilter,'enable','on');
set(handles.pushbuttonReset,'enable','on');
set(handles.pushbuttonHessian,'enable','on');
set(handles.pushbuttonTrack,'enable','off');
set(handles.pushbuttonSave,'enable','off');



% --- Executes on button press in pushbuttonPrevFrame.
%
% Calculate and display previous frame in WAV file (only enabled if there
% is one).
%
function pushbuttonPrevFrame_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPrevFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global currentFrame

% Go back one frame
currentFrame=currentFrame-1;

% Disable button if this is the first frame
if currentFrame==1
    set(handles.pushbuttonPrevFrame,'enable','off');
end

% Enable "next frame" button
set(handles.pushbuttonNextFrame,'enable','on');
% Display current frame number
set(handles.textFrameNo,'String',sprintf('(%d/%d)',currentFrame,length(FRAME)));

% Calculate and display this frame
pushbuttonCalcSpect_Callback(hObject, eventdata, handles);


% --- Executes on button press in pushbuttonNextFrame.
%
% Calculate and display next frame in WAV file (only enabled if there
% is one).
%
function pushbuttonNextFrame_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonNextFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global currentFrame FRAME

% Go forward one frame
currentFrame=currentFrame+1;

% Disable button if this is the last frame
if currentFrame==length(FRAME)
    set(handles.pushbuttonNextFrame,'enable','off');
end

% Enable "previous frame" button
set(handles.pushbuttonPrevFrame,'enable','on');
% Display current frame number
set(handles.textFrameNo,'String',sprintf('(%d/%d)',currentFrame,length(FRAME)));

% Calculate and display this frame
pushbuttonCalcSpect_Callback(hObject, eventdata, handles);



% --- Executes on button press in pushbuttonPlay.
%
% Play the WAV file.  Note the attempt to be cross platform.  'wavplay' is
% a Windows function that fails on Linux.  Unfortunately, I have had
% problems using the sound features on Ubuntu with the current version of
% Matlab, so I implemented this workaround.  Hopefully cvlc will be
% installed on your system!
%
function pushbuttonPlay_Callback(~, ~, ~)
% hObject    handle to pushbuttonPlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global FRAME currentFrame fs frameTime

try
    wavplay(FRAME{currentFrame},fs);
catch
    % wavplay fails on linux: write a temporary file and play it with cvlc
    wavwrite(FRAME{currentFrame},fs,'tmp.wav');
    system(sprintf('cvlc tmp.wav --play-and-exit\n'));
end


% --- Executes on button press in pushbuttonPlayAll.
%
% Synthesised and plays a sound, based on the extracted ridges, rather than
% on the original WAV file.  Kind of experimental.  It doesn't sound quite
% right to me...
%
function pushbuttonPlayAll_Callback(~, ~, handles)
% hObject    handle to pushbuttonPlayAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global RS

SynthesiseFromRidges(RS,handles);


% --- Executes on button press in pushbuttonPlayHighPower.
%
% Synthesise and play only the curve with the highest power.
%
function pushbuttonPlayHighPower_Callback(~, ~, handles)
% hObject    handle to pushbuttonPlayHighPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global I RS T F

R=ConvertSpectralCoordsToPixels(RS,T,F);
r=FindDominantRidges3(I,R,3);

SynthesiseFromRidges(ConvertPixelsToSpectralCoords(r,T,F),handles);


% --- Executes on button press in pushbuttonPlayDominants.
%
% Synthesise and play all the curves classed as "dominants" (see above for
% definition).
%
function pushbuttonPlayDominants_Callback(~, ~, handles)
% hObject    handle to pushbuttonPlayDominants (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global I RS T F

R=ConvertSpectralCoordsToPixels(RS,T,F);
r=FindDominantRidges3(I,R,1);

SynthesiseFromRidges(ConvertPixelsToSpectralCoords(r,T,F),handles);




% SynthesiseFromRidges
%
% Generates a sound stream based on the extracted ridges, rather than on
% the original WAV.  Uses Dan Ellis's synthtrax function.
%
% Input:
%   R - List of ridges to synthesise
%   window - FFT window size (needed for synthtrax function)
function SynthesiseFromRidges(R,handles)

global I fs frameTime F T

% Get the FFT window size from the GUI
s=get(handles.editWindow,'String');
window=str2double(s);

% Initialise empty matrices to hold the amplitude (MM) and frequency (FF)
% data.  They have as many rows as there are ridges, and as many columns as
% there are time points.
MM=zeros(length(R),size(I,2));
FF=zeros(length(R),size(I,2));

R=ConvertSpectralCoordsToPixels(R,T,F);

% Generate a row in the MM and FF matrices for each ridge
for n=1:length(R)
    % Get the ridge
    t=R{n};
    % Measure the intensity of the ridge in the original spectrogram for
    % each time point
    i=improfile(I,t(:,1),t(:,2),size(t,1));
    % Place this intesity information in the MM matrix - remembering that
    % I=log(P)
    MM(n,round(t(:,1)))=exp(i);
    % Place the frequency information in the FF matrix
    FF(n,round(t(:,1)))=F(length(F)-round(t(:,2))+1);
end

% Call the synththrax function, then standardise to [0-1]
W=synthtrax(FF,MM,fs/frameTime,window,window/2);
W=Standardise(W)*2-1;

% Try playing the sound (see above for an explanation of this workaround
% for Linux compatibility)
try
    wavplay(W,fs/frameTime);
catch
    % wavplay fails on linux: write a temporary file and play it with cvlc
    wavwrite(W,fs/frameTime,'tmp.wav');
    system(sprintf('cvlc tmp.wav --play-and-exit\n'));
end

% Display a little spectrogram of the synthesised sound, just to make sure
% that it has reproduced more or less what we wanted
p=MakeSpectrogram(W,fs,256,window);
axes(handles.axesSynthesis);
imshow(flipud(log(p)),[]);
axes(handles.axesI);



% --- Executes on button press in pushbuttonBatch.
%
% Batch process all the files in a directory:
% Take all the current parameters and apply them to all the WAV files in
% the current directory, saving the results in individual MAT files.
%
function pushbuttonBatch_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonBatch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global PathName W fs I mask HS maxF window FN FRAME T F I0

s=get(handles.editWindow,'String');
window=str2double(s);
s=get(handles.editMaxF,'String');
maxF=str2double(s);

fn=dir([PathName '/*.wav']);
FRAME=0;
for n=1:length(fn)
    FN=fn(n).name;
    fprintf('%d (%.1f%%) %s\n',n,n/length(fn)*100,FN);
    [W,fs]=wavread([PathName '/' FN]);
    [I,T,F,mask]=CalculateSpectrogram(W,fs,window);
    I0=I;
    [I,mask]=CalculateFilter(I,handles);
    HS=CalculateHessian(I,mask,handles);
    pushbuttonTrack_Callback(hObject, eventdata, handles);
    pushbuttonSave_Callback(hObject, eventdata, handles);
end


% --- Executes on button press in pushbuttonZoom.
function pushbuttonZoom_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonZoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global FRAME currentFrame maxF fs frameTime

axes(handles.axesI);
[~,rect]=imcrop;

t1=rect(1)-(currentFrame-1)*frameTime/2;
t2=rect(1)+rect(3)-(currentFrame-1)*frameTime/2;

w=FRAME{currentFrame};
w=w(round(t1*fs):round(t2*fs));

maxF=-rect(2);

CalculateAndDisplaySpectrogram(w,fs,handles);

set(handles.pushbuttonUnzoom,'enable','on');
set(handles.pushbuttonNextFrame,'enable','off');
set(handles.pushbuttonPrevFrame,'enable','off');

% --- Executes on button press in pushbuttonUnzoom.
function pushbuttonUnzoom_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonUnzoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global currentFrame FRAME

pushbuttonCalcSpect_Callback(hObject, eventdata, handles);

set(handles.pushbuttonUnzoom,'enable','off');
if currentFrame<length(FRAME)
    set(handles.pushbuttonNextFrame,'enable','on');
end
if currentFrame>1
    set(handles.pushbuttonPrevFrame,'enable','on');
end



%
%
% The rest are all automatically generated GUIDE functions
%
%













function editWindow_Callback(~, ~, ~)
% hObject    handle to editWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editWindow as text
%        str2double(get(hObject,'String')) returns contents of editWindow as a double


% --- Executes during object creation, after setting all properties.
function editWindow_CreateFcn(hObject, ~, ~)
% hObject    handle to editWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in togglebuttonAdapt.
function togglebuttonAdapt_Callback(~, ~, ~)
% hObject    handle to togglebuttonAdapt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebuttonAdapt


% --- Executes on button press in togglebuttonClick.
function togglebuttonClick_Callback(~, ~, ~)
% hObject    handle to togglebuttonClick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebuttonClick


% --- Executes on button press in togglebuttonBpass.
function togglebuttonBpass_Callback(~, ~, ~)
% hObject    handle to togglebuttonBpass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebuttonBpass



function editWidth_Callback(~, ~, ~)
% hObject    handle to editWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editWidth as text
%        str2double(get(hObject,'String')) returns contents of editWidth as a double


% --- Executes during object creation, after setting all properties.
function editWidth_CreateFcn(hObject, ~, ~)
% hObject    handle to editWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editMaxGap_Callback(~, ~, ~)
% hObject    handle to editMaxGap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMaxGap as text
%        str2double(get(hObject,'String')) returns contents of editMaxGap as a double


% --- Executes during object creation, after setting all properties.
function editMaxGap_CreateFcn(hObject, ~, ~)
% hObject    handle to editMaxGap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editHPF_Callback(~, ~, ~)
% hObject    handle to editHPF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editHPF as text
%        str2double(get(hObject,'String')) returns contents of editHPF as a double


% --- Executes during object creation, after setting all properties.
function editHPF_CreateFcn(hObject, ~, ~)
% hObject    handle to editHPF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editMinLenFinal_Callback(~, ~, ~)
% hObject    handle to editMinLenFinal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMinLenFinal as text
%        str2double(get(hObject,'String')) returns contents of editMinLenFinal as a double


% --- Executes during object creation, after setting all properties.
function editMinLenFinal_CreateFcn(hObject, ~, ~)
% hObject    handle to editMinLenFinal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editMinLen_Callback(~, ~, ~)
% hObject    handle to editMinLen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMinLen as text
%        str2double(get(hObject,'String')) returns contents of editMinLen as a double


% --- Executes during object creation, after setting all properties.
function editMinLen_CreateFcn(hObject, ~, ~)
% hObject    handle to editMinLen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLPF_Callback(~, ~, ~)
% hObject    handle to editLPF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLPF as text
%        str2double(get(hObject,'String')) returns contents of editLPF as a double


% --- Executes during object creation, after setting all properties.
function editLPF_CreateFcn(hObject, ~, ~)
% hObject    handle to editLPF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxHoriz.
function checkboxHoriz_Callback(~, ~, ~)
% hObject    handle to checkboxHoriz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxHoriz



function editMaxF_Callback(~, ~, ~)
% hObject    handle to editMaxF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMaxF as text
%        str2double(get(hObject,'String')) returns contents of editMaxF as a double


% --- Executes during object creation, after setting all properties.
function editMaxF_CreateFcn(hObject, ~, ~)
% hObject    handle to editMaxF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPower_Callback(~, ~, ~)
% hObject    handle to editPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPower as text
%        str2double(get(hObject,'String')) returns contents of editPower as a double


% --- Executes during object creation, after setting all properties.
function editPower_CreateFcn(hObject, ~, ~)
% hObject    handle to editPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in togglebuttonMask.
function togglebuttonMask_Callback(~, ~, ~)
% hObject    handle to togglebuttonMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebuttonMask



function editISD_Callback(~, ~, ~)
% hObject    handle to editISD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editISD as text
%        str2double(get(hObject,'String')) returns contents of editISD as a double


% --- Executes during object creation, after setting all properties.
function editISD_CreateFcn(hObject, ~, ~)
% hObject    handle to editISD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxRochJoiner.
function checkboxRochJoiner_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxRochJoiner (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxRochJoiner



function editMaxTurn_Callback(hObject, eventdata, handles)
% hObject    handle to editMaxTurn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMaxTurn as text
%        str2double(get(hObject,'String')) returns contents of editMaxTurn as a double


% --- Executes during object creation, after setting all properties.
function editMaxTurn_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMaxTurn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
