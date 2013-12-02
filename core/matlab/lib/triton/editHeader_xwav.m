function editHeader_xwav()
%
% editHeader_psds.m
%
% 060226 - 060227 smw
%
% used to change time or other header values for xwav files
%
%
% Do not modify the following line, maintained by CVS
% $Id: editHeader_xwav.m,v 1.4 2007/10/16 21:09:12 msoldevilla Exp $
%
global PARAMS HANDLES

%
% user interface retrieve file to open through a dialog box
boxTitle1 = 'Open XWAV File to Modify';   % psds is old neptune format
filterSpec1 = '*.x.wav';
[PARAMS.infile,PARAMS.inpath]=uigetfile(filterSpec1,boxTitle1);

% if the cancel button is pushed, then no file is loaded so exit this script
if strcmp(num2str(PARAMS.infile),'0')
    return
else % give user some feedback
    disp_msg('Opened XWAV File to Modify: ')
    disp_msg(fullfile(PARAMS.inpath, PARAMS.infile))
    cd(PARAMS.inpath)
end

% Get Header timing info and load up PARAMS

rdxwavhd

% user input dialog box
% prompt(1) = {'Raw File Start Times'};
prompt = {'yy mm dd HH MM SS mmm'};
dlgTitle=['Modify XWAV Header ',fullfile(PARAMS.inpath,PARAMS.infile)];
lineNo=PARAMS.xhd.NumOfRawFiles;

% raw file timing headers format YY MM DD HH MM SS mmm
% for k = 1:PARAMS.xhd.NumOfRawFiles
% %
% %     PARAMS.raw.dvecStart(i,:) = [PARAMS.xhd.year(i) PARAMS.xhd.month(i)...
% %         PARAMS.xhd.day(i) PARAMS.xhd.hour(i) PARAMS.xhd.minute(i) ...
% %         PARAMS.xhd.secs(i)+(PARAMS.xhd.ticks(i)/1000)];

y = [PARAMS.xhd.year' PARAMS.xhd.month' ...
        PARAMS.xhd.day' PARAMS.xhd.hour' PARAMS.xhd.minute' ...
        PARAMS.xhd.secs' PARAMS.xhd.ticks'];
    
def={num2str(y)};
% def={num2str(PARAMS.raw.dvecStart)};

AddOpts.Resize='on';
AddOpts.WindowStyle='normal';
AddOpts.Interpreter='tex';

in = inputdlg(prompt,dlgTitle,lineNo,def,AddOpts);

if length(in) == 0	% if cancel button pushed
    return
end

% input is 1x1 cell array
input = deal(in);

% need to convert cell to string, then to number
x = str2num(char(input));

% double check to make sure okay to change header values:
button = questdlg('Are you sure you want to CHANGE this file header?','Warning: Changing Header!','No');

if isempty(button) | ~strcmp(button,'Yes')
    return
end

% open 
fod = fopen(fullfile(PARAMS.inpath,PARAMS.infile),'r+');

offset1 = 100;      % number of bytes to skip in header before timing values

for k = 1:PARAMS.xhd.NumOfRawFiles
    skip = offset1 + ((k-1) * 32);
    fseek(fod,skip,'bof');

    fwrite(fod, x(k,1), 'uchar');
    fwrite(fod, x(k,2), 'uchar');
    fwrite(fod, x(k,3), 'uchar');
    fwrite(fod, x(k,4), 'uchar');
    fwrite(fod, x(k,5), 'uchar');
    fwrite(fod, x(k,6), 'uchar');
    fwrite(fod, x(k,7), 'uint16');

    % don't need write any more header info
    %
    %     fwrite(fod, PARAMS.xhd.byte_loc(k), 'uint32');
    %     fwrite(fod, PARAMS.xhd.byte_length(k), 'uint32');
    %     fwrite(fod, PARAMS.xhd.write_length(k), 'uint32');
    %     fwrite(fod, PARAMS.xhd.sample_rate(k), 'uint32');
    %     fwrite(fod, PARAMS.xhd.gain(k), 'uint8');
    %     fwrite(fod, 0, 'uchar'); % padding
    %     fwrite(fod, 0, 'uchar');
    %     fwrite(fod, 0, 'uchar');
    %     fwrite(fod, 0, 'uchar');
    %     fwrite(fod, 0, 'uchar');
    %     fwrite(fod, 0, 'uchar');
    %     fwrite(fod, 0, 'uchar');

end

fclose(fod);

disp_msg(['Finished modifying XWAV File: ',fullfile(PARAMS.inpath,PARAMS.infile)])

