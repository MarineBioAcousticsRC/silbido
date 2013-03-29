package tonals;
import java.util.*;

//Sort tonal instances according to the time field
public class tonalSortByTime implements Comparator<tonal> {
	public int compare(tonal t1, tonal t2) {
		Double time1 = new Double(t1.getFirst().time);
		Double time2 = new Double(t2.getFirst().time);
		return time1.compareTo(time2);
	}
}