function [tonals, subgraphs] = dtTonalsTracking2(Filename, Start_s, Stop_s, varargin)
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

stopwatch = tic;

% Java classes we will be needing
% Note that the Java calls have side effects to their arguments
import java.util.LinkedList;
import java.util.TreeSet;
import tonals.*;

% stuff for debugging
debug = false;
ActiveSet.setDebugging(debug);



% Settable Thresholds --------------------------------------------------
thr.whistle_dB = 10;       % SNR criterion for whistles
thr.click_dB = 10;         % SNR criterion for clicks (part of click skipping decision)

% Whistles whose duration is shorter than threshold will be discarded.
thr.minlen_ms = 150;

% Maximum gap in energy to bridge when looking for a tonal
thr.maxgap_ms = 50;

% Maximum difference in frequency to bridge when looking for a tonal
thr.maxslope_Hz_per_ms = 1000;

% define frequency range over which we search for tonals
thr.high_cutoff_Hz = 50000;
thr.low_cutoff_Hz = 5000;

thr.activeset_s = .050; % peaks with earliest time > thr.activeset_s will be
                        % part of active_set otherwise part of orphan set

thr.slope_s = .008;    % Possible predecessor that is thr.slope_s seconds
                       % behind the current peak (Slope)

thr.phase_s = .008;    % Possible predecessor that is thr.phase_s seconds
                       % behind the current peak (Phase)
                       
% Frames containing broadband signals will be ignored.
% If more than broadand% of the bins exceed the threshold,
% we consider the frame a click.  
%thr.broadband = .20;
thr.broadband = .01;

% When extracting tonals from a subgraph, use up to thr.disambiguate_s
% when computing the local polynomial fit.
thr.disambiguate_s = .3;  
thr.advance_ms = 2;
thr.length_ms = 8;
thr.blocklen_s = 3;

% Other defaults ------------------------------------------------------
NoiseSub = 'median';          % what type of noise compensation

k = 1;
while k <= length(varargin)
    switch varargin{k}
        case 'Framing'
            if length(varargin{k+1}) ~= 2
                error('Silbido:Framing', ...
                    '%s must be [Advance_ms, Length_ms]', varargin{k});
            else
                thr.advance_ms = varargin{k+1}(1);
                thr.length_ms = varargin{k+1}(2);
            end
            k=k+2;
        case 'Threshold'
            thr.whistle_dB = varargin{k+1}; k=k+2;
        case 'ParameterSet'
            k=k+2;  % already handled
        case 'ActiveSet_s'
            thr.activeset_s = varargin{k+1}; k=k+2;
        case 'Noise'
            NoiseSub = varargin{k+1}; k=k+2;
            if ~ iscell(NoiseSub)
                NoiseSub = {NoiseSub};
            end
        case 'Range'
            if length(varargin{k+1}) ~= 2 || diff(varargin{k+1}) <= 0
                error('Silbido:DetectorRange', ...
                    '%s must be [LowCutoff_Hz, HighCutoff_Hz]', ...
                    varargin{k});
            else
                thr.low_cutoff_Hz = varargin{k+1}(1);
                thr.high_cutoff_Hz = varargin{k+1}(2);
            end
            k=k+2;
        case 'RemoveTransients'
            RemoveTransients = varargin{k+1}; k=k+2;
            if RemoveTransients ~= false && RemoveTransients ~= true
                error('RemoveTransients must be true or false');
            end
        otherwise
            try
                if isnumeric(varargin{k})
                    errstr = sprintf('Bad option %f', varargin{k});
                else
                    errstr = sprintf('Bad option %s', char(varargin{k}));
                end
            catch e
                errstr = sprintf('Bad option in %d''optional argument: %s', k, e.message);
            end
            error('Silbido:Arguments', 'Detector:%s', errstr);
    end
end


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

% Derived Thresholds --------------------------------------------------
thr.minlen_s = thr.minlen_ms / 1000;
thr.minlen_frames = thr.minlen_ms / thr.advance_ms;                                         
thr.maxgap_s = thr.maxgap_ms / 1000;
thr.maxgap_frames = round(thr.maxgap_ms / thr.advance_ms);
% New peak is added to the existing peak in the orphan set if the gap
% between them is less then thr.maxspace_s. Or else new peak is added to 
% the orphan set.
thr.maxspace_s = 2 * (thr.advance_ms / 1000);

