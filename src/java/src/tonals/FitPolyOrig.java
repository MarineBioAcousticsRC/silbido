package tonals;


//FitPoly class for fitting univariate functions 
//via ordinary least squares error minimization. 
//
//OLS implementation based on implementation from 
//_JavaTech_, C. S. Lindsey, J. S. Tolliver, T. Lindblad,
//Cambridge University Press, Cambridge, 2005
//which is in turn based on Press et al.'s _Numerical
//Recipes ..._ series.
//
//See _Multivariate Analysis, Methods and Applications_, 
//W. R. Dillon and M. Goldstein, John Wiley & Sons,
//New York, 1984 for a general p-variate solution (chapter 6.2)
//and details on the adjusted R squared coefficient.
//
//This solution only implements a univariate fit.

import Jama.*;
import java.util.*;


/**
*  Fit polynomial line to a set of data points.
*
*	  
*/
public class FitPolyOrig implements FitPoly {
	
	public double coeff[];
	public double errors[];
	
	// statistics on prediction
	/*
	 * adjusted coefficient of variation
	 * measure of goodness of fit.
	 * Normally in range [0, 1] (1 indicates perfect fit),
	 * but adjusted coefficient of variation can be less than
	 * 0 due to penalties for the polynomial order. 
	 */
	public double R2;
	/*
	 * When the fitted values are quantized, it is possible to 
	 * have a very poor fit as measured by the coefficient of
	 * variation due to bouncing above & below the actual values.
	 * When the standard deviation is within a couple times the
	 * quantization value, R2 is worthless.
	 */
	public double std_dev; // standard deviation of predicted variable
	
	int degree;
	
	// temporary storage, not thread safe
	final static int data_tmp_N = 100;
	static double[] x_tmp;
	static double[] y_tmp; 
	
	static {
		// Allocate space to copy Vector types
		x_tmp = new double[data_tmp_N];
		y_tmp = new double[data_tmp_N];
	}
	
	/*	
	 *  Use the Least Squares fit method for fitting a
	 *  polynomial to 2-D data for measurements
	 *  y[i] vs. dependent variable x[i]. This fit assumes
	 *  there are errors only on the y measurements as
	 *  given by the sigma_y array.<br><br>
	 *
	 *  See, e.g. Press et al., "Numerical Recipes..." for details
	 *  of the algorithm. <br><br>
	 *
	 *  The solution to the LSQ fit uses the open source JAMA -
	 *  "A Java Matrix Package" classes. See http://math.nist.gov/javanumerics/jama/
	 *  for description.<br><br>
	 *
	 *  @param x - independent variable
	 *  @param y - dependent variable
	 *  @param sigma_x - std. dev. error on each x value (null okay)
	 *  @param sigma_y - std. dev. error on each y value (null okay)
	 *  @param num_points - number of points to fit. Less than or equal to the
	 *         dimension of the data arrays
	 */
	private void Fit(int order, double [] x, double [] y,
			double [] sigma_x, double [] sigma_y, int num_points)
	{
		int nk = order+1;
		coeff = new double[nk];
		errors = new double[nk];

		// check for small special cases first
		if (num_points == 1) {
			coeff[0] = 0;
			coeff[1] = y[0];
		} else if (order == 1) {
			// special case of line
			// thanks to Dave Mellinger who provided his linefit
			// Matlab solution from which this was ported
			
			// sums of values, products, squares
			double sum_x = 0.0;		
			double sum_y = 0.0;
			double sum_xy = 0.0;
			double sum_x2 = 0.0;
			
			for (int i=0; i < num_points; i++) {
				sum_x = sum_x + x[i];
				sum_y = sum_y + y[i];
				sum_xy = sum_xy + x[i]*y[i];
				sum_x2 = sum_x2 + x[i]*x[i];
			}
			
			double Sxx = sum_x2 - sum_x*sum_x / num_points; 
			double Sxy = sum_xy - sum_x * sum_y / num_points;

			// slope
			if (Sxx == 0) {
				coeff[0] = 0;
			} else {
				coeff[0] = Sxy / Sxx;
			}
			// intercept
			coeff[1] = sum_y/num_points - coeff[0]*sum_x/num_points;  	
		} else {
			// bring out the big guns

			double [][] alpha  = new double[nk][nk];
			double [] beta = new double[nk];

			double term = 0;

			for (int k=0; k < nk; k++) {

				// Only need to calculate diagonal and upper half
				// of symmetric matrix.
				for (int j=k; j < nk; j++) {

					// Calc terms over the data points
					term = 0.0;
					alpha[k][j] = 0.0;
					for (int i=0; i < num_points; i++) {

						double prod1 = 1.0;
						// Calculate x^k
						if ( k > 0) for (int m=0; m < k; m++) prod1 *= x[i];

						double prod2 = 1.0;
						// Calculate x^j
						if ( j > 0) for (int m=0; m < j; m++) prod2 *= x[i];

						// Calculate x^k * x^j
						term =  (prod1*prod2);

						if (sigma_y != null && sigma_y[i] != 0.0)
							term /=  (sigma_y[i]*sigma_y[i]);
						alpha[k][j] += term;
					}
					alpha[j][k] = alpha[k][j];// C will need to be inverted.
				}

				for (int i=0; i < num_points; i++) {
					double prod1 = 1.0;
					if (k > 0) for ( int m=0; m < k; m++) prod1 *= x[i];
					term =  (y[i] * prod1);
					if (sigma_y != null  && sigma_y[i] != 0.0)
						term /=  (sigma_y[i]*sigma_y[i]);
					beta[k] +=term;
				}
			}

			// Use the Jama QR Decomposition classes to solve for
			// the parameters.
			Matrix alpha_matrix = new Matrix (alpha);
			QRDecomposition alpha_QRD = new QRDecomposition (alpha_matrix);
			Matrix beta_matrix = new Matrix (beta,nk);
			Matrix param_matrix;
			try {
				param_matrix = alpha_QRD.solve (beta_matrix);
			} catch (Exception e) {
				//System.out.println ("QRD solve failed: "+ e);
				return;
			}

			// The inverse provides the covariance matrix.
			Matrix c;
			
			try {
				c = alpha_matrix.inverse ();
			} catch (Exception e) {
				//System.out.println ("QRD solve failed: "+ e);
				return;
			}

			// Matrix organized with polynomial coefficients:
			// p^0 p^1 p^2 ... 
			// need ... p^2 p^1 p^0
			int i=nk-1;
			for (int k=0; k < nk; k++, i--) {
				// polynomial coefficients
				coeff[i] = param_matrix.get (k,0);

				// Diagonal elements of the covariance matrix provide
				// the square of the parameter errors.
				errors[i] = Math.sqrt (c.get (k,k));
			}
		}
		// find coefficient of regression
		goodness_of_fit(x, y, num_points);
	}
	
