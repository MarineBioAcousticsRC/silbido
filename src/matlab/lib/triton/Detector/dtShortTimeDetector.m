function dtShortTimeDetector()
% dtShortTimeDetector()
% Run short time detection.

% default window size too small for this dialog, currently specifying
% position in normalized space but we might want to do it pixels...
handles.ContainingFig = figure('Name', 'Short Time Spectrum Detection', ...
    'Toolbar', 'None', 'Units', 'normalized', 'Position', [.1 .1 .7 .7], ...
    'MenuBar', 'none', 'NumberTitle', 'off');

% Add components of dialog
handles = guComponentLoad(handles.ContainingFig, [], handles, ...
                          'guDetectionParmComponent', 'short-time-spectrum');
handles = guComponentLoad(handles.ContainingFig, [], handles, ...
    'guFileComponent');
handles = guComponentLoad(handles.ContainingFig, [], handles, ...
    'guGuidedSearchComponent', ...
    {'Long Term Spectral Avg (LTSA) detections'});
handles = guComponentLoad(handles.ContainingFig, [], handles, ...
    'guConfirmComponent');
% Add callback to permit verification when user presses okay
handles = guConfirmComponent('Verify_CallbackFcn', ...
    handles.ContainingFig, [], handles, @ProceedOkay);

handles = guComponentScale(handles.ContainingFig, [], handles);

guidata(handles.ContainingFig, handles);  % Save application data

uiwait(handles.ContainingFig);  % wait for okay/cancel

if ishandle(handles.ContainingFig)
  handles = guidata(handles.ContainingFig);     % get fresh copy of handles 
  % User did not press close box
  if ~ handles.guConfirmComponent.canceled
    [Files, BaseDir] = guFileComponent('OutputFcn', handles.ContainingFig, [], handles);
    SearchType = guGuidedSearchComponent('OutputFcn', handles.ContainingFig, ...
                                         [], handles);
    Parameters = guDetectionParmComponent('OutputFcn', handles.ContainingFig, ...
                                          [], handles); 
    delete(handles.ContainingFig);
    
    % Get labels associated with files.
    Labels = guNameToPattern(Files);
    if ~ isempty(Labels)
      dtST_batch(BaseDir, Files, Labels, SearchType, Parameters);
    end
  else
    delete(handles.ContainingFig);
  end
  
end

% Add callback to check for errors when user presses okay
function result = ProceedOkay(hObject, eventdata, handles)
% result = ProceedOkay(hObject, eventdata, handles)
% Check if all components are populated properly for detection to proceed

Problems = '';
Files = guFileComponent('OutputFcn', handles.ContainingFig, [], handles);
if isempty(Files)
  Problems = 'No files. ';
end

if isempty(Problems)
    result = '';
else
    result = sprintf('Error(s):  %s', Problems);
end

