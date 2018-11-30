package tonals;

import java.io.EOFException;
import java.io.IOException;
import java.io.FileInputStream;
import java.io.ObjectInputStream;
import java.io.Serializable;
import java.util.Collections;
import java.io.DataInputStream;

import java.util.*;

public class tonal extends LinkedList<tfnode> implements Comparable<tonal>, Serializable
{
	static final long serialVersionUID = 0;
	private static int toStringLastN = 1;
	private static int toStringFirstN = 2;
	final double Pi2 = 2 * Math.PI;
	final long graphId;
	

	double score;
	double confidence;
	
	String species;
	String call;
	
    /* provide interface for sorting by time 
     * which is not the natural order for this set
     */
    public static final Comparator<tonal> TimeOrder = 
    	new Comparator<tonal>() {
    		public int compare(tonal t1, tonal t2) {
    			double tdiff = t1.getFirst().time - t2.getFirst().time;
    			if (tdiff == 0) {
    				tdiff = t1.getLast().time - t2.getLast().time;
    			}
    			return (int) Math.signum(tdiff);
    		}
    };
    
    public tonal() {
    	this(-1);
    }
    
	public tonal(long graphId) {
		super();
		this.graphId = graphId;
	}
	
	public tonal(tfnode n, long graphId) {
		super();
		this.add(n);
		this.graphId = graphId;
	}
	
	tonal(AbstractSequentialList<tfnode> node_list, long graphId) {
		super();
		this.addAll(node_list);
		this.graphId = graphId;
	}
	
	public tonal(double[] time, double[] freq) {
		this(time, freq, -1);
	}
	
	public tonal(double[] time, double[] freq, long graphId) {
		// Create a tonal given arrays time and frequency.
		super();
		for (int i=0; i < time.length; i++)  {
			// FIXME ridge
			this.add(tfnode.create(time[i], freq[i], 0.0, 0.0, false));
		}
		this.graphId = graphId;
	}
	
	public long getGraphId() {
		return graphId;
	}
	
	public double getScore() {
		return score;
	}

	public void setScore(double score) {
		this.score = score;
	}

	public double getConfidence() {
		return confidence;
	}

	public void setConfidence(double confidence) {
		this.confidence = confidence;
	}

	public String getSpecies() {
		return species;
	}

	public void setSpecies(String species) {
		this.species = species;
	}

	public String getCall() {
		return call;
	}

	public void setCall(String call) {
		this.call = call;
	}

	
	// 
	// Read a set of serialized tonals and return them as a linked list.
	// @param - filename from which to read
	//
	static public LinkedList<tonal> tonalsLoad(String Filename)
	throws IOException, ClassNotFoundException
	{
		FileInputStream fstream = new FileInputStream(Filename);
		ObjectInputStream istream = new ObjectInputStream(fstream);

		LinkedList<tonal> tonals = new LinkedList<tonal>();

		// Read in each tonal and append to list
		try {
			while (true) {
				tonal t = (tonal) istream.readObject();
				tonals.add(t);
			} 
		} catch (EOFException e) {
			// all done 
		}
		istream.close();
		Collections.sort(tonals, tonal.TimeOrder);	// sort by start time
		return tonals;
	}
	
	//
	// Read time and freq from the binary file. First we create tfnodes
	// then we create tonals and return linked list of tonals.
	// @param - filename from which to read
	//
	@Deprecated
	static public LinkedList<tonal> tonalsLoadBinary(String Filename)
	throws IOException, ClassNotFoundException
	{
		FileInputStream fstream = new FileInputStream(Filename);
		DataInputStream istream = new DataInputStream(fstream);
		
		LinkedList<tonal> tonals = new LinkedList<tonal>();
		
		double time = 0.0, freq = 0.0;
		
		// Read in time and freq from the file and create list of tonals
		try {
			while (true) {
				tonal t = null;
				int N = istream.readInt();
				LinkedList<tfnode> tfnodes = new LinkedList<tfnode>();
				while (N > 0) {
					time = istream.readDouble();
					freq = istream.readDouble();
					// FIXME ridge
					tfnodes.add(new tfnode(time, freq, 0.0, 0.0, false));
					N--;
				}
				// FIXME Graph ID
				t = new tonal(tfnodes, 0);
				tonals.add(t);
			}
		} catch (EOFException e) {
			// all done 
		}
		istream.close();
		Collections.sort(tonals, tonal.TimeOrder);	// sort by start time

		return tonals;
	}
	
