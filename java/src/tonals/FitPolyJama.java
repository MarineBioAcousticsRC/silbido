package tonals;

import java.util.Vector;

import Jama.Matrix;
import Jama.QRDecomposition;

public class FitPolyJama extends FitPolyBase {
    
    /**
     * The calculated coefficients of the polynomial.
     */
    private Matrix beta;
    
    /**
     * Initialize a polynomial fit using vectors as the input values;
     * 
     * @param degree
     * @param x
     * @param y
     */
    public FitPolyJama(int degree, Vector<Double> x, Vector<Double> y) {
    	super(degree, x, y);
    }
    
    public FitPolyJama(int degree, double[] x, double[] y) {
    	super(degree, x, y);
    }
    
    public FitPolyJama(int degree, tonal path, int skip_n, boolean incoming_edge) {
    	super(degree, path, skip_n, incoming_edge);
	}

	protected void createFit(double[] x, double[] y) {
		if (x.length == 1) {
			// Handle the special case where we only have one point.  We create
			// a 0 order polynomial, i.e. a constant.
			beta = new Matrix(1,1);
			beta.set(0, 0, y[0]);
			this.degree = 0;
		} else {
			
			// A little trick is that the degree must be less than the
			// number of points that you have to construct the fit with.
			// The min just ensures that this will be the case;
			
			this.degree = Math.min(x.length - 2, this.degree);
			
	        // build Vandermonde matrix
	        double[][] vandermonde = new double[numObservations][degree+1];
	        for (int i = 0; i < numObservations; i++) {
	            for (int j = 0; j <= degree; j++) {
	                vandermonde[i][j] = Math.pow(x[i], j);
	            }
	        }
	        Matrix X = new Matrix(vandermonde);
	
	        // create matrix from vector
	        Matrix Y = new Matrix(y, numObservations);
	
	        // find least squares solution
	        QRDecomposition qr = new QRDecomposition(X);
	        try {
	        	beta = qr.solve(Y);
	        } catch(Exception e) {
	        	e.printStackTrace();
	        }
		}
    }

    // predicted y value corresponding to x
    public double predict(double x) {
        // horner's method
        double y = 0.0;
        for (int j = degree; j >= 0; j--)
            y = beta.get(j, 0) + (x * y);
        return y;
    }
    
  

    public String toString() {
        StringBuilder s = new StringBuilder();
        int j = degree;

        // ignoring leading zero coefficients
        while (Math.abs(beta.get(j, 0)) < 1E-5) {
            j--;
        }

        // create remaining terms
        for (; j >= 0; j--) {
            if (j == 0) {
            	s.append(String.format("%.2f ", beta.get(j, 0)));
            } else if (j == 1) { 
            	s.append(String.format("%.2f N + ", beta.get(j, 0)));
            } else {
            	s.append(String.format("%.2f N^%d + ", beta.get(j, 0), j));
            }
        }
        
        s.append("  (R^2 = " + String.format("%.3f", getR2()) + ")");
        return s.toString();
    }
}