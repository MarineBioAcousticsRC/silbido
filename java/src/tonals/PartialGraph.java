package tonals;

public class PartialGraph {

	private tfnode graphRoot;
	private int referenceCount;
	private int corssingCount;
	private int cycleCount;

	public PartialGraph(tfnode graphRoot) {
		this.graphRoot = graphRoot;
		this.referenceCount = 1;
		this.corssingCount = 0;
		this.cycleCount = 0;
	}

	public tfnode getGraphRoot() {
		return graphRoot;
	}

	public void setGraphRoot(tfnode graphRoot) {
		this.graphRoot = graphRoot;
	}

	public int getReferenceCount() {
		return referenceCount;
	}

	public void setReferenceCount(int referenceCount) {
		this.referenceCount = referenceCount;
	}

	public int getCorssingCount() {
		return corssingCount;
	}

	public void setCorssingCount(int corssingCount) {
		this.corssingCount = corssingCount;
	}

	public int getCycleCount() {
		return cycleCount;
	}

	public void setCycleCount(int cycleCount) {
		this.cycleCount = cycleCount;
	}

	public void merge(PartialGraph other) {
		this.referenceCount = this.referenceCount + other.referenceCount;
		this.corssingCount = this.corssingCount + other.corssingCount;
		this.cycleCount = this.cycleCount + other.cycleCount;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + corssingCount;
		result = prime * result + cycleCount;
		result = prime * result
				+ ((graphRoot == null) ? 0 : graphRoot.hashCode());
		result = prime * result + referenceCount;
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		PartialGraph other = (PartialGraph) obj;
		if (corssingCount != other.corssingCount)
			return false;
		if (cycleCount != other.cycleCount)
			return false;
		if (graphRoot == null) {
			if (other.graphRoot != null)
				return false;
		} else if (!graphRoot.equals(other.graphRoot))
			return false;
		if (referenceCount != other.referenceCount)
			return false;
		return true;
	}
	
	

}
