package tonals;

import java.io.Serializable;

// Edges in a graph of nodes of a generic type
public class edge<TNode extends Comparable<TNode>, 
				  TContent extends Comparable<TContent>> 
	implements Comparable<edge<TNode, TContent>>, Serializable 
{
	public TNode from;
	public TNode to;
	public TContent content;
	
	public edge(TNode from, TNode to) {
		this.from = from;
		this.to = to;
		this.content = null;
	}
	
	public edge(TNode from, TNode to, TContent content) {
		this.from = from;
		this.to = to;
		this.content = content;
	}
	
	public String toString() {
		return String.format("[%s->%s]", from.toString(), to.toString());
	}
	
	public String ContentToString() {
		return content.toString();
	}
	
	public int compareTo(edge<TNode, TContent> other) {
		
		int comparison = from.compareTo(other.from);
		if (comparison == 0)
			comparison = to.compareTo(other.to);
		if (comparison == 0) {
			if (content != null)
				comparison = content.compareTo(other.content);
			else if (other != null)
				comparison = -1;
		}
		return comparison;
	}
}
