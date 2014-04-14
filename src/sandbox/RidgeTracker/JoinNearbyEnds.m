function TC=JoinNearbyEnds(I,TT,maxGap,terminalSmoothing,maxTurn,maxDY,maxTurn2)
% JoinNearbyEnds
%
% Takes a cell array of ridges and joins together those that seem suitable,
% according to a simple heuristic.  The ends of nearby ridges ("ends" being
% defined as being 'terminalSmoothing' pixels long) are compared for
% distance (must be less than 'maxGap') and turning angle (must be less
% than 'maxTurn').
%
% Input:
%   I - The original spectrographic image
%   TT - Cell array of ridges
%   maxGap - Maximum distance (in pixels) that can be bridged
%   terminalSmoothing - Number of pixels at the ends of each ridge to
%                       consider when calculating the turn angle
%   maxTurn - Maximum turning angle (in degrees) between two ridges that
%             can be bridged
%   maxDY - Maximum jump in y (frequency) between two ridges that can be
%           bridged
%   maxTurn2 - If not NaN, used to check the maximum of the three turning
%              angles (see below).  Not usually used, but if so, should be
%              maxTurn*3
%
% Output:
%   TC - Cell array of joined ridges
%

if nargin<7
    maxTurn2=NaN;
end
if nargin<6
    maxDY=5;
end

TC=[];
if isempty(TT)
    return;
end

MINANG=ones(length(TT))*NaN;
MAXANG=ones(length(TT))*NaN;
left=zeros(length(TT),2)*NaN;
right=zeros(length(TT),2)*NaN;

% Record the starting (left) and ending (right) positions of each ridge
for n=1:length(TT)
    T=TT{n};
    if isempty(T)
        T=[NaN NaN];
    end
    left(n,:)=T(1,:);
    right(n,:)=T(end,:);
end

% Calculate the X and Y distances between all pairs of ridges
% (right-to-left, i.e. end-to-start)
XL=repmat(left(:,1),1,length(TT))';
YL=repmat(left(:,2),1,length(TT))';
XR=repmat(right(:,1),1,length(TT));
YR=repmat(right(:,2),1,length(TT));

DX=XL-XR;
DY=YL-YR;

% Calculate the Euclidean distance between ends of all pairs
D=sqrt(DX.^2+DY.^2);
% Exclude self comparisons
D(find(eye(size(D))))=NaN;

% Identify those that are closer than 'maxGap'
DB=D<maxGap;
f=find(DB);

% Go over each of those candidates
for n=1:length(f)
    % Recover the ids of the pair of ridges
    [x,y]=ind2sub(size(DB),f(n));
    % 'A' is the left ridge (i.e. we look at its right end)
    A=right(x,:);
    % Smooth the last pixels in that ridge so we can estimate the direction
    % of the tip of the ridge
    TV1=FindTerminalVector(TT{x},terminalSmoothing,0);
    % 'B' is the right ridge (i.e. we look at its left end)
    B=left(y,:);
    TV2=FindTerminalVector(TT{y},terminalSmoothing,1);
    
    % Calculate the angle between the smoothed tip of the left ridge and 
    % the vector connecting the two ridge ends
    a1a=acos(dot(TV1,(B-A)/norm(B-A)))*180/pi;
    % Calculate the angle between the vector connecting the two ridge ends
    % and the smoothed tip of the right ridge
    a2a=acos(dot((B-A)/norm(B-A),TV2))*180/pi;
    % Calculate the angle between the two smoothed ridge tips
    a3=acos(dot(TV1,TV2))*180/pi;
    
    % Record the minimum and maximum of these three angles
    MINANG(x,y)=min([a1a a2a a3]);
    MAXANG(x,y)=max([a1a a2a a3]);
    % Record the y (frequency) difference between the two tips
    DY(x,y)=abs(A(2)-B(2));
end

% Here is the joining criterion: (a) gap is small enough, and (b) the 
% minimum of the three angles is small enough, and (c) the frequency jump
% is not too large, and OPTIONALLY (d) the maximum of the the three angles
% is small enough
critA=D<maxGap;
critB=MINANG<maxTurn | MINANG>(360-maxTurn);
critC=DY<maxDY;
if ~isnan(maxTurn2)
    critD=MAXANG<maxTurn2 | MAXANG>(360-maxTurn2);
else
    critD=1;
end
DB=critA & critB & critC & critD;

% Each ridge should be connected to just one other from its right end, so
% if there are multiple candidates, choose only the strongest
for n=1:size(DB,1)
    % Find the candidates for ridge 'n'
    f=find(DB(n,:));
    f(find(f==n))=[];
    if ~isempty(f)
        % Gather the strengths of the candidate ridges
        s=[];
        for m=1:length(f)
            s(m)=RidgeLength(TT{f(m)},I);
        end
        % Clear all these candidates (only one will be reinstated)
        DB(n,f)=0;
        % Find the strongest of the candidates
        [dum,mx]=max(s);
        % Reinstate it as the sole joined ridge
        DB(n,f(mx))=1;
    end
end

% Ridges can be chained together, so we have to unify them, even though
% there may be several links.  To do this, we use a clustering algorithm.
% First we build a "distance" matrix, which is actually zero (connected) or
% one (not connected).  This is 1-DB, more or less
DB2=DB+DB';
DB2=double(1-(DB2>0));
DB2(find(eye(size(DB2))))=0;

% If there are less than three ridges, this process makes no sense
if length(TT)>2
    % Make a linkage map from the distance matrix
    L=linkage(squareform(DB2));
    % Cluster those ridges with "distance" less than 0.5 (i.e. distance 0)
    C=cluster(L,'cutoff',0.5,'criterion','distance');
    res=0;
else
    C=1:length(TT);
    res=-1;
end

% Go over each of the clusters thus generated and unite the ridges making 
% up each one of them into a single ridge
u=unique(C);
TC=[];
for n=1:length(u)
    % Find the ridges belonging to this cluster
    f=find(C==u(n));
    % Build a ridge comprising each of them
    tc=[];
    for m=1:length(f)
        tc=[tc;TT{f(m)}];
    end
    % Sort it by time (the ridges aren't guaranteed to have been in time
    % order)
    tc=sortrows(tc,1);
    % Remove those points that are actually the same pixel
    TC{n}=RemoveOverlappingPoints(tc);
end

