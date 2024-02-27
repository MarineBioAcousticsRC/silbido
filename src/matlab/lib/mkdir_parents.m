function mkdir_parents(path, verbose)
% mkdir_parents(path, verbose)
% Make the directory specified in path.
% If parents in path do not exist, they will be created.
% If verbose present and > 0, a message is displayed for each directory
% created.

narginchk(1,2);
if nargin < 2
    verbose = 0;
end

[parent, d] = fileparts(path);
% Make sure that parent exists
if ~ exist(parent, "dir")
    mkdir_parents(parent)
end
% Make sure that path exists
if ~exist(path, "dir")
    if verbose > 0
        fprintf("Creating %s\n", path)
    end
    mkdir(path)
end