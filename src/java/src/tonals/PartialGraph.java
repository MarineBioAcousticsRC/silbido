package tonals;

public class PartialGraph {

	private tfnode graphRoot;
	
	private int referenceCount;
	
	private int candidateJoinCount;
	private int junctionCount;
	private int avoidedCycleCount;
	
	private double maxFreq;
	private double minFreq;
	
	private double minTime;
	private double maxTime;

	public PartialGraph(tfnode graphRoot) {
		this.graphRoot = graphRoot;
		this.referenceCount = 1;
		this.junctionCount = 0;
		this.avoidedCycleCount = 0;
		this.candidateJoinCount = 0;
		
		this.maxFreq = graphRoot.freq;
		this.minFreq = graphRoot.freq;
		
		this.minTime = graphRoot.time;
		this.maxTime = graphRoot.time;
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

	public int getCandidateJoinCount() {
		return candidateJoinCount;
	}

	public void setCandidateJoin(int junctionCount) {
		this.candidateJoinCount = junctionCount;
	}
	
	public void incrementCandidateJoin() {
		this.candidateJoinCount++;
	}
	
	public int getJunctionCount() {
		return junctionCount;
	}

	public void setJunctionCount(int junctionCount) {
		this.junctionCount = junctionCount;
	}
	
	public void incrementJuncionCount() {
		this.junctionCount++;
	}

	public int getAvoidedCycleCount() {
		return avoidedCycleCount;
	}

	public void setAvoidedCycleCount(int cycleCount) {
		this.avoidedCycleCount = cycleCount;
	}
	
	public void incrementAvoidedCycleCount() {
		this.avoidedCycleCount++;
	}
	
	public void merge(PartialGraph other) {
		this.referenceCount = this.referenceCount + other.referenceCount;
		this.junctionCount = this.junctionCount + other.junctionCount;
		this.avoidedCycleCount = this.avoidedCycleCount + other.avoidedCycleCount;
		this.candidateJoinCount = this.candidateJoinCount + other.candidateJoinCount;
		
		this.minFreq = Math.min(this.minFreq, other.minFreq);
		this.maxFreq = Math.max(this.maxFreq, other.maxFreq);
		
		this.minTime = Math.min(this.minTime, other.minTime);
		this.maxTime = Math.max(this.maxTime, other.maxTime);
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + junctionCount;
		result = prime * result + avoidedCycleCount;
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
		if (junctionCount != other.junctionCount)
			return false;
		if (avoidedCycleCount != other.avoidedCycleCount)
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

	public void nodeAdded(tfnode node) {
		this.minFreq = Math.min(this.minFreq, node.freq);
		this.maxFreq = Math.max(this.maxFreq, node.freq);
		
		this.minTime = Math.min(this.minTime, node.time);
		this.maxTime = Math.max(this.maxTime, node.time);
	}
	
	public double getGraphLengthSeconds() {
		return this.maxTime - this.minTime;
	}
	
	public double getGraphHeightFreq() {
		return this.maxFreq - this.minFreq;
	}
	
	public double getGraphArea() {
		return (this.maxTime - this.minTime) * (this.maxFreq - this.minFreq);
	}
}