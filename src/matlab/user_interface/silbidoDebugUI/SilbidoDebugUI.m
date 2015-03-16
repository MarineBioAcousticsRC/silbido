function varargout = SilbidoDebugUI(varargin)
% Whistle/Tonal trackingdebug tool
% Optional arguments in any order:
%   'Filename'
%       The file name of the file to open.
%   'ViewStart'
%       The location in the file (in seconds) to
%       start the debug view at.
%   'ViewLength'
%       The length (in seconds) to initially render in
%       the debugge.
%   'NoiseBoundaries'
%       The noise boundaries to use.  If none are supplied
%       standard 3 second blocks will be used.


% Note:
% This function requires SilbidoDebugUI.fig to be present and uses
% callbacks extensively.
% See also: GUIDE, GUIDATA, GUIHANDLES

% Last Modified by GUIDE v2.5 31-Aug-2014 13:20:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SilbidoDebugUI_OpeningFcn, ...
                   'gui_OutputFcn',  @SilbidoDebugUI_OutputFcn, ...
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

% --- Executes just before SilbidoDebugUI is made visible.
function handles = SilbidoDebugUI_OpeningFcn(hObject, eventdata, handles, ...
    varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SilbidoDebugUI 
%            See file header for list

% Verify correct number of inputs
%error(nargchk(4,Inf,nargin));
% Choose default command line output for SilbidoDebugUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Settable Parameters --------------------------------------------------
% The threshold set is processed before any other argument as other
% arguments override the parameter set.
data.thr = dtParseParameterSet(varargin{:});  % retrieve parameters

% Defaults
data.NoiseMethod = {'median'};
% spectrogram colors
data.SpecgramColormap = bone();
data.scale = 1000; % kHz

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% processs arguments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Defaults
viewStartSeconds = 0;
viewLengthSeconds = 10;
k = 1;
while k <= length(varargin)
    switch varargin{k}
        case 'Filename'
            Filename = varargin{k+1};
            k=k+2;
        case 'ViewStart'
            viewStartSeconds = varargin{k+1};
            k=k+2;
        case 'ViewLength'
            viewLengthSeconds = varargin{k+1};
            k=k+2;
        case 'NoiseBoundaries'
            data.noiseBoundaries = varargin{k+1};
            k=k+2;
        otherwise
            error('Unknown paramters %s', varargin{k});
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filename Handling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('Filename', 'var') || isempty(Filename)
    [Filename, FileDir] = uigetfile('.wav', 'Develop ground truth for file');
    if isnumeric(Filename)
        fprintf('User abort\n');
        close();
        return
    else
        data.Filename = fullfile(FileDir, Filename);
        cd(FileDir);
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

% This is a work around so we get access to the actual parameters
% we will use for signal processing.
tt = TonalTracker(data.Filename, 0, data.Stop_s);
data.tt = tt;

%calculate_block_starts(tt.thr.blocklen_s)

data.operation = [];

data.FigureTitle = '';

data.ms_per_s = 1000;
data.thr.advance_s = data.thr.advance_ms / data.ms_per_s;

data.noiseBoundaries = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Variables
%
data.low_disp_Hz = data.thr.low_cutoff_Hz;
set(handles.Low, 'String', num2str(data.low_disp_Hz));
data.high_disp_Hz = data.thr.high_cutoff_Hz;
set(handles.High, 'String', num2str(data.high_disp_Hz));

set(handles.frameLengthField, 'String', num2str(data.thr.length_ms));
set(handles.frameAdvanceField, 'String', num2str(data.thr.advance_ms));


handles.colorbar = [];
handles.image = [];

data.boundary_handles = [];

set(handles.TrackingDebug, 'Name', sprintf('%s%s Debug [%s]', ...
    data.FigureTitle, fname, fdir));

% I've observed some problems that may be due to a race condition.
% Try setting children's busyaction to cancel
children = setdiff(findobj(handles.TrackingDebug, 'BusyAction', 'queue'), ...
    handles.TrackingDebug);
set(children, 'BusyAction', 'cancel')

data.breakpoints = [];
data.stepAction = 0; % 0=detect peaks, 1=prune and extend.

data.debugRenderingManager = DebugRenderingManager(handles, data.thr);
data.stopRequested = false;
data.pauseRequested = false;
data.atBreakPoint = false;
data.pauseAtNextPeak = false;
hold(handles.progressAxes, 'on');

data.Start_s = start_in_range(viewStartSeconds, handles, data);
set(handles.Start_s, 'String', num2str(data.Start_s));

data.ViewLength_s = viewLengthSeconds;
set(handles.ViewLength_s, 'String', num2str(viewLengthSeconds));

linkaxes([handles.spectrogram, handles.progressAxes], 'x');

data.blocks = dtBlockBoundaries(data.noiseBoundaries,...
    data.Stop_s, data.tt.thr.blocklen_s, data.tt.block_pad_s, ...
    data.thr.advance_s, data.tt.shift_samples_s);

data.defaultBlocks = dtBlockBoundaries([],...
    data.Stop_s, data.tt.thr.blocklen_s, data.tt.block_pad_s, ...
    data.thr.advance_s, data.tt.shift_samples_s);

SaveDataInFigure(handles, data);  % save user/figure data before plot
[handles, data] = spectrogram(handles, data);
SaveDataInFigure(handles, data);

                    
% --- Outputs from this function are returned to the command line.
function varargout = SilbidoDebugUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in ThresholdEnable.
function ThresholdEnable_Callback(hObject, eventdata, handles)
% hObject    handle to ThresholdEnable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

threshold_p = get(hObject, 'Value');
brightness = get(handles.Brightness, 'Value');
contrast = get(handles.Contrast, 'Value');
if threshold_p
    dtBrightContrast(handles.image, brightness, contrast, ...
        str2double(get(handles.Threshold_dB, 'String')), handles.colorbar);
else
    dtBrightContrast(handles.image, brightness, contrast, -Inf, handles.colorbar);
end

function Threshold_dB_Callback(hObject, eventdata, handles)
% hObject    handle to Threshold_dB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

value = str2double(get(hObject, 'String'));
if isnan(value) 
    set(hObject, 'String', '10'); % bad value, set to default
end
if get(handles.ThresholdEnable, 'Value')
    % thresholding enabled, update
    ThresholdEnable_Callback(handles.ThresholdEnable, eventdata, handles);
end

% Hints: get(hObject,'String') returns contents of Threshold_dB as text
%        str2double(get(hObject,'String')) returns contents of Threshold_dB as a double


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
    length_s = str2double(get(handles.ViewLength_s, 'String'));
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
current_s = str2double(get(handles.Start_s, 'String'));
new_s = start_in_range(current_s - advance_s, handles, data);
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
current_s = str2double(get(handles.Start_s, 'String'));
advance_s = getAdvance_s(handles);
new_s = start_in_range(current_s + advance_s, handles, data);
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

% TODO:  Add warning if there are unsaved annotatations as they will be lost
data = get(handles.TrackingDebug, 'UserData');

if (strcmp(data.Mode, 'annotate') == 1)
    [Filename, FileDir] = uigetfile('.wav', 'Audio file to create/view annotations');
    if isnumeric(Filename)
        return;
    else
        data.Filename = fullfile(FileDir, Filename);
        cd(FileDir);
    end
else        
    [accepted, corupus_rel_path] = corpus_file_chooser(data.CorpusBaseDir);
    if (accepted)
        data.RelativeFilePath = corupus_rel_path;
        data.Filename = fullfile(data.CorpusBaseDir, corupus_rel_path);
        [scored_path, ~, ~] = fileparts(fullfile(data.ScoringBaseDir, data.RelativeFilePath));
        data = process_scored_detections_dir(data, scored_path);
    else
        return;
    end
end
 

data.hdr = ioReadWavHeader(data.Filename);
% defaults
data.Start_s = 0;
data.Stop_s = data.hdr.Chunks{data.hdr.dataChunk}.nSamples/data.hdr.fs;
data.AnnotationFile = AudioFname2Tonal(data.Filename);

% Clear out any existing selections/operations in progress
handles = ReleaseSelections_Callback(hObject, eventdata, handles);
handles = ReleasePoints(handles);

% Remove all tonals and editing history
data.annotations = java.util.LinkedList(); % empty list of annotations
data.undo = struct('before', {}, 'after', {});

% Make sure current point is not past end of file
% We don't set the start to 0 in case the user wants
% to look at the same point in similar files.
newstart_s = start_in_range(data.Start_s, handles, data);
data.Start_s = newstart_s;
set(handles.Start_s, 'String', num2str(newstart_s));
[handles, data] = spectrogram(handles, data);
SaveDataInFigure(handles, data);



% --------------------------------------------------------------------
function Detect_Callback(hObject, eventdata, handles)
% hObject    handle to Detect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.TrackingDebug, 'UserData');