	//
	// compare a pair of tonals
	public int compareTo(tonal other) {
		// same number of elements?
		int comparison;
		
		if (other == null)
			comparison = -1;
		else
			comparison = Integer.signum(this.size() - other.size());
		
		if (comparison == 0) {
			// same length, look at details
			Iterator<tfnode> it_this = this.iterator();
			Iterator<tfnode> it_other = other.iterator();
			
			// step through list until we find something different
			// or we are done
			while (comparison == 0 && it_this.hasNext())
				comparison = it_this.next().compareTo(it_other.next());
		}
		return comparison;
	}
	/* ================================================ */
	/* Pull out vectors of associated time, freq, etc. */
	

	public double[] get_time() {
		/* Return times associated with this tonal */
		int n = size();
		double[] time = new double[n];
		for (int i=0; i < n; i++)
			time[i] = get(i).time;
		return time;
	}

	public double[] get_freq() {
		/* Return frequencies associated with this tonal */
		int n = size();
		double[] freq = new double[n];
		for (int i=0; i < n; i++)
			freq[i] = get(i).freq;
		return freq;
	}

	public double[] get_snr() {
		/* Return SNR associated with this tonal */
		int n = size();
		double[] snr = new double[n];
		for (int i=0; i < n; i++)
			snr[i] = get(i).snr;
		return snr;
	}

	public double[] get_phase() {
		/* Return phases associated with this tonal */
		int n = size();
		double[] phase = new double[n];
		for (int i=0; i < n; i++)
			phase[i] = get(i).phase;
		return phase;
	}
	
	public int[] get_ridge() {
		/* Return times associated with this tonal */
		int n = size();
		int[] ridge = new int[n];
		for (int i=0; i < n; i++)
			ridge[i] = get(i).ridge?1:0;
		return ridge;
	}
	
	public double getPercentRidgeSupported() {
		int count = 0;
		int n = size();
		for (int i=0; i < n; i++) {
			if (get(i).ridge) {
				count++;
			}
		}
		return (double)count/(double)n;
	}
	
	
	/* ================================================ */

	// deep copy of list structure, but not list itself
	public tonal clone() {
		return new tonal(this, this.graphId);
	}
	
	// are two tonal paths the same?
	public boolean equals(tonal other) {
		// check size first
		boolean eq = this.size() == other.size();
		if (eq) {
			int n = this.size();
			int i = 0;
			// same size, check nodes
			while (eq && i < n) {
				eq = this.get(i).equals(other.get(i));
				i++;
			}
		}
		return eq;
	}
	
	/* 
	 * Create a new tonal consisting of the tonal associated with
	 * this object followed by the tonal argument.  If the last
	 * node in the caller is the first node of the argument, the
	 * resultant tonal will only have one instance of it.
	 *
	 * @param - tonal to be appended.
	 */  
	public tonal merge(tonal append_me) {
		tonal merged = this.clone();

		// Copy append_me into merged, skipping the first node
		// if it is the same as the last in merged.
		boolean skip = 
				merged.size() > 0 &&
				merged.getLast().compareTo(append_me.getFirst()) == 0;
		
		for (tfnode n : append_me) {
			if (skip)
				skip = false;
			else
				merged.add(n);
		}
		
		return merged;
	}
	
	/*
	 * Prepend the tonal associated with the argument to this
	 * tonal.
	 * 
	 *  @param - tonal to be prepend
	 */
	public void merge_prepend(tonal prepend_me) {
		this.addAll(0, prepend_me);
	}
	
