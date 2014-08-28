function changes = detect_noise_changes_in_file(Filename, StartTimeS, EndTimeS, varargin)
% trkCettolo(SourceData, varargin)
%
% Optional arguments:
% 'Delta', {LowMS, HighMS}
%       Specify the low and high resolution delta times in MS.
%       Note that the algorithm uses the cumulative sum approach
%       of Cettolo and requires many arguments to be multiples of
%       each other.  The parameters will be adjusted if this is not
%       the case.
% 'Window', {MinS, MaxS, MarginS, GrowthS, ShiftS, SecondS}
%       MinS - Smallest possible hypothesis window
%       MaxS - Largest possible  hypothesis window
%       MarginS - Don't hypothesize in the MarginMS closest
%               to either end.
%       GrowthS - Window growth size when change not detected
%       ShiftS - Window shift when maximum size reached wihtout
%               change detection.
%       Second - The largest size of the window for the high resolution
%                search.
% 'Method', {'full' (default), 'diagonal', 'adapt'}
%
%
%       feature vector sample rate and HighMS
% Initialize defaults


%-------------------------------------------------------------------------%
% Silbido Spectral Processing Parameters
%-------------------------------------------------------------------------%

sp_options = struct();

thr.high_cutoff_Hz = 50000;
thr.low_cutoff_Hz = 5000;
thr.broadband = .01;

thr.advance_ms = .5;
thr.length_ms = 1;

header = ioReadWavHeader(Filename);
handle = fopen(Filename, 'rb', 'l');
file_end_s = header.Chunks{header.dataChunk}.nSamples/header.fs;
EndTimeS = min(file_end_s, EndTimeS);

% Select channel as Triton would
channel = channelmap(header, Filename);

% Frame length and advance in samples
Length_s = thr.length_ms / 1000;
Length_samples = round(header.fs * Length_s);
Advance_s = thr.advance_ms / 1000;
Advance_samples = round(header.fs * Advance_s);
Nyquist_bin = floor(Length_samples/2);

bin_Hz = header.fs / Length_samples; 

thr.high_cutoff_bins = min(ceil(thr.high_cutoff_Hz/bin_Hz)+1, Nyquist_bin);
thr.low_cutoff_bins = ceil(thr.low_cutoff_Hz / bin_Hz)+1;

fHz = thr.low_cutoff_Hz:bin_Hz:thr.high_cutoff_Hz;
fkHz = fHz / 1000;

shift_samples = floor(header.fs / thr.high_cutoff_Hz);
shift_samples_s = shift_samples / header.fs; 

% save indices of freq bins that will be processed
range_bins = thr.low_cutoff_bins:thr.high_cutoff_bins; 
range_binsN = length(range_bins);  % # freq bin count

NoiseSub = 'median';
    
thr.click_dB = 10;

sp_args = struct();

sp_args.thr = thr;
sp_args.header = header;
sp_args.channel = channel;
sp_args.handle = handle;
sp_args.NoiseSub = NoiseSub;
sp_args.range_bins = range_bins;
sp_args.shift_samples = shift_samples;
sp_args.range_binsN = range_binsN;
sp_args.Advance_samples = Advance_samples;
sp_args.Advance_s = Advance_s;
sp_args.Length_samples = Length_samples;
sp_args.EndTimeS = EndTimeS;

%-------------------------------------------------------------------------%
% End Silbido Spectral Processing Parameters
%-------------------------------------------------------------------------%


% Low resolution search interval
DeltaMS.Low = 500;

% High resolution search interval
DeltaMS.High = 100;

WinS.WindowMin = 5;
WinS.WindowMax = 10;
WinS.Margin = .5;
WinS.Growth = .5;
WinS.Shift = 1;
WinS.Second = 3;

PenaltyWeight = .85;

CSAArgs = {};

PeakDetectorArgs = {'Method', 'regression', 'RegressionOrder', 2};

n=1;
while n <= length(varargin)

    switch varargin{n}
        case 'Delta'
            [DeltaMS.Low, DeltaMS.High] = deal(varargin{n+1}{:});
            n=n+2;
            
        case 'Callback'
            cb = varargin{n+1};
            n=n+2;
        case 'Window'
            [WinS.WindowMin, WinS.Max, WinS.Margin, WinS.Growth, ...
                WinS.Shift, WinS.Second] = deal(varargin{n+1}{:});
            n=n+2;

        case 'Method'
            if iscell(varargin{n+1})
                Methods = varargin{n+1};
            else
                Methods = {varargin{n+1}};
            end
            n=n+2;

            for k=1:length(Methods)
                switch Methods{k}
                    case 'diagonal'
                        CSAArgs{end+1} = Methods{k};
                        CSAArgs{end+1} = 1;
                    case 'full'
                        % do nothing, this is the default
                    otherwise
                        error('Bad method keyword %s', Methods{k});
                end
            end

        case 'PeakSelection'
            if iscell(varargin{n+1})
                PeakDetectorArgs = varargin{n+1};
            else
                error('PeakSelection argument must be a cell array.')
            end
            n=n+2;

        case 'PenaltyWeight',
            PenaltyWeight = varargin{n+1}; n=n+2;

        otherwise
            error('Bad optional argument: "%s"', varargin{n});
    end