resolutionHz = (1000 / thr.length_ms);
% Sets for managing search --------------------------------------------

% active_set - When looking examining peak energies from the current
% time frame, these nodes are candidates to be connected the current peaks
active_set = ActiveSet();

% Start processing ----------------------------------------------------

block_len_s = thr.blocklen_s;  % amount of data considered in each block


% Get header information of the file and then open file as little endian
header = ioReadWavHeader(Filename);
handle = fopen(Filename, 'rb', 'l');
file_end_s = header.Chunks{header.dataChunk}.nSamples/header.fs;
Stop_s = min(Stop_s, file_end_s);
if (Start_s >= Stop_s)
    error('Stop_s should be greater then Start');
end


% Select channel as Triton would
channel = channelmap(header, Filename);

% Frame length and advance in samples
Length_s = thr.length_ms / 1000;
Length_samples = round(header.fs * Length_s);
Advance_s = thr.advance_ms / 1000;
Advance_samples = round(header.fs * Advance_s);
Nyquist_bin = floor(Length_samples/2);

bin_Hz = header.fs / Length_samples;    % Hz covered by each freq bin
active_set.setResolutionHz(bin_Hz);

thr.high_cutoff_bins = min(ceil(thr.high_cutoff_Hz/bin_Hz)+1, Nyquist_bin);
thr.low_cutoff_bins = ceil(thr.low_cutoff_Hz / bin_Hz)+1;
% After discretization, the low frequency cutoff may be different than
% what the user specified.  Save the revised frequency
OffsetHz = (thr.low_cutoff_bins - 1) * bin_Hz;

% save indices of freq bins that will be processed
range_bins = thr.low_cutoff_bins:thr.high_cutoff_bins; 
range_binsN = length(range_bins);  % # freq bin count

% To compute the phase derivative, we should shift by a small
% number of samples and take the first difference
% We want the time difference to be small enough that at the highest
% frequency of interest, we will not move an entire cycle. 
% Oversampling should help us here.
shift_samples = floor(header.fs / thr.high_cutoff_Hz);
shift_samples_s = shift_samples / header.fs; 

block_pad_s = 1 / thr.high_cutoff_Hz;
block_padded_s = block_len_s + 2 * block_pad_s;
Stop_s = Stop_s - block_pad_s;

if Start_s - block_pad_s >= 0
    Start_s = Start_s - block_pad_s;
end


% Keep track of how many peaks were detected in the previous frame
% that was processed.  If the number of peaks suddenly rise by
% thr.broadband% of the bandwidth range, we are probably in a click.
% Start w/ heuristic value well beneath the number of bins required
% to indicate broadband noise.
peakN_last_processed = range_binsN * 0.25;  

StartBlock_s = Start_s;

fprintf('File length %.5f\n', file_end_s);
fprintf('Processing file from %.5f to %.5f\n', Start_s, Stop_s);

