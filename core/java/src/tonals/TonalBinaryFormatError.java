package tonals;
import java.lang.RuntimeException;

/*
 * Used to report cases when the user does not provide data
 * that meets the specified tonal file format.
 */
public class TonalBinaryFormatError extends RuntimeException {

	private static final long serialVersionUID = 1L;

	public TonalBinaryFormatError() {
		super();
	}
	
	public TonalBinaryFormatError(String message) {
		super(message);
	}
}
