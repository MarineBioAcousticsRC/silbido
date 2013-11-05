function [ ssTot, ssRes, ssReg, R2, R2_ADJ, sdRes ] = polyfit_eval( x, y, poly )
    % As described from http://www.mathworks.com/help/matlab/data_analysis/linear-regression.html
       
    n = length(x);
    p = length(poly) - 1;
    
    yfit = polyval(poly,x);
    
    % Calculate the residuals
    yresid = y - yfit;
    
    % Calculate the sum of the squares of the residuals.
    ssRes = sum(yresid.^2);
    
    
    % Sum the total squared error for all observations to their mean.
    ssTot = sum(bsxfun(@minus,y,mean(y)).^2);

    
    ssReg = ssTot - ssRes;
    
    R2 = 1 - ssRes/ssTot;
    
    R2_ADJ = 1 - ssRes/ssTot * (n - 1)/(n - p - 1);
    
    sdRes = sqrt(ssRes / (n - p - 1));
    
    
end

