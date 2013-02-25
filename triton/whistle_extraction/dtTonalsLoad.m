function tonalList = dtTonalsLoad(Filename, gui)
% tonalList = dtTonalsLoad(Filename, gui)
% Load a set of tonals from Filename.  If Filename is [] or gui is true
% the filename is requested via dialog with Filename (if any) as the
% suggested default value.
%
% Filename - Example - 'palmyra092007FS192-071011-230000.bin' or
%                       []
%
% Omit gui or set it to false to simply load from the specified file.

error(nargchk(1,2,nargin));
if nargin < 2
    if isempty(Filename)
        gui = true;
    else
        gui = false;
    end
end

if gui
    [LoadFile, LoadDir] = uigetfile({'*.bin'; '*.det'; '*.ton'},...
        'Load Tonals', Filename);
    
    % check for cancel
    if isnumeric(LoadFile)
        tonalList = [];
        return
    else
        Filename = fullfile(LoadDir, LoadFile);
    end
end

[path name ext] = fileparts(Filename);
if strcmp(ext, '.bin') || strcmp(ext, '.det')
    % loads binary file
    tonalList = tonals.tonal.tonalsLoadBinary(Filename);
else if strcmp(ext, '.ton')
        % loads objects
        tonalList = tonals.tonal.tonalsLoad(Filename);
    end
end
