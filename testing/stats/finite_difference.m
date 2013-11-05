function [midpoint_x, dydx ] = finite_difference( x, y, order )
%FINITE_DIFFERENCE Summary of this function goes here
%   Detailed explanation goes here
    dydx = y;
    midpoint_x = x;
    for cnt=1:order
        dy = diff(dydx);
        dx = diff(midpoint_x);

        dydx = dy./dx; 
        midpoint_x = midpoint(midpoint_x);
    end
end

function v = midpoint(x)
    v = zeros(length(x)-1,1);
    for k = 1:length(x)-1
        v(k) = mean([x(k), x(k+1)]);
    end
end

