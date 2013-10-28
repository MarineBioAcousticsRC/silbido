package tonals;

import java.util.Vector;

import org.apache.commons.math3.linear.MatrixUtils;
import org.apache.commons.math3.linear.RealMatrix;
import org.apache.commons.math3.stat.regression.OLSMultipleLinearRegression;


public class FitPolyCommons extends FitPolyBase {
	
    private RealMatrix coef; // will hold prediction coefs once we get values
    
    
    public FitPolyCommons(int degree, Vector<Double> x, Vector<Double> y) {
    	super(degree, x, y);
    }
    
    public FitPolyCommons(int degree, double[] x, double[] y) {
    	super(degree, x, y);
    }
    
    public FitPolyCommons(int degree, tonal path, int skip_n, boolean fit_dphase, boolean incoming_edge) {
    	super(degree, path, skip_n, fit_dphase, incoming_edge);
	}
    
    protected void createFit(double[] x, double[] y) {
    	if (x.length != y.length) {
            throw new IllegalArgumentException(
            		String.format("The numbers of y and x values must be equal (%d != %d)",y.length,x.length));
        }
        
        double[][] xData = new double[x.length][]; 
        
        for (int i = 0; i < x.length; i++) {
            // the implementation determines how to produce a vector of predictors from a single x
            xData[i] = xVector(x[i]);
        }
        
        OLSMultipleLinearRegression ols = new OLSMultipleLinearRegression();
        ols.setNoIntercept(true); // let the implementation include a constant in xVector if desired
        ols.newSampleData(y, xData); // provide the data to the model
        coef = MatrixUtils.createColumnRealMatrix(ols.estimateRegressionParameters()); // get our coefs
    }
    
   

    public double predict(double x) {
    	if (coef == null ) {
    		System.out.print("wtf?");
    	}
        double yhat = coef.preMultiply(xVector(x))[0]; // apply coefs to xVector
        return yhat;
    }
    
    protected double[] xVector(double x) { // {1, x, x*x, x*x*x, ...}
        double[] poly = new double[degree+1];
        double xi=1;
        for(int i=0; i<=degree; i++) {
            poly[i]=xi;
            xi*=x;
        }
        return poly;
    }
}