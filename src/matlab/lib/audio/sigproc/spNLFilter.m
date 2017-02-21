function Result = spNLFilter(Signal, Type, varargin)
% spNLFilter(Signal, FilterType, Arg1, ... ArgN)
%
% Perform non linear filtering upon a signal.  
%
% Valid filter types:
%	'diff' - Computer Nth difference
%		N (Arg 1) - Nth difference
%
%	'hanning' - Smooth via an N point Hanning filter with
%		normalized coefficients.  
%		N (Arg 1) - Number of points (odd recommended)
%		
%	median - Median filter
%		Median (Arg 1) - Median filter size
%		
%	peaknorm - Peak normalization
%		NormalValue (Arg 1) - Value to which highest
%			peak is normalized
%
%	Tukey - Nonlinear double smoothing.
%		described in IEEE Trans. ASSP-23 No. 6, Dec 75
%		Rabiner, Sambur, Schmidt
%
%         x(n) ----------> + -------|
%		  |        ^ 	    |
%		  v        | 	    v
%            |----------|  |   |----------|
%   	     | median   |  |   | median   |
%            | smoother |  |   | smoother |
%            |----------|  |   |----------|
%	                   |        |        |
%	                   | -1 --> *        |
%                      v        ^        v
%            |----------|  |   |----------|
%     	     | linear   |  |   | linear   |
%    	     | smoother |  |   | smoother |
%            |----------|  |   |----------|
%		           |       |	    |
%                  |       |        |
%                  |-------|        |
%                  v                |
%         w(n) <-- + <--------------|
%
%		Arguments:
%		Median (Arg 1) - Median filter size
%		Smooth Size (Arg 2) - Number of points for linear smoother
%       If arguments are not odd, they will be reduced in size by 1.
%

if size(Signal, 2) == 1
  % Row vector, we expect a column vector
  Signal = Signal';
  Transpose = 1;
else
  Transpose = 0;
end

if isstr(Type)
  switch Type(1)
    % Median filtering
    case {'m','M'}
     
     FilterSize = varargin{1};
     if license('test', 'signal_toolbox')
       % User has signal processing toolbox, use it    
       Result = medfilt1(Signal, FilterSize);
     else
       % Much slower, slightly different results
       narginchk(1,3)
       MidPtOffset = (FilterSize - 1) / 2;
       Result = Signal;
       [Dummy, SignalSize] = size(Signal);
       % Handle beginning
       for i = 1:MidPtOffset
           Result(i) = median(Signal(1:i+MidPtOffset));
       end
      % Handle middle
      for i = MidPtOffset+1:SignalSize - MidPtOffset
          Result(i) = median(Signal(i-MidPtOffset:i+MidPtOffset));
      end
      % Handle end
      for i = SignalSize - MidPtOffset + 1:SignalSize
          Result(i) = median(Signal(i-MidPtOffset:SignalSize));
      end
     end
    
  case {'d','D'}
    % Nth difference filter
    narginchk(1,3)
    Result = spDelta(Signal, varargin{1});
    
  case {'h','H'}
    % Normalized Hann Filter
    narginchk(1,3)
    FilterSize = varargin{1};
    % Reuse Hann filter from previous invocation if available
    % Helpful when called frequently w/ same size
    persistent Hann;
    if length(Hann) ~= FilterSize
        Hann = hann(FilterSize);
        Hann = Hann / sum(Hann);
    end
    % Like filter(Hann, 1, Signal), but adds trailing zeros
    % to let filter output die.
    Result = conv(Hann, Signal);

  case {'p','P'}
    % Peak Normalization
    narginchk(1,3)
    PeakVal = varargin{1};
    Result = Signal - max(Signal) + PeakVal;
    
  case {'t','T'}
    % Tukey filter
    narginchk(1,4)
    Median = varargin{1};
    HannSize = varargin{2};
    % Ensure odd
    if ~ mod(Median, 2)
        Median = Median - 1;
    end
    if ~ mod(HannSize, 2)
        HannSize = HannSize - 1;
    end
    delaylinear = floor(HannSize/2);
    
    EstSignal = spNLFilter(Signal, 'Median', Median);
    EstSignal = spNLFilter(EstSignal, 'Hann', HannSize);
    EstSignal([1:delaylinear, end-delaylinear+1:end]) = [];	% dump phase shift

    Residual = Signal - EstSignal;
    Residual = spNLFilter(Residual, 'Median', Median);
    Residual = spNLFilter(Residual, 'Hann', HannSize);
    Residual([1:delaylinear, end-delaylinear+1:end]) = [];	% dump phase shift
    
    Result = EstSignal + Residual;
    
  otherwise
    error(sprintf('Unrecognized filter type "%s"\n', Type));
end

else
	error('Type must be a string\n');
end

if Transpose
  Result = Result';
end
