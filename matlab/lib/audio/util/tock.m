function tock
% tock - Formatted version of toc, prints a pretty HH:MM:SS elapsed
% time message when used with tic.
%
% See also:  tic, toc

Elapsed = toc;
fprintf('Elapsed time %s\n', sectohhmmss(Elapsed));
