function difftime_rawHARPdirlist()
%
%
% difference sequential dirlist times to see if there are any timing errors
% if there are timing errors, report them
%
% smw 051031
% smw 060201
%
%
% Do not modify the following line, maintained by CVS
% $Id: difftime_rawHARPdirlist.m,v 1.2 2006/10/05 23:14:53 msoldevilla Exp $
global PARAMS

% name = 'OCNMS1';
% name = 'SC01A_DL07';
% name = 'Bering3M2';
%name = 'newDL15';
% name = 'OCNMS2';
% name = 'Cross1';
% name = 'GofCA3';
% name = 'GofCA2';
% name = 'HARO';
name = 'GC4A6';

% linux waterpup
% pname = ['/home/sean/diskdump/',name,'_head/'];
% pc tablet waterpup
% pname = ['D:\DATA\HARP\DataQuality+dirlist\',name,'_head/'];
% waterdawg
pname = ['E:\HARP Data\GC4\',name,'_head\'];
disp(' ')
disp('Data quality check w/ difftime_rawHARPdirlist.m')
disp(' ')
% loop over 16 disks
%for k = 1:16
%    for k = 16
for k = 14:14
    dstr = sprintf('%02d',k);
    fname = [pname,name,'_disk',dstr,'_head.hrp'];
    disp('***********************************************************')
    disp(fname)
    disp(['Disk ',dstr])
    %     if k ~= 14
    read_rawHARPhead(fname,1);  % disk header info displayed
    read_rawHARPdir(fname,0);   % read dirlist
      cktime_dirlist(fname,1);   % d
    % cktime_dirlist(fname,0);

    %     else
    %         disp('Disk Header Corrupt')
    %     end
end