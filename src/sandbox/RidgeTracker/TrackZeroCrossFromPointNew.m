function [Z,A]=TrackZeroCrossFromPointNew(A,x,y)
% TrackZeroCrossFromPointNew
%
% Given a functional matrix A and a starting point (x,y), tries to follow
% the zero-crossing (sign change) line, marking pixels as processed as it
% goes.
%
% Input:
%   A - Functional matrix.
%   x - Starting point column.
%   y - Starting point row.
%
% Output:
%   Z - 2-D vector of points along the tracked line.
%   A - Updated functional matrix with processed points replaced by NaN.

X=x;Y=y;
dd=[0 0];

% Although the output is floating point, dereferencing A requires integer
% values of x and y
x=round(x);
y=round(y);

% Process until told otherwise
while 1
    % If we've reached the edge of the matrix, stop
    if x<2 || x >size(A,2)-1 || y<2 || y>size(A,1)-1
        break;
    end
    
    % Track one step (see function description below)
    dd=Step(A(y-1:y+1,x-1:x+1),dd);
    % If we didn't find anywhere to go, stop
    if isnan(dd(1))
        break;
    end
    % Flag this pixel as processed
    A(y,x)=NaN;
    % Update our track vector
    X=[X X(end)+dd(1)];
    Y=[Y Y(end)+dd(2)];
    % Select the new focal pixel
    x=round(X(end));
    y=round(Y(end));
end

% Assemble the output matrix
Z=[X' Y'];


function dd=Step(a,ddold)
% Single step of the tracking process.  Given a focal pixel and its
% immediate 3x3 neighbourhood, follow the zero-crossing to the next pixel.

% cx and cy map the (circular) neighbouring pixels to a 1-D vector
%        1  2  3        (1,1)   (2,1)   (3,1)
%        8     4   =>   (1,2)           (3,2)
%        7  6  5        (1,3)   (2,3)   (3,3)
%
% Notice that the first element is repeated at the end to complete the
% circle.
cx=[1 2 3 3 3 2 1 1 1];
cy=[1 1 1 2 3 3 3 2 1];
i=sub2ind(size(a),cy,cx);

% b is a linear vector of the functional values
b=a(i);
% Look for sign changes (zero-crossing)
d=diff(sign(b));
F=find(d~=0 & ~isnan(d));
% If there aren't any, give up
if isempty(F)
    dd=[NaN NaN];
    return;
end

% Go through each of the zero-crossing pixels
for n=1:length(F)
    f=F(n);
    % Is this zero-crossing a vertical boundary between pixels, or a 
    % horizontal one?  In either case, find the exact point of
    % zero-crossing by using linterp() on the functional values from the
    % adjacent pixels.
    if cx(f)==cx(f+1)
        D=sortrows([[a(i(f)) ;a(i(f+1))] [cy(f) ;cy(f+1)]]);
        dy=linterp(D(:,1),D(:,2),0);
        dx=cx(f);
    else
        D=sortrows([[a(i(f)) ;a(i(f+1))] [cx(f) ;cx(f+1)]]);
        dx=linterp(D(:,1),D(:,2),0);
        dy=cy(f);
    end
    % Record the location
    dd(n,:)=[dx dy];
    % Record the distance between the previous crossing and this one
    q(n)=sum((ddold-dd(n,:)).^2);
end

% If there are multiple crossings, take the one that is nearest to the last
[~,mn]=min(q);
% Adjust the offset to [-1 1]
dd=dd(mn,:)-2;
