function R=KalmanSmoothCurve2(T,type,smoothing)
if nargin<2
    type=1;
end
if nargin<3
    smoothing=1000;
end

if type==1 % 1-D
    T=sortrows(T);
else % 2-D
end

clear kalman01;

for m=1:size(T,1);
    R(m,:)=kalman01(T(m,:)',smoothing)';
end