% wait pointer
pointer = get(handles.TrackingDebug, 'Pointer');
set(handles.TrackingDebug, 'Pointer', 'watch');

% Remove any plotted ones
drawnow update expose;

callback = DebugTrackingCallback(handles, data.thr);
start_s = str2double(get(handles.Start_s, 'String'));
end_s = start_s + str2double(get(handles.ViewLength_s, 'String'));

data.annotations = ...
    dtTonalsTracking(data.Filename, start_s, end_s, 'ParameterSet', data.thr, 'SPCallback', callback);
set(handles.TrackingDebug, 'UserData', data);


SaveDataInFigure(handles, data);

% Restore pointer
set(handles.TrackingDebug, 'Pointer', pointer);


function detect_process_block(handles, spectrogram, start_s, end_s)
    fprintf('adfasdf');


% --------------------------------------------------------------------
function audioFilenameToClipboard_Callback(hObject, eventdata, handles)
% hObject    handle to audioFilenameToClipboard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = get(handles.TrackingDebug, 'UserData');
clipboard('copy', data.Filename);


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

nb = [];

if strcmpi(get(handles.noiseBondariesToggle, 'State'), 'on')
    nb = data.noiseBoundaries;
end

% minimum value may be set < 0 for knot editing
% make sure spectrogram is >= 0
low_spec_Hz = max(0, data.low_disp_Hz);
[axisH, handles.image, handles.colorbar, snr_dB] = ...
        dtPlotSpecgram(data.Filename, blkstart_s, blkstop_s, ...
        'Contrast_Pct', contrast, 'Brightness_dB', brightness, ...
        'Axis', spH, ...
        'Framing', [data.thr.advance_ms, data.thr.length_ms], ...
        'Noise', data.NoiseMethod, ...
        'ParameterSet', data.thr, ...
        'RemoveTransients', data.RemoveTransients, ...
        'RemovalMethod', data.RemovalMethod, ...
        'Range', [low_spec_Hz, data.high_disp_Hz], ...
        'NoiseBoundaries', nb,...
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

set(handles.image, 'buttondownfcn', @spectrogram_ButtonDownFcn);

set(handles.TrackingDebug, 'Pointer', pointer);

spectrogramPos = get(axisH, 'Position');
get(handles.progressAxes, 'Position');
progressPos = get(handles.progressAxes, 'Position');
progressPos(3) = spectrogramPos(3);
set(handles.progressAxes, 'Position', progressPos);
set(handles.progressAxes, 'xlim', get(handles.spectrogram, 'xlim'));
[data, handles] = updateNoiseBoundaries(data, handles);



% --------------------------------------------------------------------
function ax_points = vport_to_axis(axis_h, points)
% fpoints = vport_to_axis(axis_h, points)
% Viewport to axis (window) mapping
%
% Given a set of points where each column is an (x,y) point in the
% coordinate system associated with a figure (the viewport), convert the
% points to the coordinate system of the specified axis that is associated
% with the figure.

% We will use a homogeneous coordinate system which appends
% a one after each vector (see any text on computer graphics
% for why we do this - bottom line is it makes affine
% transformations (scaling, rotation, translation) easy.
p = [points; ones(1, size(points, 2))];

% Get viewport extent [x, y, deltax, deltay]
extent = get(axis_h, 'Position');
% convert to [x1,x2 ; y2,y2]
VpCoord = extent_to_rectangle(extent);
% What range does the coordinate system span?
VpRange = diff(VpCoord, [], 2);  % delta x & y

% Get axis (window) rectangle
props = {'XLim', 'YLim'};
AxCoord = zeros(length(props), 2);
for idx=1:length(props)
    AxCoord(idx,:) = get(axis_h, props{idx});
end
% What range does the coordinate system span?
AxRange = diff(AxCoord, [], 2);  % delta x & y

% Build translation and scaling matrix
Op = diag(ones(3,1));
% Translate Axis Position back to origin
Op(1:2, 3) = - VpCoord(:, 1);

% Scale to the axis coordinate system 
NextOp = diag([AxRange ./ VpRange; 1]);
Op = NextOp * Op;

% Translate to axis coordinate system
NextOp = diag(ones(3,1));
NextOp(1:2, 3) = AxCoord(:,1);
Op = NextOp * Op;

ax_p = Op * p;  % transform
% Remove homogeneous space coordinate
ax_points = ax_p(1:end-1, :);


% --------------------------------------------------------------------
function rect = extent_to_rectangle(extent)
% rect = extent_to_rectangle(extent)
% Convert [x, y, width, height] to [x1 x2; y1 y2]

rect = reshape(extent, 2, 2); % [x1 width; y1 height]
rect(:,2) = rect(:,1) + rect(:,2); %[x1 x1+width; y1 y1+height]
    
% --------------------------------------------------------------------
function [time, freq, transient_posn] = ...
    getPoints(points, transient_pt, scale_Hz)
% [t, f, transient_posn] = getPoints(points, transient_pt, scale)
% Given a vector of impoints, pull out their times and frequencies.
%
% When a point is being dragged, it may occur that it has the same
% time abscissa.  In this case, we may wish to omit the data from
% that there is only one frequency value for each time.  Calling this
% function with an impoint bound to transient_pt will remove the time
% point associated with transinet_pt from the set of points if a
% duplicate time entry occurs.  Omit or set to [] if a transinet
% point does not exist.
%
% scale_Hz is an optional scale factor to scale up/down the data 
% (e.g. 1/1000 for points in kHz)
        
% get list of times and frequencies
N = length(points);
time = zeros(N,1);
freq = zeros(N,1);
for idx=1:N
    posn = getPosition(points(idx));
    time(idx) = posn(1);
    freq(idx) = posn(2);
end

transient_posn = [];
if nargin > 1 && ~ isempty(transient_pt)
    % Check to see if time(transient_pt) occurs > 1 time
    posn = getPosition(transient_pt);
    t = posn(1);
    duplicates = find(time == t);
    
    if length(duplicates) > 1
        % duplicate occurred, note the transient points position
        % in the list as some routines may wish to delete it
        transient_posn = find(points == transient_pt);
        % Remove the time frequency associated with the transient
        time(transient_posn) = [];
        freq(transient_posn) = [];
    end
end
    
if nargin > 2
    freq = freq * scale_Hz;  % set scaling appropriately
end

% sort by time
[time timeOrder] = sort(time);
freq = freq(timeOrder);

% --------------------------------------------------------------------
function TonalName = AudioFname2Tonal(AudioName)
% TonalName = AudioFname2Tonal(AudioName)
% Given the name of an audio file, suggest a tonal filename from it.
[dir, name, ext] = fileparts(AudioName);
TonalName = fullfile(dir, [name, '.ann']);


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


% --- Executes on mouse press over axes background.
function spectrogram_ButtonDownFcn(src, event)
% hObject    handle to spectrogram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(src);
breakpointSelected = get(handles.breakPointTool, 'State');
if (~strcmpi(breakpointSelected, 'on'))
    return;
end
    
cursorPoint = get(handles.spectrogram, 'CurrentPoint');
curX = cursorPoint(1,1);

data = get(handles.TrackingDebug, 'UserData');

% TODO make this range smaller
intervals = data.blkstart_s:(data.thr.advance_ms / 1000):data.blkstop_s;
dist = abs(intervals - curX);
[~, index] = min(dist);
%this is wrong;
new_point = intervals(index);
%new_point = data.tt.Indices.timeidx(index);

breakpoints = data.breakpoints;
if (isempty(breakpoints(breakpoints == new_point)))
   breakpoints = sort([breakpoints, new_point]); 
end

updateBreakpoints(handles, breakpoints);
set(handles.breakpointsList, 'value', find(breakpoints==new_point));


function updateBreakpoints(handles, breakpoints)
data = get(handles.TrackingDebug, 'UserData');
breakpointsSeconds = cell(length(breakpoints),1);
for idx=1:length(breakpoints)
    breakpointsSeconds{idx,1} = sprintf('%.4fs', breakpoints(idx));
end

set(handles.breakpointsList, 'String', breakpointsSeconds);
data.breakpoints = breakpoints;
data.debugRenderingManager.updateBreakpoints(breakpoints);
SaveDataInFigure(handles, data);
drawnow update;


% --- Executes during object creation, after setting all properties.
function breakpointsList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to breakpointsList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addBreakpoint.
function addBreakpoint_Callback(hObject, eventdata, handles)
% hObject    handle to addBreakpoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in deleteBreakpoint.
function deleteBreakpoint_Callback(hObject, eventdata, handles)
% hObject    handle to deleteBreakpoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.TrackingDebug, 'UserData');
breakpoints = data.breakpoints;
if (~isempty(breakpoints))
    selected_idx = get(handles.breakpointsList, 'Value');
    breakpoints(selected_idx) = [];
    updateBreakpoints(handles, breakpoints);
    set(handles.breakpointsList, 'value', min(selected_idx, length(breakpoints)));
end


% --------------------------------------------------------------------
function runButton_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to runButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = get(handles.TrackingDebug, 'UserData');
data.stopRequested = false;
data.pauseRequested = false;
data.debugRenderingManager.clearAll();

if (isfield(data, 'noiseBoundaries') && ...
    strcmpi(get(handles.noiseBondariesToggle, 'State'), 'on'))
    tt = TonalTracker(data.Filename, data.blkstart_s, data.blkstop_s, ...
        'SPCallback', data.debugRenderingManager, ...
        'NoiseBoundaries', data.noiseBoundaries);
else
    tt = TonalTracker(data.Filename, data.blkstart_s, data.blkstop_s, 'SPCallback', data.debugRenderingManager);
end

data.tt = tt;
tt.startBlock();
SaveDataInFigure(handles, data);

execute(handles);


% 
% Executes the main tracking loop.
function execute(handles)
data = get(handles.TrackingDebug, 'UserData');
data.debugRenderingManager.clearFits();
tt = data.tt;

set(handles.runButton,'Enable','off');
set(handles.stopButton,'Enable','on');
set(handles.stepButton,'Enable','off');
set(handles.continueToPeakButton,'Enable','off');
set(handles.resetButton,'Enable','off');
set(handles.pauseButton,'Enable','on');
set(handles.continueButton,'Enable','off');
SaveDataInFigure(handles, data);
drawnow;

peaks_only = get(handles.peaksOnlyCheckBox, 'Value');
break_on_peaks = get(handles.breakOnPeaksCheckBox, 'Value');

while (~data.stopRequested && ~data.pauseRequested)
    frame_time = tt.getCurrentFrameTime();
    data = get(handles.TrackingDebug, 'UserData');
    breakpoints = data.breakpoints;
    %if (breakpoints(breakpoints == frame_time))
    % temp hack
    bpDiffs = breakpoints - frame_time;
    bpDiffs = bpDiffs(bpDiffs > 0);
    if (~data.atBreakPoint && ~isempty(bpDiffs(bpDiffs < data.thr.advance_s)))
        data.pauseRequested = true;
        data.atBreakPoint = true;
        break;
    else
        data.atBreakPoint = false;
    end
    
    if (data.stepAction == 0)
        found = tt.selectPeaks();
        if (found)
            if (break_on_peaks || data.pauseAtNextPeak)
                data.pauseRequested = true;
                data.pauseAtNextPeak = false;
                data.stepAction = 1;
                data.debugRenderingManager.plotFits(tt);
                break;
            end
            if(~peaks_only)
                tt.pruneAndExtend();
            end
        end
    else
        % This happens when the user hit continue after being broken
        % after peak detection but before prune and extend.  This can
        % happen when stepping but also when breaking on peaks.
        if (~isempty(tt.getCurrentFramePeakFreqs()) && ~peaks_only)
            tt.pruneAndExtend();
        end
    end
    
    if (tt.hasMoreFrames())
        tt.advanceFrame();
        data.stepAction = 0;
    else
        break;
    end
    SaveDataInFigure(handles, data);
    drawnow;
end

if (~data.pauseRequested)
    set(handles.runButton,'Enable','on');
    set(handles.resetButton,'Enable','on');
    set(handles.stopButton,'Enable','off');
    set(handles.stepButton,'Enable','off');
    set(handles.continueToPeakButton,'Enable','off');
    set(handles.pauseButton,'Enable','off');
else
    set(handles.stepButton,'Enable','on');
    set(handles.pauseButton,'Enable','off');
    set(handles.continueButton,'Enable','on');
    set(handles.continueToPeakButton,'Enable','on');
    set(handles.runButton,'Enable','off');
    set(handles.resetButton,'Enable','off');
    data.pauseRequested = false;
end

SaveDataInFigure(handles, data);

% --------------------------------------------------------------------
function stopButton_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to stopButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.TrackingDebug, 'UserData');
data.stopRequested = true;
set(handles.stepButton,'Enable','off');
set(handles.stepButton,'Enable','off');
set(handles.continueToPeakButton,'Enable','off');
set(handles.stopButton,'Enable','off');
set(handles.runButton,'Enable','on');
set(handles.resetButton,'Enable','on');
set(handles.frameStartTimeField, 'String', '');
SaveDataInFigure(handles, data);
drawnow;


