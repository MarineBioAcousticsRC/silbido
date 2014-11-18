package tonals;

import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.NavigableSet;
import java.util.PriorityQueue;
import java.util.Stack;
import java.util.Vector;


// This used to be a set itself, which it should not be
public class ActiveSet {
	
	/**
	 * Determines if debugging output and data collection is performed. 
	 */
	private static boolean DEBUGGING = false;
	
	public static void setDebugging(boolean deubgging) {
		DEBUGGING = deubgging;
	}
	
	/** 
	 * The set of nodes that belong to graphs that are of sufficient
	 * length to be considered likely to produce good tonals.
	 */
	private tfTreeSet activeSet;
	
	/**
	 * The set of nodes that belong to graphs that are too short to be
	 * likely to produce good detections.  All new individual nodes get
	 * placed here if they are not joined immediately.  They are then
	 * promoted to the active set when the graphs they are a part of
	 * are of sufficient length.
	 * 
	 * These peaks are second class citizens.  The active set is extended
	 * first, and orphans can not join to peaks that are already connected
	 * to other graphs.  This helps avoid joining spurs that develop shooting
	 * off of good graphs.
	 * 
	 * TODO: for orphans, don't let them bridge as far...
	 */
	private tfTreeSet orphans;
	
	private tfTreeSet ridgeFrontier; 
	
	// used to search peak list
	private final tfnode dummySearchNode;
	
	private final HashMap<tfnode,PartialGraph> partialGraphs;
	
	/**
	 * Graphs that are closed and that were of sufficient length to likely
	 * contain good detections.
	 */
	private final LinkedList<graph> resultGraphs;
	
	
	/**
	 * Graphs that were discarded when they were closed because they were to
	 * short.
	 */
	private final LinkedList<graph> discardedGraphs;
	
	
	// TODO: What does this do?
	private double resolutionHz;
	
	/**
	 * A monotonically increasing graph id used to uniquely identify a graph 
	 * within a particular graph generator.
	 */
	private long currentGraphId = 1; 
	
	/*
	 * ActiveSet
	 * TODO:  Write docs
	 */
	public ActiveSet() {
		dummySearchNode = new tfnode(0, 0, 0, 0, false);  // used to search peak list
		resultGraphs = new LinkedList<graph>();  // completed subgraphs
		discardedGraphs= new LinkedList<graph>();  // discarded subgraphs (debug)
		orphans = new tfTreeSet();
		activeSet = new tfTreeSet();
		ridgeFrontier = new tfTreeSet();
		this.partialGraphs = new HashMap<tfnode, PartialGraph>();
		System.out.println("Using new code");
	}
	
	public tfTreeSet getActiveSet() {
		return this.activeSet;
	}
	
	public tfTreeSet getOrphanSet() {
		return this.orphans;
	}
	
	public void setResolutionHz(double resolutionHz) {
		this.resolutionHz = resolutionHz;
	}
	
	public List<graph> getResultGraphs() {
		return this.resultGraphs;
	}
	
	public void prune(double time_s, double minlen_s, double maxgap_s) { 
		/* Prune the current active set.
		 * 
		 * Nodes are pruned when they have not been extended in maxgap_s.  
		 * When this occurs, nodes are discarded if they are not part of a 
		 * long enough (minlen_s) chain, or saved in the set of tonals. 
		 */
				
		if (DEBUGGING) {
			System.out.println("Pruning active_set");
		}
		prune_aux(time_s, minlen_s, maxgap_s, activeSet);
		if (DEBUGGING) {
			System.out.println("Pruning orphans");
		}
		prune_aux(time_s, minlen_s, maxgap_s, orphans);
	}
	
