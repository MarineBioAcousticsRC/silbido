function [ridge,functionals]=TrackRidge(functionals, derivatives,x,y, forward_only)
% TrackRidge
%
% Attempt to find a ridge in a spectrogram given a (partially) filled in 
% hessian functional matrix and derivative information of a spectrogram 
% and a starting point of interest, attempt to find 
% 
%
% Input:
%   functionals
%       A struct containint the hessian functional matrix as well as flags
%       describing the state of the matrix.
%   derivatives
%       A struct containing the raw derivative infomration of the
%       spectrogram.  This is partial derivatives dx, dxx, dy, dyy, dxy,
%       dyx.
%   x - Starting point column.
%   y - Starting point row.
%
% Output:
%   ridge - 2-D vector of points along the tracked line.
%   functional - Updated functional matrix with processed points replaced by NaN.
X=x;Y=y;
dd=[0 0];

% Although the output is floating point, dereferencing A requires integer
% values of x and y
x=round(x);
y=round(y);

% Process until told otherwise
while 1
    % If we've reached the edge of the matrix, stop
    if x<2 || x >size(functionals.angles,2)-1 || y<2 || y>size(functionals.angles,1)-1
        break;
    end
    
    % Track one step (see function description below)
    [dd, functionals]=process_point(functionals,derivatives,x,y,dd,forward_only);
    % If we didn't find anywhere to go, stop
    if isnan(dd(1))
        break;
    end
    % Flag this pixel as processed
    functionals.processed(y,x)=1;
    % Update our track vector
    X=[X X(end)+dd(1)];
    Y=[Y Y(end)+dd(2)];
    % Select the new focal pixel
    x=round(X(end));
    y=round(Y(end));
end

% Assemble the output matrix
ridge=[X' Y'];


function [dd, functionals]=process_point(functionals,derivatives,x,y,ddold, forward_only)
% Single step of the tracking process.  Given a focal pixel and its
% immediate 3x3 neighbourhood, follow the zero-crossing to the next pixel.

% cx and cy map the (circular) neighbouring pixels to a 1-D vector
%        1  2  3        (1,1)   (2,1)   (3,1)
%        8     4   =>   (1,2)           (3,2)
%        7  6  5        (1,3)   (2,3)   (3,3)
%
% Notice that the first element is repeated at the end to complete the
% circle.

% This is where the hessian functional is comupted if it has not been.
% This is where the lazy calculation happens.    

if (forward_only == 1)
    x_start = x;
    cx=[1 2 2 2 1];
    cy=[1 1 2 3 3];
else
    x_start = x-1;
    cx=[1 2 3 3 3 2 1 1 1];
    cy=[1 1 1 2 3 3 3 2 1];
end

for i=x_start:x+1
    for j=y-1:y+1
        if functionals.computed(j,i)==0
            angle = HessianFunctional(derivatives,j,i);
            functionals.angles(j,i) = angle;
            functionals.computed(j,i) = 1;
        end
    end
end

a = functionals.angles(y-1:y+1,x_start:x+1);
processed = functionals.processed(y-1:y+1,x_start:x+1);


i=sub2ind(size(a),cy,cx);


% b is a linear vector of the functional values
b=a(i);
% Look for sign changes (zero-crossing)
d=diff(sign(b));
% This is a bit of a hack.  The old code uses NaN as a way to filter out
bp=processed(i);
d(find(bp==1)) = NaN;
F=find(d~=0 & ~isnan(d));
% If there aren't any, give up
if isempty(F)
    dd=[NaN NaN];
    return;
end

num_points = length(F);
dd=zeros(num_points, 2);
q = zeros(num_points, 1);

% Go through each of the zero-crossing pixels
for n=1:num_points
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

% this is a hack, I would like to put this in the logic above some how.
dd=dd(mn,:);
if (forward_only == 1)
    dd(:,1) = dd(:,1) - 1;
else
    dd(:,1) = dd(:,1) - 2;
end
dd(:,2) = dd(:,2) - 2;

