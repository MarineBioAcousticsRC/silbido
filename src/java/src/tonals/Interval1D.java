
/******************************************************************************
 *  Compilation:  javac Interval1D.java
 *  Execution:    java Interval1D
 *
 *  Interval data type with floating point coordinates.
 *  Modified from base code in:  Algorithms, 4th ed. Robert Sedgewick & Kevin Wayne,
 *  Addison-Wesley, Upper Saddle River, NJ, 2011.
 ******************************************************************************/

import java.util.LinkedList;

public class Interval1D<T> implements Comparable<Interval1D> {
    public double min;  // min endpoint
    public double max;  // max endpoint
    public LinkedList<T> data;  // data payload

    /**
     * Set the the interval times, min <= max
     * @param min - interval start
     * @param max - interval end
     */
    void commonInit(double min, double max) {
        if (min <= max) {
            this.min = min;
            this.max = max;
        } else throw new RuntimeException("Illegal interval");
    }

    // precondition: min <= max

    /**
     * Interval with data, min <= max
     * @param min - interval start
     * @param max - interval end
     * @param data - data payload
     */
    public Interval1D(double min, double max, T data) {
        commonInit(min, max);
        // Create data payload list and populate
        this.data = new LinkedList<T>();
        this.data.add(data);
    }

    // precondition: min <= max
    public Interval1D(double min, double max, LinkedList<T> list) {
        commonInit(min, max);
        this.data = (LinkedList<T>) list.clone();  // shallow copy of list
    }

    public Interval1D(double min, double max) {
        commonInit(min, max);
    }

    // does this interval intersect that one?
    public boolean intersects(Interval1D that) {
        if (that.max < this.min) return false;
        if (this.max < that.min) return false;
        return true;
    }

    // does this interval a intersect b?
    public boolean contains(double x) {
        return (min <= x) && (x <= max);
    }

    /*
     * Return 0 if exact match.
     * -1 if that is before this
     * 1 if that is after this
     */
    public int compareTo(Interval1D that) {
        if      (this.min < that.min) return -1;
        else if (this.min > that.min) return +1;
        else if (this.max < that.max) return -1;
        else if (this.max > that.max) return +1;
        else                          return  0;
    }

    public String toString() {
        return "[" + min + ", " + max + "]";
    }

    // test client
    public static void main(String[] args) {
        Interval1D<String> a = new Interval1D<String>(15, 20);
        Interval1D<String> b = new Interval1D<String>(25, 30);
        Interval1D<String> c = new Interval1D<String>(10, 40);
        Interval1D<String> d = new Interval1D<String>(40, 50);

        System.out.println("a = " + a);
        System.out.println("b = " + b);
        System.out.println("c = " + c);
        System.out.println("d = " + d);

        System.out.println("b intersects a = " + b.intersects(a));
        System.out.println("a intersects b = " + a.intersects(b));
        System.out.println("a intersects c = " + a.intersects(c));
        System.out.println("a intersects d = " + a.intersects(d));
        System.out.println("b intersects c = " + b.intersects(c));
        System.out.println("b intersects d = " + b.intersects(d));
        System.out.println("c intersects d = " + c.intersects(d));

    }

}