	private void prune_aux(double time_s, double minlen_s, double maxgap_s, Collection<tfnode> nodeset) {
		
		/* iterate over each item in the active set */
		Iterator<tfnode> iter = nodeset.iterator();
		while (iter.hasNext()) {
			tfnode node = iter.next();
			boolean retained = true;
			
			if (node.chained_forward()) {
				/* the node has been incorporated into a chain.  Remove it
				 * from the ActiveSet.
				 * 
				 * This may not be the right thing to do as it prevents
				 * the same node from being connected to another node at
				 * a later date.
				 * NEED TO THINK ABOUT THIS
				 */
				iter.remove();
				retained = false;
			} else if (time_s - node.time > maxgap_s) {
				iter.remove();  // long time no see, remove from active set
				retained = false;
			}
			
			if (!retained) {
				// Decrement the reference count of this set
				tfnode subgraph_id = node.find();
				PartialGraph graph = partialGraphs.get(subgraph_id);
				int nrefs = graph.getReferenceCount() - 1;
				graph.setReferenceCount(nrefs);

				if (nrefs == 0) {
					// We are removing the last reference to a subgraph
					// from the active set.
					double graphLengthTime = graph.getGraphLengthSeconds();
					PartialGraph partialGraph = partialGraphs.remove(subgraph_id);
					double cycleCountPerSecond = (double)partialGraph.getAvoidedCycleCount() / graphLengthTime;
					double candidateJoinsPerSecond = (double)partialGraph.getCandidateJoinCount() / graphLengthTime;
					
					//System.out.println("Graph closed  " + partialGraph.getCycleCount() + " cycles and " + cycleCountPerSecond + " per second");

					// Is the graph span long enough that there could
					// be a tonal in here?
					
					if (graphLengthTime > minlen_s) {
						if (true || (cycleCountPerSecond <= 1470 && candidateJoinsPerSecond <= 1700)) {
							//System.out.println("Graph kept with " + cycleCountPerSecond + " cycles / sec");
							// Construct explicit graph for further analysis.
							resultGraphs.addLast(constructGraph(node, partialGraph));
						} else {
							//System.out.println("Graph discarded with " + cycleCountPerSecond + " cycles / sec");
							discardedGraphs.addLast(constructGraph(node, partialGraph));
						}
					} else if (DEBUGGING && node.chained_backward()) {
						// If we are debugging capture this graph.
						//System.out.println("discarded graph that was to short.");
						discardedGraphs.addLast(constructGraph(node, partialGraph));
					}
				}
			}
		}
	}
	
	private graph constructGraph(tfnode node, PartialGraph pGraph) {
		return new graph(node, 
				getNextGraphId(), 
				pGraph.getJunctionCount(), 
				pGraph.getAvoidedCycleCount(), 
				pGraph.getCandidateJoinCount(),
				pGraph.getGraphLengthSeconds(),
				pGraph.getGraphHeightFreq());
	}
	
	/**
	 * Returns the next graph id to use when constructing a graph.
	 * @return The next graph id.
	 */
	private long getNextGraphId() {
		long id = this.currentGraphId;
		currentGraphId++;
		return id;
	}
	
	public void add_ridge(double[] times, double[] freqs, double[] dBs, double[] angles, double maxgap_Hz,
			double activeset_thr_s) {
		//System.out.println(String.format("Ridge with %d nodes being added at (%f, %f).", times.length, times[0], freqs[0]));
		
		tfnode firstNode = tfnode.create(times[0], freqs[0], dBs[0], angles[0], true);
		
		tfTreeSet set = new tfTreeSet();
		set.add(firstNode);
		
		extend_aux(set, maxgap_Hz, activeSet, true);
		extend_aux(set, maxgap_Hz, orphans, false);
		
		tfnode lastNode = firstNode;
		for (int i = 1; i < times.length; i++) {
			 tfnode curNode = tfnode.create(times[i], freqs[i], dBs[i], angles[i], true);
			 lastNode.chain_forward(curNode);
			 lastNode.union(curNode);
			 lastNode = curNode;
		}
		
		if (lastNode.time - lastNode.earliest_pred > activeset_thr_s) {
			activeSet.add(lastNode);
			//System.out.println("Last ridge node added to active set.");
		} else {
			orphans.add(lastNode);
			//System.out.println("Last ridge node added to orphan set.");
		}
		
		this.ridgeFrontier.add(firstNode);
	}
	
