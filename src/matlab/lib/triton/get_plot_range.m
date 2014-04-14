function [start, stop] = get_plot_range(plot_type)
% [start, stop] = get_plot_range(plot_type)
% Given a plot_type ('ltsa' only for now), determine the starting and
% stopping dnums for the current plot.

global PARAMS
switch plot_type
 case 'ltsa'
  %start = PARAMS.ltsa.plot.dnum;        % start time is easy

  TBinWidth_d = PARAMS.ltsa.tave / (60*60*24);  % time bin width measured in days

  % For the start and end of the plot in hours
  dnums = zeros(2,1); 
  dnumIdx = 1;
  for idx=[1, length(PARAMS.ltsa.t)]
    % Find the associated raw file and the time bin index into it
    [RawIdx, TBin] = getIndexBin(PARAMS.ltsa.t(idx));
    % Set time to start of current raw file +
    % delta for each time bin.  Subtract off 1/2 bin
    % as done in pickxzy, most likely the calculated
    % time is the center of the bin, so subtracing off
    % a half bin would give us the start.  Check with Sean.
    dnums(dnumIdx) = PARAMS.ltsa.dnumStart(RawIdx) + ...
        datenum([0 0 TBin*TBinWidth_d - TBinWidth_d/2]);
    dnumIdx = dnumIdx + 1;
  end
  dums(2) = dnums(2) + TBinWidth_d;
  % datestr(dnums, 'mmm.dd.yyyy HH:MM:SS.FFF')  % debug
  
  start = dnums(1);
  stop = dnums(2);
  
 case 'spectra'
  start = PARAMS.plot.dnum;  % start of plot
  % determine bin width
  bin_width = round((PARAMS.overlap/100)*PARAMS.nfft)/PARAMS.fs;
  % set stop at just before next bin
  stop = start + datenum([0 0 0 0 0 (PARAMS.t(end) + bin_width*.999)]);

 otherwise
  error('Bad plot_type %s', plot_type)
end
