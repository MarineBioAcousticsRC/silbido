function T=RemoveNonMonotonicities(T)
% RemoveNonMonotonicities
%
% Remove points in a curve T for which the x value decreases

d=diff(T(:,1));
f=find(d<0);

while ~isempty(f)
    T(f+1,1)=T(f,1);
    d=diff(T(:,1));
    f=find(d<0);
end