	/*	
	 *	Fit a polynomial of the specified order to the given data.
	 *  @param x - independent variable
	 *  @param y - dependent variable
	 *  @param sigma_x - std. dev. error on each x value (null okay)
	 *  @param sigma_y - std. dev. error on each y value (null okay)
	 *  @param num_points - number of points to fit. Less than or equal to the
	 *         dimension of the data arrays
	 */
	public FitPolyOrig(int order, double [] x, double [] y,
			double [] sigma_x, double [] sigma_y, int num_points) {
		this.degree = order;
		Fit(order, x, y, sigma_x, sigma_y, num_points);
	}

	/*
	 * Fit a polynomial of the specified order to the given data.
	 * @param polynomial order
	 * @param predictor variable
	 * @param predicted variable 
	 */
	public FitPolyOrig(int order, Vector<Double> x, Vector<Double> y) {
		this.degree = order;
		// For speed, we do not verify that x and y are
		// the same size.  If they're not, too bad!
		
		int n = x.size();

		if (n >= x_tmp.length) {
			// static arrays are too small, increase their size
			int new_size = (int) Math.round(n * 1.25);
			x_tmp = new double[new_size];
			y_tmp = new double[new_size];
		}

		// use static storage to avoid allocation time penalty
		// not thread safe!
		for (int i=0; i < n; i++) {
			x_tmp[i] = x.get(i);
			y_tmp[i] = y.get(i);
		}
		// build the polynomial
		Fit(order, x_tmp, y_tmp, (double[]) null, (double[]) null, n);
	}
	
