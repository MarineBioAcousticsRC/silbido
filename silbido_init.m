function silbido_init

clear global;  % clear out old globals
clc;        % clear command window  -- not needed for compiled
%               version, gets a complaint in cmd 'display' window
close('all', 'hidden');  % close all figure windows
warning off % this is turned off for plotting messages

% Add subdirectories to search path
RootDir = pwd();

paths = genpath2('matlab');
addpath(paths);


paths = genpath2('sandbox');
addpath(paths);

% Set up java.
import tonals.*;

java_base_dir = 'java/';

% First try to load it from where eclipse compiles code.
java_bin_dir = fullfile(RootDir, [java_base_dir 'bin']);
javaaddpath(java_bin_dir);

% If we didn't find it check in the ant build dir.
if (~exist('tonals.tonal')) 
    java_build_dir = fullfile(RootDir, [java_base_dir 'build']);
    javaaddpath(java_build_dir);
end

% If we still didn't find it try to load the distribution
% jar file.
if (~exist('tonals.tonal')) 
    java_dist_dir = fullfile(RootDir, [java_base_dir 'dist']);
    java_archives = utFindFiles({'*.jar'}, {java_dist_dir}, 1);
    if ~ isempty(java_archives);
        javaaddpath(java_archives);
    end
end

java_dist_dir = fullfile(RootDir, [java_base_dir 'lib']);
java_archives = utFindFiles({'*.jar'}, {java_dist_dir}, 1);
if ~ isempty(java_archives);
    javaaddpath(java_archives);
end

if (~exist('tonals.tonal')) 
    error('Could not load java classes.');
end


function p = genpath2(d, varargin)
if nargin==0,
  p = genpath(fullfile(matlabroot,'toolbox'));
  if length(p) > 1, p(end) = []; end % Remove trailing pathsep
  return
end

  
% initialise variables
methodsep = '@';  % qualifier for overloaded method directories
p = '';           % path to be returned

% Generate path based on given root directory
files = dir(d);
if isempty(files)
  return
end

ExcludeDirs{1} = {'.', '..', 'private'};   % always exclude the following

% defaults
ExcludeRootDir = 0;     % include root

k = 1;
while k < length(varargin)
  switch varargin{k}
   case 'ExcludeRootDir'
    ExcludeRootDir = varargin{k+1}; 
    varargin{k+1} = 0;  % Set argument to 0 for recursive calls
    k=k+2;
   case 'ExcludeDirs'
    ExcludeDirs{end+1} = varargin{k+1}; k=k+2;
  end
end

if ~ ExcludeRootDir
  % Add d to the path even if it is empty.
  p = [p d pathsep];
end

% set logical vector for subdirectory entries in d
isdir = logical(cat(1,files.isdir));
%
% Recursively descend through directories which are neither
% private nor "class" directories.
%
dirs = files(isdir); % select only directory entries from the current listing

for i=1:length(dirs)
  dirname = dirs(i).name;
  
  % Assume that dir should be included unless we find otherwise.
  Include = 1;
  % Don't include object methods 
  if strncmp(dirname, methodsep, 1)
    Include = 0;
  end
  % Check for other special names that should be excluded
  for k=1:length(ExcludeDirs)
      if sum(strcmp(dirname, ExcludeDirs{k})) > 0
          Include = 0;
          break;
      end
  end
  if Include
    p = [p genpath2(fullfile(d, dirname), varargin{:})];
  end
end

%------------------------------------------------------------------------------


