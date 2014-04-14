package tonals;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Formatter;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.PriorityQueue;
import java.util.Set;

public class graph implements Serializable {
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	/*
	 * Constructs a graph representing tonals.  
	 * Paths without choice points are collapsed into a single edge,
	 * so each node consists of a choice point where two or more
	 * candidate tonals meet on either the incoming or outgoing edges
	 * (or possibly both).
	 */
	public boolean debug = false;
	
	// Graph entries and exits
	private LinkedList<tfnode> nodes_in;  // nodes with no ancestors
	private LinkedList<tfnode> nodes_out; // nodes with no descendants
	
	// edge lists indexed by node
	// As it is unlikely that any given node will have a large number
	// of entries and exits
	private HashMap<tfnode, LinkedList<edge<tfnode, tonal>>> in;
	private HashMap<tfnode, LinkedList<edge<tfnode, tonal>>> out;
	
	private ArrayList<edge<tfnode, tonal>> allEdges;

	public double resolutionHz;
	public final double graphId;
	
	/*
	 * Create a graph.
	 * The first node given must be at one of the the following:
	 * entry point - no predecessors
	 * exit point - no successors
	 * junction - 2 or more entries on the successor list,
	 * 			the predecessor list, or both.
	 */
	public graph(tfnode n, double graphId) {
		
		this.graphId = graphId;
		
		// initialize edge list maps
		in = new HashMap<tfnode, LinkedList<edge<tfnode, tonal>>>();
		out = new HashMap<tfnode, LinkedList<edge<tfnode, tonal>>>();
		allEdges = new ArrayList<edge<tfnode, tonal>>();
		
		// initialize list of entries/exits
		nodes_in = new LinkedList<tfnode>();
		nodes_out = new LinkedList<tfnode>();
	
		HashSet<tfnode> visited = new HashSet<tfnode>();
		build(n, visited);
	}
	
	// Create a new copy of a graph. This is a deep copy
	public graph(graph other, double graphId) {
		this.graphId = graphId;
		
		in = map_clone(other.in);
		out = map_clone(other.out);
		
		this.nodes_in = new LinkedList<tfnode>();
		for (tfnode entry: other.nodes_in)
			this.nodes_in.add(entry);
		
		this.nodes_out = new LinkedList<tfnode>();
		for (tfnode exit: other.nodes_out)
			this.nodes_out.add(exit);
	}
	
	public double getGraphId() {
		return graphId;
	}
	
	// Moderately deep copy
	// Copy down to just above the edge level
	private HashMap<tfnode, LinkedList<edge<tfnode, tonal>>> 
		map_clone(HashMap<tfnode, LinkedList<edge<tfnode, tonal>>> map) {
		
		HashMap<tfnode, LinkedList<edge<tfnode, tonal>>> copy;
		if (map == null)
			copy = map;
		else {
			copy = new HashMap<tfnode, LinkedList<edge<tfnode, tonal>>>();
			for (tfnode keys: map.keySet()) {
				LinkedList<edge<tfnode, tonal>> items = new LinkedList<edge<tfnode, tonal>>();
				for (edge<tfnode, tonal> item : map.get(keys)) {
					items.add(item);
				}
				copy.put(keys, items);
			}
		}
		return copy;
	}

	/*
	 * get_edges
	 * Given a hash map from node to edge list and a junction node,
	 * return the list of edges in the direction associated with
	 * the hash map.
	 * If no such list exists, one is created.
	 * 
	 * @param direction - Direction of links, must be in or out
	 *                    Do not use with other hashmaps due to
	 *                    side effects (see below).
	 * @param node - associated node
	 * 
	 * Side Effects:  When a list is created, we also create
	 * one for the opposite direction.  Variables in/out are
	 * assumed. 
	 */
	LinkedList<edge<tfnode, tonal>> get_edges(
			HashMap<tfnode, LinkedList<edge<tfnode, tonal>>> direction,
			tfnode node) {
		
		// retrieve the list
		LinkedList<edge<tfnode, tonal>> list = direction.get(node);
		if (list == null) {
			// list did not exist.  Create it for  each direction
			in.put(node, new LinkedList<edge<tfnode, tonal>>());
			out.put(node, new LinkedList<edge<tfnode, tonal>>());
			// retrieve the list in the direction that the user wanted
			list = direction.get(node);
		}
		
		return list;
	}
	
	/*
	 * pred_path
	 * Given a node at a junction and the first node of a  
	 * desired predecessor path, construct a tonal from
	 * the previous junction to the specified one.
	 * @param end - terminating junction node
	 * @param pred - previous node along the desired path
	 */
	tonal pred_path(tfnode end, tfnode pred) {

		tfnode prev = end;
		tfnode node = pred;

		// Search back to previous junction point or terminal
		while (node.on_single_path() == true) {
			prev = node;
			node = node.predecessors.getFirst();
		}
		// node now at a junction, follow it forward
		return succ_path(node, prev);
	}
	
