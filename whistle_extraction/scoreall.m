function results = scoreall(detext, CorpusBase, logfile, DetectionsBase)
% results = scoreall(detext, CorpusBase)
% Given an detections extension, find all detection
% files in the current directory and compare them to the
% ground truth.

start_t = tic;

if nargin < 3
    logfile = 'score.txt';
    if nargin < 2
        system = getenv('COMPUTERNAME');  % Windows only
        switch system
            case {'CAPENSIS', 'SPINNER', 'STENELLA'}
                CorpusBase = 'c:\Users\corpora\Paris-ASA\';
            case 'IRRAWADDY'
                CorpusBase = 'd:\home\bioacoustics\Paris-ASA\';
            otherwise
                error('unknown system');
        end
    end
end

% make sure trailing file seperator on the CorpusBase
if CorpusBase(end) ~= '\' || CorpusBase(end) ~= '/'
    if (ispc)
        CorpusBase(end+1) = '\';
    else
        CorpusBase(end+1) = '/';
    end
end

% get path to detections files and their basename
[detections base] = utFindFiles({sprintf('*%s', detext)}, {DetectionsBase}, true);
relpath = cellfun(@(f) f(length(DetectionsBase)+1:end), detections, 'UniformOutput', false);

% Construct names for audio and ground truth files
audio = cellfun(@(f) fullfile(CorpusBase, strrep(f, detext, '.wav')), ...
    relpath, 'UniformOutput', false);
gt = cellfun(@(f) fullfile(CorpusBase, strrep(f, detext, '.bin')), ...
    relpath, 'UniformOutput', false);

% Verify all files exist before we start
N = length(detections);
gtI = zeros(N,1);
audioI = zeros(N,1);
for k=1:N
    audioI(k) = exist(audio{k}, 'file') > 0;
    gtI(k) = exist(gt{k}, 'file') > 0 ;
end

flameanddie = false;
if sum(audioI) ~= N 
    fprintf('Unable to find audio data for:\n');
    fprintf('%s\n', audio{~audioI});
    flameanddie = true;
end
if sum(gtI) ~= N
    fprintf('Unable to find ground truth data for:\n');
    fprintf('%s\n', gt{~gtI});
    flameanddie = true;
end

if flameanddie
    error('silbido:missing file', 'Missing audio or ground truth');
end
diary(logfile);

% Fields of result structure and how we will modify the
% detection file name to save the tonals associated with
% detections/misses, etc.
% Before the extension:
%   _a : all tonals regardless of whether or not they meet exclusion
%        criteria.
%   _s : With respect to ground truth tonals that meet the specified
%        criteria.
% Extension consists of:
%   .d or .gt : detected tonal or ground truth
%  + : correct detection or detected ground truth
%  - : false detection or missed ground truth
result_files = {
    'falsePos', [], '.d-'           % false positives
    'all', 'detections', '_a.d+'    % good detections
    'snr', 'detections', '_s.d+'
    'all', 'gt_match', '_a.gt+'     % ground truth corresponding to detection
    'all', 'gt_miss', '_a.gt-'      % missed ground truth
    'snr', 'gt_match', '_s.gt+'
    'snr', 'gt_miss', '_s.gt-'
    };

N=1;
for idx=1:length(gt) %1:length(gt)
    
    try
        % Read detection file 
        d_tonals = dtTonalsLoad(detections{idx});
    catch
        fprintf('Skipping %s, no detections\n', [base, ext]);
        continue
    end
    
    % load in ground truth for comparison
    gt_tonal = dtTonalsLoad(gt{idx});

    fprintf('\nProcessing %d/%d %s\n', idx, length(gt), audio{idx});
    result = dtPerformance(audio{idx}, d_tonals, gt_tonal, ...
        'GroundTruthCriteria', [10, .3]);
    
    % Result structure contains lists of tonals
    % If we simply concatenate it into results, we will quickly
    % run out of heap space.  
    % Instead, we write out each tonal list into a file with an
    % extension specified by results_files{:,3} and store the filename
    for k=1:size(result_files, 1)
        tfname = sprintf('%s%s', ...
            detections{idx}(1:end-length(detext)), result_files{k,end});
        if isempty(result_files{k,2})
            tonals = result.(result_files{k,1});
            % Replace list with filename to avoid running out of heap space
            result.(result_files{k,1}) = tfname;
            result.([result_files{k,1}, 'N']) = tonals.size();
        else
            tonals = result.(result_files{k,1}).(result_files{k,2});
            % Replace list with filename to avoid running out of heap space
            result.(result_files{k,1}).(result_files{k,2}) = tfname;
            result.(result_files{k,1}).([result_files{k,2}, 'N']) = tonals.size();
        end
        dtTonalsSave(tfname, tonals);
        
    end
    results(N) = result;
    N=N+1;
    
    if rem(N, 10) == 0
        fprintf('saving\n');
        save('results.mat', 'results');
    end
    fprintf('\nElapsed time since start:  %s\n', sectohhmmss(toc(start_t)));
    
end
save('results.mat', 'results');
diary off;

