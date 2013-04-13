function [tonals, subgraphs] = dtTonalsTracking(Filenames, Start_s, Stop_s, varargin)
% [tonals, subgraphs] = dtTonalsTracking(Filenames, OptionalArgs)
% Filenames - Cell array of filenames that are assumed to be consecutive
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
%   'Plot', N - Shows formation of tonals interactively
%       0 - No plot (default)
%       1 - Show peaks '^' and active set '*'
%       2 - Also show graphs as they are formed.  Graphs that are still
%           active are plotted with :, those that are closed with -.
%       3 - Add information about orphans and their subgraphs (slower)
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
%   The following options are currently depreccated and should not be used:
%   'TonalFile', File - Store the detected tonals to binary file.
%   'GraphFile', File - Store the graphs to binary file.

stopwatch = tic;

% Java classes we will be needing
% Note that the Java calls have side effects to their arguments
import java.util.LinkedList;
import java.util.TreeSet;
import tonals.*;

% stuff for debugging
colors = lines(20);
colorN = size(colors, 1);
coloridx = 1;
cmap = flag(colorN);
handles = [];
subgraphs_closed = 0;
Plot = 0;
Interactive = false;
Debug = false;


if ~iscell(Filenames)
    if isempty(Filenames)
        % add GUI filenames selection later
        error('Silbido:Specify filenames');
    elseif ischar(Filenames)
        Filenames = {Filenames};  % assume user provided a single filename
    else
        error('Silbido:Specify filenames');
    end
end

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

% Other defaults ------------------------------------------------------
Advance_ms = 2;
Length_ms = 8;
NoiseSub = 'median';          % what type of noise compensation
MovieFile = [];      % generate a movie
GraphFile = [];      % Save graphs to file
TonalFile = [];      % Save detected tonals to file
RemoveTransients = false;  % mitigate for clicks/snapping shrimp
WaitTimeRejection = [];

k = 1;
while k <= length(varargin)
    switch varargin{k}
        case 'Framing'
            if length(varargin{k+1}) ~= 2
                error('Silbido:Framing', ...
                    '%s must be [Advance_ms, Length_ms]', varargin{k});
            else
                Advance_ms = varargin{k+1}(1);
                Length_ms = varargin{k+1}(2);
            end
            k=k+2;
        case 'Interactive'
            Interactive = varargin{k+1}; k=k+2;
        case 'Plot'
            Plot = varargin{k+1}; k=k+2;
        case 'Threshold'
            thr.whistle_dB = varargin{k+1}; k=k+2;
        case 'ParameterSet'
            k=k+2;  % already handled
        case 'ActiveSet_s'
            thr.activeset_s = varargin{k+1}; k=k+2;
        case 'Noise'
            NoiseSub = varargin{k+1}; k=k+2;
        case 'Movie'
            MovieFile = varargin{k+1}; k=k+2;
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
        case 'TonalFile'
            TonalFile = varargin{k+1}; k=k+2;
        case 'GraphFile'
            GraphFile = varargin{k+1}; k=k+2;
        case 'WaitTimeRejection'
            if length(varargin{k+1}) ~= 3
                error('%s expecting [N_events, wait_s, maxdur_s]', ...
                    varargin{k});
            else
                WaitTimeRejection = varargin{k+1};
            end
            k=k+2;
        otherwise
            try
                if isnumeric(varargin{k})
                    errstr = sprintf('Bad option %f', varargin{k});
                else
                    errstr = sprintf('Bad option %s', char(varargin{k}));
                end
            catch e
                errstr = sprintf('Bad option in %d''optional argument', k);
            end
            error('Silbido:Arguments', 'Detector:%s', errstr);
    end
end

if Interactive && Plot > 0
    fprintf('Interactive, press/hold space to progress\n');
end

if ~ isempty(TonalFile)
    % open up file
    tonal_h = TonalOutputStream(TonalFile);
else
    tonal_h = [];
end

