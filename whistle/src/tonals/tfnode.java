package tonals;

/* To use in Matlab, the Java class files need to be
 * added to the path with javaaddpath(dir) 
 */

import java.util.*;
import java.io.Serializable;

public class tfnode implements Comparable<tfnode>, Serializable
{
	static final long serialVersionUID = 3;
	/* conversion factors */
	final public static double HzPerkHz = 1000.0;
	
    /* attributes of spectrum represented */
    public double time;
    public double freq;
    public double snr;  // signal to noise ratio dB re noise floor
    public double phase;
    //public double dphase;  // derivative of phase
    //public double ddphase; // 2nd derivative of phase

    /* time associated with longest successor or predecessor chains */
    public double latest_succ; // not used for now
    public double earliest_pred;    

    /* Nodes which fan in to or out of this node */
    transient public LinkedList<tfnode> predecessors;
    transient public LinkedList<tfnode> successors;
    
    private tfnode set_root;  /* for managing sets (union/find) */
    private tfnode next_free;  // used when maintaining sets of unused nodes
    
    private static tfnode free_list = null;
    
    /*
     * Grab a tfnode from the free list or create one if none
     * are available.  Use in place of new tfnode.
     * 
     * time frequency node.  Parameters are measurements of a
     * specific sample in the time x frequency domain.
     * @param time  - start time
     * @param freq - center frequency of bin
     * @param snr - signal to noise ratio re noise
     * @param phase - phase
     */
    //* @param dphase - estimate of phase derivative
    //* @param ddphase - estimate of 2nd derivative of phase
    static public tfnode create(double time, double freq, double snr, double phase)
    	//double dphase, double ddphase) {
    {
    	
    	tfnode node;
    	if (free_list != null) {
    		// Reuse the first existing node on the free list. 
    		node = free_list;
    		free_list = node.next_free;
    		
    		node.init_common(time, freq, snr, phase); //, dphase, ddphase);
    		// clear out the linked lists
    		node.predecessors.clear();
    		node.successors.clear();
    	} else {
    		node = new tfnode(time, freq, snr, phase); //, dphase, ddphase);
    	}
    	return node;
    }
    
    /*
     * Recycle a time frequency node.
     * @param node - node to recycle
     */
    static public void recycle(tfnode node) {
    	node.next_free = free_list;
    	free_list = node;
    }
    
    /*
     * time frequency node.  Parameters are measurements of a
     * specific sample in the time x frequency domain.
     * @param time  - start time
     * @param freq - center frequency of bin
     * @param snr - signal to noise ratio
     * @param phase - phase
     * @param dphase - estimate of phase derivative
     * @param ddphase - estimate of 2nd derivative of phase
     */
    
    public tfnode(double time, double freq, double snr, double phase) 
    		//double dphase, double ddphase)
    {
    	init_common(time, freq, snr, phase); //, dphase, ddphase);
    	/* linked lists serve as edges in the graph between nodes */
    	predecessors = new LinkedList<tfnode>();
    	successors = new LinkedList<tfnode>();

    }

    /* tfnode - no args */
    public tfnode() {
    	init_common(0.0, 0.0, 0.0, 0.0); // 0.0, 0.0);
    	predecessors = new LinkedList<tfnode>();
    	successors = new LinkedList<tfnode>();
	}

	/* initialize common parts of object 
     * @param time  - start time
     * @param freq - center frequency of bin
     * @param snr - signal to noise ratio
     * @param phase - phase
     * @param dphase - estimate of phase derivative
     * @param ddphase - estimate of 2nd derivative of phase
     */
    private void init_common(double time, double freq, double snr, 
    		double phase) //double dphase, double ddphase)
    {
    	next_free = null;
    	
    	/* Create a new node at the specified time, freq, and phase */
    	this.time = time;
    	this.freq = freq;
    	this.phase = phase;
    	//this.dphase = dphase;
    	//this.ddphase = ddphase;
    	
    	earliest_pred = time;  /* currently no predecessors */       	
    	set_root = this;  /* starts in its own set */
    }
    
    public tfnode find() {
    	/* find the owner of this set */
    	
    	/* implementation of the quick union-find algorithm
    	 * with path compression.  
    	 * 
    	 * See any algorithm book for details [add a specific reference, e.g. Comer], or 
    	 * http://www.cs.princeton.edu/~rs/AlgsDS07/01UnionFind.pdf 
    	 */
    	if (this != set_root) {
    		// We're not at the owner of the set yet, so ask
    		// the node we think own's us who the owner is.
    		// We update who we think the root is so that if 
    		// there is a chain we shorten it.
    		set_root = set_root.find();
    	}
    	return set_root;
    }
    
