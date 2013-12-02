package tonals;

import java.io.Serializable;

// Incoming and outgoing edges with fitness score 
public class LinkEdges implements Serializable {
	public edge<tfnode, tonal> in;
	public edge<tfnode, tonal> out;
	public double diff_dphase;
	public double diff_avg_slp;
	
	public LinkEdges (edge<tfnode, tonal> in, edge<tfnode, tonal> out,
			double diff_dphase, double diff_avg_slp) {
		this.in = in;
		this.out = out;
		this.diff_dphase = diff_dphase;
		this.diff_avg_slp = diff_avg_slp;
	}
		
	public String toString() {
		return String.format("Diff dphase:%.2f rad Diff Avg_Slp:%.2f In Tonal:%s \nOut Tonal:%s\n",
				diff_dphase, diff_avg_slp, in.toString(), out.toString());
	}
}