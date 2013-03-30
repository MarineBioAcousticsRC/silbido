package tonals;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.DataOutputStream;

public class TonalBinaryOutputStream {
	private FileOutputStream filestream;
	public DataOutputStream datastream;
	

	// Every file written will now have a header
	TonalHeader hdr;
	
	public TonalHeader getHeader() {
		return hdr;
	}

	public void setHeader(TonalHeader hdr) {
		this.hdr = hdr;
	}


	/**
	 * Construct an output stream where the user specifies
	 * what features will be saved
	 * @param - file to which we save
	 * @param - Detector version
	 * @param - User comment
	 * @param - Specification of attributes to be written.  Bitmask of 
	 *     feature attributes: TIME, FREQ, SNR, PHASE, e.g. TIME | FREQ
	 */
	public TonalBinaryOutputStream(String filename, short version, 
			String Comment, short featBitmask) 
	throws IOException {
		filestream = new FileOutputStream(filename);
		datastream = new DataOutputStream(filestream);
		
		// Write header
		this.hdr = new TonalHeader(datastream, version, 
				Comment, featBitmask);
	}


	/**
	 * Construct an output stream where default feature vectors are saved
	 * Features saved are the TonalHeader defaults which are
	 *  TIME and FREQ at the time of this writing.
	 * @param - File to which we save
	 * @param - Detector version
	 * @param - User comments  
	 */
	public TonalBinaryOutputStream(String filename, short version, String Comment) 
	throws IOException {
		filestream = new FileOutputStream(filename);
		datastream = new DataOutputStream(filestream);

		// Construct the header (all we know so far)
		hdr = new TonalHeader(datastream, version, Comment, 
				TonalHeader.DEFAULT);
	}


	/**
	 * Write to output stream
	 * Writes header info, then writes features based on feature bit mask.
	 * Features can include: TIME, FREQ, SNR, PHASE.
	 * @param - File to which we save
	 * @param - Detector version
	 * @param - User comments  Bitmask of 
	 *     feature attributes: TIME, FREQ, SNR, PHASE, e.g. TIME | FREQ
	 */


	// Write out tfnodes time and freq. Single tonal is considered at a time.
	public void write(tonal t) {
		try {
			datastream.writeInt(t.size());
			// Write out desired items for each time bin
			// Item order is important, do not change.
			for (tfnode node: t) {
				if ((hdr.bitMask & TonalHeader.TIME) != 0)
					datastream.writeDouble(node.time);
				if ((hdr.bitMask & TonalHeader.FREQ) != 0)
					datastream.writeDouble(node.freq);
				if ((hdr.bitMask & TonalHeader.SNR) != 0)
					datastream.writeDouble(node.snr);
				if ((hdr.bitMask & TonalHeader.PHASE) != 0)
					datastream.writeDouble(node.phase);
			}
		}catch (IOException e) {
			e.printStackTrace();
		}
	}
	//	All done
	public void close() {
		try {
			datastream.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