	public void extend(tfTreeSet peaks, double maxgap_Hz, double activeset_thr_s) {
		tfTreeSet newRidgeFronteier = new tfTreeSet();
		
		double time = peaks.first().time;
		for (tfnode ridgePeak : this.ridgeFrontier) {
			tfnode curNode = ridgePeak;
			while(curNode != null && curNode.time < time) {
				if (curNode.chained_forward()) {
					curNode = curNode.successors.get(0);
				} else {
					curNode = null;
				}
			}
			
			if (curNode != null) {
				newRidgeFronteier.add(curNode);
			}
		}
		
		this.ridgeFrontier = newRidgeFronteier;
		
		/* Given a set of peaks, extend the frontier.
		 * Nodes in the current active set may be joined to the
		 * new peaks in which case they will be removed from the
		 * current active set.
		 */
		if (DEBUGGING) {
			System.out.println("Extending active set");
		}
		
		// Attempt to join new peaks to existing structure
		extend_aux(peaks, maxgap_Hz, activeSet, true);
		if (this.ridgeFrontier.size() > 0) {
			extend_aux(this.ridgeFrontier, maxgap_Hz, activeSet, true);
		}

		// orphans are short segments and may be spurious.
		// We don't let them connect to established subgraphs
		// until they are long enough at which point they are
		// promoted to full class citizens in the active set.
		// When impulsive noise is present, it is very easy for these
		// to grow and as a consequence we can disable their use
		// in these regions
		if (DEBUGGING) {
			System.out.println("Extending orphans");
		}
		extend_aux(peaks, maxgap_Hz, orphans, false);
		
		// Determine where to put the new peaks
		for (tfnode p : peaks) {
			
			tfnode subgraph_id = p.find();  // find the subgraph.
			PartialGraph graph = partialGraphs.get(subgraph_id);
			
			if (graph == null) {
				partialGraphs.put(subgraph_id, new PartialGraph(subgraph_id));  // first one
			} else {
				graph.setReferenceCount(graph.getReferenceCount() + 1);
			}
			
			//System.out.printf("%s earliest %f s\n", p.toString(), p.earliest_pred);
			if (p.ridge) {
				continue;
			}
			
			if (p.time - p.earliest_pred > activeset_thr_s) {
				activeSet.add(p);
			} else {
				orphans.add(p);
			}
		}
	}

