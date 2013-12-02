function [R2,S2,N2,k,err]=RochGraphExtend2(T,Q,doPlot)
% RochGraphExtend2
%
% Implements the multi polynomial fit for the ridge joiner described
% in Roch et al 2011 Journal of the Acousical Society of America
%
% Input:
%   T - Primary ridge (curve)
%   Q - Candidate ridge (curve) for joining to T
%   doPlot - Boolean for plotting the polynomial fits
%
% Output:
%   R2 - Correlation
%   S2 - Standard deviation of residuals
%   N2 - Number of points fitted
%   k - Order of polynomial
%   err - Sum square residuals
%

if nargin<3
    doPlot=0;
end

minR2=0.6;
maxErr=5;
maxDim=5;

q=[T;Q];

R2=0;
S2=Inf;
N2=size(q,1);

for k=1:maxDim
    p=polyfit(q(:,1),q(:,2),k);
    P=polyval(p,q(:,1));
    A=sum((q(:,2)-P).^2);
    B=sum((q(:,2)-mean(q(:,2))).^2);
    R2(k)=1-A/(N2-k-1)/B*(N2-1);
    S2(k)=std((q(:,2)-P).^2);
    err(k)=mean(abs(P(end-size(Q,1)+1:end)-Q(:,2)));
end

% f=find(R2>minR2 & S2<2 & N2>3*(1:maxDim));
f=find(R2>minR2 & N2>3*(1:maxDim));

if isempty(f)
    R2=NaN;
    S2=NaN;
    err=NaN;
    k=NaN;
    N2=NaN;
else
    k=f(end);
    R2=R2(k);
    S2=S2(k);
    err=err(k);
    if doPlot
        p=polyfit(q(:,1),q(:,2),k);
        P=polyval(p,q(:,1));
        A=sum((q(:,2)-P).^2);
        B=sum((q(:,2)-mean(q(:,2))).^2);
        plot(T(:,1),T(:,2),'co',Q(:,1),Q(:,2),'gs',q(:,1),q(:,2),'b-',q(:,1),P,'r--');
    end
end



