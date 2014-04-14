package tonals;

import java.util.Arrays;
import java.util.Iterator;
import java.util.Vector;

public abstract class FitPolyBase implements FitPoly {
    
	/**
	 * The number of points used when generating the fit.
	 */
	protected int numObservations;
    
    /**
     * The degree of the polynomial to fit.
     */
	protected int degree;
    
    /**
     * Total sum of squared errors (TSS).  This does not use the independent variable.
     * Rather it just examines the deviation from the dependent variable about
     * its mean value. This is the total deviation dependent variable. 
     * Sigma(YActual_i - YMean)^2
     */
	protected double ssTotal;
    
    /**
     * Sum of squared errors (SSE) of the residuals. This is compares the actual 
     * value of y with the predicted value of y given the model. This is the 
     * variation explained by the fit.
     * 
     * Sigma(YActual_i - YPredicted_i)^2
     */
	protected double ssRes;
    
    /**
     * Regression Sum of Squared Error (RSS). This describes the reduction in
     * squared errors due to the linear model.
     * 
     * RSS = TSS - SSE
     */
	protected double ssReg;
    
	
    /**
     * R-Squared.  The coefficient of determination.
     */
	protected double R2;
	
	/**
     * The adjusted coefficient of determination
     */
	protected double R2_ADJ;
    
    /**
     * The standard deviation of residuals.
     * 
     * sqrt(RSS / (N - (degree + 1)))
     */
	protected double sdRes;
    
    /**
     * Initialize a polynomial fit using vectors as the input values;
     * 
     * @param degree
     * @param x
     * @param y
     */
    public FitPolyBase(int degree, Vector<Double> x, Vector<Double> y) {
    	this.degree = degree;
        numObservations = x.size();
        
		double[] x_tmp = new double[numObservations];
		double[] y_tmp = new double[numObservations];
		
		for (int i=0; i < numObservations; i++) {
			x_tmp[i] = x.get(i);
			y_tmp[i] = y.get(i);
		}
		
		createFit(x_tmp,y_tmp);
		evalauteFit(x_tmp,y_tmp);
    }
    
    public FitPolyBase(int degree, double[] x, double[] y) {
    	this.degree = degree;
        numObservations = x.length;
        createFit(x,y);
		evalauteFit(x,y);
    }
    
    public FitPolyBase(int degree, tonal path, int skip_n, boolean incoming_edge) {
    	this.degree = degree;
    	int n = path.size();

    	double[] x_tmp = new double[n];
    	double[] y_tmp = new double[n];

		Iterator<tfnode> it;
		if (incoming_edge) {
			it = path.descendingIterator(); // backward direction
		} else {
			it = path.iterator(); // forward direction
		}
		
		tfnode node = it.next();
		tfnode prev = null;

		double how_far_s = 0.200;
		double elapsed_s = 0.0; 
		double start_s = node.time; 

		int i = 0;
		
		// polynomial fit of frequency to time. (slope and shape)
		while (it.hasNext() & elapsed_s < how_far_s) {
			x_tmp[i] = node.time;
			y_tmp[i] = node.freq;
			i++;
			node = it.next();
			elapsed_s = Math.abs(start_s - node.time);
		}
		
		numObservations = Math.min(i, n);
		double[] x = Arrays.copyOf(x_tmp, numObservations);
		double[] y = Arrays.copyOf(y_tmp, numObservations);
		
		createFit(x,y);
		evalauteFit(x,y);
	}

    protected abstract void createFit(double[] x, double[] y);
    
	

    public int getNumPredictors() {
        return degree;
    }
    
    public double getStdDevOfResiduals() {
    	return sdRes;
    }

    public double getR2() {
        return R2;
    }
    
    public double getAdjustedR2() {
    	return R2_ADJ;
    }
    
    
    /**
	  * sq_error
	  * Given x, return the squared error between x
	  * and its prediction.
	  * @param x - predictor variable
	  * @param y - actual value
	  */
	 public double getSquaredErrorForPoint(double x, double y) {
		 double error = getErrorForPoint(x, y);
		 return error*error;
	 }
	 
	/**
	 * error
	 * Given x, return the error between x
	 * and its prediction.
	 * @param x - predictor variable
	 * @param y - actual value
	 */
	public double getErrorForPoint(double x, double y) {
		return y - predict(x);
	}
	
	public double getTotalSumOfSquares() {
		return ssTotal;
	}
	
	public double getResidualsSumOfSquares() {
		return ssRes;
	}
	
	public double getRegressionSumOfSquares() {
		return ssReg;
	}
	
	protected void evalauteFit(double[] x, double[] y) {
        
    	// The mean of the dependent variable
        double sum = 0.0;
        for (int i = 0; i < numObservations; i++) {
            sum += y[i];
        }
        double mean = sum / numObservations;

        
        // Total Sum of Squares (ssTotal)
        // The sum of all of the squared differences of the dependent variable 
        // from the mean.
        for (int i = 0; i < numObservations; i++) {
            double dev = y[i] - mean;
            ssTotal += dev*dev;
        }

        // Residual Sum of Squares (ssRes)
        // Variation caused by the regression model. 
        // Sum Of Squared Errors,  sum of squares of the residuals.
        for (int i = 0; i < numObservations; i++) {
            double dev = y[i] - predict(x[i]);
            ssRes += dev*dev;
        }
        
        // Coefficient of determination
        R2 = (ssTotal==0)?1.0:1 - ssRes / ssTotal;
        
        // Adjusted coefficient of determination.
        R2_ADJ = 1 - (1-R2) * (numObservations - 1) / (numObservations - degree - 1);
        
        // Regression sum of squares (ssReg)
        ssReg = ssTotal - ssRes;
        
        sdRes = Math.sqrt(ssRes / (numObservations - degree - 1));
	}
}