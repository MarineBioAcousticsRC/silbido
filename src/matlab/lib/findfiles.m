function fileList = findfiles(searchPath,filePattern,patternMode, pathMode, fileList)
% FUNCTION files = findfiles(searchPath, filePattern, patternMode, pathMode, fileList)
% A case insensitive search to find files with in the folder _searchPath_ 
% (if specified) whos file name matches the pattern _filePattern_ and add 
% the results to the list of files in the cell array _fileList_. 
%
% The search can be either a wild-card or regular expression search and is
% case insenstive
%
%
% INPUTS (all are optional
%    searchPath  - Default ask user
%                - directory or string to search can be either a absolute 
%                  or relative path.
%                
%    filePattern - Default: *.* (All files)
%                - List of file wildcard file patterns to search
%                - Wild-card examples
%                     filePattern = '*.xls' % find Excel files
%                     filePattern = {'*.m' *.mat' '*.fig'}; % MATLAB files
%
%                - Regular expression examples (See regexpi help for more)
%                     filePattern = '^[af].*\.xls' % Excel files beginning
%                                                  % with either A,a,F or f
%
%    patternMode - Default: 'wildcard'
%                - 'wildcard' for wild-card searches or 
%                - 'regexp' for regular expression searches
%
%    pathMode - Default: 'file'
%             - 'file' - patten match on file without directories
%             - 'path' - pattern match on entire path to file
%
%    fileList    - list of files (nx1 string array). 
%                Returns a 0x1 empty string array when there are no matches
   
%
%
% author: Azim Jinha (2011)
% modifications: Marie A Roch (2014, 2023)
%   - stopped translating the filePatterns each time
%   - return string arrays instead of cell arrays of characters

% Test inputs

%*** searchPath ***
if ~exist('searchPath','var') || isempty(searchPath) || ~exist(searchPath,'dir')
    searchPath = uigetdir('Select Path to search');
end

% *** filePattern ***
if ~exist('filePattern','var') || isempty(filePattern), filePattern={'*.*'}; end

if ~iscell(filePattern)
    % if only one file pattern is entered make sure it 
    % is still a cell-string.
    filePattern = {filePattern};
end

% *** patternMode ***
if ~exist('patternMode','var')||isempty(patternMode),patternMode = 'wildcard'; end
switch lower(patternMode)
case 'wildcard'
    % convert wild-card file patterns to regular expressions
    fileRegExp=cell(length(filePattern(:)));
    for i=1:length(filePattern(:))
        fileRegExp{i}=regexptranslate(patternMode,filePattern{i});
    end
    % Change patternmode so that recursvie calls do not retranslate.
    filePattern = fileRegExp;
    patternMode = 'regexp';
otherwise
    % assume that the file pattern(s) are regular expressions
    fileRegExp = filePattern;
end

% *** pathMode ***
if ~exist('pathMode', 'var') || isempty(pathMode), pathMode = 'file'; end

% *** fileList ***
% test input argument file list
if ~exist('fileList','var'),fileList = {}; end % does it exist

% is fileList a nx1 cell array
if size(fileList,2)>1, fileList = fileList'; end 
if ~isempty(fileList) && min(size(fileList))>1, error('input fileList should be a nx1 cell array'); end


% Perform file search
% Get the parent directory contents
dirContents = dir(searchPath);

if ~isempty(dirContents)
    % Construct paths
    names = cellfun(@string, {dirContents.name});
    newPaths = arrayfun(@(x) fullfile(searchPath, x), names);
    if size(newPaths, 2) > 1
        newPaths = newPaths';
    end
    matched = false(size(dirContents));  % assume none matched for now
    switch pathMode
        case 'file'
            matchOn = names;
        case 'path'
            matchOn = newPaths;
        otherwise
            error('Bad pathMode');
    end
    for i=1:length(dirContents)
        % don't process current/parent/private directories
        % (anything starting with a .)
        if ~strncmpi(names(i),'.',1)
            if dirContents(i).isdir
                fileList = findfiles(newPaths(i), filePattern, ...
                    patternMode, pathMode, fileList);
            else
                for jj=1:length(fileRegExp)
                    matched(i) = ~isempty(regexpi(matchOn(i), ...
                                             fileRegExp{jj}));
                    if matched(i), break; end
                end
            end
        end
    end
    fileList = [fileList; newPaths(matched)];  %#ok<AGROW>

end
