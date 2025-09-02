
import java.util.LinkedList;

public class TonalList<T extends Comparable<T>> extends LinkedList<T> {
	/**
	 * Insert a tonal into the linked list sorted by start time.
	 */
/*	public int addOrderedByStart(T element) {
		int position = 0;
		ListIterator<T> itr = listIterator();
		while (itr.hasNext()) {
			T a_tonal = itr.next();
			if (a_tonal.compareTo(element) > 0) {
				// element starts after current position
				itr.previous();
				break;  // found it
			} else {
				position = position + 1;
			}
		}
		// Either we finished iterating or we found the correct position.
		itr.add(element);
		return position;
	}*/
}