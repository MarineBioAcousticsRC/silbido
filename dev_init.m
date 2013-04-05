function dev_init

clear global;  % clear out old globals
clc;        % clear command window  -- not needed for compiled
%               version, gets a complaint in cmd 'display' window
close('all', 'hidden');  % close all figure windows
warning off % this is turned off for plotting messages

% Add subdirectories to search path
RootDir = pwd();
addpath(genpath2('.', 'ExcludeDirs', {'whistle','.hg', '.hgcheck','lib', 'java', 'build'}, 'ExcludeRootDir', 1));

% Set up java.
import tonals.*;

% First try to load it from where eclipse compiles code.
java_bin_dir = fullfile(RootDir, 'whistle/bin/');
javaaddpath(java_bin_dir);

% If we didn't find it check in the ant build dir.
if (~exist('tonals.tonal')) 
    java_build_dir = fullfile(RootDir, 'whistle/build');
    javaaddpath(java_build_dir);
end

% If we still didn't find it try to load the distribution
% jar file.
if (~exist('tonals.tonal')) 
    java_dist_dir = fullfile(RootDir, 'whistle/dist');
    java_archives = utFindFiles({'*.jar'}, {java_dist_dir}, 1);
    if ~ isempty(java_archives);
        javaaddpath(java_archives);
    end
end

if (~exist('tonals.tonal')) 
    error('Could not load java classes.');
end

