function [I2,R,V]=MallawaarachchiFilter(I,alpha,beta,M)
% http://scholarbank.nus.sg/bitstream/handle/10635/13275/Thesis_040510.pdf?sequence=1

if nargin<4
    M=3;
end
if nargin<3
    beta=1;
end
if nargin<2
    alpha=1;
end

[p,q]=meshgrid(1:M);
p=p-M/2;
q=q-M/2;

a=M/10;

v1=exp(-1/2*((p/a/6).^2+(q/a).^2));
v2=exp(-1/2*((p/a).^2+(q/a/6).^2));
v3=exp(-(((q-p)/a).^2+((q+p)/a/6).^2));
v4=exp(-(((q-p)/a/6).^2+((q+p)/a).^2));

ih=imfilter(I,v1);
iv=imfilter(I,v2);
id1=imfilter(I,v3);
id2=imfilter(I,v4);

R=max(cat(3,ih,id1,id2),[],3);
V=iv;

I2=alpha*I+beta*(R-V)/(alpha+beta);