	private void extend_aux(tfTreeSet peaks, double maxgap_Hz,
			Collection<tfnode> open, boolean joinExisting) {
		
		if (peaks.size() < 1) {
			return;
		}
		
		// Candidates for extension
		PriorityQueue<fitness<edge<tfnode, tonal>>> candidates = 
			new PriorityQueue<fitness<edge<tfnode, tonal>>>();
		
		boolean inrange = false;
		
		// At each step, all peaks are in the same time slice.
		double current_time = peaks.get_time()[0];
		

		/* Iterate over existing frontier */
		for (tfnode activenode : open) {
			
			if (activenode.time >= current_time) {
				continue;
			}
			
			if (activenode.ridge) {
				//System.out.println("Ridge now active.");
			}
			
			/* Start searching from lowest possible peak */
			dummySearchNode.freq = activenode.freq - maxgap_Hz;
			NavigableSet<tfnode> search_peaks = peaks.tailSet(dummySearchNode, true);
			LinkedList<FitPoly> active_fits;
			tfnode peak;

			Iterator<tfnode> peak_iter = search_peaks.iterator();
			if (peak_iter.hasNext()) {
				peak = peak_iter.next();
				
				// prime the loop by checking if peak is close enough to 
				// the active node.  If it isn't then we know that none of 
				// the peaks will be in range.
				inrange = Math.abs(peak.freq - search_peaks.first().freq) < maxgap_Hz;

				if (inrange) {
					// Determine time x freq trajectories into activenode
					active_fits = getFitsForNode(activenode, 0.025);
				} else {
					active_fits = null;
				}
				
				while (inrange) {
					for (FitPoly fit : active_fits) {
						// fitness criteria
						// squared error distance from predicted next
						// frequency with ties broken by choosing the
						// closest node.
						double error = fit.getSquaredErrorForPoint(peak.time, peak.freq);
						fitness<edge<tfnode, tonal>> f = 
							new fitness<edge<tfnode, tonal>>(
									new edge<tfnode, tonal>(activenode, peak), 
									fit, error, peak.time - activenode.time);
						candidates.add(f);
						//candidates.add(new fitness(activenode, peak,
						//	fit.sq_error(peak.time, peak.freq)));
					}
					if (peak_iter.hasNext()) {
						peak = peak_iter.next();
						/* check if close enough in frequency space to connect */ 
						inrange = Math.abs(peak.freq - activenode.freq) < maxgap_Hz;
					} else
						inrange = false;  // no more
				}
			}
		}

		
		if (DEBUGGING) {
			System.out.printf("Extending to peaks:\n");
		}
		
		// for debugging
		int selectedN = 0;
		LinkedList<fitness<edge<tfnode, tonal>>> selected = 
			new LinkedList<fitness<edge<tfnode, tonal>>>();

		// now have big list of candidates sorted by priority
		// need to start connecting things according to the rules
		double max_err = maxgap_Hz * maxgap_Hz;
		boolean join = false;
		
		// can't use iterator - poll
		fitness<edge<tfnode, tonal>> c = candidates.poll();
		while (c != null) {
			if (DEBUGGING) {
				System.out.printf("%s: ", c.toString());
			}
			
			join = c.score < max_err;  // meets distance criterion?
			
			if (join) {
				if (c.object.to.chained_backward()) {
					// We are joining to something that is already joined.  The graphs will
					// be merged so we only need to increment the junction on one of the
					// graphs.
					PartialGraph fromGraph = partialGraphs.get(c.object.from.find());
					fromGraph.incrementCandidateJoin();
					
					// peak is already linked to something
					// see whether or not we want to extend this
					if (joinExisting) {
						// Don't allow the graph to join to itself
						// This will cause problems when two whistles
						// legitimately cross multiple times
						
						// TODO:  What might be more appropriate is to have
						// a common ancestor test within a given amount
						// of time.  It looks like there are efficient
						// algorithms for this when the graph is constant,
						// but not dynamic.  These graphs are small enough
						// where we probably could do a depth bound search
						// fairly quickly.  We would only need to do it
						// when a graph was jointing with itself.
						//
						
						// Don't permit a cycle to form
						join = !c.object.to.ismember(c.object.from);
						if (!join) {
							// We just avoided a cycle.  Increment the avoided cycle count.
							fromGraph.incrementAvoidedCycleCount();
						}
						
						if (join) {
							// Tonals that are very close to one another
							// frequently end up forming a lattice:
							//
							//  o----o--o--o--o--
							//        \/ \/ \/   
							//        /\ /\/ \
							//  o----o--o--o--
							//
							// which creates an exponential number of paths
							// to explore when creating fits.  We try to 
							// prevent this by making sure that when a
							// second node from the active set is joined
							// to a peak, it is predicted to cross the peak
							// indicating that it really is on a downward
							// or upward trajectory.
							double next_t = c.object.to.time + 
								(c.object.to.time - c.object.from.time);
							double freq_hat = c.polynomial.predict(next_t);
							// check if path from source to prediction
							// crosses the peak.  If so, permit, otherwise
							// reject.
							double crossing = 
								(c.object.to.freq - c.object.from.freq) *
								(freq_hat - c.object.to.freq);
							
							if (crossing <= 0) {
								join = false;
							} else {
								
							}
						}
					} else {
						join = false;
					}
				}
			}

			if (join) {
				if (DEBUGGING)
					System.out.printf("accept\n");
				if (!c.object.from.ridge && c.object.to.ridge) {
//					System.out.println(
//						String.format(
//							"Peak(%.3f, %.3f) -> Ridge(%.3f, %.3f)",
//							c.object.from.time, 
//							c.object.from.freq,
//							c.object.to.time, 
//							c.object.to.freq
//						));
//					if (c.object.from.chained_forward()) {
//						System.out.println("Interior ridge node joined");
//					}
				} else if (c.object.from.ridge && !c.object.to.ridge) {
//					System.out.println(
//						String.format(
//							"Ridge(%.3f, %.3f) -> Peak(%.3f, %.3f)",
//							c.object.from.time, 
//							c.object.from.freq,
//							c.object.to.time, 
//							c.object.to.freq
//						));
//					if (c.object.from.chained_forward()) {
//						System.out.println("Interior ridge node joined");
//					}
				} else if (c.object.from.ridge && c.object.to.ridge) {
//					System.out.println(
//						String.format(
//							"Ridge(%.3f, %.3f) -> Ridge(%.3f, %.3f)",
//							c.object.from.time, 
//							c.object.from.freq,
//							c.object.to.time, 
//							c.object.to.freq
//						));
//					if (c.object.from.chained_forward()) {
//						System.out.println("Interior ridge node joined");
//					}
				}
				
				
				
				// Look up the graph for the from node.
				tfnode from_root = c.object.from.find();
				PartialGraph fromGraph = partialGraphs.get(from_root);
				
				// The to node now becomes the last node in the partial graph.
				fromGraph.nodeAdded(c.object.to);
				
				// See if the to node was part of a graph.  If it was
				// remove it and get a reference to it so we can merge.
				tfnode to_root = c.object.to.find();
				PartialGraph toGraph = partialGraphs.remove(to_root);
				if (toGraph != null) {
					fromGraph.merge(toGraph);
				}
				
				// There are are two cases where we could be creating a new junction node,
				// where one would not have existed before.
				
				// Case 1:
				// If the from node is not-chained forward yet, then it is not presently a junction node.
				// If also the to node is chained backwards exactly once, then the to node is not a junction
				// node, but is about to become one.
				//
				// Case 2:
				// If the from node is chained forward exactly once and the to node is not already chained
				// backwards we will be creating a new junction node.
				//
				// In all other cases we are either not creating a junction node at all, or we are
				// attaching another edge to a node that is already a junction node.
				
				if ((!c.object.from.chained_forward() && c.object.to.chained_backwardN() == 1) ||
				    (c.object.from.chained_forwardN() == 1 && !c.object.to.chained_backward()) ) {
					// If either the from node was already chained forward or if the to node
					// was changed backwards then the new link we are about to create will 
					fromGraph.incrementJuncionCount();
				}
				
				c.object.from.chain_forward(c.object.to);  // add the link
				c.object.to.fitError = c.score;
				
				c.object.from.union(c.object.to); // merge subgraphs
				// for now just do one, but we should find some type
				// of threshold once we have a better handle on the
				// fitness function
				
//				if (c.object.to.ridge) {
//					tfnode lastNode = c.object.to;
//					while(true) {
//						if (lastNode.successors.size() == 1) {
//							tfnode nextNode = lastNode.successors.getFirst();
//							lastNode.union(nextNode);
//							lastNode = nextNode;
//						} else if (lastNode.successors.size() == 0) {
//							break;
//						} else {
//							System.err.println("##ERror");
//						}
//					}
//				}
//				
				selectedN = selectedN + 1;
				selected.add(c);
			} else if (DEBUGGING) {
				System.out.printf("reject: ");
				if (c.score >= max_err) {
					System.out.printf("score\n");
				} else if (joinExisting) {
					System.out.printf("direct-path\n");
				} else {
					System.out.printf("joined\n");
				}
			}
				
			c = candidates.poll();
		}
		if (selectedN > 0) {
			selected.clear();
		} else {
			selected.clear();  // nobody picked
		}
	}
	
