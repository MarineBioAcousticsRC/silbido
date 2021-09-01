function [tonals, subgraphs] = dtTonalsTracking(Filename, Start_s, Stop_s, varargin)
% [tonals, subgraphs] = dtTonalsTracking(Filename, OptionalArgs)
% Filename - Cell array of filenames that are assumed to be consecutive
%            Example -  {'palmyra092007FS192-071011-230000.wav', 
%                        'palmyra092007FS192-071011-231000.wav'}
% Start_s - start time in s relative to the start of the first recording
% Stop_s - stop time in s relative to the start of the first recording
% Optional arguments in any order:
%   'Framing', [Advance_ms, Length_ms] - frame advance and length in ms
%       Defaults to 2 and 8 ms respectively
%   'Threshold', N_dB - Energy threshold in dB
%   'ParameterSet', Name - Set of default parameters, currently
%        supports 'odontocete' (default) and 'mysticete'
%   'Interactive', bool - Wait for a keypress before processing the next
%       frame.  Only valid when plot options are used (default false).
%   'ActiveSet_s', N - Graphs are added to the active set once they are
%       N s long.
%   'Movie', File - Capture plot to AVI movie file.  Plot must be > 0.
%       File must have .avi extension, but to play it in Powerpoint the
%       resulting file's extension must be changed to .wmv.
%   'Noise', Method
%       Method for noise compensation in spectrogram plots.
%       It is recommended that the same noise compensation as
%       used for creating the tonal set be used.  See
%       dtSpectrogramNoiseComp for valid methods.
%   'NoiseBoundaries', B - B is a vector of noise regime boundaries in 
%        seconds.  Noise is assumed to have different characteristics on
%        either side of each boundary, confounding any noise compensation 
%        techniques that assume a homogeneous noise source.  Noise 
%        estimates will not use data that crosses the boundaries.
%        Use detect_noise_changes() to produce B.
%   'RemoveTransients' true(default)|false - Remove short broadband
%       interference (e.g. echolocation clicks) in the time domain
%   'Range', [LowCutoff_Hz, HighCutoff_Hz] - low and high cutoff
%       frequency in Hz. Defaults to 5000 and 50000 Hz respectively
%   'WaitTimeRejection', [N, MeanWait_s, MaxDur_s]
%       Reject a detection as a false positive if the mean wait time
%       between N successive time X frequency peaks is > MeanWait_s
%       seconds.  Detections longer than MaxDur_s are not subject to
%       this test.
%       Empirical analysis of the detections in our October 2011 JASA
%       article suggests that [5, .034, .4] results in a 10% miss rate
%       for tonals < .4 s that would have otherwise been detected and
%       results in a lowering of the FA rate for tonals of the same
%       duration by about 60%.  
%   'FilterBank', The type of filter bank to use:
%       'linear' (default) or 'constantQ'. 'linear' provides a standard
%       linear spacing of center frequencies. 'constantQ' provides a
%       constant quality analysis with octave filter banks.
%   'PeakMethod', The type of method used to detect whistles:
%       'energy' (default) or 'DeepWhistle'. 'energy' provides annotations
%       based on engery peaks detected across frames. 'DeepWhistle' uses a  
%       pretrained neural network to identify whistles.
%       

stopwatch = tic;


% assume no returns until we learn otherwise.
graph_ret = false;
tonal_ret = false;
% Determine which lists are to be returned to the user by looking at the 
% number of output arguments. 
if nargout > 0
    tonal_ret = true;
    if nargout > 1
        graph_ret = true;
    end
end


tt = TonalTracker(Filename, Start_s, Stop_s, varargin{:});
tt.processFile();


if graph_ret
    subgraphs = tt.getGraphs();    
end

graph_s = toc(stopwatch);
stopwatch = tic;

if tonal_ret
    tonals = tt.getTonals();
    discarded_count = tt.getDiscardedCount();
end

disambiguate_s = toc(stopwatch);

% print summary
elapsed_s = graph_s + disambiguate_s;
processed_s = tt.getEndTime() - tt.getStartTime();

% lambda function s --> HH:MM:SS
to_time = @(s) datestr(datenum(0, 0, 0, 0, 0, s), 13);

fprintf('Detected %d tonals, rejected %d shorter than %f s\n', tonals.size(), discarded_count);
fprintf('Timing statistics\n');
fprintf('function\tduration\tx Realtime\n');
fprintf('graph gen\t%s\t%.2f\n', to_time(graph_s), processed_s / graph_s);
fprintf('tonal gen\t%s\t%.2f\n', to_time(disambiguate_s), processed_s / disambiguate_s);
fprintf('Overall\t\t%s\t%.2f\n', to_time(elapsed_s), processed_s / elapsed_s);
