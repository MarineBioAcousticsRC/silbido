function thr = dtThresh(Filename)
% thr = dtThresh(Filename)
% Get common defaults for algorithm.
% If Filename 
% - is not provided, defaults are loaded for odontocete.xml
% - is present:
%    Try to read parameters from specified filename.  When the file is
%       not an absolute path, read will be relative to the current
%       working directory.
%    If this fails, we try to read relative to Silbido's src/matlab/lib
%       directory.
%      
% For an example parameter file, see src/matlab/lib/odontocete.xml


if nargin < 1
    Filename = relativetolib('odontocete.xml');
end

if fexist(Filename)
    xml = tinyxml2_wrap('load', Filename);
else
    libFilename = relativetolib(Filename);
    if strcmp(libFilename, Filename)
        % Rethrow the error if we'd try to read the same file again
        error('Cannot find file %s', Filename);
    else if fexist(libFilename)
            xml = tinyxml2_wrap('load', libFilename);
        else
            error('Cannot find file %s', Filename);
        end         
    end
end

thr = xml.params;

function fullpath = relativetolib(filename)
% Find lib directory and look there
currdir = fileparts(which(mfilename)); % current directory
srcdir = fileparts(currdir);  % parent
fullpath = fullfile(fullfile(srcdir, 'lib'), filename);

function exists = fexist(filename)
% exists = fexist(filename)
% Check if file exists.  

% We cannot check using Matlab's exist as it will look along the Matlab 
% path and the XML loader will assume a proper path to the file without
% reference to Matlab's path.

% Determine if this is an absolute filepath
%  Check for 
%   DriveLetter:\           C:\   Windows path
%   DriveLetter:/           C:/   Windows path
%   \\path                  Windows Universal Naming Convention (UNC)
%   .\path                  Windows relative to current working directory
%   ./path                  UNIX relative to current working directory
%   /path                   UNIX absolute path
abspath = regexp(filename, ...
    '^([A-Za-z]\:[\\/]|\\\\[A-Za-z]|/|\.[/\\])', 'ONCE');

if isempty(abspath)
    % Convert to an absolute path
    filename = sprintf('.%s%s', filesep, filename);
end
   
exists = exist(filename, 'file');  
