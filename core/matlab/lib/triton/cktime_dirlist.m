function cktime_dirlist(filename,d)
%
% useage >> cktime_dirlist(filename,d)
%       if d = 1, then display header values in command window
%
% this function reads raw HARP file disk directory and compares times
% between directory entries...used for data quality checking.
%
% smw 050919
% revised smw 051108
%
% Do not modify the following line, maintained by CVS
% $Id: cktime_dirlist.m,v 1.2 2006/10/05 23:14:53 msoldevilla Exp $

global PARAMS

eflag = 1;  % eflag == 1 to show all timing errors

PARAMS.baddirlist = []; % empty it incase it has something left over

% check to see if file exists - return if not
if ~exist(filename)
    disp(['Error - no file ',filename])
    return
end

% display flag: display values = 1
if d
    dflag = 1;
    disp(['Disk # ',num2str(PARAMS.disknumberSector2)])
else
    dflag = 0;
end

% read raw HARP dirlist
read_rawHARPdir(filename,0);

% convert date time into datenumber (days since Jan 01, 0000) Note: year is
% two digits.... ie 2005 is 05
if ~strcmp(deblank(PARAMS.firmwareVersion),'1.14c')
    dnum_dirlist = datenum([PARAMS.dirlist(:,2:6) PARAMS.dirlist(:,7) + PARAMS.dirlist(:,8)/1000]);
else    % don't use milliseconds with old data
    dnum_dirlist = datenum([PARAMS.dirlist(:,2:6) PARAMS.dirlist(:,7)]);
    L = [];
    L = find(PARAMS.dirlist(:,8) ~= 0);
    if ~isempty(L)
        disp(['Number of files with non-zero millisecond values :',num2str(length(L))])
    end
end

% difference sequential directory listings
ddnum = diff(dnum_dirlist);

% convert to seconds and remove round off error
difftime = round(ddnum*60*60*24*1000)./1000;

% check for bad number of sectors recorded
K = [];
K = find(PARAMS.dirlist(:,10) > 60000);


% remaining # bytes in file = # bytes in file -  # sectors / bytes/sector
% should be zero if each file is an integer number of sectors
if isempty(K)
    dbytes = PARAMS.dirlist(:,11) - PARAMS.dirlist(:,10) .* 512 ;
else
    dbytes = PARAMS.dirlist(:,11) - 60000 * 512;
    disp(['Number of files with bad number of sectors recorded : ',num2str(length(K))])
end

J = [];
J = find(dbytes ~= 0);
if ~isempty(J)
    disp('raw HARP file is not integer number of sectors')
    % disp([PARAMS.dirlist(J,1)])
end

% DT[seconds/dirlist] = # sectors * # samples/sector / # samples/ second
% 250 samples / sector (12 bytes (of the 512bytes/sector) are for timing
% header
if isempty(K)
    DT = (PARAMS.dirlist(:,10) .* 250 + dbytes) ./ PARAMS.dirlist(:,9);
else
    DT = (60000 .* ones(length(PARAMS.dirlist(:,10)),1) .* 250 + dbytes) ./ PARAMS.dirlist(:,9);

end


% find times when the
% difference between directory listing is not what it should be
I = [];
if strcmp(deblank(PARAMS.firmwareVersion),'1.14c')
    % DT = 187.5; % for 80kHz continuous
    if PARAMS.dirlist(1,9) == 80000
%         I1 = []; I2 = [];
%         I1 = find(difftime ~= 187);
%         I2 = find(difftime(I1) ~= 188);
%         I = I1(I2);
        I = find(difftime ~= 187 & difftime ~= 188);
    elseif PARAMS.dirlist(1,9) == 200000
        I = find(difftime ~= DT(2:length(DT)));
    end
else
    if strcmp(deblank(PARAMS.firmwareVersion),'1.14e')
        % OCNMS2: 80kHz @ 10min/30min
        % use this one for scheduled data and WITHOUT full files <60000 sects
        % hardwired for scheduled data: 187.5 + 17.5*60 = 1237.5 sec is for 10/30 duration/interval
        dtime1 = 1237.5; dtime2 = 187.5;
        I = find(difftime ~= dtime2 & difftime ~= dtime1);
    elseif strcmp(deblank(PARAMS.firmwareVersion),'1.16')
        % GofCA2: 80kHz @ 10min/20min
        % use this one for scheduled data and WITHOUT full files <60000 sects
        % hardwired for scheduled data: 187.5 + 7.5*60 = 637.5 sec is for 10/20 duration/interval
        dtime1 = 637.5; dtime2 = 187.5;
        I = find(difftime ~= dtime2 & difftime ~= dtime1);
    else
        % use the following for continuous data:
        
        %I = find(difftime ~= DT(2:length(DT)));

        % hardwired for scheduled data: 75 + 20*60 = 1275 sec is for 5/25 duration/interval
       % dtime1 = 1275;
        
        % hardwired for scheduled data: 75 + 30*60 = 1575 sec is for 5/30 duration/interval
        dtime1 = 1575;
        
        % use this one for scheduled data WITH full files (i.e., are are
        % 60000 sectors long
         I = find(difftime ~= DT(2:length(DT)) & difftime ~= dtime1);
    end

end


% goal is to not tag sequential difftime for time that is ok
% in otherwords, a bad difftime happens for a good time happens from
% previous, sequential bad time.

icount = 0;
len = length(I);
Ix=[];
if len == 1 && I(1) == 1    % if the first time is bad
    Ix = 0;
elseif len == 1 && I(1) == length(difftime) % if last one is bad
    Ix = I(1);
elseif len == 2 && I(1) == I(2) - 1
    Ix = I(1);   % only first one is bad
elseif len > 2
    Ix(1) = I(1);
    for k = 2: len-1
        if I(k) == I(k-1) + 1 && I(k+1) ~= I(k) + 1
            % don't use this I(k), it's ok...
        else
            icount = icount+1;
            Ix(icount) = I(k);
        end
    end
    if I(len) == I(len-1) + 1
        % don't use last one
    else
        icount = icount+1;
        Ix(icount) = I(len);
    end
end
% increase indices by 1
Ix = Ix'+1;

% more work is need on following:
if Ix > 1
    PARAMS.baddirlist = [Ix difftime(Ix-1) PARAMS.dirlist(Ix,:)];
elseif Ix == 1
        PARAMS.baddirlist = [Ix difftime(Ix) PARAMS.dirlist(Ix,:)];
end

if d
    if isempty(Ix)
        disp('Number of directory list timing errors = 0')
        disp(['Number of raw files tested = ',num2str(length(dnum_dirlist))])
        disp(' ')
    else
        %         disp(['Disk # ',num2str(PARAMS.disknumberSector2),'
        %         Difftime == ',num2str(DT)])
        disp(['Number of directory list timing errors = ',num2str(length(Ix))])
        disp(['Number of raw files tested = ',num2str(length(dnum_dirlist))])
        if eflag
        % comment the next line if want summary without timing errors displayed
            disp(num2str(sprintf('%5d %12.3f %10d %2d %3d %3d %3d %3d %3d %7d %7d %12d %12d\n',PARAMS.baddirlist')))
        end
        disp(' ')
    end
end

