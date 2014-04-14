function angle = pointAngle(p2, p1, p3)
    a = [p1(1) - p2(1), p1(2) - p2(2)];
    b = [p1(1) - p3(1), p1(2) - p3(2)];
    angle = radtodeg(acos(dot(a,b)/(norm(a) * norm(b))));
    angle = angle - 180;
end