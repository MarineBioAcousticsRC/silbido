function [f, uppc, tffile] = tfmap(filename, channel, channels, f_desired)
% [f, uppc] = function tfmap(filename, channel, f_desired, verbose)
% transfer function map
% Given a filename and channel, determine which transfer function to use.
% Currently rather primitive (table lookup) and is only used
% in dtHighResClickBatch but transfer function handling should
% be done everywhere.
%
% If the optional argument f_desired is given, the transfer
% function is linearly interpolated to the specified frequency
% range.  Extrapolation is permitted, but should be used with
% caution.

error(nargchk(3,4,nargin))

% map to accomplish:  filename --> transfer fn file
% map contains regular expressions that are compared to
% the input filename sequentially.  When the first match
% occurs, the corresponding file is loaded and f, uppc
% are set to the appropriate frequencies and offsets.

basedirs = {
    'D:\home\bioacoustics\transfer-fns'
    'C:/users/Corpora/transfer-fns'
    '/lab/speech/corpora/Paris-ASA/transfer-fns'
    };

% preamp board assignments as per Brent Hurley's e-mail of 11/12/2008
a100array = {'A100', 'A101', 'A113', 'A103', 'A104', 'A105', 'A106'};
% FLIP Oct 2006 
% VLA - vertical long array
% consisted for VLA array with 6 channels:
% 1-4 HF only
% 5 unknown, ask Liz Henderson if needed
% 6 LF+HF
% 7 was connected to the H300 preamp of the Jessica array
% 8 IRIG-B
% At off times, disk space was conserved by only recording 4 channels:
% 1 - VLA channel 1
% 2 - VLA channel 6
% 3 - Jessica array channel 7
% 4 - IRIG-B
% Note that we do not currently have an HF335 transfer function, but as
% this channel was not used in the dataset we are currently working with,
% this does not present a serious problem.
flip_vla0610_8 = {'HF334', 'HF335', 'HF336', 'HF337', 'HF338', 'HF339', 'H300'};
flip_vla0610_4 = {'HF334', 'HF339', 'H300'};

% talk to Greg about number of channels on socal/jessica
% San Celemente Island preamp information from Greg C and Liz H
% Used to arrays in 2006/2007:  Jessica and SOCAL (aka cascadia)
jessica_pre070316 = {'H300', 'H300'};
jessica_post070316 = {'HF338' 'HF338'};
% socal = {'HT324'};  % 2006/2007 only
% socal - HT324 transfer function does not match one in log book
% Brent will retest the board.  In the mean time, we are using
% the H300 board from the Jessica pre 070316 transfer function
% as a stand in.
socal = {'H300', 'H300'};

map = {
    'CC0411', {'A103'}  % best guess, unknown as 100 Series A
    '(SC03|CC0604)', a100array
    'SCI0608-N1-06081[45]', jessica_pre070316
    'SCI0608-N1-06081[26]', socal
    'SCI0608-Ziph-06081[3679]', jessica_pre070316
    'FLIP0610-VLA', flip_vla0610_8
    % San Clemente files that were never renamed to include the RHIB...
    'Lo-B16h40m44s21apr2007y.wav', socal
    'Lo-B19h25m19s21apr2007y.wav', socal
    'Lo-B21h33m31s21apr2007y.wav', socal
    'Lo-B23h02m46s17apr2007y.wav', socal
    'Tt-B14h43m26s17apr2007y.wav', socal
    'Lb-B16h42m16s21apr2007y.wav', jessica_post070316
    'Lo-B23h23m36s21apr2007y.wav', jessica_post070316
    'Tt-B17h34m17s22apr2007y.wav', jessica_post070316
    };

% See if filename matches a map entry
idx = 1;
found = false;
while ~ found && idx <= size(map, 1)
    if regexp(filename, map{idx, 1})
        found = true;
    else
        idx = idx + 1;
    end
end

debug = false;
if found
    % special case for flip-vla
    if strcmp(map{idx,1}, 'FLIP0610-VLA') && channels == 4
        % use night time configuration
        map{idx, 2} = flip_vla0610_4;
    end
    if debug
        fprintf('%s %d/%d-> %s\n', filename, channel, channels, ...
            map{idx,2}{channel});
    end
    
    tf_fname = [map{idx,2}{channel}, '.tf']; % transfer fn file name
    % See if it exists in any of the directories...
    didx = 0;
    fid = -1;  % initialize file handle to failure
    while fid == -1 && didx <= length(basedirs)
        didx = didx + 1;
        tf_file = fullfile(basedirs{didx}, tf_fname);
        fid = fopen(tf_file,'r');
    end
    
    if fid ~= -1
        % read in transfer function file
        [A,count] = fscanf(fid,'%f %f',[2,inf]);
        f = A(1,:);
        uppc = A(2,:);    % [dB re uPa(rms)^2/counts^2]
        fclose(fid);
        
        % If user wants response for different frequencies than those
        % in the transfer function, use linear interpolation.  Check
        % for different frequencies is a bit of a kludge, there's
        % probably a better way to do this...
        if nargin > 1 && ...
                (length(f_desired) ~= length(f) || sum(f_desired ~= f))
            % interpolate for frequencies user wants
            uppc = interp1(f, uppc, f_desired, 'linear', 'extrap');
            f = f_desired;
        end
    else
        msg = sprintf('Unable to open transfer function %s in any of {%s}', ...
            tffile, sprintf('%s ', basedirs{:}));
        error('TRANSFER_FN', msg);
    end
else
    f = [];       % no transfer fn
    uppc = [];
    tf_file = [];
end
