function decimatexwav(void)
%
% decimatexwav.m
% 
% ripped off of hrp2xwav.m, but much different
%
% smw 15 June 2004
% 
% 060222 - 060227 smw modified to work with triton v1.60
% 
% 060609 - smw fix bug with 'non-perfect' data v1.61
%
% Do not modify the following line, maintained by CVS
% $Id: decimatexwav.m,v 1.2 2007/05/12 01:25:05 mroch Exp $

global PARAMS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
% get file name
%
filterSpec1 = '*.x.wav';
boxTitle1 = 'Open XWAV file to Decimate';
% user interface retrieve file to open through a dialog box
[PARAMS.infile,PARAMS.inpath]=uigetfile(filterSpec1,boxTitle1);
% if the cancel button is pushed, then no file is loaded
% so exit this script
if strcmp(num2str(PARAMS.infile),'0')
    infile = num2str(PARAMS.infile);
    return
else
    disp_msg('Opened File: ')
    disp_msg(fullfile(PARAMS.inpath,PARAMS.infile))
%     disp(' ')
    cd(PARAMS.inpath)
end
%
PARAMS.ftype = 2;   % file is xwav  
rdxwavhd        % get datafile info
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get user input decimation factor
PARAMS.df = 100; % initial decimation factor
%
% user input dialog box
prompt={'Enter Decimation Factor (integer) : '};
def={num2str(PARAMS.df)};
dlgTitle=[num2str(PARAMS.fs),' = Original Sample Rate',];
lineNo=1;
AddOpts.Resize='on';
AddOpts.WindowStyle='normal';
AddOpts.Interpreter='tex';
in=inputdlg(prompt,dlgTitle,lineNo,def,AddOpts);
if length(in) == 0	% if cancel button pushed
    return
end
%
% decimation factor
PARAMS.df = str2num(deal(in{1}));
% need to check that PARAMS.df is integer
if PARAMS.df - floor(PARAMS.df) ~= 0
    disp_msg([num2str(PARAMS.df),'  is not an integer - try again'])
    return
end

disp_msg(['Orginal Sample Rate: ',num2str(PARAMS.fs)])
disp_msg(['Decimation Factor: ',num2str(PARAMS.df)])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% open new decimated output file
% base name on input file
PARAMS.outfile = [PARAMS.infile(1:length(PARAMS.infile)-6),'.d',num2str(PARAMS.df),'.x.wav'];
PARAMS.outpath = PARAMS.inpath;
boxTitle2 = 'Save Decimated XWAV file';
%
[PARAMS.outfile,PARAMS.outpath] = uiputfile(PARAMS.outfile,boxTitle2);
%
if PARAMS.outfile == 0
    disp_msg('Cancel Save Decimated XWAV File')
    return
end

wrxwavhd(2)

%%%%%%%%%%%%%%%%%%
fid = fopen(fullfile(PARAMS.inpath,PARAMS.infile),'r');

fod = fopen(fullfile(PARAMS.outpath,PARAMS.outfile),'a');   % open as append, 
                                                    % don't need to fseek
%
% nsamp = 2e5;     % number of samples to read/write for each decimate
nsamp = 15e6;       % number of samples to read/write for each decimation
                    % also the number of samples in each hrp raw file
%
total_samples = PARAMS.xhd.dSubchunkSize / PARAMS.samp.byte;
% dnf = PARAMS.samp.data /nsamp;  % number of decimations -- floating point
dnf = total_samples/nsamp;  % number of decimations -- floating point

dn = floor(dnf);            % integer number of decimations
drem = dnf - dn;            % remainder (percentage) number of decimations
if drem ~= 0
    disp_msg(['remainder of decimated samples ', num2str(drem)])
end
%
if (drem > 0)               % most typical case
    dn = dn + 1;
    nsampLast = floor(nsamp * drem);
elseif drem == 0
    disp_msg('all decimations same size')
    nsampLast = nsamp;
elseif drem < 0
    disp_msg('error -- not possible')
end
%
disp_msg(['Number of decimations : ',num2str(dn)])
% disp(' ')
disp_msg('This takes a while, please wait')
tic % start stopwatch timer
% main loop to read in data from xwav, decimate, then write out to new xwav
% file
for di = 1:dn
    if di == dn
        nsamp = nsampLast; % number of samples for last decimation
    end
    % jump over header and the number of decimations done so far...
    fseek(fid,PARAMS.xhd.byte_loc(1) +...
        (di-1)*nsamp*PARAMS.nch*PARAMS.samp.byte,'bof');
    % read the data
    data = fread(fid,[PARAMS.nch,nsamp],'int16');
    %decimate and write
    fwrite(fod,decimate(data,PARAMS.df),'int16');
%     fwrite(fod,decimate(data,PARAMS.df,'fir'),'int16');
    
    % ndata = decimate(x,PARAMS.df); 
    % eighth-order lowpass Chebyshev Type I
    % filter. It filters the input sequence in both
    % the forward and reverse directions to remove
    % all phase distortion, effectively doubling the
    % filter order.
    
    % ndata = decimate(x,PARAMS.df,'fir'); 
    % uses a 30-point FIR filter, instead of
    % the Chebyshev IIR filter. Here decimate
    % filters the input sequence in only one direction.
    % This technique conserves memory and is useful
    % for working with long sequences.

end
toc 
fclose(fid);
fclose(fod);

% removed 060610 smw
%
% %
% % input good header values for xwav now that it is written
% databytelength = ((nsamp * (dn-1) + nsampLast) * PARAMS.xhd.BitsPerSample / 8) / PARAMS.df;
% %
% fod = fopen([PARAMS.outpath,PARAMS.outfile],'r+');
% %
% fseek(fod,4,'bof');
% ChunkSize = databytelength + PARAMS.xhd.byte_loc(1) - 8;
% fwrite(fod,ChunkSize,'uint32');
% 
% %
% fclose(fod);
% %
