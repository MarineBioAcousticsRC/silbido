function get_ltsadir
%
% get directory of wave/xwav files
%
% 060508 smw
%
%
% Do not modify the following line, maintained by CVS
% $Id: get_ltsadir.m,v 1.7 2008/06/21 16:43:57 mroch Exp $

global PARAMS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get the file type
%
prompt={'Enter File Type: (1 = WAVE, 2 = XWAV)'};
def={num2str(PARAMS.ltsa.ftype)};
dlgTitle='Select File Type';
lineNo=1;
AddOpts.Resize='on';
AddOpts.WindowStyle='normal';
AddOpts.Interpreter='tex';
% display input dialog box window
in=inputdlg(prompt,dlgTitle,lineNo,def,AddOpts);
if length(in) == 0	% if cancel button pushed
    PARAMS.ltsa.gen = 0;
    return
else
    PARAMS.ltsa.gen = 1;
end
PARAMS.ltsa.ftype = str2num(deal(in{1}));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get the directory
%
if PARAMS.ltsa.ftype == 1
    str1 = 'Select Directory with WAV files';
elseif PARAMS.ltsa.ftype == 2
    str1 = 'Select Directory with XWAV files';
else
    disp_msg('Wrong file type. Input 1 or 2 only')
    disp_msg(['Not ',num2str(PARAMS.ltsa.ftype)])
    get_ltsadir
end
ipnamesave = PARAMS.ltsa.indir;
PARAMS.ltsa.indir = uigetdir(PARAMS.ltsa.indir,str1);
if PARAMS.ltsa.indir == 0	% if cancel button pushed
    PARAMS.ltsa.gen = 0;
    PARAMS.ltsa.indir = ipnamesave;
    return
else
    PARAMS.ltsa.gen = 1;
    PARAMS.ltsa.indir = [PARAMS.ltsa.indir,'/'];
end

%%%%%%%%%%%%%%%%%%%%%%
% check for empty directory
%
if PARAMS.ltsa.ftype == 1
    d = dir(fullfile(PARAMS.ltsa.indir,'*.wav'));    % wav files
elseif PARAMS.ltsa.ftype == 2
    d = dir(fullfile(PARAMS.ltsa.indir,'*.x.wav'));    % xwav files
end

files = {d.name};          % file names in directory
nfiles = length(files);
filelen = zeros(nfiles, 1);
for k=1:nfiles
  filelen(k) = length(files{k})
end
disp_msg(sprintf('\n%d  data files for LTSA', nfiles));

filelenMax = 40;
if ~ isempty(find(filelen > filelenMax))
  BadFiles = sprintf('%s ', files{find(filelen > filelenMax)});
  error('Filenames must be %d characters or less:  %s', ...
        filelenMax, BadFiles);
end
  
FilelenTooLong = {}
for k=1:nfiles
  if length(files{k}) > 40
    FilenTooLong{end+1} = files{k};
  end
end
if ~ isempty(FilelenTooLong)
    
    

if nfiles < 1
    disp_msg(['No data files in this directory: ',PARAMS.ltsa.indir])
    disp_msg('Pick another directory')
    get_ltsadir
end

% Extract timestamp from filename if available and sort.
% Not needed for file formats that have the recording date encoded
% into the files
% Expected format:  *YYMMDD-HHMMSS* or *YYYYMMDD-HHMMSS*
% Two year digit assumes 21st century, in the unlikely case where more than
% one date string is matched in the same filename, the first one is used.
TimeStrings = regexp(files,'(\d\d)?\d\d\d\d\d\d-\d\d\d\d\d\d','match');
BadMatches = {};
BogusStart = datenum([0 1 1 0 0 0]);
for k = 1:length(TimeStrings)
    if isempty(TimeStrings{k})
        BadMatches{end+1} = files{k};
        dnumStart(k) = BogusStart;
    else
        timestamp = TimeStrings{k}{1};
        if length(timestamp) == 11      % 2 digit year
            dnumStart(k) = datenum(timestamp,'yymmdd-HHMMSS') - ...
                dateoffset();
        else
            dnumStart(k) = datenum(timestamp, 'yyyymmdd-HHMMSS');
        end
    end
end

if ~ isempty(BadMatches)
    BadFiles = sprintf('%s ', BadMatches{:});
    disp_msg(sprintf('\nNo time information from filename for: %s\n', ...
        BadFiles));
end

% Sort filenames by filename timestamp
[DontCare, OrderedIndices] = sort(dnumStart);
PARAMS.ltsa.fname = files(OrderedIndices);