if ~ isempty(GraphFile)
    % open up file
    graph_h = TonalOutputStream(GraphFile);
else
    graph_h = [];
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
thr.minlen_frames = thr.minlen_ms / Advance_ms;                                         
thr.maxgap_s = thr.maxgap_ms / 1000;
thr.maxgap_frames = round(thr.maxgap_ms / Advance_ms);

% Sets for managing search --------------------------------------------

% active_set - When looking examining peak energies from the current
% time frame, these nodes are candidates to be connected the current peaks
active_set = ActiveSet();


% Start processing ----------------------------------------------------

block_len_s = 3;  % amount of data considered in each block

% add outer loop to handle multiple filenames
file_idx = 1;

% Get header information of the file and then open file as little endian
header = ioReadWavHeader(Filenames{file_idx});
handle = fopen(Filenames{file_idx}, 'rb', 'l');
Stop_s = min(Stop_s, header.Chunks{header.dataChunk}.nSamples/header.fs);
if (Start_s >= Stop_s)
    error('Stop_s should be greater then Start');
end

MovieH = [];  % open movie file
if Plot
    [notused ImageH]= dtPlotSpecgram(Filenames{file_idx}, Start_s, Stop_s, ...
        'Framing', [Advance_ms, Length_ms], 'Render', 'floor', ...
        'Range', [thr.low_cutoff_Hz thr.high_cutoff_Hz], ...
        'Threshold', thr.whistle_dB, 'Click_dB', thr.click_dB, ...
        'Noise', NoiseSub);
    
    % Load the icon stored in icon.mat
    load icon;
    % Add Brightness/Contrast icon to standard toolbar. When pushed
    % brightness/contrast controls are displayed.
    stdtoolH = findall(gcf, 'Type', 'uitoolbar');
    uipushtool(stdtoolH, 'CData', cdata,...
        'Separator', 'on', 'HandleVisibility', 'off',...
        'TooltipString', 'Brightness/Contrast control',...
        'ClickedCallback', {@brightcontr_Callback, ImageH});
    
    activeSetH = [];
    peakSetH = [];
    hold on;
    
    if ~ isempty(MovieFile)
        [MovieDir, MovieBase, MovieExt] = fileparts(MovieFile);
        if ~ strcmp(MovieExt, '.avi')
            error('Movie filename must end in avi');
        else
            fprintf('Generating movie, should an error occur, the movie\n')
            fprintf('file cannot be closed until Matlab exits (v. 2008B)\n');
        end
        MovieFig = gcf;
        MoviePosition = get(MovieFig, 'Position');
        MoviePosition(1:2) = [0 0];  % include whole figure (axes, etc)
        MovieH = avifile(MovieFile, 'fps', 25, 'quality', 75);
    end
elseif ~ isempty(MovieFile)
    error('Movie can only be specified when ''Plot'' is > 0');
end

% Select channel as Triton would
channel = channelmap(header, Filenames{file_idx});

% Frame length and advance in samples
Length_s = Length_ms / 1000;
Length_samples = round(header.fs * Length_s);
Advance_s = Advance_ms / 1000;
Advance_samples = round(header.fs * Advance_s);
window = hamming(Length_samples);
Nyquist_bin = floor(Length_samples/2);

correction_dB = -10*log10(sum(window)^2) - 3; % correction for window energy
bin_Hz = header.fs / Length_samples;    % Hz covered by each freq bin
bin_kHz = bin_Hz / 1000;  % for plotting purposes
active_set.resolutionHz = bin_Hz;
thr.high_cutoff_bins = min(ceil(thr.high_cutoff_Hz/bin_Hz)+1, Nyquist_bin);
thr.low_cutoff_bins = ceil(thr.low_cutoff_Hz / bin_Hz)+1;
% After discretization, the low frequency cutoff may be different than
% what the user specified.  Save the revised frequency
OffsetHz = (thr.low_cutoff_bins - 1) * bin_Hz;

