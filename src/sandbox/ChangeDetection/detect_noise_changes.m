%% This file is not real.

function changes = detect_noise_changes(SourceData, FramesPerSecond, StartTime, varargin)
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


% Keep track of the default minimum number of points
% ResetMinPts will be used to reset the minimum number of points for each
% utterance
ResetMinPts = MinimumPoints;


% Reset minimum number of points to default
MinimumPoints = ResetMinPts;



%-------------------------------------------------------------------------%
% End Silbido Spectral Processing Parameters
%-------------------------------------------------------------------------%

%Frames Per Second
fprintf('Frames Per Second: %.2f\n', FramesPerSecond);

% Convert parameters to samples (frames)
WinFrames = utScaleStruct(WinS, FramesPerSecond);

% Multiply the delta ms by the frames per millisecond
DeltaFrames = utScaleStruct(DeltaMS, FramesPerSecond/1000);

% Convert parameters to secs.
DeltaS = utScaleStruct(DeltaMS,1/1000);

% Ensure correct parameters for cumulative sum approach
trkCSA_ParameterVerify(WinFrames, DeltaFrames);

% compute cumulative sum approach statistics
CSA = trkCSA(SourceData, DeltaFrames.High, CSAArgs{:});
CSACount = length(CSA.SQ);

% Convert parameters to multiples of the high resolution sample rate
WinHighUnit = utScaleStruct(WinFrames, 1/DeltaFrames.High);
DeltaHighUnit = utScaleStruct(DeltaFrames, 1/DeltaFrames.High);

% construct time axis
%CenterS = DeltaS.High/2;
time = (0:CSACount)*DeltaS.High; 
time = time + StartTime;

% search --------------------------------------------------
Search.Window = trkInitWindow(1, WinHighUnit.WindowMin); % init window
Peaks = [];

% Initialize the first search window.
Search = trkDistBICRange(Search.Window, WinHighUnit.Margin, DeltaHighUnit.Low);
while (Search.Window(end) < CSACount)
    fprintf('\nLow resolution search started for window: %s\n', searchToStr(Search, time));
    
    % Compute the BIC for the initial low resolution window.
    [maxbic, maxidx, bic] = trkBIC_CSA(CSA, Search, PenaltyWeight);
    if maxbic < 0
        cb.onNoCandidateLowRes(time(Search.Range), bic);
    else
        cb.onCandidateLowRes(time(Search.Range), bic);
    end
    

    % If maxbix is negative, we didn't find a change point.  Therefore
    % we start to grow the window.
    while maxbic < 0 && ...
            trkWindowSize(Search.Window) < WinFrames.WindowMax && ...
            Search.Window(end) < CSACount
        % Grow the window making sure not to over run the end of the data.
        Search.Window(end) = min(...
            CSACount, Search.Window(end) + WinHighUnit.Growth);
        Search = trkDistBICRange(...
            Search.Window, WinHighUnit.Margin, DeltaHighUnit.Low);
        
        fprintf('    No change detected. Growing the low resolution window to: %s\n', searchToStr(Search, time));
        
        [maxbic, maxidx, bic] = trkBIC_CSA(CSA, Search, PenaltyWeight);
        if maxbic < 0
            cb.onNoCandidateLowRes(time(Search.Range), bic);
        else
            cb.onCandidateLowRes(time(Search.Range), bic);
        end
    end

    % At this point, if we still have not found anything, it means that
    % we have gown the window to its maximum size, so we start shifting
    % the window to the right in hopes of finding something.
    while maxbic < 0 && Search.Window(end) < CSACount
        % Shift, but not past the end.
        Shift = min(WinHighUnit.Shift, CSACount - Search.Window(2));
        Search.Window = Search.Window + Shift;
        Search = trkDistBICRange(Search.Window, ...
            WinHighUnit.Margin, DeltaHighUnit.Low);
        fprintf('    No change detected. Shifting the low resolution window to: (%.2fs - %.2fs)\n', time(Search.Window(1)), time(Search.Window(end)));
        [maxbic, maxidx, bic] = trkBIC_CSA(CSA, Search, PenaltyWeight); 
        if maxbic < 0
            cb.onNoCandidateLowRes(time(Search.Range), bic);
        else
            cb.onCandidateLowRes(time(Search.Range), bic);
        end
    end

    
    % If this is true the we found something during the low resolution 
    % search, either through the original window, through goriwng the
    % window, or by shifting the window.
    if (maxbic > 0)
        % determine search size
        % Added constraint to reduce window size when near end of stream
        NewSize = min([trkWindowSize(Search.Window), WinHighUnit.Second, ...
            (CSACount - maxidx) * 2]);

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
            DeltaHighUnit, CSACount,MinimumPoints);

        fprintf('    Candidate change detected at %.2fs. Performing high resolution search in window: %s\n', time(maxidx), searchToStr(Search, time));
        
        [~, ~, bic2] = trkBIC_CSA(CSA, Search, PenaltyWeight);
        
        % Examine the results to see if a change is confirmed.
        if (TimeInPastEnd > 0) && (ShiftlftClear < 0) || ((CSACount - Search.Window(end)) < 2)
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
            fprintf('    Change confirmed at %.2fs: \n', time(maxidx2));
            cb.onConfirmedHighRes(time(Search.Range), bic2);
            % still think we have one, so we will position the window just
            % after the detection, and reset to window min.
            Peaks(end+1) = maxidx2;
            Search.Window = trkInitWindow(maxidx2+1, WinHighUnit.WindowMin);
        else
            fprintf('    Change not confirmed.\n');
            cb.onUnconfirmedHighRes(time(Search.Range), bic2);
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
                    DeltaHighUnit, CSACount,MinimumPoints);
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
                    DeltaHighUnit, CSACount,1);
            end
        end
        
        Search = trkDistBICRange(Search.Window, WinHighUnit.Margin, DeltaHighUnit.Low);
       
    end
end
cb.updateChanges(time(Peaks));
fprintf('\nDetected changes: ')
disp(time(Peaks));
changes = Peaks;

function str = searchToStr(Search, time)
    str = sprintf('[%.2f|%.2f|%.2f|%.2f]', ...
        time(Search.Window(1)), time(Search.Range(1)), ...
        time(Search.Range(end) + 1), time(Search.Window(end) + 1));
