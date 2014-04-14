load exampleridge
K=4;
gx=gfilter(I,K,[0 1]);
gy=gfilter(I,K,[1 0]);
gxx=gfilter(I,K,[0 2]);
gyy=gfilter(I,K,[2 0]);
gxy=gfilter(I,K,[2 2]);
gyx=gxy;

contour(I,'k');
hold on

step=5;
xx=1:step:size(I,2);
yy=1:step:size(I,1);
[X,Y]=meshgrid(xx,yy);
GX=gx(1:step:end,1:step:end);
GY=gy(1:step:end,1:step:end);
quiver(X(:),Y(:),GX(:),GY(:));

axis off

[TT,A]=CalculateFunctionalsAndTrackNew(I,K,zeros(size(I)),5);
for n=1:length(TT)
    T=TT{n};
    plot(T(:,1),T(:,2),'r','LineWidth',3);
end

hold off