% --------------------------------------------------------------------
function stepButton_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to stepButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.TrackingDebug, 'UserData');
tt = data.tt;
data.debugRenderingManager.clearFits();
peaks_only = get(handles.peaksOnlyCheckBox, 'Value');
stepMode = get(handles.stepModeMenu, 'Value');
if (tt.hasMoreFrames())
    switch stepMode
        case 1
            if (data.stepAction == 0)
                tt.selectPeaks();
                if (~peaks_only)
                    data.debugRenderingManager.plotFits(tt);
                end
            else
                if (~isempty(tt.getCurrentFramePeakFreqs()))
                    tt.pruneAndExtend();
                end
                tt.advanceFrame();
            end
            
            data.stepAction = mod(data.stepAction + 1, 2);
        case 2
            tt.selectPeaks();
            if (~isempty(tt.getCurrentFramePeakFreqs()))
                tt.pruneAndExtend();
            end
            tt.advanceFrame();
    end
end
if (~tt.hasMoreFrames())
    set(handles.stepButton,'Enable','off');
end
SaveDataInFigure(handles, data);
drawnow update;


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




% --------------------------------------------------------------------
function resetButton_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to resetButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.TrackingDebug, 'UserData');
data.debugRenderingManager.clearAll();
set(handles.resetButton,'Enable','off');
set(handles.frameStartTimeField, 'String', '');
SaveDataInFigure(handles, data);
drawnow;


