function dtTonalsSave(Filename, tonals, gui)
% dtTonalsSave(Filename, tonals, gui)
% Save the list of tonals to the specified file. Tonals can be saved as:
% Binary(.bin) - Simple file format (recommended)
% Object(.ton) - Save as Java objects (implementation is a memory pig)
%
% Filename - Example - 'palmyra092007FS192-071011-230000.wav' or
%                       []
% tonals - list of tonals
%
% If Filename is [] or gui is true, a dialog is presented
% and the user is allowed to select with the default value
% being Filename.

import tonals.*;

error(nargchk(2,3,nargin));
if nargin < 3
    gui = isempty(Filename);  % Only use the gui if filename empty
end

pattern = {'*.bin'; '*.ton'};
if gui
    [SaveFile, SaveDir] = uiputfile(pattern, 'Save Tonals', Filename);
    if isnumeric(SaveFile)
        return  % cancel
    end
    Filename = fullfile(SaveDir, SaveFile);
end

[path name ext] = fileparts(Filename);
% open up file
if strcmp(ext, '.ton')
    tstream = TonalOutputStream(Filename);
else
    tstream = TonalBinaryOutputStream(Filename);
end

% iterate through tonals
it = tonals.iterator();
count = 0;
while it.hasNext()
    t = it.next();
    tstream.write(t);  % write each tonal
    count = count + 1;
    if rem(count, 100) == 1 && strcmp(ext, '.ton')
        tstream.objstream.reset();
    end
end
tstream.close();