	/*
	 * succ_path
	 * Given a node at a junction and the first node of a  
	 * desired successor path, construct a tonal from
	 * the specified junction to the next one.
	 * @param first - starting junction node
	 * @param succ - node along the desired successor path
	 */
	tonal succ_path(tfnode first, tfnode succ) {
		tonal path = new tonal(this.graphId);
		tfnode node = succ;
		tfnode prev = first;
		
		path.add(prev);
		// search until we reach a junction point or terminal
		while (node.on_single_path() == true) {
			path.add(node);
			prev = node;
			node = node.successors.getFirst();
		}
		// at junction or terminal
		path.add(node);
		return path;
	}

	/*
	 * add_edge - If the edge already exists as defined by the 
	 * Comparable interface, it will not be added again.
	 * Add an edge to the graph
	 * @param - edge
	 */
	void add_edge(edge<tfnode, tonal> an_edge) {
		LinkedList<edge<tfnode, tonal>> edges;
		boolean added = false;
		
		// list of edges leading out from start
		edges = get_edges(out, an_edge.from);
		if (! edges.contains(an_edge)) {
			// wasn't in the list, add it
			edges.add(an_edge);
			added = true;
		}
		if (added) {
			// added on leading out side, handle leading in
			edges = get_edges(in, an_edge.to);
			if (edges.contains(an_edge)) {
				// uh-oh, should not be here!
				throw new GraphException(
						"Graph corrupted, in/out not symmetric.");
			} else {
				edges.add(an_edge);
			}
		}
		
		
	}

	/*
	 * add_edge - If the edge already exists as defined by the 
	 * Comparable interface, it will not be added again.
	 * Add an edge to the graph
	 * @param - origination node of path
	 * @param - termination node of path
	 * @param - path
	 */
	void add_edge(tfnode from, tfnode to, tonal path) {
		// check if outgoing edge is already in graph.
		// we only need to check in one direction as we are assuming
		// bidirectional edges
		LinkedList<edge<tfnode, tonal>> edges = get_edges(out, from);
		// assume not in edge set until we learn otherwise
		boolean exists = false;  
		for (edge<tfnode, tonal> e : edges) {
			// if an existing edge goes to the same place
			// along the same path, we already have this one.
			if (e.to == to && e.content.equals(path)) {
				exists = true;
				break;
			}
		}
		
		if (exists == false) {
			// could not find it, we have a new edge
			edge<tfnode, tonal> new_edge = 
				new edge<tfnode, tonal>(from, to, path);
			// add it to both sides 
			edges.add(new_edge);  // outgoing
			get_edges(in, to).add(new_edge);  // incoming
			this.allEdges.add(new_edge);
		}
	}
	
	/*
	 * remove_edge
	 * Remove an edge from the graph
	 */
	void remove_edge(tfnode from, tfnode to, tonal path) {
		
		// check if outgoing edge is in graph.
		// we only need to check in one direction as we are assuming
		// bidirectional edges
		LinkedList<edge<tfnode, tonal>> edges = get_edges(out, from);
		for (edge<tfnode, tonal> e : edges) {
			// if an existing edge goes to the same place
			// along the same path, we have this one.
			if (e.to == to && e.content.equals(path)) {
				// remove it from both side
				edges.remove(e); // outgoing
				get_edges(in, to).remove(e); // incoming
				break;
			}
		}
	}
	/*
	 * remove_edge
	 * Remove an edge from the graph
	 * This method does not update the nodes_in and nodes_out
	 * lists.  If an edge is deleted, these may need to be
	 * updated.
	 */
	void remove_edge(edge<tfnode, tonal> e) {
		LinkedList<edge<tfnode, tonal>> edges;
		
		// Handle source side
		edges = get_edges(out, e.from);
		edges.remove(e);
		// Handle destination side
		edges = get_edges(in, e.to);
		edges.remove(e);
	}
			
	// Create a graph junction node graph representation
	// by exploring the graph associated with the given tfnode.
	void build(tfnode n, HashSet<tfnode> visited) {
		if (visited.contains(n) == false) {
			// node is either an unvisited junction or on an arc
			// between two junctions. 

			int backN = n.chained_backwardN();
			int nextN = n.chained_forwardN();

			// does node start or terminate the graph?
			boolean starting = backN == 0;
			boolean terminating = nextN == 0;

			if (starting) {
				nodes_in.add(n);	// starting node
			} else {
				// Add edges from other nodes
				for (tfnode pred : n.predecessors) {
					// Find where we go to 
					tonal t = pred_path(n, pred);
					add_edge(t.getFirst(), n, t);
				}
			}
			
			if (terminating) {
				nodes_out.add(n);   // exit node
			} else {
				// Add edges to other nodes
				for (tfnode succ : n.successors) {
					tonal t = succ_path(n, succ);
					add_edge(n, t.getLast(), t);
				}
			} 
			
			visited.add(n);  // mark node as processed
			// visit predecessors and successors
			for (edge<tfnode, tonal> pred : in.get(n))
				build(pred.from, visited);
			for (edge<tfnode, tonal> succ : out.get(n))
				build(succ.to, visited);
		}  /* if not visited */

	}
	