% --- Executes during object creation, after setting all properties.
function frameStartTimeField_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frameStartTimeField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function pauseButton_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to pauseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.TrackingDebug, 'UserData');
data.pauseRequested = true;
set(handles.stepButton,'Enable','on');
set(handles.continueToPeakButton,'Enable','on');
set(handles.stopButton,'Enable','on');
set(handles.runButton,'Enable','off');
set(handles.resetButton,'Enable','off');
set(handles.pauseButton,'Enable','off');
SaveDataInFigure(handles, data);
drawnow;


% --------------------------------------------------------------------
function continueButton_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to continueButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
execute(handles);



% --- Executes during object creation, after setting all properties.
function stepModeMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stepModeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





% --- Executes during object creation, after setting all properties.
function frameEndTimeField_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frameEndTimeField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function blockStartTimeField_CreateFcn(hObject, eventdata, handles)
% hObject    handle to blockStartTimeField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function blockEndTimeField_CreateFcn(hObject, eventdata, handles)
% hObject    handle to blockEndTimeField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when TrackingDebug is resized.
function TrackingDebug_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to TrackingDebug (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



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


% --- Executes on button press in showFitCheckBox.
function showFitCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to showFitCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showFitCheckBox
data = get(handles.TrackingDebug, 'UserData');

checked = get(handles.showFitCheckBox, 'Value');
data.debugRenderingManager.setFitPlotsEnabled(checked);
if checked
    if isfield(data, 'tt')
        data.debugRenderingManager.plotFits(data.tt);
    end
else
    data.debugRenderingManager.clearFits();
end
SaveDataInFigure(handles, data);


% --------------------------------------------------------------------
function continueToPeakButton_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to continueToPeakButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.TrackingDebug, 'UserData');
data.pauseAtNextPeak = true;
SaveDataInFigure(handles, data);
execute(handles);