	public tfTreeSet getMergedFrontier() {
		tfTreeSet merged = new tfTreeSet();
		merged.addAll(this.activeSet);
		merged.addAll(this.orphans);
		return merged;
	}
	
	public LinkedList<FitPoly> getFitsForNode(tfnode n, double back_s) {
		LinkedList<FitPoly> list = new LinkedList<FitPoly>();

		// TODO What is this hard coded number.
		final double 	 fit_thresh = .7;
		
		double start = n.time;
		
		// time & freq
		Vector<Double> t = new Vector<Double>();
		Vector<Double> f = new Vector<Double>();
		
		// Explore using stack as opposed to recursion
		Stack<Integer> indices = new Stack<Integer>();
		Stack<tfnode> nodes = new Stack<tfnode>();
		
		boolean done = false;
		int depth = 0;
		while (! done) {
			// add node to history
			t.add(n.time);
			f.add(n.freq);
			depth = depth + 1;
			if (start - n.time >= back_s || ! n.chained_backward()) {
//				int order = t.size() > 6?2:1;
				int order = 1;
				// far enough back, fit the polynomial
				FitPoly fit = FitPolyFactory.createFitPoly(order, t, f);

				if (DEBUGGING) {
					System.out.printf("%d order fit t=%s; f=%s;\n", order, t.toString(), f.toString());
					System.out.printf("p=%s;\n", fit.toString());
				}
				
				// If the bit is bad, try the next order up.  
				// When the frequencies have a standard deviation
				// that is somewhere near our quantization noise or
				// if there are not enough points to get a good
				// higher order fit, we live with the fit we have.
				while (fit.getAdjustedR2() < fit_thresh && fit.getStdDevOfResiduals() > 2 * resolutionHz && t.size() > order*3) {
					order++;
					FitPoly newFit = FitPolyFactory.createFitPoly(order, t, f);
					if(newFit.getAdjustedR2() > fit.getAdjustedR2()){
						fit = newFit;
					}
					
					if (DEBUGGING) {
						System.out.printf("Refit p=%s\n", fit.toString());
					}
				}
				list.add(fit);
				
				// we are all done with this one, backtrack if necessary
				if (! nodes.isEmpty()) {
					n = nodes.pop();  // next node to process
					// determine depth in graph at time of last branch
					// and reset the time and frequency vectors to 
					// that size.
					depth = indices.pop();
					t.setSize(depth);
					f.setSize(depth);
				} else
					done = true;  // !nada mas! (nothing more)
				
			} else {
				if (n.chained_backwardN() == 1) {
					// follow the only predecessor, nothing to note
					// on stack
					n = n.predecessors.getFirst();
				} else {
					// more than one predecessor, choices to make...
					Iterator<tfnode> pred = n.predecessors.iterator();
					tfnode next_node = pred.next();
					// put everything else on the stack
					while (pred.hasNext()) {
						nodes.push(pred.next());
						indices.push(depth);
					}
					n = next_node;
				}
			}
		}
		return list;
	}
}