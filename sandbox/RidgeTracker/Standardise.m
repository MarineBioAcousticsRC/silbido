function S=Standardise(X)

mx=max(X);
mn=min(X);
rn=mx-mn;
S=(X-repmat(mn,size(X,1),1))./repmat(rn,size(X,1),1);
