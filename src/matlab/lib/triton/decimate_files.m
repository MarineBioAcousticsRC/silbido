function decimate_files
% decimate_files
% Prompt for a set of files to decimate


% Do not modify the following line, maintained by CVS
% $Id: decimate_files.m,v 1.3 2008/11/14 16:49:40 mroch Exp $

handles.ContainingFig = figure( ...
    'Name', 'Decimate files', ...
    'Toolbar', 'None', 'Units', 'normalized', ...
    'MenuBar', 'none', 'NumberTitle', 'off');
handles = guComponentLoad(handles.ContainingFig, [], handles, ...
    'guFileComponent');
% Disable LTSA selection
handles = guFileComponent('ltsaunavailable', [], [], handles);
% Add in decimation 
handles = guComponentLoad(handles.ContainingFig, [], handles, ...
    'guDecimationFactor');
% Add in file selection dialog
handles = guComponentLoad(handles.ContainingFig, [], handles, ...
    'guConfirmComponent');
handles = guComponentScale(handles.ContainingFig, [], handles);

guidata(handles.ContainingFig, handles);  % Save application data
uiwait(handles.ContainingFig);  % wait for okay/cancel

if ishandle(handles.ContainingFig)
  handles = guidata(handles.ContainingFig);     % get fresh copy of handles 
  % User did not press close box
  if ~ handles.guConfirmComponent.canceled
    [Files, BaseDir] = guFileComponent('OutputFcn', handles.ContainingFig, [], handles);
    N = guDecimationFactor('OutputFcn', handles.ContainingFig, [], handles);
    delete(handles.ContainingFig);
    decimate_selected(BaseDir, Files, N);
  else
    delete(handles.ContainingFig)
  end
end

function decimate_selected(BaseDir, Files, DecFactor)

tic;
FilesN= length(Files);
ProgressH = waitbar(0, 'Processing - Matlab will be unresponsive', ...
                    'Name', 'Decimate files');

SamplesPerBlock = 15e6;   % Chosen based upon HARP raw file size

for k = 1:FilesN
  ProgressTitle = ...
      sprintf('Processing %d of %d - Matlab will be unresponsive', ...
              k, FilesN);
  waitbar((k-1)/FilesN, ProgressH, ProgressTitle);
  drawnow expose;     % redraw, but don't allow processing of new events
  
  [fpath, fname, fext] = fileparts(Files{k});
  % Handle multiple dot extensions:  .x.wav
  [dfpath, fname2, fext2] = fileparts(fname);
  while ~ strcmp(fname, fname2)
    fext = [fext2, fext];
    fname = fname2;
    [dfpath, fname2, fext2] = fileparts(fname);
  end
  infile = fullfile(BaseDir, Files{k});
  outfile = fullfile(BaseDir, ...
                     fullfile(fpath, ...
                              sprintf('%s-d%d%s', fname, DecFactor, fext)));
  switch fext
   case '.x.wav' % --------------- decimate xwav file --------------------
    % to do
    disp_mesg(sprintf('decimate_files: skipping x-wav %s', Files{k}));
   case '.wav'   % --------------- decimate wav file ---------------------
    hdr = ioReadWavHeader(infile);
    FS = hdr.fs;
    Samples = hdr.Chunks{hdr.dataChunk}.nSamples;
    Channels = hdr.nch;
    BitsPerSamp = hdr.nBits;

    NewRate = FS / DecFactor;
    if rem(FS, DecFactor)
      disp_msg(sprintf(...
          'decimate_files: skipping %s - %d/%d is non-integer', ...
          Files{k}, FS, DecFactor));
      continue
    end
    SamplesToRead = floor(SamplesPerBlock / Channels);
    PartsN = ceil(Samples / SamplesToRead);
    Stop = min(SamplesToRead, Samples);

    InH = ioOpenWav(infile);
    OutH = ioWavWrite(zeros(0,Channels), NewRate, BitsPerSamp, outfile);
    for p = 1:PartsN
      ProgressTitle = ...
          sprintf('Processing %d of %d (segment %d/%d) - Matlab will be unresponsive', ...
                  k, FilesN, p, PartsN);
      waitbar((k-1)/FilesN, ProgressH, ProgressTitle);
      drawnow expose;     % redraw, but don't allow processing of new events
      
      Start = (p-1)*SamplesToRead + 1;
      Stop = min(Start + SamplesToRead - 1, Samples);
      indata = ioReadWav(InH, hdr, Start, Stop);
      outdata = [];
      % process one channel at a time
      for c=1:Channels
        outch = decimate(indata(:,c), DecFactor);
        if isempty(outdata);
          outdata = zeros(length(outch), Channels);
        end
        outdata(:,c) = outch';
      end
      OutH = ioWavWrite(outdata, OutH);
    end
    ioWavWrite([], OutH);   % close up file
    fprintf('elapsed time:  %s\n', sectohhmmss(toc));
   otherwise  % --------------- unknown audio type --------------------
    disp_msg(sprintf('decimate_files: %s - unknown file type', Files{k}));
  end
end
delete(ProgressH);
disp_msg(sprintf('Decimation by 1/%d complete (%d files, %s)', ...
                 DecFactor, FilesN, sectohhmmss(toc)));

