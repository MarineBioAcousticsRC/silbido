function [ltsainfo, success] = get_ltsaparams(ltsainfo)
% [ltsainfo, success] = get_ltsaparams(ltsainfo)
% get parameters needed for generating LTSA's from user
%
% called by mk_ltsa
%
% stolen from neptune program get_psdsparams
% 060508 smw
% 060914 smw modified for wav files
%
% Do not modify the following line, maintained by CVS
% $Id: get_ltsaparams.m,v 1.4 2007/05/13 19:18:10 mroch Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

success = true;  % Assume good until proven otherwise

prompt={'Time Average Length [seconds] : ',...
        'Frequency Bin Size [Hz] :'};

% default averaging time [s] and frqequency bin size [Hz]
def={'5', '100'};

if ltsainfo.ltsa.nch(1) > 1
  % more thanone LTSA channel, add to prompts
  prompt{end+1} = sprintf('Channel to include 1 to %d', ltsainfo.ltsa.nch(1));
  def{end+1} = '1';
end

dlgTitle='Set Long-Term Spectrogram Parameters';
lineNo=1;
AddOpts.Resize='on';
AddOpts.WindowStyle='normal';
AddOpts.Interpreter='tex';
% display input dialog box window
in=inputdlg(prompt,dlgTitle,lineNo,def,AddOpts);
if length(in) == 0	% if cancel button pushed
    success = false;
    return
end

ltsainfo.ltsa.tave = str2double(in{1});
ltsainfo.ltsa.dfreq = str2double(in{2});

if length(in) > 2
  ltsainfo.ltsa.ch = str2double(in{3});
else
  ltsainfo.ltsa.ch = 1;
end

