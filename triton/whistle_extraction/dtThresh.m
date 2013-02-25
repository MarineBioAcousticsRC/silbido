function thr = dtThresh()
% thr = dtThresh()
% Get common defaults for algorithm.

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