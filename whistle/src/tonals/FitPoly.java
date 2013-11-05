package tonals;

public interface FitPoly {

	public int getNumPredictors();

	public double getR2();
	
	public double getAdjustedR2();

	// predicted y value corresponding to x
	public double predict(double x);

	/**
	 * sq_error Given x, return the squared error between x and its prediction.
	 * 
	 * @param x
	 *            - predictor variable
	 * @param y
	 *            - actual value
	 */
	public double getSquaredErrorForPoint(double x, double y);

	/**
	 * error Given x, return the error between x and its prediction.
	 * 
	 * @param x
	 *            - predictor variable
	 * @param y
	 *            - actual value
	 */
	public double getErrorForPoint(double x, double y);
	
	public double getStdDevOfResiduals();
	
	public double getTotalSumOfSquares();
	
	public double getResidualsSumOfSquares();
	
	public double getRegressionSumOfSquares();
}
