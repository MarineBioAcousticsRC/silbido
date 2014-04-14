function Args = utVarArgsPartition(varargin)
% Args = utVarArgsPartition('argtype', ArgType1, Arg1, Arg2, ..., ArgN
%			'argtype', ArgType2, args...
%			...
%			'argtype', ArgTypeN, args...)
% Processes multiple keyword argument sets.
% Each keyword argument set must be preceded by 'argtype'
% and followed by keyword/value pairs.  Args will be
% a structure whose fields are ArgType1 through ArgTypeN.
% Each of these is a cell array containing the associated
% arguments.
%
% Although not explicitly checked, the argtype 'Parsed' should
% be considered reserved.  Args.Parsed.ArgTypeN may be used
% by the user to store a parsed version of the argument list.
%
% This code is copyrighted 1999 by Marie Roch.
% e-mail:  marie-roch@uiowa.edu
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 


m=1;
ArgCount = length(varargin);

% Prime loop
if varargin{1} ~= 'argtype'
  error('Bad keyword argument set, expected ''argtype''');
else
  ArgStart = 2;
  ArgEnd = 1;
end

while m <= ArgCount
  if isstr(varargin{m})
    switch varargin{m}
      case 'argtype'
	% New argument list type
	% Store any arguments associated with previous argument type
	if (ArgEnd >= ArgStart)
	  eval(sprintf('Args.%s = {varargin{ArgStart:ArgEnd}};', ...
	      CurrentArgType));
	end
	% Set up new argument type list
	ArgEnd = m;
	CurrentArgType = varargin{m+1}; m=m+2;
	ArgStart = m;
      otherwise
	ArgEnd = m;	% Update last argument of current list
	m=m+1;
    end
  else
    ArgEnd = m;	% Update last argument of current list
    m=m+1;
  end
end

% store final arguments
if (ArgEnd >= ArgStart)
  eval(sprintf('Args.%s = {varargin{ArgStart:ArgEnd}};', ...
      CurrentArgType));
end

