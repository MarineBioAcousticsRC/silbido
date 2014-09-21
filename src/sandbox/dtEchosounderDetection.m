function dtEchoSounderDetection(Filenames, varargin)
% boundingboxes = dtEchoSounderDetection(Filenames, OptionalArgs)
% 
% Filename - Cell array of filenames that are assumed to be consecutive
%            Example -  {'palmyra092007FS192-071011-230000.wav', 
%                        'palmyra092007FS192-071011-231000.wav'}
% Start_s - start time in s relative to the start of the first recording
% Stop_s - stop time in s relative to the start of the first recording
% Optional arguments in any order:
%   'Framing', [Advance_ms, Length_ms] - frame advance and length in ms
%       Defaults to 2 and 8 ms respectively
%   'NoiseBoundaries' - Precomputed noise boundaries in seconds.  If more
%       than one file, use a cell array with boundaries for each file in
%       a cell.

Advance_ms = 10;
Length_ms = 10;
BlockLen_s = 75;

PeriodMin_s = 1;   % Echounders Hz range:
PeriodMax_s = 10;  % [1/PeriodMax_s:1/PeriodMin_s] Hz

Shoulder_s = PeriodMin_s * .4;  % Shoulder for autocorrelation

freqblocks = 5; % Split spectrum into N processing blocks

StartAt_s = 0;  % defaults for now, let user override later
EndAt_s = Inf;
NoiseBoundaries = [];
Channel = [];

if ~ iscell(Filenames)
    if ~ischar(Filenames)
        error('Filenames must be a character string or cell array of strings');
    else
        Filenames = {Filenames};
    end
end

vidx = 1;
while vidx < length(varargin)
    switch varargin{vidx}
        case 'Start_s'
            Start_s = varargin{vidx+1};
            if ~ isscalar(Start_s)
                error('silbido: %s requires scalar value', varargin{vidx});
            end
            vidx = vidx + 2;
        case 'Stop_s'
            EndAt_s = varargin{vidx+1};
            if ~ isscalar(Start_s)
                error('silbido: %s requires scalar value', varargin{vidx});
            end
            vidx = vidx + 2;            
        case 'NoiseBoundaries'
            NoiseBoundaries = varargin{vidx+1};
            if isnumeric(NoiseBoundaries)
                NoiseBoundaries = {NoiseBoundaries};
            end
            if ~ iscell(NoiseBoundaries)
                error('silbido:Noise regime boundaries must be a vector or cell array');
            elseif length(NoiseBoundaries) ~= length(Filenames)
                error('silbido:Noise regime boundaries cell array must have an entry for each filename');
            end
            vidx = vidx + 2;
            
        otherwise
            error('silbido:Bad argument')
    end
end


for fidx=1:length(Filenames)
    Header = ioReadWavHeader(Filenames{fidx});
    AudioH = fopen(Filenames{fidx}, 'rb');
    
    Start_s = StartAt_s;
    Last_s = Header.Chunks{Header.dataChunk}.nSamples/Header.fs;
    End_s = min(EndAt_s, Last_s);
    
    if isempty(Channel)
        % Triton channel selection
        usechannel = channelmap(Header, Filenames{fidx});
    else
        % User specified channel
        usechannel = Channel;
    end
    
    if ~isempty(NoiseBoundaries)
        Boundaries = NoiseBoundaries{fidx};
    else
        % todo:  does not respect channel specification
        Boundaries = detect_noise_changes_in_file(Filenames{fidx}, Start_s, End_s);
    end
    
    frame_len= spMS2Sample(Length_ms, Header.fs);
    frame_advance = spMS2Sample(Advance_ms, Header.fs);
    bin_Hz = 1000 / Length_ms;
    
    bins = frame_len;
    % Set up ranges of frequency bins between [0, Nyquist]
    bandbounds_Hz = linspace(0, Header.fs/2, freqblocks + 1)';
    bandbounds_Hz = [bandbounds_Hz(1:end-1), bandbounds_Hz(2:end)];
    bandbounds_bins = floor(bandbounds_Hz / bin_Hz);
    bandbounds_bins(:,1) = bandbounds_bins(:,1)+1;
    
    blkidx = 1;
    blkstart_s = Start_s;
    
    reduced_specgram = [];
    while blkstart_s < Last_s
        % Read in to end of this noise regime
        if blkidx <= length(Boundaries)
            % process to next block boundary or user specified end
            blkstop_s = min(Boundaries(blkidx), Last_s);
            blkidx = blkidx + 1;
        else
            blkstop_s = Last_s;  % last regime
        end
            
        [~, block_dB, blockSNR_dB, Indices] = dtProcessBlock(AudioH, ...
            Header, usechannel, blkstart_s, blkstop_s - blkstart_s, ...
            [frame_len, frame_advance], 'Noise', {'distributional'});
        
        % Reduce frequency resolution
        blockgram = zeros(freqblocks, size(blockSNR_dB, 2));
        for bandidx = 1:freqblocks
            blockgram(bandidx, :) = max(blockSNR_dB(bandbounds_bins(bandidx, :), :));
        end
        reduced_specgram = [reduced_specgram, blockgram];
        
        blkstart_s = blkstop_s;
    end
    1;
    
    minlag = round(PeriodMin_s * (1000/Advance_ms));
    maxlag = round(PeriodMax_s * (1000/Advance_ms));
    taxis = (Advance_ms:Advance_ms:Advance_ms*maxlag)/1000;
    bands = zeros(maxlag, freqblocks);
    frames = size(reduced_specgram, 2);
    
    % Running over the entire thing seems to be smearing it,
    % will need to set up smaller blocks to process, e.g. 30 s
    % kludge for now.
    timerng=1:3000;
    
    q1idx = round(.25*length(timerng));  % positions of 25/50/75% order stats
    q2idx = round(.50*length(timerng));
    q3idx = round(.75*length(timerng));
    for bandidx = 1:size(reduced_specgram, 1)
        sorted = sort(reduced_specgram(bandidx,timerng));
        q1 = sorted(q1idx);
        q3 = sorted(q3idx);
        outliers = reduced_specgram(bandidx,timerng) > q3 + 1.6 * (q3 - q1);
        %outliers = outliers * 100;
        
        bandcorr = xcorr(outliers, maxlag);
        bandcorr(1:maxlag+1) = [];  % Remove left side
        bands(:,bandidx) = bandcorr'
    end
    plot(taxis, bands);
    1;
        
    
    
    
    
    
    
end
    