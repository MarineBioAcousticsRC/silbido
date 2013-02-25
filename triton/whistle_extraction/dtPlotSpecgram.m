function [AxisH ImageH] = dtPlotSpecgram(File, Start_s, Stop_s, varargin)
% dtPlotSpecgram(File, Start_s, Stop_s, OptionalArgs)
% Plot spectrogram for specified file between start and stop time in s.
%
% Optional arguments
%   'Framing', [Advance_ms, Length_ms] - frame advance and length in ms
%       Defaults to 1 and 2 ms respectively
%   'Threshold', N_dB - Threshold in dB, only applicable when
%       Type is binary or thresholded.
%   'Click_dB', N_dB - Threshold in dB for clicks, a certain percentage
%       of the bins must exceed this.  This is used for excluding clicks
%       from the noise floor computation.
%   'Noise', String - See dtSpectrogramNoiseComp for valid noise
%        compensation methods.  (default 'none')
%   'Range' [lowHz highHz]
%   'Render', String - How image should be rendered
%       'grey' - grey scale image.  Note that this does not literally
%                mean grey, the current colormap will be used.  Rather
%                colors are picked from the active color map using the
%                spectral power.
%       'binary' - index 0 below threshold, 1 above
%       'floor' - index 0 below threshold, power above
%   'AxisColor', Color - Axis and labels in specified color, e.g. 'c'
%       (cyan)
%   'TransferFn', true|false - enable transfer function if available


error(nargchk(3,Inf,nargin));  % check arguments

% defaults
Advance_ms = 1;
Length_ms = 2;
AxisColor = [];
NoiseComp = 'none';
Render = 'grey';
Range_Hz = [5000 50000];
bright_dB = 10;
contrast_dB = 200;
TransferFn = false;
% Borrowed these thresholds from dtTonalsTracking
% Settable Thresholds --------------------------------------------------
thr.whistle_dB = 10;        % Assuming whistles are normally above
                           % 10dB energy (SNR criterion)

thr.click_dB = 10;         % SNR criterion for clicks

% Whistles whose duration is shorter than threshold will be discarded. 
thr.minlen_ms = 400;       

% Maximum gap in energy to bridge when looking for a tonal
thr.maxgap_ms = 30;
% Maximum difference in frequency to bridge when looking for a tonal
thr.maxgap_Hz = 600; 


% Frames containing broadband signals will not be used in
% any means estimates.
% If more than broadand% of the bins exceed the threshold,
% we consider the frame a click.  
thr.broadband = .05;

%-------------------------------------------------------------------------

k = 1;
while k <= length(varargin)
    switch varargin{k}
        case 'Framing'
            if length(varargin{k+1}) ~= 2
                error('%s must be [Advance_ms, Length_ms]', varargin{k});
            else
                Advance_ms = varargin{k+1}(1);
                Length_ms = varargin{k+1}(2);
            end
            k=k+2;
        case 'Range'
            Range_Hz = varargin{k+1};
            if length(Range_Hz) ~= 2 || ~ isnumeric(Range_Hz) ...
                    || diff(Range_Hz) <= 0;
                error('%s arg must be [LowHz, HighHz]', varargin{k});
            end
            k=k+2;
        case 'Render'
            Render = varargin{k+1}; k=k+2;
        case 'Threshold'
            thr.whistle_dB = varargin{k+1}; k=k+2;
        case 'Click_dB'
            thr.click_dB = varargin{k+1}; k=k+2;
        case 'Noise'
            NoiseComp = varargin{k+1}; k=k+2;
        case 'AxisColor'
            AxisColor =  varargin{k+1}; k=k+2;
            
        otherwise
            try
                if isnumeric(varargin{k})
                    errstr = sprintf('Bad option %f', varargin{k});
                else
                    errstr = sprintf('Bad option %s', char(varargin{k}));
                end
            catch
                errstr = sprintf('Bad option in %d''optional argument', k);
            end
            error(sprintf('Detector:%s', errstr));
    end
end


header = ioReadWavHeader(File);
handle = fopen(File, 'rb', 'l');
% Select channel as per Triton
channel = channelmap(header, File);

Nyquist = header.fs / 2;
if Range_Hz(2) > Nyquist
    Range_Hz(2) = Nyquist;
end

% Frame length and advance in samples
Length_s = Length_ms / 1000;
Length_samples = round(header.fs * Length_s);
Advance_s = Advance_ms / 1000;
Advance_samples = round(header.fs * Advance_s);
window = hamming(Length_samples);
bin_Hz = 1 / Length_s;

Overlap_samples = Length_samples - Advance_samples;

block_len_s = 3;        % process how much at a time

