function batchdetect(detext, CorpusBase)
% batchdetect(detext, CorpusBase)
% Run detections on a set of files in directory CorpusBase

if nargin < 1 || ~ ischar(detext)
    error('Must supply extension for detection files')
elseif detext(1) ~= '.'
        detext = ['.', detext];
end

if nargin < 2
    system = getenv('COMPUTERNAME');  % Windows only
    switch system
        case {'CAPENSIS', 'SPINNER'}
            CorpusBase = 'c:\Users\corpora\Paris-ASA\';
        case 'IRRAWADDY'
            CorpusBase = 'd:\home\bioacoustics\Paris-ASA\';
        otherwise
            error('unknown system');
    end
end

% make sure trailing file seperator on the CorpusBase
if CorpusBase(end) ~= filesep && CorpusBase(end) ~= '/'
    CorpusBase(end+1) = '\';
end

start_t = tic;

% find files for which we have ground truth
bhaveshonly = true;
if bhaveshonly
  bhavesh = bhavesh_corpus();
  audio = bhavesh.gtfiles(:,1);
  gtfiles = strrep(audio, '.wav', '.bin');
  detections = strrep(audio, '.wav', detext);
  basedir = CorpusBase;
else
  [gtfiles, gtbasename] = utFindFiles({'*.bin'}, {CorpusBase}, true);
  audio = strrep(gtfiles, '.bin', '.wav');
  detections = strrep(gtfiles, CorpusBase, '');  % strip base prefix
  detections = strrep(detections, '.bin', detext);
  basedir = '';
end

N = length(audio);
for idx=1:N
    fprintf('Processing %d/%d %s to\n\t%s\n', idx, N, audio{idx}, detections{idx});
    d = dtTonalsTracking(fullfile(basedir, audio{idx}), 0, Inf, 'Framing', [2 8], 'Noise', 'median');
    % Create subdirectory if it does not exist
    [dname, fname] = fileparts(detections{idx});
    if ~ exist(dname, 'dir')
        mkdir(dname);
    end
    dtTonalsSave(detections{idx}, d);
    
    fprintf('Elapsed time since start:  %s\n', sectohhmmss(toc(start_t)));
    
end

