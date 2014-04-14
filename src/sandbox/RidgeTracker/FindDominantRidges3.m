function R=FindDominantRidges3(I,TT,type)
% FindDominantRidges3
%
% Identifies ridges from within a selection, that are in some way
% "important", i.e. powerful.  The criteria for selection are determined by
% the third parameter, 'type'.
%
% Input:
%   I - Original spectrographic image
%   TT - Cell array of ridges
%   type - Which criteria to use for selecting "dominant" ridges:
%           1: All ridges that are, for at least one time point, the
%              strongest ridge at that time point.
%           2: The single ridge with the lowest variation along its length.
%           3: The single ridge with the greatest overall spectral power.
%
% Output:
%   R - Cell array of selected ridges (or single ridge)
%

if isempty(TT)
    return;
end

p=[];
switch type
    case 1
        % Strongest for at least one time point
        stime=ones(length(TT),1)*NaN;
        etime=ones(length(TT),1)*NaN;
        
        for n=1:length(TT)
            T=TT{n};
            if ~isempty(T)
                T=sortrows(T);
                etime(n)=T(end,1);
                stime(n)=T(1,1);
                S(n)=RidgeLength(T,I);
            end
        end
        
        % for every x, find the strongest of the ridges present at that x
        if isempty(I)
            for nx=1:100
                x=max(etime)/100*nx;
                c=find(stime<=x & etime>=x);
                if ~isempty(c)
                    [dum,ms]=max(S(c));
                    p=[p c(ms)];
                end
            end
        else
            for x=1:size(I,2)
                c=find(stime<=x & etime>=x);
                if ~isempty(c)
                    [dum,ms]=max(S(c));
                    p=[p c(ms)];
                end
            end
        end
        % p are the ridges that have a claim to dominance at some x
    case 2
        for t=1:length(TT)
            T=TT{t};
            % find the ridge with the lowest std
            z=impixel(I,T(:,1),T(:,2));
            sd(t)=std(z(:,1));
        end
        [~,p]=min(sd);
    case 3
        for t=1:length(TT)
            T=TT{t};
            % find the ridge with the highest power
            L(t)=RidgeLength(T,I);
        end
        [~,p]=max(L);
end

R=TT(unique(p));