	public graph disambiguate(double disamb_thr_s, double resolutionHz, boolean use_ridges, double ridge_thresh) {
		// Create a moderately deep copy of this graph.
		// The edge containers have fresh copies, but the edges
		// and nodes are shared.
		graph copy = new graph(this, this.graphId);
		copy.compress(disamb_thr_s, resolutionHz);
		if (use_ridges) {
			copy.process_bridges(ridge_thresh);
		}
		return copy;
	}
	
	/* 
	 * compress
	 * Compress the graph by linking likely edges considering
	 * slope and phase derivative.
	 * @param disamb_thr_s - How long to look for change 
	 * 						 in phase derivative and slope
	 * @param fit_dphase - boolean for considering first phase difference
	 * @param fit_vecstr - boolean for considering vector strength method
	 */
	void compress(double disamb_thr_s, double resolutionHz) {
		debug = false;
		if (debug) {
			System.out.printf("compress graph: *************************** \n%s\n", this.toString());
		}
		
		// Remove spurious edges at input/output
		discard_spurious();

		this.resolutionHz = resolutionHz;
		// outgoing and incoming edges for junction 
		LinkedList<edge<tfnode,tonal>> outgoing;
		LinkedList<edge<tfnode,tonal>> incoming;

		// MinHeap for edge pairings, sorted by fitness
		PriorityQueue<fitness<edgepair>> scores =
			new PriorityQueue<fitness<edgepair>>();
		
		// Iterate on a copy of the incoming edge keys
		// We don't iterate on the keySet as it is linked to
		// to the hash table and the hash table is modified
		// during the iteration (which is not allowed).
		
		// Order keys such that those with the longest edges are handled first
		PriorityQueue<fitness<tfnode>> inKeys = new PriorityQueue<fitness<tfnode>>();

		for (tfnode node : in.keySet()) {
			double score= node_fitness(node);
			inKeys.add(new fitness<tfnode>(node, score));
		}
		fitness<tfnode> f = inKeys.poll();
		boolean multicopy;
		while (f != null) {
			tfnode node = f.object;
			incoming = in.get(node);
			outgoing = out.get(node);
			
			if (debug && incoming != null) {
				System.out.printf("evaluating fitness node %s in %d out %d ----------\n", 
						node.toString(), 
						in.get(node).size(), out.get(node).size());
			}

			// Collapsing nodes
			// multicopy,boolean
			// true - Collapsing nodes
			// false (default) -  No collapsing nodes
			multicopy = false;
			if (incoming != null && (incoming.size() >  1 && outgoing.size() == 1)) {
				edge<tfnode, tonal> out_edge = outgoing.getFirst();
				tfnode n = out_edge.to;
				if (in.get(n).size() == 1 && out.get(n).size() > 1)
					multicopy = true;
			}
			
			if (incoming != null && incoming.size() >= 1 && outgoing.size() >= 1) { 
				// Junction
				// Retrieve the incoming and outgoing edge lists
				scores.clear();		// empty out any previous scores
				
				// consider all possible pairs of edges
				for (edge<tfnode,tonal> out: outgoing) {
					for (edge<tfnode,tonal> in: incoming) {
						tonal out_edge = out.content;
						tonal in_edge = in.content;
						
						// Error calculation
						double fit_err_dphase = fit(in_edge, out_edge, disamb_thr_s, true);
						double fit_err_slp = fit(in_edge, out_edge, disamb_thr_s, false);
						
						
						if (debug) {
							System.out.printf("fitness: %s -> %s = %f\n", 
								in.content.toString(1,1), 
								out.content.toString(1,1), fit_err_slp);
						}
						
						scores.add(new fitness<edgepair>(
								new edgepair(in, out), 
								fit_err_slp,
								0//fit_err_dphase
						));
						
						// The fitness value of the to and from nodes
						// is likely to have improved.  Add them both
						double scoreFrom = node_fitness(in.from);
						double scoreTo = node_fitness(out.to);
						inKeys.add(new fitness<tfnode>(in.from, scoreFrom));
						inKeys.add(new fitness<tfnode>(out.to, scoreTo));
					}
				}
				
				// Select the best pair.
				// Both slope and phase derivative must be considered
				// as a fitness parameter while selecting the best pair.
				// For now we consider the slope.
				// TO DO: To consider both slope and phase derivative 
				fitness<edgepair> c;
				c = scores.poll();  // next candidate
				while (c != null) {
					if (debug)
						System.out.printf("Edge pair %s score [%f %f]: " ,
								c.object.toString(), c.score, c.score2);
					
					if (c.score < Double.POSITIVE_INFINITY && viable_pair(c.object)) {
						if (debug)
							System.out.printf("merge\n");

						// remove edge pair from the graph
						remove_edge(c.object.a);
						if (! multicopy) {
							// Not a collapsing node so we can remove the outgoing edge
							remove_edge(c.object.b);
						}
						
						// link together
						edge<tfnode, tonal> new_edge = 
							new edge<tfnode, tonal>(
									c.object.a.from, 
									c.object.b.to, 
									c.object.a.content.merge(
											c.object.b.content));
						c.object.a.to.fitError = c.score;
						add_edge(new_edge);
						// very verbose, we'll probably want to comment
						// this out or put in a verbosity flag once
						// we know it works.
						if (debug) {
							System.out.printf("Resulting graph:\n%s\n",
									this.toString());
						}
						
					}
					c = scores.poll();
				}
				
				if (multicopy) {
					// Collapsing node
					// Time to remove the outgoing edge as it is now the part of 
					// incoming edges.
					remove_edge(outgoing.getFirst());
				}
				
				// Remove stray edges associated with the node
				remove_stray_edges(incoming, outgoing);
				
				// What's left of the node?
				outgoing = out.get(node);
				incoming = in.get(node);
				if (incoming.size() == 1 && outgoing.size() == 1) {
					// only one left...  several choices
					// 1. merge although it didn't meet the criteria
					// 2. break into two tonals.
					// 3. examine the loner.  If it is short or not coherent,
					// delete the edge and the node.
					//
					// Need to think about which is the right choice
				} else if (incoming.size() == 0 && outgoing.size() > 0
						&& ! nodes_in.contains(node)) {
					// Add to the in list if there are no incoming edges
					// and it is not already on it
					nodes_in.add(node);
				} else if (incoming.size() > 0 && outgoing.size() == 0 
						&& ! nodes_out.contains(node)) {
					// similar for outgoing edges
					nodes_out.add(node);
				} else if (incoming.size() == 0 && outgoing.size() == 0) {
					// This junction has been completely removed
					// note that we do not remove it from the nodes_in
					// and nodes_out lists as the node may have been subsumed
					// into a larger edge.  We may need to think more about 
					// this.
					in.remove(node);
					out.remove(node);
				}
			}
			f = inKeys.poll();
		}
		
		// Remove spurious edges at input/output
		discard_spurious();
	}
	
