package tonals;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.DataOutputStream;

public class TonalBinaryOutputStream {
	private FileOutputStream filestream;
	public DataOutputStream datastream;

	public TonalBinaryOutputStream(String filename) throws IOException {
		filestream = new FileOutputStream(filename);
		datastream = new DataOutputStream(filestream);
	}

	// Write out tfnodes time and freq. Single tonal is considered at a time.
	public void write(tonal t) {
		try {
			datastream.writeInt(t.size());
			for (tfnode node: t) {
				datastream.writeDouble(node.time);
				datastream.writeDouble(node.freq);
			}
		}catch (IOException e) {
			e.printStackTrace();
		}
	}

	public void close() {
		try {
			datastream.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
