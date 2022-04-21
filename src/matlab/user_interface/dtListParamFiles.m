function [files, libdir] = dtListParamFiles()
% files = dtListParamFiles()
% Return list of parameter files distributed with silbido and the
% directory in which they are stored.
%
% The 'ParameterSet' keyword of the detector and annotation tools
% (dtTonalsTracking and dtTonalAnnotate) can be used to set parameters
% to any one of these.

% Find lib directory 
currdir = fileparts(which(mfilename)); % current directory
srcdir = fileparts(currdir);  % parent
libdir = fullfile(srcdir, 'lib');

% Get the parameter files and convert to a string array
file_list = dir(fullfile(libdir, '*.xml'));
files = string({file_list.name});