    public void union(tfnode other) {
    	// union the set associated with this node and another one
    	
    	// Find the node which is the root of the other set.
    	tfnode other_root = other.find();
    	// Set it's root to the root of this set.
    	other_root.set_root = this.find();
    }
    
    public boolean ismember(tfnode other) {
    	// is other a member of the same set as this one?
    	return this.find() == other.find();
    }
    
    public int compareTo(tfnode other) {
    	/* Comparison of nodes to make them sortable:
    	 * Priority in order of comparison:  freq, time
    	 */
    	int result = (int) Math.signum(this.freq - other.freq);
    	if (result == 0)
    		result = (int) Math.signum(this.time - other.time);
    	return result;
    }
     
    public boolean chain_forward(tfnode to) {
    	/* Link this node forward to another one */
    	
    	/* Create forward and backwards links */
    	boolean linked;
    	linked = this.successors.add(to);   /* forward link */
    	if (linked) {
    		/* try to add backlink */
    		linked = to.predecessors.add(this);
    		if (! linked)
    			this.successors.remove(to);  /* couldn't do it... */
    	}
    	
    	/* Update information about earliest predecessor for the to node */
    	if (linked) {
    		if (earliest_pred < to.earliest_pred)
    			to.earliest_pred = earliest_pred;
    	}
    	return linked;
    }
    
    public tonal best_path() {
    	
    	LinkedList<tfnode> path = new LinkedList<tfnode>();
    	
    	/* Search for best predecessor path.
    	 * For now, just look for longest
    	 * later look at slope and phase
    	 */
    	    	
    	tfnode current = this;
    	while (current != null) {    		    		    		  			
    		path.addFirst(current);      
    		
    		/* look for best previous one. 
    		 * Single node lookback may not be the best strategy,
    		 * but okay for now.
    		 */
    		current = current.best_predecessor();
    	}
    	
    	tonal tonepath = new tonal(path);
    	return tonepath;
    }
    
    /* estimate the derivative of phase */
    double dphase_est(double min_s) {
    	/* Estimate by searching back and seeing how phase changes.
    	 * Searches back to the first point at which there is a choice
    	 * and takes the average change in phase.
    	 * If none is possible, return Inf.
    	 */
    	tfnode after = this;;
    	tfnode current;
    	
    	double duration = 0; 
    	double dphase_sum = 0; 
    	while (after.predecessors.size() == 1) {
    		current = after.predecessors.get(0);
    		dphase_sum += after.phase - current.phase;
    		duration += after.time - current.time;
    		if (duration > min_s)
    			break;
    		after = current;
    	}
    	
    	if (duration > min_s)
    		return dphase_sum / duration;
    	else
    		return Double.POSITIVE_INFINITY;
    }
    
    /* estimate average of slope */
    double slope_est_avg(double min_s) {
    	/* Estimate by searching back and seeing how slope changes.
    	 * Searches back to the point N seconds behind the current point
    	 * and take average change in slope
    	 * NOTE: If there is a choice before we could reach a point
    	 * N seconds behind the current point we return INF
    	 */    	
    	tfnode after = this;
    	tfnode current;
    	
    	double duration = 0; 
    	double delta_freq_sum = 0; 
    	
    	while (after.predecessors.size() == 1) {
    		current = after.predecessors.get(0);    		
    		delta_freq_sum += Math.abs(after.freq - current.freq);
    		duration += after.time - current.time;    		
    		if (duration > min_s)
    			break;
    		after = current;
    	}
    	
    	if (duration > min_s)
    		return delta_freq_sum / duration;   
    	else
    		return Double.POSITIVE_INFINITY;
    }
    
    /* estimate the slope of a point N seconds behind the current point */     
    public double slope_est(double min_s) {
    	/* Searches back to the point N seconds behind the current point
    	 * and estimate slope of current point with regard to point searched. 
    	 * NOTE: If there is a choice before we could reach a point
    	 * N seconds behind the current point we return INF
    	 */     	
    	tfnode after = this;
    	tfnode current = null;
    	
    	double duration = 0;     	
    	
    	while (after.predecessors.size() == 1) {
    		current = after.predecessors.get(0);    		    		
    		duration += after.time - current.time;    		
    		if (duration > min_s)
    			break;
    		after = current;
    	}
    	
    	if (duration > min_s)
    		return Math.abs(this.freq - current.freq) / (this.time - current.time);    	
    	else
    		return Double.POSITIVE_INFINITY;
    }

