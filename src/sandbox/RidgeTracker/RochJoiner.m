function TT2=RochJoiner(TT,maxDt,TERM,maxDf)
% RochJoiner
%
% Implements (something similar to) the ridge joining heuristic described
% in Roch et al 2011 Journal of the Acousical Society of America
%
% Input:
%   TT - Cell array of ridges
%   maxDt - Maximum allowed gap between ridges on the x (time) axis
%   TERM - When considering whether to join two ridges, the
%          algorithm takes into account at most this many
%          pixels from the ends of each ridge
%   maxDf - Maximum allowed gap between ridges on the y (frequency) axis
%
% Output:
%   TT2 - Cell array of ridges after joining
%

if nargin<4
    maxDf=15;
end
if nargin<3
    TERM=10;
end
if nargin<2
    maxDt=10;
end

% Prepare vectors of the start and end times and frequencies of each ridge,
% and their lengths
etime=ones(length(TT),1)*NaN;
stime=ones(length(TT),1)*NaN;
efreq=ones(length(TT),1)*NaN;
sfreq=ones(length(TT),1)*NaN;
l=ones(length(TT),1)*NaN;

for n=1:length(TT)
    T=TT{n};
    if ~isempty(T)
        TT{n}=T;
        etime(n)=T(end,1);
        stime(n)=T(1,1);
        efreq(n)=T(end,2);
        sfreq(n)=T(1,2);
        l(n)=size(T,1);
    end
end

Z=zeros(length(TT),1);

% Order the ridges by end time and go through them one by one
E=sortrows([etime (1:length(etime))']);

for nn=1:size(E,1)
    n=E(nn,2);
    T=TT{n};
    % Extract the terminal part of the ridge, as defined by the TERM
    % parameter
    T=T(max(1,end-TERM+1):end,:);
    
    % Find those other ridges that fall within the allowable time and
    % frequency window
    f=find(stime>etime(n) & stime<(etime(n)+maxDt) & abs(sfreq-efreq(n))<maxDf);
    
    % For each candidate matching ridge, apply the Roch heuristic
    r2=[];s2=[];n2=[];k=[];err=[];
    for m=1:length(f)
        Q=TT{f(m)};
        Q=Q(1:min(TERM,size(Q,1)),:);
        
        [r2(m),s2(m),n2(m),k(m),err(m)]=RochGraphExtend2(T,Q);
    end

    % Find the polynomial fit with the largest number of points
    [mx,nmx]=max(n2);
    if ~isempty(mx) && ~isnan(mx)
        % If there are more than one, go through them and choose the one
        % with the minimum error
        j=find(n2==mx);
        if length(j)>1
            [~,nmx2]=min(err(j));
            Z(f(j(nmx2)))=n;
        else
            Z(f(nmx))=n;
        end
    end
    
end

% Now order the joined ridges backwards in time and join them together
E=sortrows([-stime (1:length(stime))' Z]);

TT2=TT;
for n=1:size(E,1)
    if E(n,3)==0
        continue;
    end
    
    T1=TT2{E(n,3)};
    T2=TT2{E(n,2)};
    
    T=[T1;T2];
    TT2{E(n,3)}=T;
    TT2{E(n,2)}=[];
end

% Remove any ridges that are empty
bad=[];
for n=1:length(TT2)
    T=TT2{n};
    if isempty(T)
        bad=[bad n];
    end
end
TT2(bad)=[];

    

