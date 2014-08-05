function val = trkBIC_nFold(segin, winoffsetin, EnergyPct)

% function val = trkBIC_rmloweng(segvect, engvect, winoffset)
% finds low energy frame according 'engin' and excludes the low 10 per cents 
% of 'segin' as whole from computing BIC value. In computing BIC the 'segin'
% generally is divided into two parts by 'winoffsetin'. After deleting 
% 10 per cents the the number of frames before and after 'winoffsetin'
% may be different. So the left and right size are computed accordingly
% for each BIC window.
%
% This code is copyrighted 2003 by Marie Roch and Yanliang Cheng.
% e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 


% get the numberof vector in time domain  N, 
% and the dimension of the cepstral space d
[N, d]  = size(segin);

% remove indices with low energy
engin = segin(:,1);  % store the energy in separate vector
segin(:,1) = [];   % remove the energy column

[dumbdata, indices] = sort(engin);
rmind = floor(N * EnergyPct);
highengindices = indices(rmind:end);

% Find indices for high energy
leftindices = highengindices(find(highengindices<=winoffsetin));
rightindices = highengindices(find(highengindices>winoffsetin));

% left and right segments after removing low energy vectors
left = segin(leftindices, :);
right = segin(rightindices, :);
%all = [left', right']';   % be careful of transpose
all = [left; right];

% find the right and left segment size
leftsize = length(leftindices);
rightsize = length(rightindices);

% add engin as one col at end of segin 
%mix = [segin,engin]; 

% sort mix with each row as a group and 
% used engin accending sorted
% mixsort = sortrows(mix, [size(mix,2)]);

% find the first row 

% take off 10 per cents  with least engin
% mixused = mixsort(rmind:end, :);

% take off the attached energy col
% segused = mixused(:, 1:end-1);

% used modified seg
% Nused = size(segused, 1);
% winoffset = round(Nused/2);

% compute the penalty factor  p
p = 0.5*(d+(0.5*d*(d+1)))*log(leftsize+ rightsize); %Nused);

% set the penalty weight w
%w = 1.2;
w=1.2;
% compute the most likelihood R
%R =  Nused*log(det(cov(segused)))...
%    -winoffset*log(det(cov(segused(1:winoffset,:))))...
%    -(Nused-winoffset)*log(det(cov(segused(winoffset+1:Nused, :))));

 R = (leftsize+rightsize)*log(det(cov(all)))...
	- leftsize*log(det(cov(left)))...
	- rightsize*log(det(cov(right))); 
% compute BIC value
val = R - w*p;