% save indices of freq bins that will be processed
range_bins = thr.low_cutoff_bins:thr.high_cutoff_bins; 
range_binsN = length(range_bins);  % # freq bin count

% Set up frequency axis for debugging plots
freq = (range_bins - 1)/Length_samples * header.fs;

% To compute the phase derivative, we should shift by a small
% number of samples and take the first difference
% We want the time difference to be small enough that at the highest
% frequency of interest, we will not move an entire cycle. 
% Oversampling should help us here.
shift_samples = floor(header.fs / thr.high_cutoff_Hz);
shift_samples_s = shift_samples / header.fs; 

TwoPi = 2*pi;  % constant we use in phase estimation

block_pad_s = 1 / thr.high_cutoff_Hz;
block_padded_s = block_len_s + 2 * block_pad_s;
Stop_s = Stop_s - block_pad_s;

if Start_s - block_pad_s >= 0
    Start_s = Start_s - block_pad_s;
end

% Flags required for computing MA(moving average) implementation.
start_sect = false;  % Start section
stop_sect = false;  % End section

% Keep track of how many peaks were detected in the previous frame
% that was processed.  If the number of peaks suddenly rise by
% thr.broadband% of the bandwidth range, we are probably in a click.
% Start w/ heuristic value well beneath the number of bins required
% to indicate broadband noise.
peakN_last_processed = range_binsN * 0.25;  

