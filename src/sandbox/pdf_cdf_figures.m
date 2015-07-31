x = -4:.1:4;
norm = normpdf(x,0,1);
figure;
plot(x,norm);
xlhand = get(gca,'xlabel');
set(gca,'FontSize',14);


x = -4:.1:4;
norm = normcdf(x,0,1);
figure;
plot(x,norm);
set(gca,'FontSize',14);