    public tfnode best_predecessor() {
    	/* look for the best preceding node
    	 * Currently, best means longest.
    	 */
    	tfnode best = null;
    	if (chained_backward() == true) {
    		boolean found = false;
    		Iterator<tfnode> iter = predecessors.iterator();
    		/* search previous nodes for best one */
    		while (! found && iter.hasNext()) {
    			tfnode pred;
    			pred = iter.next();
    			if (pred.earliest_pred == earliest_pred) {
    				found = true; /* got it */
    				best = pred;
    			}
    		}
    		
    		if (! found) {
    			// throw an exception, we shouldn't see this
    		}
    	}
    	return best;
    }
    
    public void visit(ExamineNode callback) {
    	/* Search all successors and predecessors recursively 
    	 * For each node, the method examine is called on the callback object
    	 * which is expected to mutate itself for each node examined as
    	 * needed by the caller.
    	 */

    	// make sure we don't visit any node twice
    	HashSet<tfnode> visited = new HashSet<tfnode>();  
    	visit(callback, visited);
    }
    
    private void visit(ExamineNode callback, HashSet<tfnode> visited) {
    	/* auxilary function for void visit(ExamineNode callback) */

    	visited.add(this);  // note our visit
    	callback.examine(this);  // process node
    	
    	/* search the successors of current node */
    	for (tfnode successor : successors)
    		// Only visit if never seen
    		if (! visited.contains(successor))
    			successor.visit(callback, visited);
    	
    	/* search the predecessors of current node */
    	for (tfnode predecessor : predecessors)
    		if (! visited.contains(predecessor))
    			predecessor.visit(callback, visited);
    }
    
    public void visitPostOrder(ExamineNode callback) {
    	/* Search all successors and predecessors recursively 
    	 * For each node, the method examine is called on the callback object
    	 * which is expected to mutate itself for each node examined as
    	 * needed by the caller.
    	 */

    	// make sure we don't visit any node twice
    	HashSet<tfnode> visited = new HashSet<tfnode>();  
    	visitPostOrder(callback, visited);
    }
    
    private void visitPostOrder(ExamineNode callback, HashSet<tfnode> visited) {
    	/* auxilary function for void visit(ExamineNode callback) */

    	visited.add(this);  // note our visit
    	    	
    	/* search the successors of current node */
    	for (tfnode successor : successors)
    		// Only visit if never seen
    		if (! visited.contains(successor))
    			successor.visit(callback, visited);
    	
    	/* search the predecessors of current node */
    	for (tfnode predecessor : predecessors)
    		if (! visited.contains(predecessor))
    			predecessor.visit(callback, visited);
    	
    	callback.examine(this);  // process node
    }
    
    public boolean chain_backward(tfnode to) {
    	/* Link this node backward to another one */
    	return to.chain_forward(this);
    }
    
    final public boolean chained_forward() {
    	/* Are there any successors? */
    	return ! successors.isEmpty();
    }
    
    final public int chained_forwardN() {
    	return successors.size();  // N forward links
    }
    
    final public boolean chained_backward() {
    	/* Are there any predecessors? */
    	return ! predecessors.isEmpty();
    }
    
    final public int chained_backwardN() {
    	return predecessors.size();  // N backward links
    }

	/*
	 * is_junction()
	 * Returns true if there are multiple entries or exits into/from
	 * this node.
	 */
	final public boolean is_junction() {
		return chained_forwardN() > 1 || chained_backwardN() > 1;
	}
	
	/*
	 * on_single_path()
	 * Returns true if when there is exactly one way in and out of the node
	 */
	final public boolean on_single_path() {
		return chained_forwardN() == 1 && chained_backwardN() == 1; 
	}
	
    public Iterator<tfnode> iter_forward() {
    	/* Get iterator over nodes fanning out from this one */
    	return successors.iterator();
    }
    
    public Iterator<tfnode> iterator_predecessors() {
    	/* Get iterator over nodes fanning into this one. */
    	return predecessors.iterator();
    }
    
    public String toString() {
    	return String.format("(%.3f s, %.2f kHz, %.2f rad)",
    			time, freq/HzPerkHz, phase);
    }
    
}
    
