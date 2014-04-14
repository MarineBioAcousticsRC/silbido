function dtST_GuidedHiResDetector()
% dtST_GuidedHiResDetector()
% Run short time guided high resolution click detection.

global PARAMS


[BaseDir, Files, TimeRE] = getFiles;

if isempty(Files)
  return
else
  % Convert into full path (will want to do something else later on
  % so that we don't have hardcoded paths)
  for idx=1:length(Files)
    Files{idx} = fullfile(BaseDir, Files{idx});
  end
end

% default window size too small for this dialog, currently specifying
% position in normalized space but we might want to do it pixels...
handles.ContainingFig = figure( ...
    'Name', 'Short Time Guided High Resolution Click Detection', ...
    'Toolbar', 'None', 'Units', 'normalized', 'Position', [.1 .1 .7 .7], ...
    'MenuBar', 'none', 'NumberTitle', 'off');

% Add components of dialog
handles = guComponentLoad(handles.ContainingFig, [], handles, ...
    'guLabelsComponent');
handles = guComponentLoad(handles.ContainingFig, [], handles, ...
    'guFeatureExtractionComponent');

handles = guComponentLoad(handles.ContainingFig, [], handles, ...
    'guConfirmComponent');
handles = guConfirmComponent('Verify_CallbackFcn', ...
    handles.ContainingFig, [], handles, @LabelsOkay);
handles = guComponentScale(handles.ContainingFig, [], handles);

guidata(handles.ContainingFig, handles);  % Save application data

uiwait(handles.ContainingFig);  % wait for okay/cancel

if ishandle(handles.ContainingFig)
  handles = guidata(handles.ContainingFig);     % get fresh copy of handles 
  % User did not press close box
  if ~ handles.guConfirmComponent.canceled
    FeatParams = guFeatureExtractionComponent('OutputFcn', handles.ContainingFig, ...
        [], handles);
    LabelParams = guLabelsComponent('OutputFcn', handles.ContainingFig, ...
        [], handles); 
    delete(handles.ContainingFig);
    
    [filetype ext] = ioGetFileType(Files);

    % Build click label filenames
    labels = cell(size(Files));
    for idx=1:length(Files);
        labels{idx} = strrep(Files{idx}, ext{idx}, '.c');
    end

    % Look for specific type...
    OptArgs = {};
    if ~ isempty(LabelParams.filter)
      OptArgs{end+1} = 'LabelFilter';
      OptArgs{end+1} = LabelParams.filter;
    end
    if isfield(FeatParams, 'maxsep_s')
      OptArgs{end+1} = 'MaxSep_s';
      OptArgs{end+1} = FeatParams.maxsep_s;
    end
    if isfield(FeatParams, 'maxlen_s')
      OptArgs{end+1} = 'MaxClickGroup_s';
      OptArgs{end+1} = FeatParams.maxlen_s;
    end
    if isfield(FeatParams, 'meanssub')
      OptArgs{end+1} = 'MeansSub';
      OptArgs{end+1} = FeatParams.meanssub;
    end
    if isfield(FeatParams, 'FrameLength_us')
      OptArgs{end+1} = 'FrameLength_us';
      OptArgs{end+1} = FeatParams.FrameLength_us;
    end
    if isfield(FeatParams, 'FrameAdvance_us')
      OptArgs{end+1} = 'FrameAdvance_us';
      OptArgs{end+1} = FeatParams.FrameAdvance_us;
    end
    if isfield(FeatParams, 'MaxFramesPerClick')
        OptArgs{end+1} = 'MaxFramesPerClick';
        OptArgs{end+1} = FeatParams.MaxFramesPerClick;
    end
    if isfield(FeatParams, 'Narrowband')
        OptArgs{end+1} = 'FilterNarrowband';
        OptArgs{end+1} = FeatParams.Narrowband;
    end
    debug = false;
    if debug
      OptArgs{end+1} = 'Plot';
      OptArgs{end+1} = 2;       % 1 clicks only, 2 clicks+Teager
    end

    FeatureType = FeatParams.FeatureType;
    
    % Get name without extension so we can generate others
    [dir, fname, ext] = fileparts(LabelParams.script);
    BaseName = fullfile(dir, fname);
    
    dtHighResClickBatch(Files, labels, sprintf('%s.mlf', BaseName), ...
                        LabelParams.script, ...
                        'LabelTranslation', {LabelParams.re_pat, LabelParams.re_replace}, ... 
                        'DateRegexp', TimeRE, ...
                        'FeatureExt', FeatureType, ...
                        'FeatureId', FeatParams.FeatureID, ...
                        'TritonLabelFile', sprintf('%s.tlab', BaseName), ...
                        'ClickAnnotExt', 'cTg', ...
                        'GroupAnnotExt', 'gTg', ...
                        'HTKConfigFile', sprintf('%s.cfg', BaseName), ...
                        OptArgs{:});
            
  else
    delete(handles.ContainingFig);
  end
  
end

% ----------------------------------------------------------------------
function [BaseDir, Files, TimeRE] = getFiles()

handles.ContainingFig = figure( ...
    'Name', 'Short Time Guided High Resolution Click Detection', ...
    'Toolbar', 'None', 'Units', 'normalized', 'MenuBar', 'None', ...
    'NumberTitle', 'off');
handles = guComponentLoad(handles.ContainingFig, [], handles, ...
    'guFileComponent');
% Register callback to extract timestamps from file list
handles = guComponentLoad(handles.ContainingFig, [], handles, 'guTimeEncoding');
set(handles.guFileComponent.specify_files_dir, 'String', pwd);
handles = guFileComponent('FileChangeCallback', handles, @guParseTimestamps);
% Register callback to change time encodings when user
% changes regexp
handles = guTimeEncoding('RegexpChangeCallback', handles, @guParseTimestamps);
handles = guComponentLoad(handles.ContainingFig, [], handles, ...
    'guConfirmComponent');
handles = guComponentScale(handles.ContainingFig, [], handles);
handles = guConfirmComponent('Verify_CallbackFcn', ...
    handles.ContainingFig, [], handles, @FilesOkay);

guidata(handles.ContainingFig, handles);  % Save application data
uiwait(handles.ContainingFig);  % wait for okay/cancel

BaseDir = [];
Files = [];
TimeRE = [];
if ishandle(handles.ContainingFig)
  handles = guidata(handles.ContainingFig);     % get fresh copy of handles 
  % User did not press close box
  if ~ handles.guConfirmComponent.canceled
    [Files, BaseDir] = guFileComponent('OutputFcn', ...
            handles.ContainingFig, [], handles);
    TimeRE = guTimeEncoding('OutputFcn', ...
            handles.guTimeEncoding.timeenc_panel, [], handles);
  end
  delete(handles.ContainingFig);
end


% ----------------------------------------------------------------------
% callbacks to check for errors when user presses okay

function result = FilesOkay(hObject, eventdata, handles)
% result = FilesOkay(hObject, eventdata, handles)
% Check if user has specified files.
[Files, BaseDir] = guFileComponent('OutputFcn', ...
    handles.ContainingFig, [], handles);
if isempty(Files)
    result = 'Specify files';
else
    result = [];
end

function result = LabelsOkay(hObject, eventdata, handles)
% result = ProceedOkay(hObject, eventdata, handles)
% Check if all components are populated properly for detection to proceed

LabelParams = guLabelsComponent('OutputFcn', handles.ContainingFig, ...
    [], handles);
    
errors = {};
if isempty(LabelParams.script)
    errors{end+1} = 'script';
end

if length(errors)
    errstr = errors{1};
    if length(errors) > 1
        errstr = [errstr, sprintf(', %s', errors{2:end})];
    end
    result = sprintf('Specify valid %s', errstr);
else
    result = '';
end