	/* 
	 * Estimate the average slope of the tonal by considering
	 * N sec. tail/head part of the tonal.
	 * Overlapping node is skipped while estimating slope average 
	 * of the tonal. Overlapping node is a tail in the case of 
	 * incoming tonal and a head in the case of outgoing tonal.
	 * @param min_s Duration of the tonal to be considered. 
	 * @param terminatingNodes Incoming(true) or outgoing(false) tonal.
	 */
	public double slope_avg (double min_s, boolean terminatingNodes) {
		
		double slp_avg = 0.0;
		double delta_freq_sum = 0.0;
		double duration = 0.0;
		
		if (terminatingNodes) {
			/* Consider part of tonal N sec. before the tail
			 * while estimating the slope average.
			 * Skip the tail as it is overlapping point.
			 */
			
			tfnode node_before_tail = this.getLast().predecessors.getFirst();
			tfnode after = node_before_tail; 
			while (!after.predecessors.isEmpty()) {
				tfnode current = after.predecessors.getFirst();
				delta_freq_sum += Math.abs(after.freq - current.freq);
				duration += after.time - current.time;
				if (duration > min_s)
					break;
				after = current;
			}
		} else {
			/* Consider part of tonal N sec. after the head
			 * while estimating the slope average.
			 * Skip the head as it is overlapping point.
			 */
			
			tfnode node_after_tail = this.getFirst().successors.getFirst();
			tfnode after = node_after_tail; 
			while (!after.successors.isEmpty()) {
				tfnode current = after.successors.getFirst();
				delta_freq_sum += Math.abs(after.freq - current.freq);
				duration += Math.abs(after.time - current.time);
				if (duration > min_s)
					break;
				after = current;
			}
		}

		if (delta_freq_sum == 0.0 && duration == 0.0) {
			/* Tonal has single edge (A->B).
			 * 
			 * In case of incoming tonal tail node (B) is a junction point 
			 * (overlapping of tonals).
			 * OR
			 * In case of outgoing tonal head node (A) is a junction point
			 * (overlapping of tonals).
			 * 
			 * What to do in this case ? Should we consider taking average ? 
			 */
			
			// For now we take average
			slp_avg = Math.abs(get(0).freq - get(1).freq) /
					  Math.abs(get(0).time - get(1).time);
		} else
			slp_avg = delta_freq_sum / duration;
		
		return slp_avg;
	}
	
	/* Estimate the derivative of phase of the tonal by considering 
	 * N sec. tail/head part of the tonal.
	 * Overlapping node is skipped while estimating phase derivative 
	 * of the tonal. Overlapping node is a tail in the case of 
	 * incoming tonal and a head in the case of outgoing tonal.
	 * @param min_s Duration of the tonal to be considered. 
	 * @param terminatingNodes Incoming(true) or outgoing(false) tonal.
	 */
	public double dphase_est (double min_s, boolean terminatingNodes) {
		
		double dphase = 0.0;
		double delta_phase_sum = 0.0;
		double duration = 0.0;
		tfnode before = null, after = null;
		Iterator<tfnode> it;
		
		if (terminatingNodes) {
			/* Consider part of tonal N sec. before the tail
			 * while estimating the phase derivative.
			 * Skip the tail as it is overlapping point.
			 */
			it = this.descendingIterator();

			if (it.hasNext()) {
				after = it.next(); // get initial node, we won't process it
			}
			while (it.hasNext() && duration < min_s) {
				before = it.next();
				delta_phase_sum += after.phase - before.phase;
				duration += after.time - before.time;
				after = before;
			}
		} else {
			/* Consider part of tonal N sec. after the head
			 * while estimating the phase derivative.
			 * Skip the head as it is overlapping point.
			 */
			it = this.iterator();

			if (it.hasNext()) {
				before = it.next(); // get initial node, we won't process it
			}
			while (it.hasNext() && duration < min_s) {
				after = it.next();
				delta_phase_sum += after.phase - before.phase;
				duration += after.time - before.time;
				after = before;
			}
		}

		if (delta_phase_sum == 0.0 && duration == 0.0) {
			/* Tonal has single edge (A->B).
			 * 
			 * In case of incoming tonal tail node (B) is a junction point 
			 * (overlapping of tonals).
			 * OR
			 * In case of outgoing tonal head node (A) is a junction point
			 * (overlapping of tonals).
			 * 
			 * What to do in this case ? Should we consider taking average ? 
			 */
			
			// For now we take average
			dphase = get(0).phase - get(1).phase /
					 Math.abs(get(0).time - get(1).time);
		} else 
			dphase = delta_phase_sum / duration;
		
		return dphase;
	}
	
