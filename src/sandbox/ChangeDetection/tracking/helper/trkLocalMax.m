function pk = trkLocalMax(vec, n)

% This filter is for n > 3 
% 0 = filt out 
% 1 = shown peak
%                   0  /\ 1
%             0    /\_/  \  
%          0  /\  /       \ 
%          /\/  \/         \       1
%         /                 \    /\
%    n->  |_______|          \  /  \
%              |_______|      \/
%                      |_______|  
%  problem!!! :(  
%  solution:
%  applying this filter on peaks instead of each
%  point in ceptrum vector.  Strictly it is not a filter.
%  Vec stores the peak indice in ceptrum 
%  n as is the window width as indicated above 

mid = floor((n+1)/2);

pk = [];
%pk =[pk, vec(1:mid-1)];
temp1 = [1:mid-1];
temp2 = temp1;
add = temp1 ./ temp2;

vec = [add, vec];
vec = [vec, add];
vec = [vec, 0];

for i = mid:(length(vec)-mid)
	if vec(i) == max(vec((i-mid+1):(i+mid-1)));    % win)
		pk(end+1) = vec(i);
	else
		pk(end+1) = min(vec((i-mid+1):(i+mid-1)));
	end
end
%
%pk= [pk, vec((length(vec)-mid+1):length(vec))];