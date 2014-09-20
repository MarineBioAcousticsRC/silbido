function trkCettoloV3(SourceData, varargin)
% trkCettolo(SourceData, varargin)
%
% Optional arguments:
% 'Tolerance', Secs
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
%       Second - Something to do with centering window, update
%               comment later.
% 'Method', {'full' (default), 'diagonal', 'adapt'}
%
%
%       feature vector sample rate and HighMS
% Initialize defaults

% for debugging
global data

DefaultType = 'conversational';
switch DefaultType
    case 'conversational'
        % Cettolo defaults for NIST data

        DeltaMS.Low = 250;
        DeltaMS.High = 50;

        PenaltyWeight = .85;

        WinS.WindowMin = 2;
        WinS.WindowMax = 5;
        WinS.Margin = .5;
        WinS.Growth = .5;
        WinS.Shift = 1;
        WinS.Second = 4;

    otherwise
        error('Defaults not availble for type %s', DeafultType);
end


Prior = [];
CSAArgs = {};
Method = 'bic';
FilterType = 'none';
FilterArgs = {[3.25, 3.5]};
Display = 0;
Keyboard = 0;	% Pause in debug mode?
Bayesian = 'mean';%'mode'; 
PeakDetectorArgs = {'Method', 'regression', 'RegressionOrder', 2};
%seg length in computation of priors
SegmentLength = -1;
FeatureString = 'sw%s.mfc';     % format feature filename
ToleranceS = .5;                % tolerance for correctness
TruthString = 'sw%s.csv';       % format truth filename

LineSpecs = {'b', 'm', 'r', 'k','g', 'c','y', 'm^', 'r^', 'k^'};
Handles = [];
% Used with trkPlot
Compare = 0;
n=1;
while n <= length(varargin)

    switch varargin{n}
        case 'Tolerance'
            ToleranceS = varargin{n+1}; n=n+2;

        case 'Delta'
            [DeltaMS.Low, DeltaMS.High] = deal(varargin{n+1}{:});
            n=n+2;

        case 'Window'
            [WinS.WindowMin, WinS.Max, WinS.Margin, WinS.Growth, ...
                WinS.Shift, WinS.Second] = deal(varargin{n+1}{:});
            n=n+2;

        case 'Bayesian'
            Bayesian = varargin{n+1}; n=n+2;

        case 'Display',
            Display = varargin{n+1}; n=n+2;

        case 'FilterType'
            FilterType = varargin{n+1}; n=n+2;

        case 'Keyboard'
            Keyboard = varargin{n+1}; n=n+2;

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

        case 'Prior'
            Prior = varargin{n+1}; n=n+2;

        otherwise
            error(sprintf('Bad optional argument: "%s"', varargin{n}));
    end
end
%  Initialize minimum number of points to use with each type of peak
%  selector, where the number of points was determined based on the
%  mathematics

if length(PeakDetectorArgs) == 2 & strcmp(PeakDetectorArgs(2), 'magnitude')
    MinimumPoints = 1;

elseif length(PeakDetectorArgs) == 2 & strcmp(PeakDetectorArgs(2), 'simple')
    MinimumPoints=1;

elseif length(PeakDetectorArgs) == 4 & cell2mat(PeakDetectorArgs(4)) == 1
    MinimumPoints=3;

elseif length(PeakDetectorArgs) == 4 & cell2mat(PeakDetectorArgs(4)) == 2
    MinimumPoints=7;

else
    error(sprintf('Bad PeakDetector Cell Array Passed In'));
end

%  For MAP adaptation
if ~ isempty(Prior)
    Prior.Statistic = Bayesian;
end

% hardcoded information --------------------
Corpus = 'spidre';
FeatureFormat = 'htk';

% prior data
PriorPath = '/lab/speech/corpora/swb2/cep/';

out=1;     % Output handle (1=stdout, 2=stderr, or fopen result)

UtteranceCount = length(SourceData);

% Build appropriate filter if needed

if strcmp(FilterType, 'lowpass')
    % build a low-pass filter for the BIC
    BPFilter = spBuildLP(FilterArgs{1}, SampleRate, [1, 0], [1, 18]);
end

Test = trkInitTest(ToleranceS);     % data structure describing test types

% Initialize counters
Results = trkInitCounts(Test, UtteranceCount);

%Print Window Size
fprintf('Minimun Window Size %d \n', WinS.WindowMin*1000);
fprintf('Tolerance:  %d \n', ToleranceS);

Current = 0;

fprintf(out, 'Test date: %s \n',datestr(date,1));

fprintf(out, 'Token\tAllCat\t\t\tChangePt\t\tOverlap\t\t\tPause\t\t\tFalse Positive\n');

