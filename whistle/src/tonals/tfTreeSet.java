package tonals;

import java.util.*;

// Extension of nodes of tfTreeSets with node to array accessors

public class tfTreeSet extends TreeSet<tfnode> {

	static final long serialVersionUID = 0;

	public tfTreeSet(double[] time, double[] freq, double[] snr,
			double[] phase, int[] ridge) {
		//, double[] dphase, double[] ddphase) {

		/* Create a set of tfnodes given arrays time, freq, 
    	 * phase, and its derivative
    	 */
    	
    	/* todo - add exception for bad lengths */
    	for (int i=0; i < time.length; i++)
    		this.add(tfnode.create(time[i], freq[i], snr[i], phase[i], ridge[i]==1));
    				//dphase[i], ddphase[i]));
    }
    
	public tfTreeSet() {
		// nothing to do, super class handles it
	}
	
	/* ================================================ */
	/* Pull out vectors of associated time, freq, phase */
	public double[] get_time() {
		/* Return times */
		int n = this.size();
		double[] time = new double[n];
		int i = 0;
		for (tfnode node : this) {
			time[i++] = node.time;
		}
		return time;
	}

	public double[] get_freq() {
		/* Return frequencies */
		int n = this.size();
		double[] freq = new double[n];
		int i = 0;
		for (tfnode node : this) {
			freq[i++] = node.freq;
		}
		return freq;
	}

	public double[] get_phase() {
		/* Return phases */
		int n = this.size();
		double[] phase= new double[n];
		int i = 0;
		for (tfnode node : this) {
			phase[i++] = node.phase;
		}
		return phase;
	}
	/* ================================================ */
}
