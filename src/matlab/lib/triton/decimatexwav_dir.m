function decimatexwav_dir(void)
%
% decimatexwav_dir.m
%
% ripped off from decimatexwav.m
%
% smw 050225
% 060219 - 060227 smw modified for v1.60
%
% Do not modify the following line, maintained by CVS
% $Id: decimatexwav_dir.m,v 1.4 2009/08/06 19:57:49 mroch Exp $
global PARAMS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get input directory with only x.wav files
%
ii = 1;
PARAMS.ddir = 'C:\';     % default directory
PARAMS.idir{ii} = uigetdir(PARAMS.ddir,['Select Directory ',num2str(ii),' with only XWAV files']);
% if the cancel button is pushed, then no file is loaded so exit this script
if strcmp(num2str(PARAMS.idir{ii}),'0')
    disp_msg('Canceled Button Pushed - no directory for PSD output file')
    return
else
    disp_msg('Input file directory : ')
    disp_msg([PARAMS.idir{ii}])
%     disp(' ')
end
% get info on xwav files in dir
d = dir(fullfile(PARAMS.idir{ii},'*.x.wav'));    % directory info

PARAMS.fname{ii} = char(d.name);                % xwav file names
fnsz = size(PARAMS.fname{ii});
PARAMS.nfiles{ii} = fnsz(1);   % number of xwavs in directory

disp_msg(['Number of XWAV files in Input file directory is ',num2str(PARAMS.nfiles{ii})])

PARAMS.inpath = [PARAMS.idir{ii},'\'];
PARAMS.ftype = 2;   % files are xwavs

% first file's sample rate
PARAMS.infile = deblank(PARAMS.fname{ii}(1,:));
rdxwavhd        % get datafile info
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get user input decimation factor
PARAMS.df = 100; % initial decimation factor

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

% decimation factor
PARAMS.df = str2num(deal(in{1}));
% need to check that df is integer
if PARAMS.df - floor(PARAMS.df) ~= 0
    disp_msg([num2str(PARAMS.df),'  is not an integer - try again'])
    return
end

% newfs = PARAMS.fs/PARAMS.df;       %new sample rate

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get output directory for decimated x.wav files
%
PARAMS.odir{ii} = uigetdir(PARAMS.ddir,['Select Directory ',num2str(ii),' for Output Decimated XWAV files']);
% if the cancel button is pushed, then no file is loaded so exit this script
if strcmp(num2str(PARAMS.odir{ii}),'0')
    disp_msg('Canceled Button Pushed - no directory for PSD output file')
    return
else
    disp_msg('Output decimated file directory : ')
    disp_msg([PARAMS.odir{ii}])
%     disp(' ')
end
PARAMS.outpath = [PARAMS.odir{ii},'\'];

disp_msg('This takes a while, please wait')
tic % start stopwatch timer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% loop over the files and
% get header info, start time, data byte loc and byte length

% for jj = 1:2    % for testing purposes
for jj = 1:PARAMS.nfiles{ii}
    disp_msg(['File Number ', num2str(jj)])
    % these needed for rdxwavhd
    PARAMS.infile = deblank(PARAMS.fname{ii}(jj,:)); % get file names sequentally
   % PARAMS.filesize{jj} = getfield(dir([PARAMS.inpath,PARAMS.infile]),'bytes'); % file length in bytes
    PARAMS.outfile = [PARAMS.infile(1:length(PARAMS.infile)-6),'.d',num2str(PARAMS.df),'.x.wav'];
    PARAMS.xhd.dSubchunkSize = [];
    rdxwavhd        % get datafile info
    
    wrxwavhd(2)

    % nsamp = 2e5;     % number of samples to read/write for each decimate
    nsamp = 15e6;       % number of samples to read/write for each decimation
                    % also the number of samples in each hrp
                    
    % disp(num2str(PARAMS.xhd.SubchunkSize))
                    
    total_samples = PARAMS.xhd.dSubchunkSize / PARAMS.samp.byte;

%     dnf = PARAMS.samp.data /nsamp;  % number of decimations -- floating point
    dnf = total_samples /nsamp; % number of decimations -- floating point

    dn = floor(dnf);            % integer number of decimations
    drem = dnf - dn;            % remainder (percentage) number of decimations
if drem ~= 0
    disp_msg(['remainder of decimated samples ', num2str(drem)])
end
    if (drem > 0)               % most typical case
        dn = dn + 1;
        nsampLast = floor(nsamp * drem);
    elseif drem == 0
        disp_msg('all decimations same size')
        nsampLast = nsamp;
    elseif drem < 0
        disp_msg('error -- not possible')
    end

     disp_msg(['Number of decimations : ',num2str(dn)])
%     disp(' ')

    % main loop to read in data from xwav, decimate, then write out to new xwav
    % file
    fid = fopen(fullfile(PARAMS.inpath,PARAMS.infile),'r');
    fod = fopen(fullfile(PARAMS.outpath,PARAMS.outfile),'a');   % open as append, don't need to fseek
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
        %fwrite(fod,decimate(data,PARAMS.df,'fir'),'int16');

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

    fclose(fid);
    fclose(fod);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % input good header values for xwav now that it is written
% removed 060629 smw
%
% %     databytelength = ((nsamp * (dn-1) + nsampLast) * PARAMS.xhd.BitsPerSample / 8) / PARAMS.df;
% % 
% %     fod = fopen([PARAMS.outpath,PARAMS.outfile],'r+');
% %     %
% %     fseek(fod,4,'bof');
% %     ChunkSize = databytelength + PARAMS.xhd.byte_loc(1) - 8;
% %     fwrite(fod,ChunkSize,'uint32');
% % 
% %     fclose(fod);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
toc
