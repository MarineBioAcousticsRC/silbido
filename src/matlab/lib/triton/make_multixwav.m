% make_multixwav.m
%
% script to run write_hrp2xwavs over many hrp files to make xwavs
%
% BE SURE output directories EXIST BEFORE EXECUTING
%
% 060126 smw
%
% Do not modify the following line, maintained by CVS
% $Id: make_multixwav.m,v 1.1.1.1 2006/09/23 22:31:54 msoldevilla Exp $

% input 
d1 = '/hrp_dump1/';     %input directory name

d2 = '/hrp_dump2/';     %input directory name

f1 = 'Cross1_disk';     %input file name prefix

f2 = '.hrp';            %input file name suffix(extension)

infile = [d1 f1 '01' f2; d1 f1 '02' f2; d1 f1 '03' f2; d1 f1 '04' f2;...
        d2 f1 '05' f2; d2 f1 '06' f2; d2 f1 '07' f2; d2 f1 '08' f2];

% header file
%
hdrfilename = '/home/sean/hdrfiles/Cross1.hdr'

% output
d1 = '/xwav_dump1/Cross1_disks01-04_xwavs/';     %output directory name

d2 = '/xwav_dump2/Cross1_disks05-08_xwavs/';     %output directory name

outdir = [d1; d1; d1; d1; d2; d2; d2; d2];


disp(infile)
disp(hdrfilename)
disp(outdir)


for di = 1 : 8
    disp(['Convert File ',infile(di,:)])
    write_hrp2xwavs(infile(di,:),hdrfilename,outdir(di,:),1);
end

