package tonals;

import java.io.Serializable;
import java.util.Formatter;

public class edgepair implements Comparable<edgepair>, Serializable {
	public edge<tfnode, tonal> a;
	public edge<tfnode, tonal> b;
	
	edgepair(edge<tfnode, tonal> a, edge<tfnode, tonal> b) {
		this.a = a;
		this.b = b;
	}
	
	public int compareTo(edgepair other) {
		int result = a.compareTo(other.a);
		if (result == 0)
			result = b.compareTo(other.b);
		return result;
	}
	
	public String toString() {
		StringBuilder sbld = new StringBuilder();
		Formatter str = new Formatter(sbld);
		str.format("e[%s->%s->%s]", a.from, a.to, b.to);
		return str.toString();
	}
	
}