% Track time used from here on
StartWallClock = clock;
StartCPUClock = cputime;

% Keep track of the default minimum number of points
% ResetMinPts will be used to reset the minimum number of points for each
% utterance
ResetMinPts = MinimumPoints;

for utterance=1:UtteranceCount

    % prepare --------------------------------------------------
    % Reset vectors for this utterance
    bic2 = [];  % kludge for plotting comparisons

    % Reset minimum number of points to default
    MinimumPoints = ResetMinPts;

    [data, cepSpcMS] = trkReadFeatures(Corpus, SourceData{utterance}, ...
        FeatureFormat, FeatureString);
    Energy = data(:,1);
    data(:,1) = [];     % assume energy in feature set and remove it

    SampleRate = 1000 / cepSpcMS;
    if isempty(data)
        warning('Utterance %s:  cannot find data', SourceData{utterance})
        continue
    end

    [VectorCount, Dim] = size(data);
    % Convert parameters to samples
    WinSamp = utScaleStruct(WinS, SampleRate);
    DeltaSamp = utScaleStruct(DeltaMS, SampleRate/1000);
    % Convert parameters to secs.
    DeltaS = utScaleStruct(DeltaMS,1/1000);

    % Read in ground truth
    Truth = trkReadTruth(Corpus, SourceData{utterance}, TruthString, Test, DeltaS);

    % Ensure correct parameters for cumulative sum approach
    trkCSA_ParameterVerify(WinSamp, DeltaSamp);

    % compute cumulative sum approach statistics
    CSA = trkCSA(data, DeltaSamp.High, CSAArgs{:});
    CSACount = length(CSA.SQ);

    % Convert parameters to multiples of the high resolution sample rate
    WinHighUnit = utScaleStruct(WinSamp, 1/DeltaSamp.High);
    DeltaHighUnit = utScaleStruct(DeltaSamp, 1/DeltaSamp.High);

    % construct time axis
    CenterS = DeltaS.High/2;
    time = (0:CSACount-1)*DeltaS.High + CenterS;

    % search --------------------------------------------------
    Search.Window = trkInitWindow(1, WinHighUnit.WindowMin); % init window
    Peaks = [];
    if Display
        figure('Name', sprintf('%s in %s', SourceData{utterance}, Corpus));
        trkPlot(1);
        hold on
    end
    Search = trkDistBICRange(Search.Window, ...
        WinHighUnit.Margin, DeltaHighUnit.Low);
    while (Search.Window(end) < CSACount)

        %         Search.Range = trkDistBICRange(Search.Window, ...
        %       adapt      WinHighUnit.Margin, DeltaHighUnit.Low);

        if ~isempty(Prior)
            [maxbic, maxidx, bic] = trkBIC_CSA(CSA, Search, PenaltyWeight, Prior);
        else
            [maxbic, maxidx, bic] = trkBIC_CSA(CSA, Search, PenaltyWeight);
        end

        if Display

            trkPlot(0, maxidx, time, Search, bic, Test, Truth, 1, Compare);
        end

        % if nothing found, grow window
        GrowthCount = 0;
        while maxbic < 0 & ...
                trkWindowSize(Search.Window) < WinSamp.WindowMax & ...
                Search.Window(end) < CSACount
            % Grow, but not past the end
            Search.Window(end) = min(CSACount, Search.Window(end) + WinSamp.Growth);
            Search = trkDistBICRange(Search.Window, ...
                WinHighUnit.Margin, DeltaHighUnit.Low);
            if ~isempty(Prior)
                [maxbic, maxidx, bic] = trkBIC_CSA(CSA, Search, PenaltyWeight, Prior);
            else
                [maxbic, maxidx, bic] = trkBIC_CSA(CSA, Search, PenaltyWeight);
            end

            if Display
                trkPlot(0, maxidx, time, Search, bic, Test, Truth, 1, Compare);
            end
            GrowthCount = GrowthCount + 1;
            if Keyboard && GrowthCount > 10
                GrowthCount = 0;
                keyboard;
            end
        end

        % if nothing found, shift
        while maxbic < 0 & Search.Window(end) < CSACount
            % Shift, but not past the end.
            Shift = min(WinHighUnit.Shift, CSACount - Search.Window(2));
            Search.Window = Search.Window + Shift;
            Search = trkDistBICRange(Search.Window, ...
                WinHighUnit.Margin, DeltaHighUnit.Low);
            if ~isempty(Prior)
                [maxbic, maxidx, bic] = trkBIC_CSA(CSA, Search, PenaltyWeight, Prior);
            else
                [maxbic, maxidx, bic] = trkBIC_CSA(CSA, Search, PenaltyWeight);
            end

            if Display
                trkPlot(0, maxidx, time, Search, bic, Test, Truth,1, Compare);
            end
        end

        % found something... 2nd high resolution search
        if (maxbic > 0)
            % determine search size
            % Added constraint to reduce window size when near end of stream
            NewSize = min([trkWindowSize(Search.Window), WinHighUnit.Second, ...
                (CSACount - maxidx) * 2]);

            % center the window on the hypthosesis
            Search.Window = trkInitWindow(...
                max(1, maxidx - floor(NewSize/2)), NewSize);

            Search = trkDistBICRange(Search.Window, ...
                WinHighUnit.Margin, ...
                DeltaHighUnit.High);

            % Adjust search taking into account overlapping into previous
            % changepoint, as well as being at the end and beginning of an
            % utterance
            [Search, TimeInPastEnd, ShiftlftClear, LeftNeed] = ...
                trkWindowAdjust(Search, WinHighUnit, Peaks, ...
                DeltaHighUnit, CSACount,MinimumPoints);

            % Search
            if ~isempty(Prior)
                [maxbic2, maxidx2, bic2] = trkBIC_CSA(CSA, Search, PenaltyWeight, Prior);
            else
                [maxbic2, maxidx2, bic2] = trkBIC_CSA(CSA, Search, PenaltyWeight);
            end
            if (TimeInPastEnd > 0) & (ShiftlftClear < 0) | ((CSACount - Search.Window(end)) < 2)
                % Use Magnitude not enought points for any other method
                PeakList = spPeakSelector(bic2, 'Method', 'magnitude');
                [maxbic2 maxidx2] = max(bic2(PeakList));
                maxidx2 = Search.Range(PeakList(maxidx2));

            elseif (TimeInPastEnd > 0) & (ShiftlftClear > 0)
                % Shift over to the right and use Peak selected by user
                Search.Window(1) = Search.Window(1) - LeftNeed;

                Search = trkDistBICRange(Search.Window, ...
                    WinHighUnit.Margin, ...
                    DeltaHighUnit.High);
                % Search
                if ~isempty(Prior)
                    [maxbic2, maxidx2, bic2] = trkBIC_CSA(CSA, Search, PenaltyWeight, Prior);
                else
                    [maxbic2, maxidx2, bic2] = trkBIC_CSA(CSA, Search, PenaltyWeight);
                end
                PeakList = spPeakSelector(bic2, PeakDetectorArgs{:});
                % end ----changed May27th----
                [maxbic2 maxidx2] = max(bic2(PeakList));
                maxidx2 = Search.Range(PeakList(maxidx2));
            else
                PeakList = spPeakSelector(bic2, PeakDetectorArgs{:});
                % end ----changed May27th----
                [maxbic2 maxidx2] = max(bic2(PeakList));
                maxidx2 = Search.Range(PeakList(maxidx2));
            end
            if Display
                trkPlot(0, maxidx2, time, Search, bic2, Test, Truth,1, Compare);
            end
            if maxbic2 > 0
                % still think we have one...
                Peaks(end+1) = maxidx2;
                Search.Window = trkInitWindow(maxidx2+1, WinHighUnit.WindowMin);
            else

                % Shift when the maxbic2 found is actually a negative value
                % Shift window so that it goes half of the margin size past
                % the last change point for maxbic2.
                if ~isempty(maxidx2) & (maxidx2 > maxidx)
                    WindWidth = Search.Window(2) - Search.Window(1);
                    Search.Window(1) = maxidx2 + 1;
                    Search.Window(2) = Search.Window(1) + WindWidth;
                    Search = trkDistBICRange(Search.Window, ...
                        WinHighUnit.Margin, DeltaHighUnit.Low);
                    
                    % Precaution used to check for being at the end and overlap into prior
                    % change point
                    [Search, TimeInPastEnd, ShiftlftClear, LeftNeed] = ...
                        trkWindowAdjust(Search, WinHighUnit, Peaks, ...
                        DeltaHighUnit, CSACount,MinimumPoints);
                else
                    WindWidth = Search.Window(2) - Search.Window(1);
                    Search.Window(1) = maxidx + 1;
                    Search.Window(2) = Search.Window(1) + WindWidth;
                    Search = trkDistBICRange(Search.Window, ...
                        WinHighUnit.Margin, DeltaHighUnit.Low);

                    % Precaution used to check for being at the end and overlap into prior
                    % change point
                    [Search, TimeInPastEnd, ShiftlftClear, LeftNeed] = ...
                        trkWindowAdjust(Search, WinHighUnit, Peaks, ...
                        DeltaHighUnit, CSACount,MinimumPoints);
                end
            end
            Search = trkDistBICRange(Search.Window, ...
                WinHighUnit.Margin, DeltaHighUnit.Low);
            if Keyboard
                fprintf('High resolution search complete: ');
                if maxbic2 > 0
                    fprintf('Change point found at %d (%.2f s.)\n', maxidx2, time(maxidx2));
                else
                    fprintf('No changepoint found\n');
                end
                fprintf('New search:\n')
                Search
                keyboard
            end
        end
    end
    % analyze --------------------------------------------------

    Results = trkAnalyzeResults(utterance, time(Peaks), Truth, Test, Results);

    % Determine how many unclassified points there were so that we can
    % compute the false postive rate.
    [PossibleHits, PossibleMisses] = trkFrameClass(time, Truth.Front, Truth.Back, ...
        Test.ToleranceS);
    Results.NoChangeClassCount(utterance) = length(PossibleMisses);

    % print file id and results
    fprintf(out, '%s\t', SourceData{utterance});
    for type=[Test.TypeCount+1, 1:Test.TypeCount]
        fprintf(out, '%s\t', trkReportStat(Results.Correct(utterance,type), ...
            Results.Actual(utterance,type), 1));
    end
    fprintf(out, '%s\n', trkReportStat(Results.FalsePositives(utterance), ...
        Results.NoChangeClassCount(utterance)));