	/*
	 * remove_stray_edges
	 * Remove short edges associated with the junction node 
	 * that can no longer be linked to other edges.
	 */
	private void remove_stray_edges(LinkedList<edge<tfnode,tonal>> incoming, 
			LinkedList<edge<tfnode,tonal>> outgoing) {

		// Iterate on a copy of the incoming edges and outgoing edges.
		// We don't iterate on the actual edges as they are 
		// modified during the iteration (which is not allowed).
		LinkedList<edge<tfnode,tonal>> list_edge = new LinkedList<edge<tfnode,tonal>>();
		// Stray edges of duration less then N s are removed
		double stray_edge_thr_s = 0.050;

		// Check if there are any stray edges in the outgoing list of edges.
		// Remove the stray edges that are found.
		if (outgoing.size() >= 1) {
			for (edge<tfnode,tonal> out_edge : outgoing)
				list_edge.add(out_edge); // copy of outgoing edges
					
			for (edge<tfnode,tonal> out_edge : list_edge) {
				tfnode n = out_edge.to;
				if ((in.get(n).size () == 1 && out.get(n).size() == 0) && 
						(out_edge.to.time - out_edge.from.time) < stray_edge_thr_s) {
						// edge small enough to be removed
						remove_edge(out_edge);
				}
			}
		}
		// Check if there are any stray edges in the incoming list of edges.
		// Remove the stray edges that are found.
		if (incoming.size() >= 1) {
			for (edge<tfnode,tonal> in_edge : incoming)
				list_edge.add(in_edge); // copy of incoming edges

			for (edge<tfnode,tonal> in_edge : list_edge) {
				tfnode n = in_edge.from;
				if ((in.get(n).size () == 0 && out.get(n).size() == 1) && 
						(in_edge.to.time - in_edge.from.time) < stray_edge_thr_s) {
					// edge small enough to be removed
					remove_edge(in_edge);
				}
			}
		}
	}
	
	/*
	 * node_fitness
	 * Given a node, determine how important it is based
	 * on the product of the durations of it's maximal
	 * input and output edges.
	 * 
	 * Note that duration is measure by the number of nodes
	 * on the tonal path as opposed to actual duration.
	 * 
	 * This is used to prioritize the merge measure
	 */
	private double node_fitness(tfnode node) {

		LinkedList<edge<tfnode,tonal>> outgoing;
		LinkedList<edge<tfnode,tonal>> incoming;
		
		int outmax = 1;  // never weight anything less than this value
		outgoing = out.get(node);
		if (outgoing != null) {
			for (edge<tfnode,tonal> e : outgoing) {
				if (e.content.size() > outmax)
					outmax = e.content.size();
			}
		}
		int inmax = 1;
		incoming = in.get(node);
		if (incoming != null) {
			for (edge<tfnode, tonal> e : incoming) {
				if (e.content.size() > inmax)
					inmax = e.content.size();
			}
		}
		return 1.0/ (inmax * outmax); 
	}

