function varargout = ChagneDetectionUI(varargin)
% ChagneDetectionUI(AudioFilename, OptionalArguments)
% Whistle/Tonal trackingdebug tool

% Note:
% This function requires ChagneDetectionUI.fig to be present and uses
% callbacks extensively.
% See also: GUIDE, GUIDATA, GUIHANDLES

% Last Modified by GUIDE v2.5 28-Aug-2014 12:03:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ChagneDetectionUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ChagneDetectionUI_OutputFcn, ...
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


% =====================================================================
% Callbacks 
% ====================================================================

% --- Executes just before ChagneDetectionUI is made visible.
function handles = ChagneDetectionUI_OpeningFcn(hObject, eventdata, handles, ...
    varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ChagneDetectionUI 
%            See file header for list

% Verify correct number of inputs
%error(nargchk(4,Inf,nargin));
% Choose default command line output for ChagneDetectionUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Settable Parameters --------------------------------------------------
% The threshold set is processed before any other argument as other
% arguments override the parameter set.
data.thr = dtParseParameterSet(varargin{:});  % retrieve parameters

% Defaults
data.NoiseMethod = {'none'};
% spectrogram colors
data.SpecgramColormap = bone();
data.scale = 1000; % kHz

data.thr.advance_ms = .5;
data.thr.length_ms = 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filename Handling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Filename = varargin{1};
if isempty(Filename)
    [Filename, FileDir] = uigetfile('.wav', 'Develop ground truth for file');
    if isnumeric(Filename)
        fprintf('User abort\n');
        close();
        return
    else
        data.Filename = fullfile(FileDir, Filename);
    end
else
    data.Filename = Filename;
end

[fdir, fname] = fileparts(data.Filename);
data.hdr = ioReadWavHeader(data.Filename);


% defaults
data.Start_s = 0;
data.Stop_s = data.hdr.Chunks{data.hdr.dataChunk}.nSamples/data.hdr.fs;
data.RemoveTransients = false;
data.RemovalMethod = '';

data.operation = [];

data.FigureTitle = '';

data.ms_per_s = 1000;
data.thr.advance_s = data.thr.advance_ms / data.ms_per_s;
viewStartSeconds = 0;
viewLengthSeconds = 7;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% processs arguments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
k = 2;
while k <= length(varargin)
    switch varargin{k}
        case 'ViewStart'
            viewStartSeconds = varargin{k+1};
            k=k+2;
        case 'ViewLength'
            viewLengthSeconds = varargin{k+1};
            k=k+2;
        otherwise
            error('Unknown paramters %s', varargin{k});
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Change Detection

DeltaMS = struct();
DeltaMS.Low = 500; % Low resolution search interval
DeltaMS.High = 50; % High resolution search interval
data.DeltaMS = DeltaMS;

set(handles.deltaLow, 'String', num2str(DeltaMS.Low ));
set(handles.deltaHigh, 'String', num2str(DeltaMS.High));

WinS = struct();
WinS.WindowMin = 5;
WinS.WindowMax = 10;
WinS.Margin = .5;
WinS.Growth = .5;
WinS.Shift = 1;
WinS.Second = 3;
data.WinS = WinS;

set(handles.windowMinSize, 'String', num2str(WinS.WindowMin));
set(handles.windowMaxSize, 'String', num2str(WinS.WindowMax));
set(handles.margin, 'String', num2str(WinS.Margin));
set(handles.growth, 'String', num2str(WinS.Growth));
set(handles.shift, 'String', num2str(WinS.Shift));
set(handles.secondSize, 'String', num2str(WinS.Second));

data.PenaltyWeight = .85;

set(handles.penaltyWeight, 'String', num2str(data.PenaltyWeight));


data.low_disp_Hz = data.thr.low_cutoff_Hz;
set(handles.Low, 'String', num2str(data.low_disp_Hz));
data.high_disp_Hz = data.thr.high_cutoff_Hz;
set(handles.High, 'String', num2str(data.high_disp_Hz));

set(handles.frameLengthField, 'String', num2str(data.thr.length_ms));
set(handles.frameAdvanceField, 'String', num2str(data.thr.advance_ms));

handles.colorbar = [];
handles.image = [];

set(handles.TrackingDebug, 'Name', sprintf('%s%s Annotation [%s]', ...
    data.FigureTitle, fname, fdir));

% I've observed some problems that may be due to a race condition.
% Try setting children's busyaction to cancel
children = setdiff(findobj(handles.TrackingDebug, 'BusyAction', 'queue'), ...
    handles.TrackingDebug);
set(children, 'BusyAction', 'cancel')

data.Start_s = start_in_range(viewStartSeconds, handles, data);
set(handles.Start_s, 'String', num2str(data.Start_s));

data.ViewLength_s = viewLengthSeconds;
set(handles.ViewLength_s, 'String', num2str(viewLengthSeconds));

linkaxes([handles.spectrogram, handles.bic], 'x');

data.changeCallback = ChangePointCallback(handles.bic, handles.spectrogram);

SaveDataInFigure(handles, data);  % save user/figure data before plot
[handles, data] = spectrogram(handles, data);
SaveDataInFigure(handles, data);

                    
% --- Outputs from this function are returned to the command line.
function varargout = ChagneDetectionUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function Threshold_dB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Threshold_dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function High_Callback(hObject, eventdata, handles)
% hObject    handle to High (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

high = str2double(get(hObject,'String'));
data = get(handles.TrackingDebug, 'UserData');
if isnan(high)
    report(hObject, handles, 'Invalid high range');
    set(hObject, 'String', str2double(data.high_disp_Hz));
elseif high < data.low_disp_Hz
    report(hObject, handles, 'Display limits:  low > high ');
    set(hObject, 'String', str2double(data.high_disp_Hz));
else    
    data.high_disp_Hz = high;
    set(handles.TrackingDebug, 'UserData', data);
end


% --- Executes during object creation, after setting all properties.
function High_CreateFcn(hObject, eventdata, handles)
% hObject    handle to High (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Low_Callback(hObject, eventdata, handles)
% Low_Callback(hObject, eventdata, handles)
% hObject    handle to Low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Set lower plot limit for spectrogram

low = str2double(get(hObject,'String'));
data = get(handles.TrackingDebug, 'UserData');
if isnan(low)
    report(hObject, handles, 'Invalid low range');
    set(hObject, 'String', str2double(data.low_disp_Hz));
elseif low >= data.high_disp_Hz
    report(hObject, handles, 'Display limits:  low > high ');
    set(hObject, 'String', str2double(data.low_disp_Hz));
else    
    data.low_disp_Hz = low;
    set(handles.TrackingDebug, 'UserData', data);
end

% --- Executes during object creation, after setting all properties.
function Low_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Low (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ViewLength_s_Callback(hObject, eventdata, handles)
% hObject    handle to ViewLength_s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

length_s = str2double(get(hObject, 'String'));
if isnan(length_s);
    % bad entry, set to current display length, bad luck for user 
    % if they zoomed in
    xlim = get(handles.spectrogram, 'XLim');
    length_s = diff(xlim);
    report(hObject, handles, 'Bad plot length.');
    set(hObject, 'String', num2str(length_s));
else
    data = get(handles.TrackingDebug, 'UserData');
    [handles, data] = spectrogram(handles, data);
    SaveDataInFigure(handles, data);
end
    
% --- Executes during object creation, after setting all properties.
function ViewLength_s_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ViewLength_s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Advance_Pct_Callback(hObject, eventdata, handles)
% hObject    handle to Advance_Pct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

advance_pct = str2double(get(hObject, 'String'));
if isnan(advance_pct) || advance_pct <= 0
    report(hObject, handles, 'Advance % must be > 0');
    set(hObject, 'String', '80')
end

% --- Executes during object creation, after setting all properties.
function Advance_Pct_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Advance_Pct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Start.
function Start_Callback(hObject, eventdata, handles)
% hObject    handle to Start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set start time to earliest specified by the user.
data = get(handles.TrackingDebug, 'UserData');
% See what we are currently starting at
if data.Start_s ~= 0
    data.Start_s = 0;
    set(handles.TrackingDebug, 'UserData', data);
    set(handles.Start_s, 'String', num2str(data.Start_s));
    [handles, data] = spectrogram(handles, data);
    SaveDataInFigure(handles, data);
end


% --- Executes on button press in Rewind.
function Rewind_Callback(hObject, eventdata, handles)
% hObject    handle to Rewind (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Rewind by specified Advance/Rewind frame parameters

data = get(handles.TrackingDebug, 'UserData');
advance_s = getAdvance_s(handles);
new_s = start_in_range(data.Start_s - advance_s, handles, data);
if data.Start_s ~= new_s
    set(handles.Start_s, 'String', num2str(new_s));
    data.Start_s = new_s;
    [handles, data] = spectrogram(handles, data);
    SaveDataInFigure(handles, data);
end

% --- Executes on button press in Advance.
function Advance_Callback(hObject, eventdata, handles)
% hObject    handle to Advance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set start time to earliest specified by the user.
data = get(handles.TrackingDebug, 'UserData');
advance_s = getAdvance_s(handles);
new_s = start_in_range(data.Start_s + advance_s, handles, data);
if data.Start_s ~= new_s
    set(handles.Start_s, 'String', num2str(new_s));
    data.Start_s = new_s;
    [handles, data] = spectrogram(handles, data);
    SaveDataInFigure(handles, data);
end

% --- Executes on button press in End.
function End_Callback(hObject, eventdata, handles)
% hObject    handle to End (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set start time to earliest specified by the user.
data = get(handles.TrackingDebug, 'UserData');
% See what we are currently starting at
current_s = str2double(get(handles.Start_s, 'String'));
latest_start = start_in_range(data.Stop_s, handles, data);
if current_s ~= latest_start
    set(handles.Start_s, 'String', num2str(latest_start));
    data.Start_s = latest_start;
    [handles, data] = spectrogram(handles, data);
    SaveDataInFigure(handles, data);
end

% --- Executes on slider movement.
function Brightness_Callback(hObject, eventdata, handles)
% hObject    handle to Brightness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

brightness = get(handles.Brightness, 'Value');
contrast = get(handles.Contrast, 'Value');
set(handles.BrightnessValue, 'String', num2str(brightness));
handles.colorbar = colorbar('peer', handles.spectrogram);
dtBrightContrast(handles.image, brightness, contrast, -Inf, handles.colorbar);
guidata(handles.TrackingDebug, handles);


% --- Executes during object creation, after setting all properties.
function Brightness_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Brightness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function Contrast_Callback(hObject, eventdata, handles)
% hObject    handle to Contrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
brightness = get(handles.Brightness, 'Value');
contrast = get(hObject, 'Value');
set(handles.ContrastValue, 'String', num2str(contrast));
handles.colorbar = colorbar('peer', handles.spectrogram);
dtBrightContrast(handles.image, brightness, contrast, -Inf, handles.colorbar);
guidata(handles.TrackingDebug, handles);


% --- Executes during object creation, after setting all properties.
function Contrast_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Contrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function BrightnessValue_Callback(hObject, eventdata, handles)
% hObject    handle to BrightnessValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

brightness = str2double(get(hObject, 'String'));
% Ensure in range
brightness = max(get(handles.Brightness, 'Min'), brightness);
brightness = min(get(handles.Brightness, 'Max'), brightness);
set(handles.Brightness, 'Value', brightness);
Brightness_Callback(handles.Brightness, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function BrightnessValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BrightnessValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ContrastValue_Callback(hObject, eventdata, handles)
% hObject    handle to ContrastValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

contrast = str2double(get(hObject, 'String'));
% Ensure in range
if isnan(contrast)
    contrast = 100;
end
contrast = max(get(handles.Contrast, 'Min'), contrast);
contrast = min(get(handles.Contrast, 'Max'), contrast);
set(handles.Contrast, 'Value', contrast);
Contrast_Callback(handles.Contrast, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function ContrastValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ContrastValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
        
function new_s = start_in_range(start_s, handles, data)
% Ensure start time is valid 

% Make sure we don't go past the end
viewlength_s = str2double(get(handles.ViewLength_s, 'String'));
new_s = min(data.Stop_s - viewlength_s, start_s);
% Start >= 0
new_s = max(0, new_s);

% Ensure aligned on a frame
new_s = new_s - rem(new_s, data.thr.length_ms/1000);

function Start_s_Callback(hObject, eventdata, handles)
% hObject    handle to Start_s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Start_s as text
%        str2double(get(hObject,'String')) returns contents of Start_s as a double
data = get(handles.TrackingDebug, 'UserData');
start_s = str2double(get(hObject, 'String'));
if isnan(start_s)
    report(hObject, handles, 'Bad start time');
    set(hObject, 'String', num2str(data.Start_s));
    return
end
new_s = start_in_range(start_s, handles, data);
if new_s ~= start_s
    %report(hObject, handles, 'Adjusted start time');
    set(hObject, 'String', num2str(new_s));
end
data.Start_s = new_s;
[handles, data] = spectrogram(handles, data);
SaveDataInFigure(handles, data);


% --- Executes during object creation, after setting all properties.
function Start_s_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Start_s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function openAudioFile_Callback(hObject, eventdata, handles)
% hObject    handle to openAudioFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.TrackingDebug, 'UserData');

[Filename, FileDir] = uigetfile('.wav', 'Open audio file.');
if isnumeric(Filename)
    return;
else
    data.Filename = fullfile(FileDir, Filename);
end
 

data.hdr = ioReadWavHeader(data.Filename);
% defaults
data.Start_s = 0;
data.Stop_s = data.hdr.Chunks{data.hdr.dataChunk}.nSamples/data.hdr.fs;


% Make sure current point is not past end of file
% We don't set the start to 0 in case the user wants
% to look at the same point in similar files.
newstart_s = start_in_range(data.Start_s, handles, data);
data.Start_s = newstart_s;
set(handles.Start_s, 'String', num2str(newstart_s));
[handles, data] = spectrogram(handles, data);
SaveDataInFigure(handles, data);



% --------------------------------------------------------------------
function advance_s = getAdvance_s(handles)
% advance_s = getAdvance_s(handles)
% Compute the current advance based on the Adv/Rew percentage
% and the plot length
length_s = str2double(get(handles.ViewLength_s, 'String'));
percent = str2double(get(handles.Advance_Pct, 'String'))/100;
advance_s = length_s * percent;

% --------------------------------------------------------------------
function [handles, data] = spectrogram(handles, data)
% wait pointer
pointer = get(handles.TrackingDebug, 'Pointer');
set(handles.TrackingDebug, 'Pointer', 'watch');
drawnow update;

spH = handles.spectrogram;
blkstart_s = str2double(get(handles.Start_s, 'String'));
blkstop_s = blkstart_s + str2double(get(handles.ViewLength_s, 'String'));
data.blkstart_s = blkstart_s;
data.blkstop_s = blkstop_s;

RenderOpts = {};
if ishandle(handles.colorbar)  % remove current colorbar if present
    delete(handles.colorbar);
end
if ~isempty(handles.image)   % remove old image panes before drawing new ones
    images = ishandle(handles.image);
    if sum(images) > 0
        delete(handles.image(images));
    end
    handles.image = [];
end

brightness = get(handles.Brightness, 'Value');
contrast = get(handles.Contrast, 'Value');

colormap(data.SpecgramColormap);

% minimum value may be set < 0 for knot editing
% make sure spectrogram is >= 0
low_spec_Hz = max(0, data.low_disp_Hz);
[axisH, handles.image, handles.colorbar, snr_dB, power_dB] = ...
        dtPlotSpecgram(data.Filename, blkstart_s, blkstop_s, ...
        'Contrast_Pct', contrast, 'Brightness_dB', brightness, ...
        'Axis', spH, ...
        'Framing', [data.thr.advance_ms, data.thr.length_ms], ...
        'Noise', data.NoiseMethod, ...
        'ParameterSet', data.thr, ...
        'RemoveTransients', data.RemoveTransients, ...
        'RemovalMethod', data.RemovalMethod, ...
        'Range', [low_spec_Hz, data.high_disp_Hz], ...
        RenderOpts{:});
    
if data.low_disp_Hz < low_spec_Hz
    set(axisH, 'YLim', ...
        [data.low_disp_Hz/data.scale, data.high_disp_Hz/data.scale]);
end

data.snr_dB = snr_dB;
        
% Has user enabled thresholding?
threshold_p = get(handles.ThresholdEnable, 'Value');
if threshold_p
    % Perform thresholding of energy bins
    dtBrightContrast(handles.image, brightness, contrast, ...
        str2double(get(handles.Threshold_dB, 'String')), handles.colorbar);
end

% Images will painted on top of any preview or selected points, 
% Reorder, placing images at end of list
axisChildren = get(axisH, 'Children');
axisIndcs = 1:length(axisChildren);

% Locate the images in the list of children
imageIndcs = zeros(length(handles.image), 1);
for idx=1:length(imageIndcs)
    imageIndcs(idx) = find(axisChildren == handles.image(idx));
end
% Reorder to place at end
set(axisH, 'Children', ...
    axisChildren([setdiff(axisIndcs, imageIndcs'), imageIndcs']));

set(handles.TrackingDebug, 'Pointer', pointer);

spectrogramPos = get(handles.spectrogram, 'Position');

progressPos = get(handles.bic, 'Position');
progressPos(3) = spectrogramPos(3);
set(handles.bic, 'Position', progressPos);
set(handles.bic, 'xlim', get(handles.spectrogram, 'xlim'));

cla(handles.bic);
hold(handles.bic, 'on');

hold(handles.spectrogram, 'on');
SaveDataInFigure(handles, data);
detectChanges(handles);



% --------------------------------------------------------------------
function SaveDataInFigure(handles, data)
% Save the handles/data structures as GUI and user data in the 
% figure
guidata(handles.TrackingDebug, handles);
set(handles.TrackingDebug, 'UserData', data);


% --------------------------------------------------------------------
function Close_Callback(hObject, eventdata, handles)
% hObject    handle to Close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close();

% --- Executes when TrackingDebug is resized.
function TrackingDebug_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to TrackingDebug (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function frameLengthField_Callback(hObject, eventdata, handles)
% hObject    handle to frameLengthField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frameLengthField as text
%        str2double(get(hObject,'String')) returns contents of frameLengthField as a double
data = get(handles.TrackingDebug, 'UserData');
data.thr.length_ms = str2double(get(handles.frameLengthField, 'String'));
[handles, data] = spectrogram(handles, data);
SaveDataInFigure(handles, data);

% --- Executes during object creation, after setting all properties.
function frameLengthField_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frameLengthField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function frameAdvanceField_Callback(hObject, eventdata, handles)
% hObject    handle to frameAdvanceField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frameAdvanceField as text
%        str2double(get(hObject,'String')) returns contents of frameAdvanceField as a double
data = get(handles.TrackingDebug, 'UserData');
data.thr.advance_ms = str2double(get(handles.frameAdvanceField, 'String'));
[handles, data] = spectrogram(handles, data);
SaveDataInFigure(handles, data);

% --- Executes during object creation, after setting all properties.
function frameAdvanceField_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frameAdvanceField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in noiseCompMenu.
function noiseCompMenu_Callback(hObject, eventdata, handles)
% hObject    handle to noiseCompMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns noiseCompMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from noiseCompMenu
data = get(handles.TrackingDebug, 'UserData');
selectedIdx = get(handles.noiseCompMenu, 'Value');
values = get(handles.noiseCompMenu, 'String');
selectedValue = values(selectedIdx);
data.NoiseMethod = lower(selectedValue{:});
SaveDataInFigure(handles, data);  % save user/figure data before plot
[handles, data] = spectrogram(handles, data);
SaveDataInFigure(handles, data);

% --- Executes during object creation, after setting all properties.
function noiseCompMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to noiseCompMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on selection change in transientMenu.
function transientMenu_Callback(hObject, eventdata, handles)
% hObject    handle to transientMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns transientMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from transientMenu
data = get(handles.TrackingDebug, 'UserData');
selectedIdx = get(handles.transientMenu, 'Value');
data.RemoveTransients = selectedIdx > 1;
switch selectedIdx
    case 2
        data.RemovalMethod = 'poly';
    case 3
        data.RemovalMethod = 'linear';
end

[handles, data] = spectrogram(handles, data);
SaveDataInFigure(handles, data);


% --- Executes during object creation, after setting all properties.
function transientMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to transientMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function windowMinSize_Callback(hObject, eventdata, handles)
% hObject    handle to windowMinSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of windowMinSize as text
%        str2double(get(hObject,'String')) returns contents of windowMinSize as a double
data = get(handles.TrackingDebug, 'UserData');
data.WinS.WindowMin = str2double(get(handles.windowMinSize, 'String'));
SaveDataInFigure(handles, data);
detectChanges(handles);


% --- Executes during object creation, after setting all properties.
function windowMinSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to windowMinSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function windowMaxSize_Callback(hObject, eventdata, handles)
% hObject    handle to windowMaxSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of windowMaxSize as text
%        str2double(get(hObject,'String')) returns contents of windowMaxSize as a double
data = get(handles.TrackingDebug, 'UserData');
data.WinS.WindowMax = str2double(get(handles.windowMaxSize, 'String'));
SaveDataInFigure(handles, data);
detectChanges(handles);

% --- Executes during object creation, after setting all properties.
function windowMaxSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to windowMaxSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function margin_Callback(hObject, eventdata, handles)
% hObject    handle to margin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of margin as text
%        str2double(get(hObject,'String')) returns contents of margin as a double


% --- Executes during object creation, after setting all properties.
function margin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to margin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function growth_Callback(hObject, eventdata, handles)
% hObject    handle to growth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of growth as text
%        str2double(get(hObject,'String')) returns contents of growth as a double


% --- Executes during object creation, after setting all properties.
function growth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to growth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function shift_Callback(hObject, eventdata, handles)
% hObject    handle to shift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of shift as text
%        str2double(get(hObject,'String')) returns contents of shift as a double


% --- Executes during object creation, after setting all properties.
function shift_CreateFcn(hObject, eventdata, handles)
% hObject    handle to shift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function secondSize_Callback(hObject, eventdata, handles)
% hObject    handle to secondSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of secondSize as text
%        str2double(get(hObject,'String')) returns contents of secondSize as a double


% --- Executes during object creation, after setting all properties.
function secondSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to secondSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function deltaLow_Callback(hObject, eventdata, handles)
% hObject    handle to deltaLow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of deltaLow as text
%        str2double(get(hObject,'String')) returns contents of deltaLow as a double
data = get(handles.TrackingDebug, 'UserData');
data.DeltaMS.Low = str2double(get(handles.deltaLow, 'String'));
SaveDataInFigure(handles, data);
detectChanges(handles);



% --- Executes during object creation, after setting all properties.
function deltaLow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to deltaLow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function deltaHigh_Callback(hObject, eventdata, handles)
% hObject    handle to deltaHigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of deltaHigh as text
%        str2double(get(hObject,'String')) returns contents of deltaHigh as a double
data = get(handles.TrackingDebug, 'UserData');
data.DeltaMS.High = str2double(get(handles.deltaHigh, 'String'));
SaveDataInFigure(handles, data);
detectChanges(handles);

% --- Executes during object creation, after setting all properties.
function deltaHigh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to deltaHigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function penaltyWeight_Callback(hObject, eventdata, handles)
% hObject    handle to penaltyWeight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of penaltyWeight as text
%        str2double(get(hObject,'String')) returns contents of penaltyWeight as a double


% --- Executes during object creation, after setting all properties.
function penaltyWeight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to penaltyWeight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function detectChanges(handles)
data = get(handles.TrackingDebug, 'UserData');
data.changeCallback.clearRendering();
detect_noise_changes_in_file(data.Filename, data.blkstart_s, data.blkstop_s, ...
    'Delta', data.DeltaMS,...
    'Window', data.WinS,...
    'Callback', data.changeCallback, ...
    'PeakSelection', {'Method', 'magnitude'}...
);