end % end for utterance


% All done, save time
ElapsedWallClock = etime(clock, StartWallClock);
ElapsedCPUClock = cputime - StartCPUClock;

% Final report ----------------------------------------

fprintf('Elapsed wall clock time: %s\n', ...
    sectohhmmss(ElapsedWallClock));
fprintf('Elapsed CPU time: %s\n', sectohhmmss(ElapsedCPUClock));

% dump parameters
DeltaMS
WinS

CorrectAll = sum(Results.Correct(:,end));
Insertions = sum(Results.FalsePositives);
Deletions = sum(Results.Actual(:,end) - Results.Correct(:,end));
fprintf('Precision %.2f%%\tRecall %.2f%%\n', ...
    CorrectAll / (CorrectAll + Insertions) * 100, ...
    CorrectAll / (CorrectAll + Deletions) * 100);



fprintf('Overall ERROR RATES\n');
fprintf(out, ['Easy cut/paste:  method, tolerance, penalty ', ...
    'all, change, overlap, pause, false+ \n']);
Method='DIST-BIC';
PeakDetectorArgs{2} = 'none';
fprintf(out, '%s\t%.2f\t%.2f\t', Method, Test.ToleranceS, ...
    PenaltyWeight);
for type=[Test.TypeCount+1, 1:Test.TypeCount]
    fprintf(out, '%.2f\t', ...
        (1 - sum(Results.Correct(:,type))/sum(Results.Actual(:,type)))*100)
