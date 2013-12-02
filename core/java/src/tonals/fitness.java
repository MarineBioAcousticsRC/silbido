package tonals;

public class fitness<T extends Comparable<T>> 
implements Comparable<fitness<T>> 
{
	public T object;
	double score;
	double score2;   // Secondary metric, tie break
	FitPoly polynomial;
	
	/*
	 * fitness
	 * Create a new fitness node which contains a metric or score
	 * of how fit two nodes are to join.
	 * @param source node
	 * @param destination node
	 * @param polynomial used to make prediction
	 * @param fitness metric
	 * @param secondary fitness metric used to break ties
	 */
	public fitness(T object, FitPoly polynomial, 
			double score, double score2) {
		this.object = object;
		this.polynomial = polynomial;
		this.score = score;
		this.score2 = score2;
		
	}
	
	/*
	 * fitness
	 * Create a new fitness node which contains a metric or score
	 * of how fit two nodes are to join.
	 * @param source node
	 * @param destination node
	 * @param fitness metric
	 * 
	 */
	public fitness(T object, double score) {
		this(object, null, score, 0.0);
	}
	
	public fitness(T object, double score, double auxscore) {
		this(object, null, score, auxscore);
	}
	
	public int compareTo(fitness<T> other) {
		int comparison = (int) Math.signum(score - other.score);
		if (comparison == 0)  // tied?
			comparison = (int) Math.signum(score2 - other.score2);
		if (comparison == 0) {
			// tie on both primary and secondary scores
			
			// we don't really care what it is, but let's keep
			// it clean for priority queues which do not like
			// duplicates in Java
			comparison = this.object.compareTo(other.object);
		}
		return comparison;
	}
	
	public String toString() {
		return String.format("fit(%s)=%f", object.toString(), score);
	}
}
