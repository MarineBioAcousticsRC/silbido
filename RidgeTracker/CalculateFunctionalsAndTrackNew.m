function [TT,A]=CalculateFunctionalsAndTrackNew(I,K,mask,minLen,HPF,LPF,horizPriority)
% CalculateFunctionalAndTrackNew
%
% Performs the ridge tracking by (a) calculating the angle between the
% dominant eigenvector of the Hessian matrix and the gradient vector for
% each pixel, and (b) tracking the zero-crossing of this 'functional'
% matrix.
%
% Input:
%   I - The spectrogram image.
%   K - Gaussian kernel standard deviation (in pixels) for calculating the
%       gradients.
%   mask - Interest mask.  Greatly reduces processing time by skipping
%          pixels not considered "interesting".  Note that a zero in the
%          mask is a pixel that _should_ be processed (the opposite of what
%          you might expect...)
%   minLen - Minimum length of ridge to accept (in pixels).
%   HPF - High pass filter (in PIXELS).  How many pixels to exclude from
%         the bottom of the spectrogram.
%   LPF - Low pass filter (in PIXELS).  How many pixels to exclude from
%         the top of the spectrogram.
%   horizPriority - Whether to give priority to the detection of horizontal
%                   ridges by considering only those pixels where gyy<=0.
%
% Output:
%   TT - Cell array of ridges.
%   A - Functional matrix (angles).
%

% Set some default values for the parameters
if nargin<7
    horizPriority=1;
end
if nargin<6
    LPF=0;
end
if nargin<5
    HPF=0;
end

% Calculate the functional matrix A
A=HessianFunctional2(I,K,mask,horizPriority);

% This is an optional resize factor, not used at the moment
rzfact=1;
if rzfact~=1
    A=imresize(A,rzfact);
end

% Track the zero-crossings
TT=TrackRidgesNew(A);


% Resize the ridges, and the A matrix, if it was changed
if rzfact~=1
    for n=1:length(TT)
        t=TT{n};
        t=t/rzfact;
        TT{n}=t;
    end
    A=imresize(A,1/rzfact);
end


% Eliminate those points that fall in the bandstops, and ridges that are 
% too short
bad=[];
for n=1:length(TT)
    T=TT{n};
    % Remove points below HPF or above LPF
    T(find(T(:,2)<=LPF | T(:,2)>=(size(I,1)-HPF)),:)=[];
    TT{n}=T;
    % Remove short ridges
    if size(T,1)<minLen
        bad=[bad n];
    end
end

TT(bad)=[];
