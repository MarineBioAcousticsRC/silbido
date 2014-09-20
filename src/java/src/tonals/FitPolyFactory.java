package tonals;

import java.util.Vector;

public class FitPolyFactory {

	public static FitPoly createFitPoly(int order, Vector<Double> x, Vector<Double> y) {
		return new FitPolyJama(order, x, y);
	}
	
	public static FitPolyJama createFitPoly(int degree, tonal path, int skip_n, boolean fit_dphase, boolean incoming_edge) {
		return new FitPolyJama(degree, path, skip_n, incoming_edge);
	}
}