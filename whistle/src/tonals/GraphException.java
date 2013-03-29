package tonals;

public class GraphException extends RuntimeException {
	public GraphException(String string) {
		// I don't think we actually need this next line,
		// but we had errors when the constructor was
		// not declared which is a bit strange as the
		// string constructor for RuntimeException is public.
		super(string);
	}

	private static final long serialVersionUID = 1L;
}
