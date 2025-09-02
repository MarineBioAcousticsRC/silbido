

public class TonalSearchTree {

    public IntervalSearchTree<Interval1D<tonal>> tree;

    TonalSearchTree() {
        tree = new IntervalSearchTree<Interval1D<tonal>>();
    }

    void add(tonal t) {
        double [] time = t.get_time();

        // Build an interval
        Interval1D<tonal> interval = new Interval1D<tonal>(time[0], time[time.length], t);

        // Retrieve the interval if it exists
        Interval1D<tonal> entry = tree.contains(interval);
        if (entry) {
            // Multiple tonals covering the same time, add to list
            entry.value.add(t);
        } else {
            tree.put(interval); // new tonal, add to tree
        }
    }

    /**
     * overlaps - Find tonals overlapping specified interval
     * @param interval
     * @return
     */
    LinkedList<tonal> overlaps(Interval1D<tonal> interval) {

        // Find overlapping intervals
        LinkedList<Interval1D<tonal>> overlapping = tree.searchAll(interval);

        // Merge all overlapping intervals into a singe linked list
        LinkedList<tonal> list = new LinkedList<tonal>;
        for (LinkedList<Interval1D<tonal> interval : overlapping) {
            for (LinkedList<tonal> t : interval) {
                list.add(t);  //  each tonal in the interval
            }
        }

        return list
    }

    /**
     * overlaps - Find tonals overlapping specified min/max time
     * @param min
     * @param max
     * @return
     */
    LinkedList<tonal> overlaps(dobule min, double max) {
        Interval1D<tonal> interval = new Interval1D<tonal>(min, max);
        return this.overlaps(interval)
    }


}