	private double fit(tonal in_edge, tonal out_edge, double disamb_thr_s,
			boolean fit_dphase) {
		
		double err_out;
		double err_in;
		
		// Skip N nodes of the tonal when considering polynomial
		// fit of first phase difference to frequency.
		// Reason being that the phase at the the junction node and
		// nearby nodes are influenced by the phase of each other due to closeness.
		// Phase of these nodes does not represent correct phase information.
		//
		// In case of:
		// incoming tonal skip last N nodes;
		// outgoing tonal skip first N nodes.
		int skip_n = 2;
		
		FitPoly in_fit = fit(in_edge, skip_n, fit_dphase, true);
		FitPoly out_fit = fit(out_edge, skip_n, fit_dphase, false);
		
		err_out = get_err(in_fit, out_edge, disamb_thr_s, skip_n, fit_dphase)
				  / out_edge.duration();
		err_in = get_err(out_fit, in_edge, -disamb_thr_s, skip_n, fit_dphase)
				  / in_edge.duration();
		return err_in + err_out;
	}
	
	private double get_err(FitPoly fit, tonal path, double how_far_s,
			int skip_n, boolean fit_dphase) {
		
		boolean incoming_edge;
		Iterator<tfnode> it;
		
		if (how_far_s >= 0) {
			it = path.iterator();  // forward direction
			incoming_edge = false;
		} else {
			it = path.descendingIterator();   // backward direction
			how_far_s = -how_far_s;
			incoming_edge = true;
		}
		
		double elapsed_s = 0; 
		tfnode node = it.next();  // prime loop
		double start_s = node.time;
		double error = 0.0;
		double cum_error = 0.0;
		
		if (fit_dphase) {
			int n = path.size();
			double freq = 0.0;
			double diff = 0.0;
			tfnode prev = null;
			int count = 0;
			
			if (n <= skip_n + 1) {
				// Tonal not having enough node to skip.
				// First difference of phase is calculated without 
				// skipping the nodes. 
				
				// iterate through list accumulating error until done
				while (it.hasNext() & elapsed_s < how_far_s) {
					prev = node;
					node =  it.next();
					elapsed_s = Math.abs(start_s - node.time);
					if (incoming_edge)
						freq = prev.freq;
					else
						freq = node.freq;
					
					// first phase difference
					if (Math.signum(node.phase) == Math.signum(prev.phase))
						diff = Math.abs(node.phase - prev.phase);
					else {
						if (node.phase < 0.0)
							diff = Math.abs(node.phase) + prev.phase;
						else
							diff = Math.abs(prev.phase) + node.phase;
					}
					error = fit.getSquaredErrorForPoint(freq, diff);
					cum_error += error;
					count++;
				}
				return cum_error / count;
			} else {
				while (skip_n != 0) {
					// skip N nodes
					node = it.next();
					skip_n--;
					start_s = node.time;
				}
				// iterate through list accumulating error until done
				while (it.hasNext() & elapsed_s < how_far_s) {
					// First difference of phase is calculated after
					// skipping the nodes.
					prev = node;
					node =  it.next();
					elapsed_s = Math.abs(start_s - node.time);
					if (incoming_edge)
						freq = prev.freq;
					else
						freq = node.freq;
					
					// first phase difference
					if (Math.signum(node.phase) == Math.signum(prev.phase))
						diff = Math.abs(node.phase - prev.phase);
					else {
						if (node.phase < 0.0)
							diff = Math.abs(node.phase) + prev.phase;
						else
							diff = Math.abs(prev.phase) + node.phase;
					}
					error = fit.getSquaredErrorForPoint(freq, diff);
					cum_error += error;
					count++;
				}
				return cum_error / count;
			}
		} else {
			error = fit.getSquaredErrorForPoint(node.time, node.freq);
			cum_error = error;
			int count = 1;
			// iterate through list accumulating error until done
			while (it.hasNext() & elapsed_s < how_far_s) {
				node = it.next();
				elapsed_s = Math.abs(start_s - node.time);
				error = fit.getSquaredErrorForPoint(node.time, node.freq);
				cum_error += error;
				count++;
			}
			return cum_error / count;
		}
	}
	
