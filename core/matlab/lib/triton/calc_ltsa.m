function result = calc_ltsa
%
% calculate spectral averages and save to ltsa file
%
% called by mk_ltsa
%
% 060612 smw
%
%
% Do not modify the following line, maintained by CVS
% $Id: calc_ltsa.m,v 1.12 2009/08/21 12:41:44 mroch Exp $

result = true;  % Assume success
global PARAMS
tic
disp('calculating  spectral averages, Matlab window will be unresponsive')

window = hanning(PARAMS.ltsa.nfft);
overlap = 0;
noverlap = round((overlap/100)*PARAMS.ltsa.nfft);

sampPerAve = PARAMS.ltsa.tave * PARAMS.ltsa.fs;
bytesPerAve = sampPerAve * PARAMS.ltsa.nBits/8;
rawFileCountField = 80; % offset into xwav file for raw files

% open output file
fod = fopen(fullfile(PARAMS.ltsa.outdir,PARAMS.ltsa.outfile),'r+');

m = 0;
count = 0;
ProgressH = waitbar(0, 'Processing - Matlab will be unresponsive', ...
                    'Name', 'LTSA Computation');
for k = 1:PARAMS.ltsa.nxwav            % loop over all xwavs
    ProgressTitle = ...
        sprintf('Processing %d of %d - Matlab will be unresponsive', ...
                k, PARAMS.ltsa.nxwav);
    waitbar((k-1)/PARAMS.ltsa.nxwav, ProgressH, ProgressTitle);
    drawnow expose;     % redraw, but don't allow processing of new events
    if PARAMS.ltsa.ftype ~= 1           % only for HARP and ARP & OBS data
        % open xwav file
        fid = fopen(fullfile(PARAMS.ltsa.indir,PARAMS.ltsa.fname{k}),'r');
        fseek(fid, rawFileCountField, 'bof');
        nrf = fread(fid,1,'uint16');         % Number of RawFiles in XWAV file (80 bytes from bof)

    else                                % wav/Ishmael data
      nrf = 1;  % Fake number of raw files

      % Read wave header information and get handle.
      % Once this works for xwav as well, merge above if/else
      hdr = ioReadWavHeader(fullfile(PARAMS.ltsa.indir,PARAMS.ltsa.fname{k}));
      fid = fopen(fullfile(PARAMS.ltsa.indir,PARAMS.ltsa.fname{k}),'r');
      % Determine channel based on file characteristics
      % NOTE:  This is not automatically determined.  
      %        Examine channelmap to make certain that
      %        values are reasonable.
      channel = channelmap(hdr, ...
          fullfile(PARAMS.ltsa.indir,PARAMS.ltsa.fname{k}));
    end

    for r = 1:nrf                       % loop over each raw file in xwav
        m = m + 1;                  % count total number of raw files
        % jump to correct place in output file to put spectral averages
        status = fseek(fod,PARAMS.ltsa.byteloc(m),'bof');
        if status == -1
          try
            % Generate stack trace
            error('triton:internal_error', 'fseek past end of file');
          catch
            fclose(fod);
            % Display error dialog with backtrace, note failure, abort.
            guErrorBacktrace(lasterror, 'Internal error', ...
                             'Seek past end of file - contact developers');
            result = false;
            delete(ProgressH);  % remove progress bar
            return      % abort
          end
        end
        
        xi = 0;
        for n = 1 : PARAMS.ltsa.nave(m) % loop over the number of spectral averages

            if PARAMS.ltsa.ftype ~= 1       % xwavs (count bytes)
                % start Byte location in xwav file of spectral average
                if n == 1
                    xi = PARAMS.ltsahd.byte_loc(m);
                else
                    xi = xi + (bytesPerAve * PARAMS.ltsa.nch);
                end
            else                    % wav files (count samples)
                if n == 1
                    yi = 1;
                else
                    yi = yi + sampPerAve;
                end
            end

            % check to see if full data for average
            %             nave1 = (PARAMS.ltsahd.write_length(m) * 250)/(PARAMS.ltsa.nfft * PARAMS.ltsa.cfact);
            if PARAMS.ltsa.ftype ~= 1       % xwavs
                nave1 = (PARAMS.ltsahd.write_length(m) * PARAMS.ltsa.blksz)/(PARAMS.ltsa.nfft * PARAMS.ltsa.cfact);
            else                            % wavs
                nave1 = PARAMS.ltsahd.nsamp(m)/(PARAMS.ltsa.nfft * PARAMS.ltsa.cfact);
            end

            dnave = PARAMS.ltsa.nave(m) - nave1;    % difference the number of averages and size of raw file

            % number of samples to grab
            if dnave == 0       % number of averages divide evenly into size of raw file
                nsamp = sampPerAve;
            else
                if n == PARAMS.ltsa.nave(m)     % last average, data not full number of samples
                    %                     nsamp = (PARAMS.ltsahd.write_length(m) * 250) - ((PARAMS.ltsa.nave(m) - 1) * sampPerAve);
                    if PARAMS.ltsa.ftype ~= 1       % xwavs
                        nsamp = (PARAMS.ltsahd.write_length(m) * PARAMS.ltsa.blksz) - ((PARAMS.ltsa.nave(m) - 1) * sampPerAve);
                    else
                        nsamp = PARAMS.ltsahd.nsamp(m)  - ((PARAMS.ltsa.nave(m) - 1) * sampPerAve);
                    end                             % wav
                    PARAMS.ltsa.dur = nsamp / PARAMS.ltsa.fs;
                else
                    nsamp = sampPerAve;
                end
            end
            
