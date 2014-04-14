package tonals;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;

public class TonalOutputStream {

	private FileOutputStream filestream;
	public ObjectOutputStream objstream;
		
	public TonalOutputStream(String filename) throws IOException {
		filestream = new FileOutputStream(filename);
		objstream = new ObjectOutputStream(filestream);
	}
	
	// Write out a single tonal
	public void write(tonal t) {
		try {
			objstream.writeObject(t);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	public void close() {
		try {
			objstream.close();
		} catch (IOException e) {  // shouldn't happen - flame and die
			e.printStackTrace();
		}
	}
}
