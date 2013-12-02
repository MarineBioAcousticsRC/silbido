function Base = utBaseName(Path)
% Base = utBaseName(Path)
% Equivalent to the Bourne/Korn basename shell command
% Both / and \ are considered as path separators.

Indices = union(findstr(Path, '/'), findstr(Path, '\'));
Base = Path(Indices(end)+1:end);