% --------------------------------------------------------------------
function noiseBondariesToggle_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to noiseBondariesToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.TrackingDebug, 'UserData');
[handles, data] = spectrogram(handles, data);
SaveDataInFigure(handles, data);


% --------------------------------------------------------------------
function showNoiseBoundariesToggle_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to showNoiseBoundariesToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.TrackingDebug, 'UserData');
data = updateNoiseBoundaries(data, handles);
SaveDataInFigure(handles, data);


function [data, handles] = updateNoiseBoundaries(data, handles)
% clear anything we have rendered prsently
for idx = 1:length(data.boundary_handles)
    delete(data.boundary_handles(idx));
end
    
if strcmpi(get(handles.showNoiseBoundariesToggle, 'State'), 'on')
    data.boundary_handles = drawNoiseBoundaries(handles);
else
    data.boundary_handles = [];
end


function boundary_handles = drawNoiseBoundaries(handles)
data = get(handles.TrackingDebug, 'UserData');

blkstart_s = str2double(get(handles.Start_s, 'String'));
blkstop_s = blkstart_s + str2double(get(handles.ViewLength_s, 'String'));

blocks = dtBlocksForSegment(data.blocks, blkstart_s, blkstop_s);
defaultBlocks = dtBlocksForSegment(data.defaultBlocks, blkstart_s, blkstop_s);

boundaries = data.noiseBoundaries(data.noiseBoundaries >= blkstart_s);
boundaries = boundaries(boundaries <= blkstop_s);

lim = ylim(handles.spectrogram);
boundary_handles = [];

if strcmpi(get(handles.noiseBondariesToggle, 'State'), 'off')
    for idx = 1:size(defaultBlocks,1)
        xval = defaultBlocks(idx,1);
        h = plot(handles.spectrogram, ... 
            [xval xval], ...
            lim,...
            'g-');
        boundary_handles = [boundary_handles, h];
    end
else
    for idx = 1:size(blocks,1)
        xval = blocks(idx,1);
        h = plot(handles.spectrogram, ... 
            [xval xval], ...
            lim,...
            'c-');
        boundary_handles = [boundary_handles, h];
    end

    for idx = 1:length(boundaries)
        h = plot(handles.spectrogram, ... 
            [boundaries(idx) boundaries(idx)], ...
            lim,...
            'r-');
        boundary_handles = [boundary_handles, h];
    end
end
