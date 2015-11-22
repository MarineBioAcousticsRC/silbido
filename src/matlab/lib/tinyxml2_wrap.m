%  tinyxml2_wrap - XML serializing/deserializing of MATLAB arrays
%  usage:
%    tinyxml2('save', filename, variable)
%    tinyxml2('save', filename, variable, options)
%    variable = tinyxml2('load', filename)
%
%
%   options.fp_format_double = '%.17le';   % default:  %lg
%   options.fp_format_single = '%.7e';     % default:  %g
%   options.store_class = 1;               % default: 1    - saves class of variables
%   options.store_size = 1;                % default: 1    - saves sizes of arrays (required for 2D arrays)
%
%
%  errors throw exceptions
%
%
%  Author:  Ladislav Dobrovsky
%           ladislav.dobrovsky@gmail.com
%
%  Modifications:
%   2015-02-28     Peter van den Biggelaar    Handle structure similar to xml_load from Matlab Central

%   2015-03-05     Ladislav Dobrovsky         Function handles load/save  (str2func, func2str)
%   2015-03-05     Peter van den Biggelaar    Support N-dimension arrays
%
%
%  see tinyxml2.h - Original code by Lee Thomason (www.grinninglizard.com)
%
%
%  compilation:   mex tinyxml2_wrap.cpp

function varargout = tinyxml2_wrap(varargin)
    fname = which(mfilename);
    [dir, fname] = fileparts(fname);
    
    error(sprintf(['%s must be compiled with a C++ compiler.\n', ...
        'If needed,\n\t1 - install supported C++ compiler\n', ...
        '\t2 - Execute "mex -setup"\n', ...
        'Then\n\t1 - Execute:  cd %s\n', ...
        '\t2 - Execute:  mex %s\n'], fname, dir, [fname, '.cpp']))
