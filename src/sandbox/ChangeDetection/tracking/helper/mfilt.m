function m = mfilt(dat, rng)
% function meanfilt(vector, rng) does mean-filtering on 
% vector to smooth it 
%
% This code is copyrighted 2003 by Yanliang Cheng.
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 

% output vector
m = [];
% Half size of rng used for offset
offset = floor(rng/2);
% Copy data not change at beginning
m = dat(1, 1:offset);
% find length of dat
len = size(dat,2);
for i=(offset+1):1:(len-offset)
    m(end+1)  = mean(dat(1,i-offset:i+offset));
end   
%Copy and append not changed data at end
m = [m, dat(len-offset+1:len)];    
    