end
fprintf(out, '%.2f\n', sum(Results.FalsePositives) / ...
    sum(Results.NoChangeClassCount) * 100);


fprintf(out, 'AllCat\t\t\tChangePt\t\tOverlap\t\t\tPause\t\t\tFalse Positive\n');
for type=[Test.TypeCount+1, 1:Test.TypeCount]
    fprintf(out, '%s\t', trkReportStat(sum(Results.Correct(:,type)), ...
        sum(Results.Actual(:,type)), 1));
end
fprintf(out, '%s\n', trkReportStat(sum(Results.FalsePositives), ...
    sum(Results.NoChangeClassCount)));

% Statistics on per utterance stats
fprintf('type\tmin\tmax\tvar\n');
for type=[Test.TypeCount+1, 1:Test.TypeCount]
    Denominator = Results.Actual(:,type);
    Denominator(find(Denominator == 0)) = 1;       % eliminate / 0
    ErrorRates = (Results.Actual(:,type) - Results.Correct(:,type)) ./ ...
        Denominator * 100;
    fprintf(out, '%s\t', Test.Labels{type});
    fprintf(out, '%.3f\t', min(ErrorRates), max(ErrorRates), ...
        var(ErrorRates))
    fprintf(out, '\n');
end

Denominator = Results.NoChangeClassCount';
Denominator(find(Denominator == 0)) = 1;        % eliminate / 0
ErrorRates = Results.FalsePositives ./ Denominator * 100;
fprintf(out, 'False+\t');
fprintf(out, '%.3f\t', min(ErrorRates), max(ErrorRates), ...
    var(ErrorRates))
fprintf(out, '\n');

fprintf(out, 'Duplicate counts table\n')
Results.DuplicateCounts
fprintf(out, 'Duplicate counts percentages\n')
DupCounts = repmat(sum(Results.DuplicateCounts,2), 1, ...
    size(Results.DuplicateCounts, 2));
Results.DuplicateCounts ./ DupCounts