end

%  Initialize minimum number of points to use with each type of peak
%  selector, where the number of points was determined based on the
%  mathematics

if length(PeakDetectorArgs) == 2 && strcmp(PeakDetectorArgs(2), 'magnitude')
    MinimumPoints = 1;

elseif length(PeakDetectorArgs) == 2 && strcmp(PeakDetectorArgs(2), 'simple')
    MinimumPoints=1;

elseif length(PeakDetectorArgs) == 4 && cell2mat(PeakDetectorArgs(4)) == 1
    MinimumPoints=3;

elseif length(PeakDetectorArgs) == 4 && cell2mat(PeakDetectorArgs(4)) == 2
    MinimumPoints=7;

else
    error('Bad PeakDetector Cell Array Passed In');
end

% Compute the total number of frames to expext and the number
% of frames per second.
TotalFrames = (EndTimeS - StartTimeS) / Advance_s;
FramesPerSecond = 1 / Advance_s;
fprintf('Frames Per Second: %.2f\n', FramesPerSecond);

% Keep track of the default minimum number of points
% ResetMinPts will be used to reset the minimum number of points for each
% utterance
ResetMinPts = MinimumPoints;

% Reset minimum number of points to default
MinimumPoints = ResetMinPts;

% Convert parameters to samples (frames)
WinFrames = utScaleStruct(WinS, FramesPerSecond);

% Multiply the delta ms by the frames per millisecond
DeltaFrames = utScaleStruct(DeltaMS, FramesPerSecond/1000);

% Convert parameters to secs.
DeltaS = utScaleStruct(DeltaMS,1/1000);

% Ensure correct parameters for cumulative sum approach
trkCSA_ParameterVerify(WinFrames, DeltaFrames);

% The total CSA entries we should expect to process
TotalCSACount = ceil(TotalFrames / DeltaFrames.High);

BlockStartS = StartTimeS;
BlockEndS = BlockStartS + WinS.WindowMax;

% compute cumulative sum approach statistics for the first window
CSA = getSourceData(StartTimeS,WinS.WindowMax,DeltaFrames, CSAArgs, sp_args);
CSACount = length(CSA.SV);

% Convert parameters to multiples of the high resolution sample rate
WinHighUnit = utScaleStruct(WinFrames, 1/DeltaFrames.High);
DeltaHighUnit = utScaleStruct(DeltaFrames, 1/DeltaFrames.High);

% construct time axis
%CenterS = DeltaS.High/2;
time = (0:TotalCSACount)*DeltaS.High; 
time = time + StartTimeS;

% search --------------------------------------------------
Search.Window = trkInitWindow(1, WinHighUnit.WindowMin); % init window
Peaks = [];

