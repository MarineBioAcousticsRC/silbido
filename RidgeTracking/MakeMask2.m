function mask=MakeMask2(I,isd,HPF,LPF)
if nargin<3
    HPF=0;
end
if nargin<4
    LPF=0;
end

I(isnan(I))=0;
% select pixels for processing
    I2=imdilate(I,ones(4));

th0=mean(I2(:))+isd*std(I2(:));
mask=I2<th0;
mask=imerode(mask,ones(4));

if HPF>0
    mask(end-HPF:end,:)=1;
end
if LPF>0
    mask(1:LPF,:)=1;
end