% Seem to be having problem getting to stop time due to
% incomplete frames.  For now kludge in a little padding
% to stop just before stop time.  Bhavesh, please fix.
%
% We will also need to take into account the amount of extra
% time needed for determining the phase.
while StartBlock_s + 2 * Length_s < Stop_s

    % Retrieve the data for this block
    StopBlock_s = min(StartBlock_s + block_padded_s, Stop_s);
    fprintf('Processing block from %.5f to %.5f\n', StartBlock_s, StopBlock_s);
    
    Signal = ioReadWav(handle, header, StartBlock_s, StopBlock_s, ...
        'Units', 's', 'Channels', channel);
    
    % Perform spectral analysis on block
    [~, snr_power_dB, Indices, ~, ~] = dtSpecAnal(Signal, header.fs, ...
        Length_samples, Advance_samples, shift_samples, ...
        range_bins, thr.broadband * range_binsN, ...
        thr.click_dB, NoiseSub);
   
    % relative to file rather than blockclear
    Indices.timeidx = Indices.timeidx + StartBlock_s;
   
   
    for frame_idx = 1:size(snr_power_dB, 2)              
       
       % determine current time
       % could be computed only when we know that we have something
       % (inside the if block below, but this makes it easy to set
       % break points for specific times
       current_s = Indices.timeidx(frame_idx);
       
       
       % no smoothing for now, but pretend anyway
       smoothed_dB = snr_power_dB(:, frame_idx);
       % Generate list of peaks
       % peak selector still has some issues, but good enough for now
       peak = spPeakSelector(smoothed_dB, 'Method', 'simple');

       % Remove peaks that don't meet SNR criterion
       peak(smoothed_dB(peak) < thr.whistle_dB) = [];  
       
       peak = consolidate_peaks(peak, smoothed_dB, 2);
       
       peakN = length(peak);
       if ~ isempty(peak)
           % found something
           
           % If the number of peaks has increased dramatically between
           % the last frame we processed, assume that we have a broadband
           % signal (click) and skip this frame.
           increase = (peakN - peakN_last_processed) / range_binsN;
           if increase > thr.broadband
               continue
           end
           
           peakN_last_processed = peakN;
           
           peaks = peak;
           ridge_supported_peaks_f = zeros(1,length(peaks));
    
           % Convert the peak location to frequencies.
           peak_freq = (peaks - 1)* bin_Hz + OffsetHz;
           
           % examine active list and see if anything needs to be removed
           % or moved to the list of whistles
           active_set.prune(current_s, thr.minlen_s, thr.maxgap_s);
           
           % Create TreeSet of time-frequency nodes for peaks
           peak_list = tfTreeSet(current_s(ones(size(peaks))), ...
               peak_freq, smoothed_dB(peaks), zeros(size(peaks)), ridge_supported_peaks_f);
           
           % Link anything possible from the current active set to the
           % new peaks then add them to the active set.            
           active_set.extend(peak_list, thr.maxslope_Hz_per_ms, thr.activeset_s); 
       end
    end % end for frame_idx
    StartBlock_s = Indices.timeidx(end) + Advance_s - shift_samples_s;  % Set time for next block
end  % for block_idx

% Clean up, process any remaining partial tonals by faking a time in the 
% future.
active_set.prune(current_s + 2*thr.maxgap_s,thr.minlen_s, thr.maxgap_s);

if graph_ret
    subgraphs = active_set.getResultGraphs();    
end

graph_s = toc(stopwatch);
stopwatch = tic;

tonals = java.util.LinkedList(); % Detected tonals
discarded_count = 0;
it = active_set.getResultGraphs().iterator();
while it.hasNext()
    subgraph = it.next();

    % NOTE: Last 2 flag argument for disambiguate java
    %       method can't both be true (Experimental stage)
    % false, true - polynomial fit of first difference of
    %               phase to frequency
    % true, false - vector strength
    % false, false - polynomial fit of frequency to time
    g = subgraph.disambiguate(thr.disambiguate_s, resolutionHz,...
        false, 0);
    % Obtain the edges
    edges = g.topological_sort();
    % Loop through each edge
    segIt = edges.iterator();
    while segIt.hasNext()
        edge = segIt.next();
        tone = edge.content;
        if tone.get_duration() > thr.minlen_s
            if tonal_ret
                tonals.addLast(tone);
            end
        else
            discarded_count = discarded_count + 1;
        end
    end
end


disambiguate_s = toc(stopwatch);

% print summary
elapsed_s = graph_s + disambiguate_s;
processed_s = Stop_s - Start_s;

% lambda function s --> HH:MM:SS
to_time = @(s) datestr(datenum(0, 0, 0, 0, 0, s), 13);

fprintf('Detected %d tonals, rejected %d shorter than %f s\n', tonals.size(), discarded_count);
fprintf('Timing statistics\n');
fprintf('function\tduration\tx Realtime\n');
fprintf('graph gen\t%s\t%.2f\n', to_time(graph_s), processed_s / graph_s);
fprintf('tonal gen\t%s\t%.2f\n', to_time(disambiguate_s), processed_s / disambiguate_s);
fprintf('Overall\t\t%s\t%.2f\n', to_time(elapsed_s), processed_s / elapsed_s);