StartBlock_s = Start_s;
% Seem to be having problem getting to stop time due to
% incomplete frames.  For now kludge in a little padding
% to stop just before stop time.  Bhavesh, please fix.
%
% We will also need to take into account the amount of extra
% time needed for determining the phase.
while StartBlock_s + 2 * Length_s < Stop_s

   % Retrieve the data for this block
   StopBlock_s = min(StartBlock_s + block_padded_s, Stop_s);
   Signal = ioReadWav(handle, header, StartBlock_s, StopBlock_s, ...
       'Units', 's', 'Channels', channel);
   % Perform spectral analysis on block
   [snr_power_dB, Indices, dft, clickP] = dtSpecAnal(Signal, header.fs, ...
       Length_samples, Advance_samples, shift_samples, ...
       range_bins, thr.broadband * range_binsN, ...
       thr.click_dB, NoiseSub);
   
   
   
   % relative to file rather than block
   Indices.timeidx = Indices.timeidx + StartBlock_s;

   % Reserve memory for dfts used in derivative estimation
   dft2 = zeros(Length_samples, 2);
   phaseO = zeros(size(snr_power_dB, 1), 2);
   
   active_set.debug = false;
   for frame_idx = 1:size(snr_power_dB, 2)              
       
       % determine current time
       % could be computed only when we know that we have something
       % (inside the if block below, but this makes it easy to set
       % break points for specific times
       current_s = Indices.timeidx(frame_idx);
       % fprintf('t=%.3f\n', current_s);
       
       % no smoothing for now, but pretend anyway
       smoothed_dB = snr_power_dB(:, frame_idx);
       % Generate list of peaks
       % peak selector still has some issues, but good enough for now
       peak = spPeakSelector(smoothed_dB, 'Method', 'simple');

       % Remove peaks that don't meet SNR criterion
       peak(smoothed_dB(peak) < thr.whistle_dB) = [];  
       % some of the peaks may be too close and are probably local maxima
       % of the same peak
       if length(peak) > 1 && false
           peak_dist = diff(peak);
           % temporary hard code, should drive by Hz
           too_close = find(peak_dist < 2);
           if ~ isempty(too_close)
               % find the larger peak and remove the other one
               [maxval maxidx] = ...
                   max(smoothed_dB(peak([too_close; too_close+1])));
               % remove lower peaks
               peak(too_close + maxidx - 1) = [];
           end
       end

       peakN = length(peak);
       if ~ isempty(peak)
           % found something
           
           % If the number of peaks has increased dramatically between
           % the last frame we processed, assume that we have a broadband
           % signal (click) and skip this frame.
           increase = (peakN - peakN_last_processed) / range_binsN;
           if increase > thr.broadband
               if (Plot > 0)
                   plot([current_s current_s], ...
                       [thr.high_cutoff_Hz*.95, thr.high_cutoff_Hz]/1000, 'm-');
               end
               continue
           end
           
           
           peakN_last_processed = peakN;
           peak_freq = (peak - 1)* bin_Hz + OffsetHz;
                   
           % gathering information for phase derivatives
           % Take short-time Fourier transforms of signal in neighborhood
           % of the original transform
           if false
               dft_idx = 1;
               for delta = [-shift_samples shift_samples]
                   % compute phase shift
                   samp = Indices.idx(frame_idx,:) + delta;
                   dft2(:, dft_idx) = fft(Signal(samp(1):samp(2)).*window);
                   phaseO(:, dft_idx) = angle(dft2(range_bins, dft_idx));
                   
                   dft_idx = dft_idx + 1;
               end
               % estimate derivates, but only bother doing it for peaks
               % Takes into account the phase change due to framing and
               % does not include it in the derivative estimate.
               d_frame = shift_samples/header.fs * peak_freq' * TwoPi;
               pkangle = angle(dft(peak, frame_idx));
               dphase1 = pkangle - d_frame - phaseO(peak, 1);
               dphase2 = phaseO(peak, 2) - d_frame - pkangle;
               dphase = (dphase1 + dphase2) / 2;
               ddphase = dphase2 - dphase1;
           end
           
           % examine active list and see if anything needs to be removed
           % or moved to the list of whistles
           active_set.prune(current_s, thr.minlen_s, thr.maxgap_s);

           % Create TreeSet of time-frequency nodes for peaks
           peak_list = tfTreeSet(current_s(ones(size(peak))), ...
               peak_freq, smoothed_dB(peak), angle(dft(peak, frame_idx)));
           %, , dphase, ddphase);
           % something new to process - display if needed
           if Plot > 0
               if ~ isempty(handles)
                   delete(handles{:});     % remove plots from last iteration
                   clear handles;
               end
               handles{1} = plot(peak_list.get_time(), ...
                   peak_list.get_freq/1000, 'r^');
               handles{2} = plot(active_set.get_time(), ...
                   active_set.get_freq/1000, 'bp');
               if Plot > 2
                   handles{3} = plot(active_set.orphans.get_time(), ...
                       active_set.orphans.get_freq/1000, 'ko');
               end
           end
           
           % Link anything possible from the current active set to the
           % new peaks then add them to the active set.            
           active_set.extend(peak_list, thr.maxslope_Hz_per_ms, thr.activeset_s);
           
           if Plot > 1
               % plot subgraphs associated with the active and orphan sets
               seen = [];
               [handles, coloridx] = plot_graph(active_set, ...
                   handles, cmap, coloridx, ':', 'd');
               if Plot > 2
                   [handles, coloridx] = plot_graph(active_set.orphans, ...
                       handles, cmap, coloridx, ':', 'o');
               end

               % Plot 
               % Check for any new subgraphs as a result of pruning
               prev_closed = subgraphs_closed;
               subgraphs_closed = active_set.subgraphs.size();
               if  subgraphs_closed > prev_closed
                   plotted = true;
                   % plot out the new closed off subgraphs
                   % we don't save their handles as we aren't
                   % planning on deleting them (yet at least)
                   for k = prev_closed:(subgraphs_closed-1)
                       g = active_set.subgraphs.get(k);
                       dtPlotGraph(g, ...
                               'ColorMap', cmap, 'LineStyle', '-', ...
                               'ColorIdx', coloridx, 'Marker', 'x', ...
                               'DistinguishEdges', false);
                   end
               end               
           end
       end
       if Plot > 0
           if ~ isempty(MovieH)
               FrameH = getframe(MovieFig, MoviePosition);
               MovieH = addframe(MovieH, FrameH);
           end
           if Interactive
               pause
           else
               drawnow;
           end
       end
   end % end for frame_idx
   
   StartBlock_s = Indices.timeidx(end) + Advance_s - shift_samples_s;  % Set time for next block
   
