function varargout = TrackingDebugUI(varargin)
% TrackingDebugUI(AudioFilename, OptionalArguments)
% Whistle/Tonal annotation tool

% Note:
% This function requires TrackingDebugUI.fig to be present and uses
% callbacks extensively.
% See also: GUIDE, GUIDATA, GUIHANDLES

% Last Modified by GUIDE v2.5 28-Nov-2013 08:59:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TrackingDebugUI_OpeningFcn, ...
                   'gui_OutputFcn',  @TrackingDebugUI_OutputFcn, ...
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

% --- Executes just before TrackingDebugUI is made visible.
function handles = TrackingDebugUI_OpeningFcn(hObject, eventdata, handles, ...
    varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TrackingDebugUI 
%            See file header for list

% Verify correct number of inputs
%error(nargchk(4,Inf,nargin));
% Choose default command line output for TrackingDebugUI
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

Filename = varargin{1};


if isempty(Filename)
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


data.operation = [];

data.FigureTitle = '';

data.ms_per_s = 1000;
data.thr.advance_s = data.thr.advance_ms / data.ms_per_s;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Variables
%
data.low_disp_Hz = data.thr.low_cutoff_Hz;
set(handles.Low, 'String', num2str(data.low_disp_Hz));
data.high_disp_Hz = data.thr.high_cutoff_Hz;
set(handles.High, 'String', num2str(data.high_disp_Hz));



% Vectors for undo operation
data.undo = struct('before', {}, 'after', {});
handles.colorbar = [];
handles.image = [];

set(handles.Annotation, 'Name', sprintf('%s%s Annotation [%s]', ...
    data.FigureTitle, fname, fdir));

% I've observed some problems that may be due to a race condition.
% Try setting children's busyaction to cancel
children = setdiff(findobj(handles.Annotation, 'BusyAction', 'queue'), ...
    handles.Annotation);
set(children, 'BusyAction', 'cancel')

data.breakpoints = [];

data.debugRenderingManager = DebugRenderingManager(handles, data.thr);
data.stopRequested = false;
data.pauseRequested = false;
hold(handles.progressAxes, 'on');
SaveDataInFigure(handles, data);  % save user/figure data before plot
[handles, data] = spectrogram(handles, data);
SaveDataInFigure(handles, data);

                    
% --- Outputs from this function are returned to the command line.
function varargout = TrackingDebugUI_OutputFcn(hObject, eventdata, handles) 
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
data = get(handles.Annotation, 'UserData');
if isnan(high)
    report(hObject, handles, 'Invalid high range');
    set(hObject, 'String', str2double(data.high_disp_Hz));
elseif high < data.low_disp_Hz
    report(hObject, handles, 'Display limits:  low > high ');
    set(hObject, 'String', str2double(data.high_disp_Hz));
else    
    data.high_disp_Hz = high;
    set(handles.Annotation, 'UserData', data);
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
data = get(handles.Annotation, 'UserData');
if isnan(low)
    report(hObject, handles, 'Invalid low range');
    set(hObject, 'String', str2double(data.low_disp_Hz));
elseif low >= data.high_disp_Hz
    report(hObject, handles, 'Display limits:  low > high ');
    set(hObject, 'String', str2double(data.low_disp_Hz));
else    
    data.low_disp_Hz = low;
    set(handles.Annotation, 'UserData', data);
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
    data = get(handles.Annotation, 'UserData');
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
data = get(handles.Annotation, 'UserData');
% See what we are currently starting at
if data.Start_s ~= 0
    data.Start_s = 0;
    set(handles.Annotation, 'UserData', data);
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

data = get(handles.Annotation, 'UserData');
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
data = get(handles.Annotation, 'UserData');
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
data = get(handles.Annotation, 'UserData');
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
guidata(handles.Annotation, handles);

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
guidata(handles.Annotation, handles);

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
data = get(handles.Annotation, 'UserData');
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

1;


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
data = get(handles.Annotation, 'UserData');

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
data = get(handles.Annotation, 'UserData');

% wait pointer
pointer = get(handles.Annotation, 'Pointer');
set(handles.Annotation, 'Pointer', 'watch');

% Remove any plotted ones
drawnow update expose;

callback = DebugTrackingCallback(handles, data.thr);
start_s = str2double(get(handles.Start_s, 'String'));
end_s = start_s + str2double(get(handles.ViewLength_s, 'String'));

data.annotations = ...
    dtTonalsTracking(data.Filename, start_s, end_s, 'ParameterSet', data.thr, 'SPCallback', callback);
set(handles.Annotation, 'UserData', data);


SaveDataInFigure(handles, data);

% Restore pointer
set(handles.Annotation, 'Pointer', pointer);

function Annotation_KeyPressFcn(hObject, eventdata, handles)


function detect_process_block(handles, spectrogram, start_s, end_s)
    fprintf('adfasdf');


% --------------------------------------------------------------------
function tools_Callback(hObject, eventdata, handles)
% hObject    handle to tools (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function copyClipboard_Callback(hObject, eventdata, handles)
% hObject    handle to copyClipboard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Annotations_Callback(hObject, eventdata, handles)
% hObject    handle to Annotations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function audioFilenameToClipboard_Callback(hObject, eventdata, handles)
% hObject    handle to audioFilenameToClipboard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = get(handles.Annotation, 'UserData');
clipboard('copy', data.Filename);


% --------------------------------------------------------------------
function annotationFilenameToClipboard_Callback(hObject, eventdata, handles)
% hObject    handle to annotationFilenameToClipboard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = get(handles.Annotation, 'UserData');
clipboard('copy', data.AnnotationFile);




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
% Plot spectrogram and add annotations

% wait pointer
pointer = get(handles.Annotation, 'Pointer');
set(handles.Annotation, 'Pointer', 'watch');
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
[axisH, handles.image, handles.colorbar, snr_dB] = ...
        dtPlotSpecgram(data.Filename, blkstart_s, blkstop_s, ...
        'Contrast_Pct', contrast, 'Brightness_dB', brightness, ...
        'Axis', spH, ...
        'Framing', [data.thr.advance_ms, data.thr.length_ms], ...
        'Noise', data.NoiseMethod, ...
        'ParameterSet', data.thr, ...
        'RemoveTransients', data.RemoveTransients, ...
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

set(handles.image, 'buttondownfcn', @spectrogram_ButtonDownFcn);

set(handles.Annotation, 'Pointer', pointer);

spectrogramPos = get(axisH, 'Position');
get(handles.progressAxes, 'Position');
progressPos = get(handles.progressAxes, 'Position');
progressPos(3) = spectrogramPos(3);
set(handles.progressAxes, 'Position', progressPos);
set(handles.progressAxes, 'xlim', get(handles.spectrogram, 'xlim'));



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

guidata(handles.Annotation, handles);
set(handles.Annotation, 'UserData', data);


% --------------------------------------------------------------------
function quit_Callback(hObject, eventdata, handles)
% hObject    handle to quit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close();


% --- Executes on mouse press over axes background.
function spectrogram_ButtonDownFcn(src, event)
% hObject    handle to spectrogram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(src);
cursorPoint = get(handles.spectrogram, 'CurrentPoint');
curX = cursorPoint(1,1);

data = get(handles.Annotation, 'UserData');

% TODO make this range smaller
intervals = data.blkstart_s:(data.thr.advance_ms / 1000):data.blkstop_s;
dist = abs(intervals - curX);
[~, index] = min(dist);
new_point = intervals(index);

breakpoints = data.breakpoints;
if (isempty(breakpoints(breakpoints == new_point)))
   breakpoints = sort([breakpoints, new_point]); 
end

breakpointsSeconds = cell(size(breakpoints));
for idx=1:length(breakpoints)
    breakpointsSeconds{idx} = sprintf('%.4fs', breakpoints(idx));
end

set(handles.breakpointsList, 'String', breakpointsSeconds);

data.breakpoints = breakpoints;
SaveDataInFigure(handles, data);


% --- Executes on selection change in breakpointsList.
function breakpointsList_Callback(hObject, eventdata, handles)
% hObject    handle to breakpointsList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns breakpointsList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from breakpointsList


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


% --------------------------------------------------------------------
function detectButton_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to detectButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = get(handles.Annotation, 'UserData');
data.stopRequested = false;
data.pauseRequested = false;
data.debugRenderingManager.clearAll();
tt = TonalTracker(data.Filename, data.blkstart_s, data.blkstop_s, 'SPCallback', data.debugRenderingManager);
data.tt = tt;
tt.startBlock();
SaveDataInFigure(handles, data);

execute(handles);


function execute(handles)
data = get(handles.Annotation, 'UserData');
tt = data.tt;

set(handles.detectButton,'Enable','off');
set(handles.stopButton,'Enable','on');
set(handles.stepButton,'Enable','off');
set(handles.resetButton,'Enable','off');
set(handles.pauseButton,'Enable','on');
set(handles.continueButton,'Enable','off');
SaveDataInFigure(handles, data);
drawnow;

peaks_only = get(handles.peaksOnlyCheckBox, 'Value');

while (~data.stopRequested && ~data.pauseRequested)
    frame_time = tt.getCurrentFrameTime();
    data = get(handles.Annotation, 'UserData');
    breakpoints = data.breakpoints;
    if (breakpoints(breakpoints == frame_time))
        data.pauseRequested = true;
        break;
    end
    
    found = tt.selectPeaks();
    if (found && ~peaks_only)
        tt.pruneAndExtend();
    end
    
    if (tt.hasMoreFrames())
        tt.advanceFrame();
    else
        break;
    end
    drawnow;
end

if (~data.pauseRequested)
    set(handles.detectButton,'Enable','on');
    set(handles.resetButton,'Enable','on');
    set(handles.stopButton,'Enable','off');
    set(handles.stepButton,'Enable','off');
    set(handles.pauseButton,'Enable','off');
else
    set(handles.stepButton,'Enable','on');
    set(handles.pauseButton,'Enable','off');
    set(handles.continueButton,'Enable','on');
    set(handles.detectButton,'Enable','off');
    set(handles.resetButton,'Enable','off');
    data.pauseRequested = false;
end

SaveDataInFigure(handles, data);

% --------------------------------------------------------------------
function stopButton_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to stopButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.Annotation, 'UserData');
data.stopRequested = true;
set(handles.stepButton,'Enable','off');
set(handles.stopButton,'Enable','off');
set(handles.detectButton,'Enable','on');
set(handles.resetButton,'Enable','on');
set(handles.timeField, 'String', '');
SaveDataInFigure(handles, data);
drawnow;


% --------------------------------------------------------------------
function stepButton_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to stepButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.Annotation, 'UserData');
tt = data.tt;
peaks_only = get(handles.peaksOnlyCheckBox, 'Value');
if (tt.hasNextStep())
    tt.step(peaks_only);
end
if (~tt.hasNextStep())
    set(handles.stepButton,'Enable','off');
end
SaveDataInFigure(handles, data);
drawnow update;


% --- Executes on button press in peaksOnlyCheckBox.
function peaksOnlyCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to peaksOnlyCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of peaksOnlyCheckBox


% --- Executes on selection change in noiseCompMenu.
function noiseCompMenu_Callback(hObject, eventdata, handles)
% hObject    handle to noiseCompMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns noiseCompMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from noiseCompMenu

data = get(handles.Annotation, 'UserData');
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
data = get(handles.Annotation, 'UserData');
data.debugRenderingManager.clearAll();
set(handles.resetButton,'Enable','off');
set(handles.timeField, 'String', '');
SaveDataInFigure(handles, data);
drawnow;



function timeField_Callback(hObject, eventdata, handles)
% hObject    handle to timeField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timeField as text
%        str2double(get(hObject,'String')) returns contents of timeField as a double


% --- Executes during object creation, after setting all properties.
function timeField_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeField (see GCBO)
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
data = get(handles.Annotation, 'UserData');
data.pauseRequested = true;
set(handles.stepButton,'Enable','on');
set(handles.stopButton,'Enable','on');
set(handles.detectButton,'Enable','off');
set(handles.resetButton,'Enable','off');
set(handles.pauseButton,'Enable','off');
SaveDataInFigure(handles, data);
drawnow;


% --- Executes on button press in breakOnPeaksCheckBox.
function breakOnPeaksCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to breakOnPeaksCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of breakOnPeaksCheckBox


% --------------------------------------------------------------------
function continueButton_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to continueButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
execute(handles);