% Initialize the first search window.
Search = trkDistBICRange(Search.Window, WinHighUnit.Margin, DeltaHighUnit.Low);
while (Search.Window(end) < TotalCSACount)
    %fprintf('\nLow resolution search started for window: %s\n', searchToStr(Search, time));
    
    % Compute the BIC for the initial low resolution window.
    [maxbic, maxidx, bic] = trkBIC_CSA(CSA, Search, PenaltyWeight);
    if exist('cb','var')
        if maxbic < 0
            cb.onNoCandidateLowRes(time(Search.Range), bic);
        else
            cb.onCandidateLowRes(time(Search.Range), bic);
        end
    end
    

    % If maxbix is negative, we didn't find a change point.  Therefore
    % we start to grow the window.
    while maxbic < 0 && ...
            trkWindowSize(Search.Window) < WinFrames.WindowMax && ...
            Search.Window(end) < TotalCSACount
        % Grow the window making sure not to over run the end of the data.
        Search.Window(end) = min(...
            TotalCSACount, Search.Window(end) + WinHighUnit.Growth);  
        
        Search = trkDistBICRange(...
            Search.Window, WinHighUnit.Margin, DeltaHighUnit.Low);
        
        if Search.Window(end) > CSACount
            [CSA, CSACount, BlockStartS, BlockEndS] = loadNextBlockAndMergeCSA(CSA, BlockEndS, WinS.WindowMax, DeltaFrames, CSAArgs, sp_args);
        end
        
        %fprintf('    No change detected. Growing the low resolution window to: %s\n', searchToStr(Search, time));
        
        [maxbic, maxidx, bic] = trkBIC_CSA(CSA, Search, PenaltyWeight);
        if exist('cb','var')
            if maxbic < 0
                cb.onNoCandidateLowRes(time(Search.Range), bic);
            else
                cb.onCandidateLowRes(time(Search.Range), bic);
            end
        end
    end

    % At this point, if we still have not found anything, it means that
    % we have gown the window to its maximum size, so we start shifting
    % the window to the right in hopes of finding something.
    while maxbic < 0 && Search.Window(end) < TotalCSACount
        % Shift, but not past the end.
        Shift = min(WinHighUnit.Shift, TotalCSACount - Search.Window(2));
        Search.Window = Search.Window + Shift;
        Search = trkDistBICRange(Search.Window, ...
            WinHighUnit.Margin, DeltaHighUnit.Low);
        if Search.Window(end) > CSACount
            [CSA, CSACount, BlockStartS, BlockEndS] = loadNextBlockAndMergeCSA(CSA, BlockEndS, WinS.WindowMax, DeltaFrames, CSAArgs, sp_args);
        end
        %fprintf('    No change detected. Shifting the low resolution window to: (%.2fs - %.2fs)\n', time(Search.Window(1)), time(Search.Window(end)));
        [maxbic, maxidx, bic] = trkBIC_CSA(CSA, Search, PenaltyWeight); 
        if exist('cb','var')
            if maxbic < 0
                cb.onNoCandidateLowRes(time(Search.Range), bic);
            else
                cb.onCandidateLowRes(time(Search.Range), bic);
            end
        end
    end

    
    % If this is true the we found something during the low resolution 
    % search, either through the original window, through goriwng the
    % window, or by shifting the window.
    if (maxbic > 0)
        % determine search size
        % Added constraint to reduce window size when near end of stream
        NewSize = min([trkWindowSize(Search.Window), WinHighUnit.Second, ...
            (TotalCSACount - maxidx) * 2]);

        % center the window on the hypthosesis
        Search.Window = trkInitWindow(...
            max(1, maxidx - floor(NewSize/2)), NewSize);

        Search = trkDistBICRange(...
            Search.Window, WinHighUnit.Margin, DeltaHighUnit.High);

        % Adjust search taking into account overlapping into previous
        % changepoint, as well as being at the end and beginning of an
        % utterance
        [Search, TimeInPastEnd, ShiftlftClear, LeftNeed] = ...
            trkWindowAdjust(Search, WinHighUnit, Peaks, ...
            DeltaHighUnit, TotalCSACount,MinimumPoints);
        
        if Search.Window(end) > CSACount && Search.Window(end) < TotalCSACount
            [CSA, CSACount, BlockStartS, BlockEndS] = loadNextBlockAndMergeCSA(CSA, BlockEndS, WinS.WindowMax, DeltaFrames, CSAArgs, sp_args);
        end

        %fprintf('    Candidate change detected at %.2fs. Performing high resolution search in window: %s\n', time(maxidx), searchToStr(Search, time));
        
        [~, ~, bic2] = trkBIC_CSA(CSA, Search, PenaltyWeight);
        
        % Examine the results to see if a change is confirmed.
        if (TimeInPastEnd > 0) && (ShiftlftClear < 0) || ((TotalCSACount - Search.Window(end)) < 2)
            % Use Magnitude not enought points for any other method
            PeakList = spPeakSelector(bic2, 'Method', 'magnitude');
            [maxbic2, maxidx2] = max(bic2(PeakList));
            maxidx2 = Search.Range(PeakList(maxidx2));
        elseif (TimeInPastEnd > 0) && (ShiftlftClear > 0)
            % Shift over to the right and use Peak selected by user
            Search.Window(1) = Search.Window(1) - LeftNeed;

            Search = trkDistBICRange(Search.Window, ...
                WinHighUnit.Margin, ...
                DeltaHighUnit.High);
            
            if Search.Window(end) > CSACount
                [CSA, CSACount, BlockStartS, BlockEndS] = loadNextBlockAndMergeCSA(CSA, BlockEndS, WinS.WindowMax, DeltaFrames, CSAArgs, sp_args);
            end

            [~, ~, bic2] = trkBIC_CSA(CSA, Search, PenaltyWeight);
            
            PeakList = spPeakSelector(bic2, PeakDetectorArgs{:});
            [maxbic2, maxidx2] = max(bic2(PeakList));
            maxidx2 = Search.Range(PeakList(maxidx2));
        else
            PeakList = spPeakSelector(bic2, PeakDetectorArgs{:});
            [maxbic2, maxidx2] = max(bic2(PeakList));
            maxidx2 = Search.Range(PeakList(maxidx2));
        end

        
        if maxbic2 > 0
            %fprintf('    Change confirmed at %.2fs: \n', time(maxidx2));
            if exist('cb','var')
                cb.onConfirmedHighRes(time(Search.Range), bic2);
            end
            % still think we have one, so we will position the window just
            % after the detection, and reset to window min.
            Peaks(end+1) = maxidx2;
            Search.Window = trkInitWindow(maxidx2+1, WinHighUnit.WindowMin);
        else
            %fprintf('    Change not confirmed.\n');
            if exist('cb','var')
                cb.onUnconfirmedHighRes(time(Search.Range), bic2);
            end
            
            % Shift when the maxbic2 found is actually a negative value
            % Shift window so that it goes half of the margin size past
            % the last change point for maxbic2.
            if ~isempty(maxidx2) && (maxidx2 > maxidx)
                Search.Window(1) = maxidx2 + 1;
                Search.Window(2) = Search.Window(1) + WinHighUnit.WindowMin;
                Search = trkDistBICRange(Search.Window, ...
                    WinHighUnit.Margin, DeltaHighUnit.Low);

                % Precaution used to check for being at the end and overlap into prior
                % change point
                [Search, TimeInPastEnd, ShiftlftClear, LeftNeed] = ...
                    trkWindowAdjust(Search, WinHighUnit, Peaks, ...
                    DeltaHighUnit, TotalCSACount,MinimumPoints);
            else
                if (maxidx == Search.Range(1))
                    maxidx = maxidx + 1;
                end
               
                Search.Window = trkInitWindow(maxidx - WinHighUnit.Margin + 1, WinHighUnit.WindowMin);
                Search = trkDistBICRange(Search.Window, ...
                    WinHighUnit.Margin, DeltaHighUnit.Low);

                % Precaution used to check for being at the end and overlap into prior
                % change point
                [Search, TimeInPastEnd, ShiftlftClear, LeftNeed] = ...
                    trkWindowAdjust(Search, WinHighUnit, Peaks, ...
                    DeltaHighUnit, TotalCSACount,1);
            end
        end
        
        Search = trkDistBICRange(Search.Window, WinHighUnit.Margin, DeltaHighUnit.Low);
        
        if Search.Window(end) > CSACount && Search.Window(end) < TotalCSACount
            [CSA, CSACount, BlockStartS, BlockEndS] = loadNextBlockAndMergeCSA(CSA, BlockEndS, WinS.WindowMax, DeltaFrames, CSAArgs, sp_args);
        end
    end
