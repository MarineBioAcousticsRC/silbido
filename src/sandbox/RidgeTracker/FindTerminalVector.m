function TV=FindTerminalVector(T,k,isStart)

if k>size(T,1)
    k=size(T,1);
end

if isStart
    t=T(k:-1:1,:);
else
    t=T((end-k+1):end,:);
end
p=polyfit(t(:,1),t(:,2),1);
b=[t(1,1) polyval(p,t(1,1))];
a=[t(end,1) polyval(p,t(end,1))];
if isStart
    TV=(b-a)/norm(b-a);
else
    TV=(a-b)/norm(a-b);
end
