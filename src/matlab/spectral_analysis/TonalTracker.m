classdef TonalTracker < handle
    %TONALTRACKER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        thr;
        NoiseSub;
        active_set;
        header;
        handle;
        Start_s;
        Stop_s;
        channel;
        Advance_s;
        Advance_samples;
        StartBlock_s;
        StopBlock_s;
        Length_s;
        Length_samples;
        snr_power_dB;
        Indices;
        range_bins;
        range_binsN;
        
        OffsetHz;
      
        shift_samples;
        shift_samples_s;
        block_padded_s;
        
        current_frame_peak_bins;
        current_frame_peak_freqs;
        peakN_last_processed;
        smoothed_dB;
        
        current_s;
        bin_Hz;
        frame_idx;
        
        discarded_count;
        
        SPCallback;
        callbackSet;
        
        block_pad_s;
        
        removeTransients;
        removalMethod;
        noiseBoundaries;
        blocks;
        block_idx;
    end
    
    methods
        function tt = TonalTracker(Filename, Start_s, Stop_s, varargin)
            % Java classes we will be needing
            % Note that the Java calls have side effects to their arguments
            import tonals.*;
            
            tt.Start_s = Start_s;
            
            tt.thr = struct();

            ActiveSet.setDebugging(false);

            % Settable Thresholds --------------------------------------------------
            tt.thr.whistle_dB = 10;       % SNR criterion for whistles
            tt.thr.click_dB = 10;         % SNR criterion for clicks (part of click skipping decision)

            % Whistles whose duration is shorter than threshold will be discarded.
            tt.thr.minlen_ms = 150;

            % Maximum gap in time to bridge when looking for a tonal
            tt.thr.maxgap_ms = 50;

            % Maximum difference in frequency to bridge when looking for a tonal
            tt.thr.maxslope_Hz_per_ms = 1000;

            % define frequency range over which we search for tonals
            tt.thr.high_cutoff_Hz = 50000;
            tt.thr.low_cutoff_Hz = 5000;

            tt.thr.activeset_s = .050; % peaks with earliest time > thr.activeset_s will be
                                    % part of active_set otherwise part of orphan set

            tt.thr.slope_s = .008;    % Possible predecessor that is thr.slope_s seconds
                                   % behind the current peak (Slope)

            tt.thr.phase_s = .008;    % Possible predecessor that is thr.phase_s seconds
                                   % behind the current peak (Phase)

            % Frames containing broadband signals will be ignored.
            % If more than broadand% of the bins exceed the threshold,
            % we consider the frame a click.  
            %thr.broadband = .20;
            tt.thr.broadband = .01;

            % When extracting tonals from a subgraph, use up to thr.disambiguate_s
            % when computing the local polynomial fit.
            tt.thr.disambiguate_s = .3;  
            tt.thr.advance_ms = 2;
            tt.thr.length_ms = 8;
            tt.thr.blocklen_s = 3;

            % Other defaults ------------------------------------------------------
            tt.NoiseSub = 'median';          % what type of noise compensation

            k = 1;
            while k <= length(varargin)
                switch varargin{k}
                    case 'Framing'
                        if length(varargin{k+1}) ~= 2
                            error('Silbido:Framing', ...
                                '%s must be [Advance_ms, Length_ms]', varargin{k});
                        else
                            tt.thr.advance_ms = varargin{k+1}(1);
                            tt.thr.length_ms = varargin{k+1}(2);
                        end
                        k=k+2;
                    case 'Threshold'
                        tt.thr.whistle_dB = varargin{k+1}; k=k+2;
                    case 'ParameterSet'
                        k=k+2;  % already handled
                    case 'ActiveSet_s'
                        tt.thr.activeset_s = varargin{k+1}; k=k+2;
                    case 'Noise'
                        tt.NoiseSub = varargin{k+1}; k=k+2;
                        if ~ iscell(tt.NoiseSub)
                            tt.NoiseSub = {tt.NoiseSub};
                        end
                    case 'Range'
                        if length(varargin{k+1}) ~= 2 || diff(varargin{k+1}) <= 0
                            error('Silbido:DetectorRange', ...
                                '%s must be [LowCutoff_Hz, HighCutoff_Hz]', ...
                                varargin{k});
                        else
                            tt.thr.low_cutoff_Hz = varargin{k+1}(1);
                            tt.thr.high_cutoff_Hz = varargin{k+1}(2);
                        end
                        k=k+2;
                    case 'SPCallback'
                        tt.SPCallback = varargin{k+1}; k=k+2;
                        tt.callbackSet = true;
                    case 'RemoveTransients'
                        tt.removeTransients = varargin{k+1}; k=k+2;
                    case 'RemovalMethod'
                        tt.removalMethod = varargin{k+1}; k=k+2;
                    case 'NoiseBoundaries'
                        tt.noiseBoundaries = varargin{k+1}; k=k+2;
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

            % Derived Thresholds --------------------------------------------------
            tt.thr.minlen_s = tt.thr.minlen_ms / 1000;
            tt.thr.minlen_frames = tt.thr.minlen_ms / tt.thr.advance_ms;                                         
            tt.thr.maxgap_s = tt.thr.maxgap_ms / 1000;
            tt.thr.maxgap_frames = round(tt.thr.maxgap_ms / tt.thr.advance_ms);
            % New peak is added to the existing peak in the orphan set if the gap
            % between them is less then thr.maxspace_s. Or else new peak is added to 
            % the orphan set.
            tt.thr.maxspace_s = 2 * (tt.thr.advance_ms / 1000);

            tt.thr.resolutionHz = (1000 / tt.thr.length_ms);
            % Sets for managing search --------------------------------------------

            % active_set - When looking examining peak energies from the current
            % time frame, these nodes are candidates to be connected the current peaks
            tt.active_set = ActiveSet();

            % Start processing ----------------------------------------------------

            block_len_s = tt.thr.blocklen_s;  % amount of data considered in each block

            % Get header information of the file and then open file as little endian
            tt.header = ioReadWavHeader(Filename);
            tt.handle = fopen(Filename, 'rb', 'l');
            file_end_s = tt.header.Chunks{tt.header.dataChunk}.nSamples/tt.header.fs;
            tt.Stop_s = min(Stop_s, file_end_s);
            
            if (tt.Start_s >= tt.Stop_s)
                error('Stop_s should be greater then Start');
            end

            % Select channel as Triton would
            tt.channel = channelmap(tt.header, Filename);

            % Frame length and advance in samples
            tt.Length_s = tt.thr.length_ms / 1000;
            tt.Length_samples = round(tt.header.fs * tt.Length_s);
            tt.Advance_s = tt.thr.advance_ms / 1000;
            tt.Advance_samples = round(tt.header.fs * tt.Advance_s);
            Nyquist_bin = floor(tt.Length_samples/2);

            tt.bin_Hz = tt.header.fs / tt.Length_samples;    % Hz covered by each freq bin
            tt.active_set.setResolutionHz(tt.bin_Hz);

            tt.thr.high_cutoff_bins = min(ceil(tt.thr.high_cutoff_Hz/tt.bin_Hz)+1, Nyquist_bin);
            tt.thr.low_cutoff_bins = ceil(tt.thr.low_cutoff_Hz / tt.bin_Hz)+1;
            % After discretization, the low frequency cutoff may be different than
            % what the user specified.  Save the revised frequency
            tt.OffsetHz = (tt.thr.low_cutoff_bins - 1) * tt.bin_Hz;

            % save indices of freq bins that will be processed
            tt.range_bins = tt.thr.low_cutoff_bins:tt.thr.high_cutoff_bins; 
            tt.range_binsN = length(tt.range_bins);  % # freq bin count

            % To compute the phase derivative, we should shift by a small
            % number of samples and take the first difference
            % We want the time difference to be small enough that at the highest
            % frequency of interest, we will not move an entire cycle. 
            % Oversampling should help us here.
            tt.shift_samples = floor(tt.header.fs / tt.thr.high_cutoff_Hz);
            tt.shift_samples = 0;
            tt.shift_samples_s = tt.shift_samples / tt.header.fs; 

            tt.block_pad_s = 1 / tt.thr.high_cutoff_Hz;
            tt.block_padded_s = block_len_s + 2 * tt.block_pad_s;
            tt.Stop_s = tt.Stop_s - tt.block_pad_s;

            if tt.Start_s - tt.block_pad_s >= 0
                tt.Start_s = tt.Start_s - tt.block_pad_s;
            end

            % Keep track of how many peaks were detected in the previous frame
            % that was processed.  If the number of peaks suddenly rise by
            % thr.broadband% of the bandwidth range, we are probably in a click.
            % Start w/ heuristic value well beneath the number of bins required
            % to indicate broadband noise.
            tt.peakN_last_processed = tt.range_binsN * 0.25;  

            tt.StartBlock_s = tt.Start_s;
            tt.frame_idx = 0;
            

            allBlocks = dtBlockBoundaries(tt.noiseBoundaries, ...
                file_end_s, block_len_s, tt.block_pad_s, ...
                tt.Advance_s, tt.shift_samples_s);
            
            tt.blocks = dtBlocksForSegment(allBlocks, tt.Start_s, min(tt.Stop_s, file_end_s));
            tt.block_idx = 1;
            
            fprintf('\nFile length %.5f\n', file_end_s);
            fprintf('Processing file from %.5f to %.5f\n', tt.Start_s, tt.Stop_s);
        end
        
        function startBlock(tt)
            tt.StartBlock_s = tt.blocks(tt.block_idx,1);
            tt.StopBlock_s = tt.blocks(tt.block_idx,2);
            
            % Retrieve the data for this block
            %tt.StopBlock_s = min(tt.StartBlock_s + tt.block_padded_s, tt.Stop_s);
            
            %fprintf('Processing raw block from %.10f to %.10f\n', tt.StartBlock_s, tt.StopBlock_s);
            %noiseBoundary = min(tt.noiseBoundaries(tt.noiseBoundaries > tt.StartBlock_s + tt.Advance_s & tt.noiseBoundaries < tt.StopBlock_s));
            %if ~isempty(noiseBoundary) && false
            %    tt.StopBlock_s = noiseBoundary + 2 * tt.block_pad_s;
            %end

            length_s = tt.StopBlock_s - tt.StartBlock_s;
            %fprintf('Processing noise block from %.10f to %.10f\n', tt.StartBlock_s, tt.StopBlock_s);
            
            [~, ~, tt.snr_power_dB, tt.Indices, ~, ~] = dtProcessBlock(...
                tt.handle, tt.header, tt.channel, ...
                tt.StartBlock_s, length_s, [tt.Length_samples, tt.Advance_samples], ...
                'Pad', 0, 'Range', tt.range_bins, ...
                'Shift', tt.shift_samples, ...
                'ClickP', [tt.thr.broadband * tt.range_binsN, tt.thr.click_dB], ...
                'RemoveTransients', tt.removeTransients, ...
                'RemovalMethod', tt.removalMethod, ...
                'Noise', {tt.NoiseSub});
            
            %fprintf('Processed indicies from %.10f to %.10f\n', tt.Indices.timeidx(1), tt.Indices.timeidx(end));

            % The first frame is 1, so we set this to zero, so we can call
            % advance, to get to the first frame.
            if (tt.block_idx == 1)
                timeidx = tt.Indices.timeidx;
                tt.frame_idx = max(find(timeidx > tt.Start_s, 1) - 1, 0);
            else
                tt.frame_idx = 0;
            end
            tt.advanceFrameInBlock();
            if (tt.callbackSet)
               tt.SPCallback.blockStarted(tt.snr_power_dB,tt.StartBlock_s,tt.StopBlock_s);
            end
        end
        
        function foundPeaks = selectPeaks(tt)
           foundPeaks = false;
           tt.current_frame_peak_bins = [];
           tt.current_frame_peak_freqs = [];
        
           % no smoothing for now, but pretend anyway
           tt.smoothed_dB = tt.snr_power_dB(:, tt.frame_idx);
           
           % Generate list of peaks
           % peak selector still has some issues, but good enough for now
           peaks = spPeakSelector(tt.smoothed_dB, 'Method', 'simple');

           % Remove peaks that don't meet SNR criterion
           peaks(tt.smoothed_dB(peaks) < tt.thr.whistle_dB) = [];  

           peaks = consolidate_peaks(peaks, tt.smoothed_dB, 2);

           peakN = length(peaks);
           if ~isempty(peaks)
               % found something

               % If the number of peaks has increased dramatically between
               % the last frame we processed, assume that we have a broadband
               % signal (click) and skip this frame.
               increase = (peakN - tt.peakN_last_processed) / tt.range_binsN;
               if increase > tt.thr.broadband
                   if (tt.callbackSet)
                       tt.SPCallback.handleBroadbandFrame(tt.current_s);
                   end
               else
                   % Convert the peak location to frequencies.
                   peak_freq = (peaks - 1)* tt.bin_Hz + tt.OffsetHz;
                   
                   if (tt.callbackSet)
                       tt.SPCallback.handleFramePeaks(tt.current_s, peak_freq);
                   end
                   
                   tt.current_frame_peak_bins = peaks;
                   tt.current_frame_peak_freqs = peak_freq;
                   tt.peakN_last_processed = peakN;
                   foundPeaks = true;
               end
           end
        end
        
         function foundPeaks = selectPeaksZimmer(tt)
            % foundPeaks = selectPeaksZimmer(tt)
            % Find peaks in the current frame based on
            % power and acceleration
            
            foundPeaks = false;
            tt.current_frame_peak_bins = [];
            tt.current_frame_peak_freqs = [];
            
            % no smoothing for now, but pretend anyway
            tt.smoothed_dB = tt.snr_power_dB(:, tt.frame_idx);
            
            % Peaks must meet SNR threshold and have a 2nd derivative
            % that also exceeds threshold
            %d2 = diff(tt.smoothed_dB, 2);
            delta=2;  % frequency bin delta
            d1 = tt.smoothed_dB(delta+1:end) - tt.smoothed_dB(1:end-delta);
            d1 = [d1(1)*ones(delta,1); d1];
            d2 = diff(d1);
            d2 = [d2(1); d2];
            d2_thresh = -2;  % was -1 earlier, not sure which is better

            % Remove peaks that don't meet SNR & 2nd deriv criteria
            peaks = find(tt.smoothed_dB > tt.thr.whistle_dB & ...
                d2 < d2_thresh);
            % When peaks are too close, pick the best one
            % find peaks that are close to one another
            close_thr = 1;
            peak_dist = diff(peaks);
            nearby = find(peak_dist <= close_thr);
            % on the off chance that we have three consecutive peak dections
            % 
            if ~ isempty(nearby)
                remove = zeros(length(nearby),1);
                for nidx = 1:length(nearby)
                    [~,rmoffset] = min(tt.smoothed_dB(peaks(nidx:nidx+1)));
                    remove(nidx) = nearby(nidx) + rmoffset - 1;
                end
                peaks(remove) = [];
            end
            
            
            %peaks = consolidate_peaks(peaks, tt.smoothed_dB, 2);
            
            peakN = length(peaks);
            if ~isempty(peaks)
                % found something
                
                % If the number of peaks has increased dramatically between
                % the last frame we processed, assume that we have a broadband
                % signal (click) and skip this frame.
                increase = (peakN - tt.peakN_last_processed) / tt.range_binsN;
                if increase > tt.thr.broadband
                    if (tt.callbackSet)
                        tt.SPCallback.handleBroadbandFrame(tt.current_s);
                    end
                else
                    % Convert the peak location to frequencies.
                    peak_freq = (peaks - 1)* tt.bin_Hz + tt.OffsetHz;
                    
                    if (tt.callbackSet)
                        tt.SPCallback.handleFramePeaks(tt.current_s, peak_freq);
                    end
                    
                    tt.current_frame_peak_bins = peaks;
                    tt.current_frame_peak_freqs = peak_freq;
                    tt.peakN_last_processed = peakN;
                    foundPeaks = true;
                end
            end
        end
        
        function freqs = getCurrentFramePeakFreqs(tt)
            freqs = tt.current_frame_peak_freqs;
        end
           
        function pruneAndExtend(tt)
            if (~isempty(tt.current_frame_peak_bins))
                
               % examine active list and see if anything needs to be removed
               % or moved to the list of whistles
               tt.active_set.prune(tt.current_s, tt.thr.minlen_s, tt.thr.maxgap_s);
               
               import tonals.*;
               % Create TreeSet of time-frequency nodes for peaks
               times = tt.current_s(ones(size(tt.current_frame_peak_bins)));
               freqs = tt.current_frame_peak_freqs;
               dbs = tt.smoothed_dB(tt.current_frame_peak_bins);
               phases = zeros(size(tt.current_frame_peak_bins));
               ridges = zeros(size(tt.current_frame_peak_bins));
               
               peak_list = tfTreeSet(times, freqs, dbs, phases, ridges);
               
               % Link anything possible from the current active set to the
               % new peaks then add them to the active set.            
               tt.active_set.extend(peak_list, tt.thr.maxslope_Hz_per_ms, tt.thr.activeset_s);
               if (tt.callbackSet)
                   tt.SPCallback.handleActiveSetExtension(tt);
               end
            end
        end
        
        function advanceFrameInBlock(tt)
            tt.frame_idx = tt.frame_idx + 1;
            tt.current_s = tt.Indices.timeidx(tt.frame_idx);
            if (tt.callbackSet)
               tt.SPCallback.frameAdvanced(tt);
            end
        end
        
        function completeBlock(tt)
            if (tt.callbackSet)
                tt.SPCallback.blockCompleted();
            end
        end
        
        function advanceBlock(tt)
            %tt.StartBlock_s = tt.Indices.timeidx(end) + tt.Advance_s - tt.shift_samples_s;
            tt.block_idx = tt.block_idx + 1;
        end
        
        function processBlock(tt)
            tt.startBlock();
            while (true)
                tt.processCurrentFrame();
                if (tt.blockHasNextFrame())
                    tt.advanceFrameInBlock();
                else
                    break;
                end
            end
            tt.completeBlock();
        end
        
        function hasNext = hasNextBlock(tt)
            %hasNext = tt.StartBlock_s + 2 * tt.Length_s < tt.Stop_s;
            % This is a hack.
            %hasNext = tt.StartBlock_s + tt.block_padded_s + 2 * tt.Length_s < tt.Stop_s;
            hasNext = tt.block_idx < length(tt.blocks);
        end
        
        function hasNext = blockHasNextFrame(tt)
            hasNext = tt.frame_idx < size(tt.snr_power_dB, 2);
        end
        
        function processCurrentFrame(tt)            
            found = tt.selectPeaks();
            %found = tt.selectPeaksZimmer();
            if (found)
                tt.pruneAndExtend();
            end
        end
        
        function finalizeTracking(tt)
            % Clean up, process any remaining partial tonals by faking a time in the 
            % future.
            tt.active_set.prune(tt.current_s + 2*tt.thr.maxgap_s,tt.thr.minlen_s, tt.thr.maxgap_s);
        end
        
        
        function advanceFrame(tt)
            if (tt.blockHasNextFrame())
                tt.advanceFrameInBlock();  
                if (~tt.blockHasNextFrame())
                    tt.completeBlock();
                end
            elseif (tt.hasNextBlock())
                tt.advanceBlock();
                tt.startBlock();
            else
                error('Cannont advance frame');
            end
        end
                        
        function processFile(tt)
            tt.startBlock();
            while (tt.hasMoreFrames())
                tt.advanceFrame();
                tt.processCurrentFrame();
            end
            tt.finalizeTracking();
        end
        
        function complete = hasMoreFrames(tt)
            complete = tt.blockHasNextFrame() || tt.hasNextBlock();
        end
        
        function time_s = getCurrentFrameTime(tt)
            time_s = tt.current_s;
        end
        
        function time_s = getNextFrameTime(tt)
            time_s = tt.current_s + tt.Advance_s;
        end
        
        function graphs = getGraphs(tt)
            graphs = tt.active_set.getResultGraphs();
        end
        
        function discard_count = getDiscardedCount(tt)
            discard_count = tt.discarded_count;
        end
        
        function tonals = getTonals(tt)
            tonals = java.util.LinkedList(); % Detected tonals
            tt.discarded_count = 0;
            it = tt.active_set.getResultGraphs().iterator();
            while it.hasNext()
                subgraph = it.next();

                % NOTE: Last 2 flag argument for disambiguate java
                %       method can't both be true (Experimental stage)
                % false, true - polynomial fit of first difference of
                %               phase to frequency
                % true, false - vector strength
                % false, false - polynomial fit of frequency to time
                g = subgraph.disambiguate(tt.thr.disambiguate_s, tt.thr.resolutionHz,...
                    false, 0);
                % Obtain the edges
                edges = g.topological_sort();
                % Loop through each edge
                segIt = edges.iterator();
                while segIt.hasNext()
                    edge = segIt.next();
                    tone = edge.content;
                    if tone.get_duration() > tt.thr.minlen_s && stat_avg_nth_wait_times(tone,3) < 18
                          tonals.addLast(tone);
                        
                    else
                        tt.discarded_count = tt.discarded_count + 1;
                    end
                end
            end
        end
        
        function start_time = getStartTime(tt)
            start_time = tt.Start_s;
        end
        
        function end_time = getEndTime(tt)
            end_time = tt.Stop_s;
        end
        
        function active_set = getActiveSet(tt)
            active_set = tt.active_set;
        end
    end
end