	private FitPoly fit(tonal path, int skip_n, boolean fit_dphase, boolean incoming_edge) {
		
		final double 	 fit_thresh = .7;

		int order = 1;
		// far enough back, fit the polynomial
		FitPoly fit = null;
		if (fit_dphase) {
			fit = new FitPolyOrig(order, path, skip_n, fit_dphase, incoming_edge);
		} else {
			fit = new FitPolyOrig(order, path, skip_n, fit_dphase, incoming_edge);
		}
		
		order = order + 1;
		// If the bit is bad, try the next order up.  
		// When the frequencies have a standard deviation
		// that is somewhere near our quantization noise or
		// if there are not enough points to get a good
		// higher order fit, we live with the fit we have.
		while (fit.getR2() < fit_thresh && fit.getStdDevOfResiduals() > 2 * resolutionHz && path.size() > order*3) {
//		while (fit.getAdjustedR2() < fit_thresh && path.size() > order*3) {
			// lousy fit, try again
//			order = order + 1;
			FitPoly newFit;
			
			if (fit_dphase) {
				newFit = new FitPolyOrig(order, path, skip_n, fit_dphase, incoming_edge);
			} else {
				newFit = new FitPolyOrig(order, path, skip_n, fit_dphase, incoming_edge);
			}
			
			if(newFit.getAdjustedR2() > fit.getAdjustedR2()){
				fit = newFit;
			}
			
			order = order + 1;
		}
		return fit;
	}

	private double fit_phase_vec (tonal in_edge, tonal out_edge, double disamb_thr_s) {
		double in_vec_str = vector_str(in_edge, -disamb_thr_s);
		double out_vec_str = vector_str(out_edge, disamb_thr_s);
		return Math.abs(in_vec_str - out_vec_str);
	}
	
	private double vector_str(tonal path, double how_far_s) {
	
		Iterator<tfnode> it;
		
		if (how_far_s >= 0) {
			it = path.iterator();  // forward direction
		} else {
			it = path.descendingIterator();   // backward direction
			how_far_s = -how_far_s;
		}

		// Skip N nodes of the tonal.
		// Reason being that the phase at the the junction node and
		// nearby nodes are influenced by the phase of each other due to closeness.
		// Phase of these nodes does not represent correct phase information.
		//
		// In case of:
		// incoming tonal skip last N nodes;
		// outgoing tonal skip first N nodes.
		int skip_n = 2;
		
		int n = path.size();
		double elapsed_s = 0.0;
		tfnode node = it.next();	
		double start_s = node.time;
		tfnode prev = null;
		
		double diff = 0.0;
		double S = 0; // sin value
		double C = 0; // cos value
		int count = 0;
		
		if (n <= skip_n + 1) {
			// Tonal not having enough node to skip.
			// First difference of phase is calculated without 
			// skipping the nodes.
			
			while (it.hasNext() & elapsed_s < how_far_s) {
				prev = node;
				node =  it.next();
				elapsed_s = Math.abs(start_s - node.time);
				// first phase difference
				if (Math.signum(node.phase) == Math.signum(prev.phase))
					diff = Math.abs(node.phase - prev.phase);
				else {
					if (node.phase < 0.0)
						diff = Math.abs(node.phase) + prev.phase;
					else
						diff = Math.abs(prev.phase) + node.phase;
				}
				S = S + Math.sin(diff);
				C = C + Math.cos(diff);
				count++;
			}
			return (Math.sqrt(S*S + C*C) / count); // Vector strength
		} else {
			while (skip_n != 0) {
				// skip N nodes
				node = it.next();
				skip_n--;
				start_s = node.time;
			}
			while (it.hasNext() & elapsed_s < how_far_s) {
				// First difference of phase is calculated after 
				// skipping the nodes.
				prev = node;
				node =  it.next();
				elapsed_s = Math.abs(start_s - node.time);
				// first phase difference
				if (Math.signum(node.phase) == Math.signum(prev.phase))
					diff = Math.abs(node.phase - prev.phase);
				else {
					if (node.phase < 0.0)
						diff = Math.abs(node.phase) + prev.phase;
					else
						diff = Math.abs(prev.phase) + node.phase;
				}
				S = S + Math.sin(diff);
				C = C + Math.cos(diff);
				count++;
			}
			return (Math.sqrt(S*S + C*C) / count); // Vector strength
		}
	}

	/*
	 * viable_pair
	 * Given a pair of edges, check and see if they still exist
	 * in the graph as they may have been incorporated into 
	 * other edges and no longer available.
	 * @param - pair of edges
	 */
	boolean viable_pair(edgepair pair) {
		boolean viable;  // Assume viable until we learn otherwise
		LinkedList<edge<tfnode, tonal>> list;
		
		list = in.get(pair.a.to);
		if (list == null)
			viable = false;  // node is gone
		else if (list.contains(pair.a)) {
			// okay for a edge, check b edge
			list = out.get(pair.b.from);
			if (list == null)
				viable = false;
			else 
				viable = list.contains(pair.b); 
		} else 
			viable = false;
		
		return viable;
	}
	
