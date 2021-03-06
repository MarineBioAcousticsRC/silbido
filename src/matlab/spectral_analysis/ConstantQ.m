%
% ConstantQ.m
%

classdef ConstantQ < handle
    properties (Access = public)
        fileFs;
        topOctaveRatio;
        initDSTimes = 0;
        resampleFs;
                
        inputBuffer;
        circBuffer;
        octaveSet;
        topOctave;
        octaveSetStart = 1000; 
        
        halfband;
        bandpass;
        halfbandStates;
        bandpassStates;
        
        filtersPerOctave;
        centerFreqRatios;
        bandwidthRatios;
        
        frameSize;
        polyCoefficients;
        kaiserWindow;
        
        centerFreqs;
        freqEstimations;
        
        init = true;
        linearEvalPoints;
        windowWeights;
    end
    methods
        
        function object = ConstantQ(freqLow, freqHigh, fileFs, frameSize, varargin)
            % Ensure proper input
            setFreqMin = object.octaveSetStart;
            setFreqMax = fileFs * (2/6); % Upper limit as reccomended in the lodermilk paper.
            if ((freqHigh < setFreqMin) || (freqHigh > setFreqMax) || (freqHigh < freqLow))
                error(['Invalid value for freqHigh. Must be greater than or equal to ' num2str(setFreqMin) ...
                    ' Hz, and less than or equal to ' num2str(setFreqMax) ' Hz. This value must also be greater than or equal to freqLow' ]);
            end
            if ((freqLow < setFreqMin) || (freqLow > setFreqMax) || (freqLow > freqHigh))
                error(['Invalid value for freqLow. Must be greater than or equal to ' num2str(setFreqMin) ...
                    ' Hz, and less than or equal to ' num2str(setFreqMax) ' Hz. This value must also be less than or equal to freqHigh' ]);
            end
            if (fileFs <= 0)
               error('fileFs must be greater than 0'); 
            end
            
            object.frameSize = frameSize;
            
            % Set defaults for variable arguments.
            object.filtersPerOctave = 100;
            
            % Parse variable arguments.
            v=1;
            while v <= length(varargin)
                switch varargin{v}
                    case 'numFilters'
                        object.filtersPerOctave = varargin{v+1}; v=v+2;
                    otherwise
                        try
                            if isnumeric(varargin{v})
                                errstr = sprintf('Bad option: %f', varargin{v});
                            else
                                errstr = sprintf('Bad option: %s', char(varargin{v}));
                            end
                        catch e
                            errstr = sprintf('Bad option in %d''optional argument: %s', v, e.message);
                        end
                        error('ConstantQ: %s', errstr);
                end
            end
            
            % Account for non-natural sampling rate.
            fileFs = round(fileFs);
            % Store as property to be later referenced in processFrame().
            object.fileFs = fileFs;
            
            % Set up "default" octave sets. Calculate as many needed to
            % cover the user-requested frequency range.
            octaveStart = object.octaveSetStart;
            octaveEnd = octaveStart * 2;
            i = 1;
            while (freqHigh >= octaveStart)
                object.octaveSet(i,1) = octaveStart;
                object.octaveSet(i,2) = octaveEnd;
                octaveStart = octaveEnd;
                octaveEnd = octaveStart * 2;
                i = i + 1;
            end
               
            % Remove any lower frequency octaves that fall under the
            % user requested frequency range.
            while (size(object.octaveSet,1) ~= 0) && (freqLow >= object.octaveSet(1,2))
               object.octaveSet = object.octaveSet(1+1:end,:); 
            end
            
            % Remove any high-end octaves which fall above the user
            % requested frequency range.
            while (size(object.octaveSet,1) ~= 0) && (freqHigh <= object.octaveSet(end,1))
                % Handle edge case: freqLow is equal to freqHigh --
                % removing an octave at this point would result in an empty
                % octaveSet, so just break instead.
                if (freqLow == freqHigh)
                    break;
                end
               object.octaveSet = object.octaveSet(1:end-1,:); 
            end
            
            % Remove any octaves that contain frequencies greater than
            % setFreqMax.
            while (size(object.octaveSet,1) ~= 0) && (setFreqMax < object.octaveSet(end,end))
                object.octaveSet = object.octaveSet(1:end-1,:);
            end
            
            % If octaveSet is empty, the user-requested range is too small
            % to result in any octave sets.
            if (size(object.octaveSet,1) == 0)
               error('Input frequency range is too small. No ''default'' octave sets have been produced.'); 
            end
                                 
            object.topOctave = [object.octaveSet(end,1) object.octaveSet(end,2)];
            topOctaveBandwidth = object.topOctave(2) - object.topOctave(1);
            topOctaveCenter = object.topOctave(1) + topOctaveBandwidth/2;

            % The required sampling rate necessary for subsequent 4:1
            % downsampling to work properly.
            requiredFs = topOctaveCenter * 4;
            
            object.topOctaveRatio = object.topOctave / requiredFs;
                        
            % (Redundantly?) Ensure that the initial sample rate
            % is indeed greater or equal to the requiredFs.
            if (fileFs < requiredFs)
               error('Sampling rate is too low for requested frequency range. Decrease the freqHigh input parameter');
            end
            
            % Determine the resampleFs that the fileFs first has to be
            % resampled to before undergoing initial 2:1 downsampling.
            object.resampleFs = requiredFs;
            while (object.resampleFs*2 <= fileFs)
                object.resampleFs = object.resampleFs * 2;
                % Record the number of times to later perform 2:1
                % downsampling after performing the non-integer resampling
                % of fileFs to resampleFs.
                object.initDSTimes = object.initDSTimes + 1;
            end
            
                 
            % Create halfband filter.
            nyquist = requiredFs/2;
            halfbandOrder = 36;
            object.halfband = firpm(halfbandOrder,[0 object.topOctave(1) object.topOctave(2) nyquist]/nyquist,{@myfrf,[1 1 0 0]},[1 5]);
            
            % Create bandpass filter.
            heterodyneRatio = topOctaveCenter / requiredFs;
            bandpassOrder = 74;
            object.bandpass = firpm(bandpassOrder,[0 topOctaveBandwidth/2 topOctaveBandwidth nyquist]/nyquist,{@myfrf,[1 1 0 0]},[1 10]) ...
                 .* exp(1i*2*pi*(3:77)*heterodyneRatio);
             
            % Calculate number of octaves needed (circBuffer rows) and
            % number of times needed (circBuffer cols) to provide enough
            % data for the lowest octave's DFT.
            numOctaves = size(object.octaveSet,1);
            numTimes = 2^(numOctaves-1);
            
            % Array holding the inputs for each octave. While not
            % necessary, this array exists for transparency in
            % testing/debugging.
            object.inputBuffer = cell(numOctaves,1);
            [object.inputBuffer{:}] = deal(struct('data',[],'Fs',0));
            
            % Create circBuffer which stores the data necessary to perform
            % the DFT for each octave. Each entry contains a struct which
            % contains audio data and its respective sampling frequency.
            object.circBuffer = cell(numOctaves, numTimes);
            [object.circBuffer{:}] = deal(struct('data',[],'Fs',0));
            
            % Cell array to preserve states of halfband filter.
            object.halfbandStates = cell(numOctaves + object.initDSTimes, 1);
            [object.halfbandStates{:}] = deal(zeros(halfbandOrder,1));
            % States for the bandpass filter.
            object.bandpassStates = cell(numOctaves,1);
            [object.bandpassStates{:}] = deal(zeros(bandpassOrder,1));
            
            % Calculate center freqs of proportional BW filters. Center
            % frequencies are calculated from lowest octave, to highest
            % octave. The size of this array will then be
            % 'object.filtersPerOctave' * number of octaves.
            % Formula is from 'Constant_Q_FIR_Filter_Freq_Weights_2.m'.
            R = 10^(log10(2)/(2*object.filtersPerOctave));
            for i=1:size(object.octaveSet,1)
                f0 = object.octaveSet(i,1);
                offset = (i-1) * object.filtersPerOctave;
                for k=1:object.filtersPerOctave
                   object.centerFreqs(k+offset,1) = f0 * R^(2*k-1);
                end
            end
            
            % Freq estimations array.
            object.freqEstimations = zeros(size(object.centerFreqs));
            
            % Calculate center frequencies of proportional BW filters in terms of
            % ratios of a given bandwidth. Here the first
            % 'object.filtersPerOctave' number of center frequencies in the
            % lowest octave is divided by this lowest octave's bandwidth.
            %
            % The intent is that 'centerFreqRatios' is an array of proportions 
            % that can then be used to calculate the center frequency
            % values of the filters for any octave, given the octave's
            % bandwidth. For example, to calculate the center frequency
            % values for the filters spanning the octave [4000-8000] Hz, multiply
            % 'centerFreqRatios' by 4000.
            object.centerFreqRatios = (object.centerFreqs(1:object.filtersPerOctave,1) - object.octaveSet(1,1)) / object.octaveSet(1,1);
            
            % bandwidthRatios follows the same reasoning as
            % centerFreqRatios, however this array is used to calculate the
            % passband bandwidth of each individual filter, rather than its
            % center frequency. Formula is again from 'Constant_Q_FIR_Filter_Freq_Weights_2.m'.
            object.bandwidthRatios = (object.centerFreqs(1:object.filtersPerOctave,1) * (R-1/R)) / object.octaveSet(1,1);
            
            
            % The DFTSize is determined by the size of the data in the top
            % octave's circBuffer cell, which corresponds to the size of
            % the input frame divided by 4.
            DFTSize = object.frameSize/4;
            %Create blackman-harris window.
            window = blackmanharris(DFTSize);
            % The window's main lobe is fit while its in decibel form, then converted out
            % of decibel form at time of lookup.
            windowMag = fftshift(20*log10(abs(fft(window/sum(window),DFTSize))));
            % Locate the main lobe for fitting.
            mainLobeIndices = object.mainLobeIndices(windowMag,-100);
            lobeCenterIdx = mainLobeIndices(1) + ((mainLobeIndices(2) - mainLobeIndices(1))/2);
            
            % Shift x axis of main lobe to be centered on 0 when
            % polyfitting.
            normWindowX = ((mainLobeIndices(1):mainLobeIndices(2)) - lobeCenterIdx);
            % Normalize to -0.5 to 0.5
            normWindowX = normWindowX/(size(mainLobeIndices(1):mainLobeIndices(2)-1,2));
            normWindowY = windowMag(mainLobeIndices(1):mainLobeIndices(2))';
            % Fit polynomial to normalized axis.
            object.polyCoefficients = polyfit(normWindowX, normWindowY,10);
            % Refit the polynomial to the portion of the window at or above
            % -1 dB.
            object.polyCoefficients = object.refitLobe(object.polyCoefficients,-1);
            
            % Create kaiser window for DFTs.
            object.kaiserWindow = kaiser(DFTSize,0);
            % TODO: INVESTIGATING SCALING:
            object.kaiserWindow = object.kaiserWindow/sum(object.kaiserWindow);
            %object.kaiserWindow = hamming(DFTSize);
            
            % Create cache container for reused lookup points and window
            % weights.
            object.linearEvalPoints = cell(size(object.octaveSet,1), object.filtersPerOctave);
            object.windowWeights = cell(size(object.octaveSet,1), object.filtersPerOctave);
            
            % Provide feedback on octaveSet, sampling rate manipulations.
            fprintf('User requested frequency range: %i - %i Hz. \n', freqLow, freqHigh);
            disp('Octave Set (Hz):');
            disp(object.octaveSet);
            fprintf('Initial Fs: %i Hz, Resample Fs: %i Hz, Final Fs: %i Hz \n'  ,fileFs, object.resampleFs, requiredFs);
        end
        
        function [outputFreqs, outputEstimations] = processFrame(object, frame)
            % Encapsulate signal data and its respective sample rates into
            % 'octave' structures. It is currently assumed that the frame
            % has the Fs specified in ConstantQ's constructor.
            topOctaveStruct = struct('data', frame, 'Fs', object.fileFs);
            topOctaveStruct = object.decimateFrame(topOctaveStruct);
            
            % Circular shift on times.
            object.circBuffer = circshift(object.circBuffer,1,2);
            
            % Prepare input data for each octave.
            for i=size(object.inputBuffer,1):-1:1
               if i==size(object.inputBuffer,1)
                   object.inputBuffer{size(object.inputBuffer,1),1} = topOctaveStruct;
               else 
                   % Halfband, 2:1 downsampling.
                   [object.inputBuffer{i,1}.data, object.halfbandStates{i,1}] = filter(object.halfband,1,object.inputBuffer{i+1,1}.data, object.halfbandStates{i,1});
                   object.inputBuffer{i,1}.data = object.inputBuffer{i,1}.data(2:2:end);
                   object.inputBuffer{i,1}.Fs = object.inputBuffer{i+1,1}.Fs/2;
               end
            end
            
            for i=size(object.circBuffer,1):-1:1                
                % Bandpass, 4:1 downsampling.
                [object.circBuffer{i,1}.data, object.bandpassStates{i,1}] = filter(object.bandpass,1,object.inputBuffer{i,1}.data, object.bandpassStates{i,1});
                object.circBuffer{i,1}.Fs = object.inputBuffer{i,1}.Fs;
                object.circBuffer{i,1}.data = object.circBuffer{i,1}.data(4:4:end);
                object.circBuffer{i,1}.Fs = object.circBuffer{i,1}.Fs/4;
            end
            
            % Only the first call to processFrame() calculates the linear
            % lookup points and window weights associated with each
            % individual constant-Q filter. These values are cached and
            % recalled in sucessive calls to processFrame().
            if object.init == true
                object.calculateEstimationsInit;
                object.init = false;
            else
                object.calculateEstimations;
            end
            
            % Prepare outputs.
            outputFreqs = object.getCenterFreqs;
            outputEstimations = object.getFreqEstimations;
            
        end % End processFrame.
        
        function centerFreqs = getCenterFreqs(object)
            centerFreqs = object.centerFreqs;
        end
        
        function freqEstimations = getFreqEstimations(object)
            freqEstimations = object.freqEstimations;
        end
        
    end % End public methods.
    
    methods(Access = private)      
        % Perform initial resampling operations if required. Whether or not
        % these operations are needed depend on the class properties
        % object.resampleFs and object.initDSTimes, as calculated in the
        % constructor.
        function outputFrameStruct = decimateFrame(object, inputFrameStruct)
            outputFrameStruct = inputFrameStruct;
            %TODO: Integrate non-integer downsampling.
            % Perform initial non-integer downsampling, if needed.
            if (outputFrameStruct.Fs > object.resampleFs)
                % Neighbor term number - input parameter for resample(). 
                % "The length of the antialiasing FIR
                % filter is proportional to n". See resample's
                % documentation.
                resampleN = 10;
                [p,q] = rat( object.resampleFs/outputFrameStruct.Fs, 1e-12 );
                pqmax = max(p,q);
                
                % Length of filter that will be constructed within
                % resample().
                filterLength = 2*resampleN*pqmax + 1;
                %outputFrameStruct.data = resample(outputFrameStruct.data,object.resampleFs,outputFrameStruct.Fs,resampleN);
                % Throw away filterLength's worth of data on both "sides"
                % of the resampled data.
                %outputFrameStruct.data = outputFrameStruct.data(2:end-1,1);
                %outputFrameStruct.data = outputFrameStruct.data(filterLength+1:end-(filterLength+1),1);
                
                outputFrameStruct.Fs = object.resampleFs;
            elseif (outputFrameStruct.Fs < object.resampleFs)
                % Code execution should never reach this point.
                error('Error in code logic: resampleFs is greater than fileFs');
            end
            
            % Perform 2:1 downsampling along with necessary halfband
            % filtering.
            offset = size(object.octaveSet,1);
            for i=object.initDSTimes:-1:1
                [outputFrameStruct.data, object.halfbandStates{offset + i,1}] = filter(object.halfband,1,outputFrameStruct.data,object.halfbandStates{offset + i,1});
                outputFrameStruct.data = outputFrameStruct.data(2:2:end);
                outputFrameStruct.Fs = outputFrameStruct.Fs/2;
            end
        end
        
        function indices = mainLobeIndices(object, window, threshold)
           [~,maxIndex] = max(window);
           % Find left index of main lobe.
           leftIndex = maxIndex;
           while (leftIndex >1 && window(leftIndex) > threshold)
               leftIndex = leftIndex - 1;
           end
           % Find right index of main lobe.
           rightIndex = maxIndex;
           while (rightIndex < size(window,1) && window(rightIndex) > threshold)
               rightIndex = rightIndex + 1;
           end
           indices = [leftIndex rightIndex];
        end
        
        function refitCoefficients = refitLobe(object, coefficients, targetDB)
            f = @(x)polyval(coefficients,x) - targetDB;
            x = abs(fzero(f,0));
            xAxis = (-x:0.001:x);
            yAxis = polyval(coefficients,xAxis);
            % Renormalize xAxis to -0.5 to 0.5
            normFactor = 0.5 / x;
            refitCoefficients = polyfit(xAxis .* normFactor, yAxis,10);
        end
        
        function calculateEstimationsInit(object)
            % Perform DFT on each octave, calculating from lowest to highest octave.
            dftSize = object.frameSize/4;
            for i=1:size(object.circBuffer,1)
                dftData = object.concatenateData(dftSize, i);
                
                % Perform DFT and window operations
                octaveFFT = fftshift((abs(fft(dftData .* object.kaiserWindow))));
                
                % Calculate bandwidth of octave after 4:1 DS. Alternatively
                % one can just look up the bandwidths from the octave set.
                octaveBW = (object.topOctaveRatio(2) + object.topOctaveRatio(2)) * object.circBuffer{i,1}.Fs;
                % DOUBLE CHECK THIS LINE. CONFIRM THAT THIS IS A PROPER WAY
                % TO "TRANSLATE" CENTER FREQUENCIES ONTO THE 4:1 DOWNSAMLE
                % DOMAIN.
                octaveCenterFreqs = (object.centerFreqRatios .* octaveBW) + (-object.topOctaveRatio(2) * object.circBuffer{i,1}.Fs); 
                
                % Calculate frequencies that are multiples of 2pi/N
                linearFreqs = ((-0.5:1/dftSize:0.5-1/dftSize) * object.circBuffer{i,1}.Fs)';
                
                for k=1:size(octaveCenterFreqs,1)
                    % Calculate passband BW for each center frequency filter.
                    passbandBW = object.bandwidthRatios(k) * octaveBW;
                    % Create constant-Q filters for this octave.
                    lowerBound = (octaveCenterFreqs(k) - (passbandBW/2));
                    upperBound = (octaveCenterFreqs(k) + (passbandBW/2));
                    linEvalPoints = (linearFreqs >= lowerBound) & (linearFreqs <= upperBound);
                    % Cache look-up points of linear FFT bins for each
                    % proportional filter.
                    object.linearEvalPoints{i,k} = linEvalPoints;
                    if isequal(object.linearEvalPoints{i,k}, zeros(length(linearFreqs),1))
                        error('Insufficient input: Decrease number of filters per octave and/or increase frame length.');
                    end
                    polyvalX = (linearFreqs(object.linearEvalPoints{i,k}) - octaveCenterFreqs(k)) / passbandBW;
                    % Cache window weights of sliding frequency window for each proportional filter.  
                    object.windowWeights{i,k} = (10.^(polyval(object.polyCoefficients,polyvalX)/20));
                    
                    % Estimate amplitude of arbitrary center frequency.
                    % This coresponds to equation 4 in 'An Efficient FFT
                    % Based Spectrum Analyzer For Arbitrary Center
                    % Frequencies And Arbitrary Resolutions Analysis'.
                    freqEstimation = sum(octaveFFT(object.linearEvalPoints{i,k}) .* object.windowWeights{i,k}) / sum(object.windowWeights{i,k});
                    freqEstimation = 20*log10(freqEstimation);
                    %freqEstimation = freqEstimation - 2.899; %Temporary scaling factor correction (-2.899)
                    
                    offset = (i-1) * object.filtersPerOctave;
                    object.freqEstimations(k + offset,1) = freqEstimation; 
                end
            end
        end
        
        function calculateEstimations(object)
            % Perform DFT on each octave, calculating from lowest to highest octave.
            dftSize = object.frameSize/4;
            for i=1:size(object.circBuffer,1)
                dftData = object.concatenateData(dftSize, i);
                
                % Perform DFT and window operations
                octaveFFT = fftshift((abs(fft(dftData .* object.kaiserWindow))));

                for k=1:object.filtersPerOctave
                    % Estimate amplitude of arbitrary center frequency.
                    % This coresponds to equation 4 in 'An Efficient FFT
                    % Based Spectrum Analyzer For Arbitrary Center
                    % Frequencies And Arbitrary Resolutions Analysis'.
                    freqEstimation = sum(octaveFFT(object.linearEvalPoints{i,k}) .* object.windowWeights{i,k}) / sum(object.windowWeights{i,k});                    
                    freqEstimation = 20*log10(freqEstimation);
                    %freqEstimation = freqEstimation - 2.899; %Temporary scaling factor correction (-2.899)
                    
                    offset = (i-1) * object.filtersPerOctave;
                    object.freqEstimations(k + offset,1) = freqEstimation;
                    
                end
            end
        end
        
        function dftData = concatenateData(object, dftSize, octaveIdx)
            dftData = [];
            numCells = 2^(size(object.circBuffer,1) - (octaveIdx-1)-1);
            % Concatenate data if needed.
            for j=1:numCells
                dftData = vertcat(dftData,object.circBuffer{octaveIdx,numCells-(j-1)}.data);
            end
            
            %Pad dftData with zeros if necessary
            if (size(dftData,1) < dftSize)
                difference = dftSize - size(dftData,1);
                dftData(end + difference,1) = 0;
            end
        end
    end % End private methods.
    methods(Static)

    end
end % End class.