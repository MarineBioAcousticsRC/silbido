function x = date_to_xaxis(plot_type, datenums)
% x = date_to_xaxis(plot_type, datenums)
% For the specified plot type ('ltsa' only for now), convert each of the
% serial dates (datenums) to an x axis offset.  x is a matrix of the 
% same shape as datenums.  If a date lies outside the current plot, its
% offset is set to NaN.

global PARAMS

% initialize x to same shape as datenums with NaN
x = NaN;
x = x(ones(size(datenums)));

[start, stop] = get_plot_range(plot_type);
valid = find(start <= datenums & stop >= datenums);
if size(valid, 1) > 1
    valid = valid';
end

switch plot_type
 case 'ltsa'
  [startFile, startIdx] = ltsa_TimeIndexBin(start);
  [stopFile, stopIdx] = ltsa_TimeIndexBin(stop);
  % Indicate how many averages there in the preceding files for each file
  % in range.
  CumAvg = cumsum([0 PARAMS.ltsa.nave(startFile:max(startFile, stopFile-1))]);
  
  % Compute bin width in hours 
  BinWidth_u = PARAMS.ltsa.tave/(60*60);
  
  for idx = valid
    % find the file and ltsa bin idx for the idx'th date
    [fileIdx binIdx, present] = ltsa_TimeIndexBin(datenums(idx));
    % Take into account the number of bins in other files covered in
    % the plot.  
    cumAvgIdx = fileIdx - startFile + 1;
    offsetFromStart = CumAvg(cumAvgIdx) + binIdx - startIdx;
    % Convert to x-axis units and store.
    x(idx) = offsetFromStart * BinWidth_u;
  end
  
 case 'spectra'
  % Compute bin width in s
  BinWidth_u = PARAMS.t(2) - PARAMS.t(1);
  for idx = valid
    offset = datenums(idx) - start;
    % Convert to x axis in s.  Note that we are assuming a representation
    % for serial dates.  This is somewhat dangerous, but is done in
    % a couple other places... 
    x(idx) = offset * 24*3600;
  end

 otherwise
  error('Bad plot type "%s"', plot_type)
end
   
   