Nyquist_bin = floor(Length_samples/2);
% Determine which bins to use and build frequency axis
thr.low_cutoff_Hz = Range_Hz(1);
thr.high_cutoff_Hz = Range_Hz(2);
thr.high_cutoff_bins = min(ceil(thr.high_cutoff_Hz/bin_Hz)+1, Nyquist_bin);
thr.low_cutoff_bins = ceil(thr.low_cutoff_Hz / bin_Hz)+1;

% save indices of freq bins that will be plotted
range_bins = thr.low_cutoff_bins:thr.high_cutoff_bins; 
range_binsN = length(range_bins);  % # freq bin count

fHz = thr.low_cutoff_Hz:bin_Hz:thr.high_cutoff_Hz;
fkHz = fHz / 1000;

% determine transfer function if available
if TransferFn
    [xfr_f, xfr_offset] = tfmap(File, channel, header.nch, fHz);
    xfr_offset = xfr_offset';
else
    xfr_offset = [];
    xfr_f = [];
end

% offset the first window by this many samples
shift_samples = floor(header.fs / thr.high_cutoff_Hz);
shift_samples_s = shift_samples / header.fs;

block_pad_s = 1 / thr.high_cutoff_Hz;
block_padded_s = block_len_s + 2 * block_pad_s;
Stop_s = Stop_s - block_pad_s;

if Start_s - block_pad_s >= 0
    Start_s = Start_s - block_pad_s;
end
blkstart_s = Start_s;


done = false;
hidx = 1;
while ~ done
    blkstop_s = min(blkstart_s + block_padded_s, Stop_s);
    % Read in block and compute spectrogram
    Signal = ioReadWav(handle, header, blkstart_s, blkstop_s, ...
        'Units', 's', 'Channels', channel);
    
   % perform spectral analaysis 
   [snr_dB, Indices, dft, clickP] = dtSpecAnal(Signal, header.fs, ...
       Length_samples, Advance_samples, shift_samples, ...
       range_bins, thr.broadband * range_binsN, ...
       thr.click_dB, NoiseComp);
   
   if ~ isempty(xfr_offset)
       % adjust for transfer function
       snr_dB = snr_dB - xfr_offset(:, ones(size(snr_dB, 2), 1));
   end
   % relative to file rather than block
   Indices.timeidx = Indices.timeidx + blkstart_s;  
   
   switch Render
       case {'grey', 'gray'}
           % do nothing
       case 'binary'
           snr_dB(snr_dB < thr.whistle_dB) = 0;   % Threshold image
           snr_dB(snr_dB >= thr.whistle_dB) = 1;
       case 'floor'
           snr_dB(snr_dB < thr.whistle_dB) = 0;   % Threshold image
       otherwise
           error('Bad render type %s', Render);
   end
    
    ImageH(hidx) = image(Indices.timeidx, fkHz, snr_dB);  % plot the block
    colorData = (contrast_dB/100) .* snr_dB + bright_dB;
    set(ImageH(hidx), 'CData', colorData);
    
    % Store the snr, brightness and contrast in UserData structure
    % associated with the image
    pwr_brt_cont.snr_dB = snr_dB;
    pwr_brt_cont.bright_dB = bright_dB;
    pwr_brt_cont.contrast_dB = contrast_dB;
    set(ImageH(hidx), 'UserData', pwr_brt_cont);
    
    hidx = hidx + 1;
    datacursorH = datacursormode(gcf);
    set(datacursorH, 'UpdateFcn', @dtTFNodeDatatip);

    hold on;

    % set start to next frame
    blkstart_s = Indices.timeidx(end) + Advance_s - shift_samples_s;
    done = blkstart_s + Length_s >= Stop_s;
end

fclose(handle);
AxisH = gca;
set(AxisH, 'XLim', [Start_s, Stop_s]);
set(AxisH, 'YDir', 'normal');
set(AxisH, 'YLim', [fkHz(1), fkHz(end)]);
set(AxisH, 'fontsize', 12, 'fontweight', 'b');
xlabel('time (s)', 'fontsize', 12, 'fontweight', 'b');
ylabel('freq (kHz)', 'fontsize', 12, 'fontweight', 'b');

colorbar_h = colorbar;
set(get(colorbar_h, 'YLabel'), ...
    'String', 'Spectrum Level [dB re counts^2/Hz]', 'fontsize', 12,...
    'fontweight', 'b');

if ~ isempty(AxisColor)
    set(AxisH, 'XColor', AxisColor);
    set(AxisH, 'YColor', AxisColor);
    set(get(AxisH, 'XLabel'), 'Color', AxisColor);
    set(get(AxisH, 'YLabel'), 'Color', AxisColor);
    set(colorbar_h, 'YColor', AxisColor);
    set(get(colorbar_h, 'YLabel'), 'Color', AxisColor);
end
1;