	/*
	 * discard_spurious
	 * Remove very short edges that are not preceded or followed by 
	 * anything
	 */
	public void discard_spurious() {
		final double min_start_s = .025;
		final double min_end_s = .025;
		
		edge<tfnode, tonal> e;
		LinkedList<edge<tfnode, tonal>> incoming, outgoing;

		tfnode n;
		LinkedList<tfnode> new_in = new LinkedList<tfnode>();
		LinkedList<tfnode> new_out = new LinkedList<tfnode>();

		// examine inputs
		Iterator<tfnode> nodeIt = nodes_in.iterator();
		while (nodeIt.hasNext()) {
			n = nodeIt.next();
			outgoing = out.get(n);  // outgoing edges from this node
			if (outgoing.size() == 1) {
				// only one way out
				e = outgoing.getFirst();
				if (e.content.get_duration() < min_start_s) {
					// See what is is coming in to the dest side of this edge
					incoming = get_edges(in, e.to);
					if (incoming.size() == 1) {
						// only edge in, this will become a new entry point
						new_in.add(e.to);
					}
					nodeIt.remove();   // remove from list of possible starts
					remove_edge(e);
				}
			}
		}
		nodes_in.addAll(new_in);


		// examine outputs
		nodeIt = nodes_out.iterator();
		while (nodeIt.hasNext()) {
			n = nodeIt.next();
			incoming = in.get(n);
			if (incoming.size() == 1) {
				e = incoming.getFirst();
				// only one way in
				if (e.content.get_duration() < min_end_s) {
					// See what is is leaving the to side of this edge
					outgoing = get_edges(out, e.from);
					if (outgoing.size() == 1) {
						// only edge out, this will become a new exit point
						new_out.add(e.to);
					}
					// Remove this node
					nodeIt.remove();  // remove from list of possible outputs
					remove_edge(e);   
				}
			}
		}
		nodes_out.addAll(new_out);
	}
	
	public boolean overlaps(double start_time, double end_time) {
		LinkedList<edge<tfnode, tonal>> sorted = topological_sort();
		for (edge<tfnode, tonal> edge : sorted) {
			if ( (edge.from.time > start_time && edge.from.time < end_time) ||
				 (edge.to.time > start_time && edge.to.time < end_time)	) {
				return true;
			}
		}
		return false;
	}
	
	@SuppressWarnings("unchecked")
	public LinkedList<edge<tfnode, tonal>> topological_sort() {
		/* Returns collection of edges in topological order */
		
		LinkedList<edge<tfnode, tonal>> sorted = 
			new LinkedList<edge<tfnode, tonal>>();
		
		// Create reference counts
		HashMap<tfnode, Integer> refcount = new HashMap<tfnode, Integer>();
		for (LinkedList<edge<tfnode, tonal>> tolist : in.values()) {
			for (edge<tfnode, tonal> e : tolist) {
				Integer count = refcount.get(e.to);
				if (count == null)
					refcount.put(e.to, 1);
				else
					refcount.put(e.to, count+1);
			}
		}
		
		// Create a copy of the input arcs. 
		HashMap<tfnode, LinkedList<edge<tfnode, tonal>>> inarcs = 
			new HashMap<tfnode, LinkedList<edge<tfnode, tonal>>>();
		for (tfnode key : in.keySet()) {
			inarcs.put(key,
					(LinkedList<edge<tfnode, tonal>>) in.get(key).clone());
		}

		// Queue of nodes to process
		LinkedList<tfnode> queue = (LinkedList<tfnode>) nodes_in.clone();
		
		while (queue.isEmpty() == false) {
			// process a node with no inputs
			tfnode node = queue.remove();
			
			// Output edges to subsequent nodes
			// Remove the arc from the input links for the destination.
			// If there are not more input links, add the destination
			// to the queue.
			LinkedList<edge<tfnode, tonal>> nodedests = out.get(node);
			for (edge<tfnode, tonal> e : nodedests) {
				sorted.add(e);	// Add edge to sorted edges

				// Remove edge from incoming arcs associated with 
				// edge termination point.
				LinkedList<edge<tfnode, tonal>> inputs = inarcs.get(e.to);

				// Find this edge in the list of incoming edges on the
				// destination node
				Iterator<edge<tfnode, tonal>> iter = inputs.iterator();
				boolean found = false;
				while (! found && iter.hasNext()) {
					found = e == iter.next();
					if (found)
						iter.remove();
				}
				if (! found) {
					// oh oh, should never be here!
					throw new GraphException("Corrupted graph:  " + 
							"Unable to find known edge to remove in edge list");
				}
				if (inputs.size() == 0) {
					// Removed last input, ready to process this node
					queue.add(e.to);
				}
			}
		}
		return sorted;
	}
	
	/*
	 * edge_count - Return number of edges
	 */
	public int edge_count() {
		int count = 0;
		for (tfnode key : in.keySet()) {
			count = count + in.get(key).size();
		}
		return count;
	}
	
	/*
	 * node_count - Return number of nodes
	 */
	public int node_count() {
		return in.size();
	}
	