%             % check if last average is full or partial
%             rNave = 0;      % remainder of non-integer number of averages
%             rNave =  ((PARAMS.ltsahd.write_length(m) * 250)/(PARAMS.ltsa.nfft * PARAMS.ltsa.cfact)) - PARAMS.ltsa.nave(m);
% 
%             if n == PARAMS.ltsa.nave(m) && rNave ~= 0
%                 nsamp = PARAMS.ltsahd.write_length(m) * 250 - ((PARAMS.ltsa.nave(m) - 1) * sampPerAve);
%             else
%                 nsamp = sampPerAve;
%             end
            
            % clear data vector
            data = [];
            % jump to correct location in xwav file
            if PARAMS.ltsa.ftype ~= 1
                fseek(fid,xi,'bof');
                % get data for spectra
                if nsamp == sampPerAve
                    data = fread(fid,[PARAMS.ltsa.nch,nsamp],PARAMS.ltsa.dbtype);   %
                else            % add pad with zeros if not full data for spectra average
                    data = fread(fid,[PARAMS.ltsa.nch,nsamp],PARAMS.ltsa.dbtype);
                    %                 padsize = sampPerAve - nsamp;
                    %                 data = padarray(data,padsize);
                end
                data = data(PARAMS.ltsa.ch,:);
            else
                
              dall = ioReadWav(fid, hdr, yi, yi-1+nsamp);
              % Determine channel based on file characteristics
              % NOTE:  This is not automatically determined.  
              %        Examine channelmap to make certain that
              %        values are reasonable.
              data = dall(:,channel);
            end

            % if not enough data samples, pad with zeroes
            %             if nsamp < PARAMS.ltsa.nfft
            dsz = length(data);
            if dsz < PARAMS.ltsa.nfft
                %                 dz = zeros(PARAMS.ltsa.nfft-nsamp,1);
                dz = zeros(PARAMS.ltsa.nfft-dsz,1);
                data = [data;dz];
                disp_msg(sprintf('File %s, raw %d Ave %d DataSize: %d < %d', ...
                                 PARAMS.ltsa.fname{k}, r, n, ...
                                 dsz, PARAMS.ltsa.nfft));
                % disp_msg('Paused ... press any key to continue')
                % pause
            end

            % calculate spectra
            [ltsa,freq] = PWELCH(data,window,noverlap,PARAMS.ltsa.nfft,PARAMS.ltsa.fs);   % pwelch is supported psd'er
            ltsa = 10*log10(ltsa); % counts^2/Hz
            % write data
            fwrite(fod,ltsa,'int8');
            count = count + 1;
        end     % end for n - loop over the number of spectral averages
    end     % end for r - loop over each raw file
    fclose(fid);        % close input data file
    disp_msg(sprintf('Processed audio file %d/%d (%d%%)', ...
                     k, PARAMS.ltsa.nxwav, ...
                     round(k/PARAMS.ltsa.nxwav*100)))
    drawnow expose      % udpate GUI
end     % end for k - loop over each xwav file
% close output ltsa file
fclose(fod);
disp_msg(sprintf('Time to calculate %d spectra is %s', ...
    count, sectohhmmss(toc)));
disp_msg(sprintf('LTSA %s complete', ...
    fullfile(PARAMS.ltsa.outdir,PARAMS.ltsa.outfile)));
delete(ProgressH);      % delete progress bar
