function R=TrackCurves(TT,type,I,maxGap,terminalSmoothing,minLen,maxTurn)
% TrackCurves
%
% Joins ridges into longer curves, according to one of a number of
% heuristics.
%
% Input:
%   TT - Cell array of ridges from CalculateFunctionalsAndTrackNew
%   type - Type of joining algorithm:
%           1: Rule based joiner
%           2: Roch joiner (Silbido, Roch et al. JASA 2011)
%   maxGap - Largest gap (in pixels) to be bridged by the joiner
%   terminalSmoothing - When considering whether to join two ridges, the
%                       algorithm takes into account at most this many
%                       pixels from the ends of each ridge
%   I - Original spectrogram (not used in some heuristics)
%   minLen - The minimum length of a joined curve to be considered valid
%   maxTurn - Maximum turning angle for joining
%
% Output:
%   R - Cell array of joined curves
%

if isempty(TT)
    R=TT;
    return
end

% Apply the joining heuristic

switch type
    case 1
        % Simple rule-based joiner
        R=JoinNearbyEnds(I,TT,maxGap,terminalSmoothing,maxTurn);
    case 2
        R1=RochJoiner(TT,maxGap,terminalSmoothing);
        % Rotate the ridges through 90 degrees and reappy the heuristic
        for n=1:length(R1)
            r=R1{n};
            Rv{n}=r(:,[2 1]);
        end
        Rv2=RochJoiner(Rv,maxGap,terminalSmoothing);
        if isempty(Rv2)
            R=[];
            return;
        end
        % Rotate the ridges back through 90 degrees
        for n=1:length(Rv2)
            r=Rv2{n};
            R{n}=r(:,[2 1]);
        end
end

% Smooth the curves using a Kalman filter (usually)
R=SmoothCurves2(R,2,1000);

% Exclude curves shorter than the minimum length
bad=[];
for m=1:length(R)
    T=R{m};
    L=RidgeLength(T);
    if L<minLen
        bad=[bad m];
    end
end
R(bad)=[];

% Exclude out of range points created by the smoothing process
for m=1:length(R)
    T=R{m};
    f=find(T(:,1)<1 | T(:,1)>size(I,2) | T(:,2)<1 | T(:,2)>size(I,1));
    T(f,:)=[];
    R{m}=T;
end