	public FitPolyOrig(int order, tonal tone, int skip_n, boolean fit_dphase,
			boolean incoming_edge) {
		this.degree = order;
		// fit_dphase, boolean
		// true - polynomial fit of first difference of phase to frequency
		// false  - polynomial fit of frequency to time.
		
		int n = tone.size();

		if (n >= x_tmp.length) {
			// static arrays are too small, increase their size
			int new_size = (int) Math.round(n * 1.25);
			x_tmp = new double[new_size];
			y_tmp = new double[new_size];
		}

		Iterator<tfnode> it;
		if (incoming_edge)
			it = tone.descendingIterator(); // backward direction
		else
			it = tone.iterator(); // forward direction
		tfnode node = it.next();
		tfnode prev = null;

		double how_far_s = 0.200;
		double elapsed_s = 0.0; 
		double start_s = node.time; 

		// use static storage to avoid allocation time penalty
		// not thread safe!
		int i = 0;
		if (fit_dphase) {
			double diff = 0.0;
			if (n <= skip_n + 1) {
				// Tonal not having enough node to skip.
				// First difference of phase is calculated without 
				// skipping the nodes.

				while (it.hasNext() & elapsed_s < how_far_s) {
					prev = node;
					node =  it.next();
					elapsed_s = Math.abs(start_s - node.time);
					if (incoming_edge)
						x_tmp[i] = prev.freq;
					else
						x_tmp[i] = node.freq;

					// first phase difference
					if (Math.signum(node.phase) == Math.signum(prev.phase))
						diff = Math.abs(node.phase - prev.phase);
					else {
						if (node.phase < 0.0)
							diff = Math.abs(node.phase) + prev.phase;
						else
							diff = Math.abs(prev.phase) + node.phase;
					}
					y_tmp[i] = diff;
					i++;
				}
			} else {
				while (skip_n != 0 & elapsed_s < how_far_s) {
					// skip N nodes
					node = it.next();
					elapsed_s = Math.abs(start_s - node.time);
					skip_n--;
				}
				while (it.hasNext() & elapsed_s < how_far_s) {
					// First difference of phase is calculated after 
					// skipping the nodes.

					prev = node;
					node =  it.next();
					elapsed_s = Math.abs(start_s - node.time);
					if (incoming_edge)
						x_tmp[i] = prev.freq;
					else
						x_tmp[i] = node.freq;

					// first phase difference
					if (Math.signum(node.phase) == Math.signum(prev.phase))
						diff = Math.abs(node.phase - prev.phase);
					else {
						if (node.phase < 0.0)
							diff = Math.abs(node.phase) + prev.phase;
						else
							diff = Math.abs(prev.phase) + node.phase;
					}
					y_tmp[i] = diff;
					i++;
				}
			}
		}
		else {
			// polynomial fit of frequency to time. (slope and shape)
			while (it.hasNext() & elapsed_s < how_far_s) {
				x_tmp[i] = node.time;
				y_tmp[i] = node.freq;
				i++;
				node = it.next();
				elapsed_s = Math.abs(start_s - node.time);
			}
		}

		// build the polynomial
		Fit(order, x_tmp, y_tmp, (double[]) null, (double[]) null, n);
	}
	
	void goodness_of_fit(double[] x, double[] y, int num_points) {

		// Determine adjusted R^2
		double sum_sq_err = 0.0;  // sum prediction err squared
		double sum_sq_total = 0.0;  // deviation from mean squared
		double ybar = 0.0;	           // sample mean Y

		for (int i=0; i < num_points; i++) {
			ybar = ybar + y[i];
		}

		ybar = ybar / num_points;
		
		double deviation;
		for (int i=0; i < num_points; i++) {
			deviation = y[i] - predict(x[i]);
			sum_sq_err = sum_sq_err + deviation * deviation;
			deviation = y[i] - ybar;
			sum_sq_total = sum_sq_total + deviation * deviation;
		}
		
		if (sum_sq_total < 1e-20) {
			// y is near constant, predictor should be a perfect fit
			R2 = 1.0;
		} else {
			// compute adjusted R^2 coefficient
			// which takes into account the number of predictor variables
			R2 = 1 - (sum_sq_err / (num_points - (coeff.length-1))) / 
					 (sum_sq_total / (num_points - 1));
		}
	}

	/*
	 * predict
	 * Given x, predict y
	 * @param x - predictor variable
	 */
	public double predict(double x) {
		double result = 0.0;
		
		int i = coeff.length - 1;

		double pow_x = 1;   // x^0
		// loop invariant:
		//    pow_x is x^(coeff.length - (i+1))
		while (i >= 0) {
			result = result + coeff[i] * pow_x;
			pow_x = x * pow_x;	// x^(coeff.length - (i+1))
			i--;
		}
		return result;
	}
	
	/*
	 * error
	 * Given x, return the error between x
	 * and its prediction.
	 * @param x - predictor variable
	 * @param y - actual value
	 */
	public double getErrorForPoint(double x, double y) {
		double error = y - predict(x);
		return error;
	}
	 
	 /*
	  * sq_error
	  * Given x, return the squared error between x
	  * and its prediction.
	 * @param x - predictor variable
	 * @param y - actual value
	  */
	 public double getSquaredErrorForPoint(double x, double y) {
		 double error = y - predict(x);
		 return error*error;
	 }

	 /*
	  * toString
	  * string representation of polynomial
	  */
	 public String toString() {
			StringBuffer str = new StringBuffer();
			str.append("poly: [");
			for (int idx=0; idx < coeff.length; idx++) {
				if (idx > 0)
					str.append(", ");
				str.append(String.format("%f", coeff[idx]));
			}
			str.append(String.format("] R2 = %f", R2));
			return str.toString();
	 }

	@Override
	public int getNumPredictors() {
		return this.degree;
	}

	@Override
	public double getR2() {
		return R2;
	}

	@Override
	public double getStdDevOfResiduals() {
		return this.std_dev;
	}

	@Override
	public double getAdjustedR2() {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public double getTotalSumOfSquares() {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public double getResidualsSumOfSquares() {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public double getRegressionSumOfSquares() {
		// TODO Auto-generated method stub
		return 0;
	}
} // FitPoly