	/*
	 * presence
	 * Given a list of tonals, it derives non overlapping 
	 * start and stop times of when tonals are present. 
	 *
	 * @param tonals[] - list of tonals
	 */
	public ArrayList<ArrayList<Double>> presence (tonal tonals[]) {
		
		ArrayList<tonal> list_tonals = new ArrayList<tonal>(Arrays.asList(tonals));
		
		// Check for empty tonals, if found one
		// remove it from the list.
		for (tonal t : tonals) {
			if (t.isEmpty())
				list_tonals.remove(t);
		}

		// Sort the tonals based on their start time
		Collections.sort(list_tonals, new tonalSortByTime());
		
		// Stores start and end time ArrayLists in single ArrayList.
		ArrayList<ArrayList<Double>> presence_mtr = new ArrayList<ArrayList<Double>>(); 

		// Records the start time and end time of when
		// tonals are present.
		ArrayList<Double> start_times = new ArrayList<Double>();
		ArrayList<Double> end_times = new ArrayList<Double>();

		// Tonals visited
		HashSet<tonal> visited = new HashSet<tonal>();

		for (tonal t : list_tonals) {
			if (!visited.contains(t)) {
				visited.add(t);
				double t_start = t.getFirst().time;
				double t_end = t.getLast().time;
				double min_time = t_start;
				double max_time = t_end;
				for (tonal k : list_tonals) {
					if (!visited.contains(k)) {
						if (t_start <= k.getFirst().time && 
								k.getFirst().time <= t_end) {
							visited.add(k);
							if (k.getLast().time > t_end) {
								max_time = k.getLast().time;
								t_end = k.getLast().time;
							}
						}
					}
				}
				start_times.add(min_time);
				end_times.add(max_time);
			}
		}

		presence_mtr.add(start_times);
		presence_mtr.add(end_times);
		return presence_mtr;
	}
	
	/*
	 * get_time_startEnd
	 * Given a list of tonals, returns the start and stop times of
	 * the tonals. 
	 *
	 * @param tonals[] - list of tonals
	 */
	public ArrayList<ArrayList<Double>> get_time_startEnd (tonal tonals[]) {
		
		// Stores start and end time ArrayLists in single ArrayList.
		ArrayList<ArrayList<Double>> performance_mtr = new ArrayList<ArrayList<Double>>();

		// Records the start and end times of all the tonals
		ArrayList<Double> tonals_startTime = new ArrayList<Double>();
		ArrayList<Double> tonals_endTime = new ArrayList<Double>();

		for (tonal t: tonals) {
			if (!t.isEmpty()) {
				tonals_startTime.add(t.getFirst().time);
				tonals_endTime.add(t.getLast().time);
			} else {
				// Empty tonal 
				tonals_startTime.add(0.0);
				tonals_endTime.add(0.0);
			}
		}

		performance_mtr.add(tonals_startTime);
		performance_mtr.add(tonals_endTime);
		return performance_mtr;
	}
	
	/*
	 * overlapping_tonal
	 * Given a list of tonals, start time and end time returns overlapping tonals 
	 *
	 * @param tonals - list of detected tonals
	 * @param startTime - start time 
	 * @param endTime - end time
	 */
	public ArrayList<tonal> overlapping_tonals(List<tonal> tonals) {

		ArrayList<tonal> overlap_tonals = new ArrayList<tonal>();
		double startTime = getFirst().time;
		double endTime = getLast().time;
		/* iterate over each tonal in the tonal list */
		Iterator<tonal> iter = tonals.iterator();
		while (iter.hasNext()) {
			tonal t = iter.next();
			if ((t.getFirst().time <= startTime && t.getLast().time >= startTime)
					|| (t.getFirst().time >= startTime && t.getFirst().time <= endTime)) {

				overlap_tonals.add(t);
			}
		}
		return overlap_tonals;
	}
	
	/*
	 * Determine the phase coherency of this path
	 * Phase coherency is a measure of how consistent the change in
	 * phase is from one measurement to the next, normalized by 
	 * the difference in time.
	 */
	class phase_coherency {
		public double mean;
		public double var;
		public int n;
		
		public phase_coherency(int n, double mean, double var) {
			this.n = n;
			this.mean = mean;
			this.var = var;
		}
		
		public String toStr() {
			return String.format("mu=%f var=%f n=%d", mean, var, n);
		}
	}
	