end
if exist('cb','var')
    cb.updateChanges(time(Peaks));
end
changes = time(Peaks);

function str = searchToStr(Search, time)
    str = sprintf('[%.2f|%.2f|%.2f|%.2f]', ...
        time(Search.Window(1)), time(Search.Range(1)), ...
        time(Search.Range(end) + 1), time(Search.Window(end) + 1));
    

function CSA = getSourceData(start_s, length_s, DeltaFrames, CSAArgs, sp_args) 
    fprintf('loading block at %f\n', start_s);
    [~, power_dB, ~, ~, ~, ~] = dtProcessBlock(...
        sp_args.handle, sp_args.header, sp_args.channel, ...
        start_s, length_s, [sp_args.Length_samples, sp_args.Advance_samples], ...
        'Pad', 0, 'Range', sp_args.range_bins, ...
        'Shift', sp_args.shift_samples, ...
        'ClickP', [sp_args.thr.broadband * sp_args.range_binsN, sp_args.thr.click_dB], ...
        'RemoveTransients', false, ...
        'RemovalMethod', '', ...
        'Noise', {sp_args.NoiseSub});
    
    CSA = trkCSA(power_dB', DeltaFrames.High, CSAArgs{:});
    
function CSA = mergeCSA(existingCSA, newCSA)
    CSA = struct();
    CSA.SV = vertcat(existingCSA.SV,newCSA.SV);
    CSA.SQ = vertcat(existingCSA.SQ,newCSA.SQ);
    CSA.Ranges = vertcat(existingCSA.Ranges,newCSA.Ranges);
    CSA.N = existingCSA.N;
    CSA.Dim = existingCSA.Dim;
    CSA.Diagonalize = existingCSA.Diagonalize;
    

function [CSA, CSACount, BlockStartS, BlockEndS] = loadNextBlockAndMergeCSA(existingCSA, BlockEndS, BlockLengthS, DeltaFrames, CSAArgs, sp_args)
    BlockStartS = BlockEndS + sp_args.Advance_s;
    BlockLengthS = min(BlockLengthS, sp_args.EndTimeS - BlockStartS);
    BlockEndS = BlockStartS + BlockLengthS;
    
    newCSA = getSourceData(BlockStartS, BlockLengthS, DeltaFrames, CSAArgs, sp_args);
    CSA = mergeCSA(existingCSA, newCSA);
    CSACount = length(CSA.SV);