end  % for block_idx

if ~ isempty(MovieH)
    MovieH = close(MovieH);
end
% Clean up, process any remaining partial tonals by faking a time in the 
% future.
active_set.prune(current_s + 2*thr.maxgap_s, ...
    thr.minlen_s, thr.maxgap_s);

if graph_ret
    subgraphs = active_set.subgraphs;    
end
if ~ isempty(graph_h)
    % To Do: write out the graphs 
    
    % graph_h.write(active_set.subgraphs);
    graph_h.close();
end

graph_s = toc(stopwatch);
stopwatch = tic;

tonals = java.util.LinkedList(); % Detected tonals
discarded_count = 0;
it = active_set.subgraphs.iterator();
resolutionHz = (1000 / Length_ms);
while it.hasNext()
            toneset = it.next();
                                        
            % NOTE: Last 2 flag argument for disambiguate java
            %       method can't both be true (Experimental stage)
            % false, true - polynomial fit of first difference of
            %               phase to frequency
            % true, false - vector strength
            % false, false - polynomial fit of frequency to time
            g = toneset.disambiguate(thr.disambiguate_s, resolutionHz,...
                false, false);
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
                    if ~ isempty(tonal_h)
                        % write out the tonal
                        tonal_h.write(tone);
                    end
                else
                    discarded_count = discarded_count + 1;
                end
            end
end
if ~ isempty(tonal_h)
    tonal_h.close();
end
disambiguate_s = toc(stopwatch);

% print summary
elapsed_s = graph_s + disambiguate_s;
processed_s = Stop_s - Start_s;

% lambda function s --> HH:MM:SS
to_time = @(s) datestr(datenum(0, 0, 0, 0, 0, s), 13);

fprintf('Detected %d tonals, rejected %d shorter than %f s\n', ...
    tonals.size(), discarded_count);

fprintf('Timing statistics\n');
fprintf('function\tduration\tx Realtime\n')
fprintf('graph gen\t%s\t%.2f\n', to_time(graph_s), processed_s / graph_s);
fprintf('tonal gen\t%s\t%.2f\n', ...
    to_time(disambiguate_s), processed_s / disambiguate_s);
fprintf('Overall\t\t%s\t%.2f\n', to_time(elapsed_s), processed_s / elapsed_s);

1;

function [handles, coloridx] = plot_graph(set, handles, cmap, ...
    coloridx, style, marker)
% Given a tfTressSet set, create the subgraph associated with each
% node and plot it.  Nodes attached to the same subset will only
% be plotted once.  
% cmap is a colormap, and coloridx is the next color to plot.  
% coloridx is incremented modulo the # of entries in the colormap
% and returned on exit along with a cell array of handles for each
% subgraph that is plotted.

import tonals.*;

if nargin > 5
    MarkerArgs = {'Marker', marker};
else
    MarkerArgs = {};
end

piter = set.iterator();
plotted = false;
seen = [];
while piter.hasNext();
    p = piter.next();
    % only plot if there's something attached to this.
    if p.chained_backward()
        % check if we have already plotted the
        % graph associated with this peak
        need_plot = true;
        for k=1:length(seen)
            if p.ismember(seen{k})
                need_plot = false;
            end
        end
        if need_plot
            % Store the set associated with this one
            seen{end+1} = p.find();
            g = graph(p);
            [newh, coloridx] = dtPlotGraph(g, ...
                'ColorMap', cmap, 'LineStyle', style, ...
                MarkerArgs{:}, 'ColorIdx', coloridx, ...
                'DistinguishEdges', false);
            plotted = true;
            handles = horzcat(handles, newh');
        end
    end
end

function brightcontr_Callback(hObject,eventdata, varargin)
% Brightness/Contrast controls
dtPlotBrightContrast(varargin{1});