	phase_coherency get_phase_coherency() {
		phase_coherency phase = null;
		int length = size();

		if (length > 2) {
			
			int n = length - 1;  // one less derivative than samples
			
			// vector of phase derivatives
			double[] dphases = new double[n];
			double prev = this.getFirst().phase;
			for (int i=0; i < n; i++) {
				double current = get(i+1).phase;
				/* find the difference in phase.  As phase wraps at 2pi, we 
				 * check with an offset of 2pi as well so that a pair of 
				 * phases near 0 and 2pi do not seem far apart.
				 * 
				 * For now, we're only concerned with the absolute value, 
				 * we don't care which direction it is changing.  We may want 
				 * to look at this again later.
				 */
				dphases[i] = Math.min(Math.abs(current - prev),
						Math.abs(prev - current - Pi2));
			}
			
			// compute statistics
			double mu = 0;
			for (int i=0; i < n; i++)
				mu += dphases[i];
			mu = mu / n;
			
			double var = 0.0;
			for (int i=0; i < n; i++) {
				double diff = dphases[i] - mu;
				var += diff*diff;
			}
			var = var / (n - 1);
			
			phase = new phase_coherency(n, mu, var);
		}
		
		return phase;
				
	} 
	
	/*
	 * Return duration of tonal
	 */
	public double get_duration() {
		return Math.abs(this.getFirst().time - this.getLast().time);
	}
			
	
	/* Set the number of elements printed from head of list
	 * when toString() is called.
	 * 
	 * @param firstN - how many, < 0 implies all
	 * 
	 * @see set_toStrlastN get_toStrFirstN get_toStrLastN
	 */
	static public void set_toStrFirstN(int firstN) {
		tonal.toStringFirstN = firstN;
	}

	/* Set the number of elements printed from tail of list
	 * when toString() is called.
	 * 
	 * @param lastN Print the last N
	 * 
	 * @see set_toStrFirstN get_toStrFirstN get_toStrLastN 
	 * 
	 * Overlap between set_toStrFirstN and set_toStrLastN is permitted
	 * e.g. get_toStrFirstN() + get_toStrLastN() > tonal_instance.size()
	 */
	static public void set_toStrLastN(int lastN) {
		tonal.toStringLastN = lastN;
	}
	
	/* Get the number of elements printed from the head of list
	 * when toString() is called.
	 * 
	 * @returns Number of elements
	 * @see set_toStrFirstN set_toStrLastN get_toStrLastN 
	 */
	static public int get_toStrFirstN() {
		return tonal.toStringFirstN;
	}
	
	/* Get the number of elements printed from the tail of list
	 * when toString() is called.
	 * 
	 * @returns Number of elements
	 * @see set_toStrFirstN get_toStrFirstN set_toStrLastN
	 */
	static public int get_toStrLastN() {
		return tonal.toStringLastN;
	}
	
	/*
	 * toString 
	 * Create a string representation of the tonal.
	 * 
	 */
	public String toString() {
		return toString(tonal.toStringFirstN, tonal.toStringLastN);
	}
	
	/*
	 * toString
	 * Covert tonal to a string, displaying up to the first N tfnodes.
	 * @param - Maximal # of nodes at beginning to display, negative for all
	 * @param - Maximal # of nodes at end to display.
	 */
    public String toString(int FirstN, int LastN) {
    	/* format path as string showing starting/stopping time & freq */
    	StringBuffer str = new StringBuffer();
    	int length = size();
    	
    	// how many to print from head?  Whole list or first N subject to size
    	int headN = (FirstN < 0) ? 
    			length : Math.min(FirstN, length);
    			
    	if (headN > 0) {
    		str.append('[');
        	// handle head of list
    		for (int i=0; i < headN; i++) {
    			str.append(get(i).toString());
    		}
    		// handle tail - find size
    		int tailIdx = length - LastN;
    		if (tailIdx <= headN)
    			tailIdx = headN;  // overlap, start right after head
    		else if (tailIdx < length)
    			str.append("...");  // indicate skipping
    		
    		// print any needed tail items
    		while (tailIdx < length)
    			str.append(get(tailIdx++).toString());
    		
    		str.append(']');
    	} else {
    		str.append("[]");
    	}
    	
    	return str.toString();
    }
    
    public String toRidgeSupprtString() {
		StringBuilder builder = new StringBuilder();
		Iterator<tfnode> i = iterator();
		while (i.hasNext()) {
			builder.append(i.next().ridge?"1":"0");
		}
		return builder.toString();
	}

	public double duration() {
		return Math.abs(this.getFirst().time - this.getLast().time);
	}
}
