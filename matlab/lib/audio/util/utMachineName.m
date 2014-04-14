function String = utMachineName
% String = utMachineName
% Determine name of machine
if isunix
  % Try to retrieve name from environment, otherwise use uname
  String = getenv('HOSTNAME');
  if strcmp(String, '')
    [result, String] = system('uname -n');
  end
else
  % Try to retrieve name from environment.
  String = getenv('%computername%');
end

if strcmp(String, '')
  String = 'unknown';
end
