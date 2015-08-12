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

try
    xml = tinyxml2_wrap('load', Filename);
catch e
    libFilename = relativetolib(Filename);
    if strcmp(libFilename, Filename)
        % Rethrow the error if we'd try to read the same file again
        rethrow(e)
    else        
        xml = tinyxml2_wrap('load', libFilename);
    end
end

thr = xml.params;

function fullpath = relativetolib(filename)
% Find lib directory and look there
currdir = fileparts(which(mfilename)); % current directory
srcdir = fileparts(currdir);  % parent
fullpath = fullfile(fullfile(srcdir, 'lib'), filename);