	public void process_bridges(double ridge_thresh) {
		LinkedList<edge<tfnode, tonal>> outgoing;
		tfnode currentNode = null;
		
		boolean modified = false;
		
		for (tfnode inNode : in.keySet()) {
			outgoing = out.get(inNode);
			if (outgoing.size()==0)
				continue;
			else if (outgoing.size() > 1) {
				//System.out.println("Node has more than one outgoing edges: " + inNode);
				continue;
			}
			
			edge<tfnode,tonal> edge = outgoing.get(0);
			tonal t = edge.content;
				
			//System.out.println("Edge" + edge + "is " + t.getPercentRidgeSupported());
			if (t.getPercentRidgeSupported() < ridge_thresh) {
				//System.out.println("Edge" + edge + "is removed: " + t.getPercentRidgeSupported());
				remove_edge(edge);
			}
			// now find and evaluate bridges
			//HashSet<BridgeIndicies> bridgeIndicies = new HashSet<BridgeIndicies>();
			
//			int i = 0;
//			while(i < t.size()){
//				currentNode = t.get(i);
//				if (currentNode.ridge) {
//					i++;
//					continue;
//				}
//				
//				//First non-ridge node;
//				int bridgeStart = i;
//				int bridgeEnd = i;
//				i++;
//				if (i == t.size() ) {
//					// end of the list
//					bridgeEnd = i - 1;
//					
//				} else {
//					currentNode = t.get(i);
//					while(!currentNode.ridge) {
//						i++;
//						if (i<t.size()) {
//							currentNode = t.get(i);
//						} else {
//							break;
//						}
//					}
//					
//					// The bridge ended one index ago, either because we
//					// it a ridge node or because we went off of the tonal.
//					bridgeEnd = i - 1;
//				}
//				
//				//BridgeResult bridgeResult = evalute_bridge(t,bridgeStart,bridgeEnd);
//				//if(bridgeResult.modified) {
//					// do stuff.
//				//}
//			}
		}
	}
	
	public List<tfnode> getAllNodes() {
		ArrayList<tfnode> allnodes = new ArrayList<tfnode>();
		Set<tfnode> nodes = this.in.keySet();
		allnodes.addAll(nodes);
		
		nodes = this.out.keySet();
		for (Iterator<tfnode> iterator = nodes.iterator(); iterator.hasNext();) {
			tfnode tfnode = iterator.next();
			if (!allnodes.contains(tfnode)) {
				allnodes.add(tfnode);
			}
		}
		
		return allnodes;
	}
	
	public List<edge<tfnode,tonal>> getAllEdges() {
		return allEdges;
	}
	
	private class BridgeResult{
		boolean modified = false;
		edge<tfnode, tonal> leftEdge;
		edge<tfnode, tonal> rightEdge;
		int nextIndex;
	}
	
	
	
	private BridgeResult evalute_bridge(tonal tonal, int bridgeStart, int bridgeEnd) {
		System.out.println(
			String.format(
					"Bridge detected from %d to %d in tonal %s", bridgeStart, bridgeEnd, tonal.toString()));
		// FIXME Better structure for holding distance outside of node.
		int cutThresh = 5;
		// Forward scan.
		int distance = 0;
		if (bridgeStart == 0) {
			distance = Integer.MAX_VALUE;
		}
		
		int rightCutPoint = -1;
		int leftCutPoint = -1;
		
		for(int i = bridgeStart; i <= bridgeEnd; i++) {
			if (distance < Integer.MAX_VALUE) {
				distance++;
			}
			if (distance > cutThresh && leftCutPoint < 0) {
				leftCutPoint = i;
			}
			tonal.get(i).distFromRidge = distance;
		}
		
		
		
		// Backward scan
		distance = 0;
		if (bridgeEnd == tonal.size() - 1) {
			distance = Integer.MAX_VALUE;
		}
		
		for(int i = bridgeEnd; i >= bridgeStart; i--) {
			tfnode node = tonal.get(i);
			
			if (distance < Integer.MAX_VALUE) {
				distance++;
			}
			
			if (node.distFromRidge > distance) {
				node.distFromRidge = distance;
			}
			
			if (distance > cutThresh && rightCutPoint < 0) {
				rightCutPoint = i;
				break;
			}
			
		}
		
		return new BridgeResult();
	}
	
	
	
	/*
	 * toString
	 * Convert graph to a string representation
	 */
	public String toString() {
		StringBuilder sbld = new StringBuilder();
		Formatter str = new Formatter(sbld);
		
		// format graph inputs and outputs
		str.format("------------- begin graph ---------------------\n");
		str.format("In nodes: ");
		for (tfnode in : nodes_in) {
			str.format(" ");
			str.format(in.toString());
		}
		
		str.format("\nOut nodes: ");
		for (tfnode out : nodes_out) {
			str.format(" ");
			str.format(out.toString());
		}
		
		// format edges
		
		str.format("\nEdges\n");
		str.format(":::: arriving at ::::\n");
		for (tfnode from : in.keySet()) {
			for (edge<tfnode,tonal> e : in.get(from))
				str.format("%s\n", e.ContentToString());
		}
		str.format("\n:::: leaving from ::::\n");
		for (tfnode leaving : out.keySet()) {
			for (edge<tfnode,tonal> e : out.get(leaving))
				str.format("%s\n", e.ContentToString());
		}
		str.format("------------- end graph ---------------------\n");
		
		return str.toString();
	}

}