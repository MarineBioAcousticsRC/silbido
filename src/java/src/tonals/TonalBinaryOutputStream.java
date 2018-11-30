package tonals;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.DataOutputStream;
import java.util.IllegalFormatException;

public class TonalBinaryOutputStream {
	private FileOutputStream filestream;
	public DataOutputStream datastream;
	

	// Every file written will now have a header
	TonalHeader hdr;
	
	// per tonal metadata
	private double confidence;
	private double score;
	private String species;
	private String call;
	
	final private String emptyString = new String("");
	
	public TonalHeader getHeader() {
		return hdr;
	}

	public void setHeader(TonalHeader hdr) {
		this.hdr = hdr;
	}


	/**
	 * toString - Given a string that may be null return the string or a
	 *   non-null empty string
	 * @param x
	 * @return String 
	 */
	private String toString(String x) {
		String result;
		if (x == null)
			result = emptyString;
		else
			result = x;
		return result;
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



	/*
	 * Write a tonal to the output stream
	 * @parm - tonal
	 */
	private void write_tonal(tonal t) {
		try {
			
			// Write out any required metadata about the tonal
			if ((hdr.bitMask & TonalHeader.SCORE) != 0)
				datastream.writeDouble(t.getScore());
			if ((hdr.bitMask & TonalHeader.CONFIDENCE) != 0)
				datastream.writeDouble(t.getConfidence());
			if ((hdr.bitMask & TonalHeader.SPECIES) != 0)
				datastream.writeUTF(toString(t.getSpecies()));
			if ((hdr.bitMask & TonalHeader.CALL) != 0)
				datastream.writeUTF(t.getCall());
				
			datastream.writeLong(t.getGraphId());
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
				if ((hdr.bitMask & TonalHeader.RIDGE) != 0)
					datastream.writeBoolean(node.ridge);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}	
	
	/*
	 * Write a tonal to the output stream
	 * Simple output that does not require a tonal structure.
	 * Easier for non silbido users
	 */
	private void write_tonal(double time[], double freq[]) {
		if (time.length != freq.length) {
			throw new TonalBinaryFormatError(
					"Time and freq lengths must match");
		}
		
		// Check for required additional data about the tonal path
		// or metadata about the tonal (the user did not provide these)
		short unexpected = TonalHeader.SNR | TonalHeader.PHASE | TonalHeader.RIDGE
				| TonalHeader.SCORE | TonalHeader.CONFIDENCE 
				| TonalHeader.SPECIES | TonalHeader.SPECIES;
		if ((hdr.bitMask & unexpected) > 0)
			throw new TonalBinaryFormatError(
			  "Additional information besides time and frquency was specifed, use tonal object version of write call");

		try {				
			// Write the number of nodes followed by the nodes
			datastream.writeInt(time.length);
			for (int idx=0; idx < time.length; idx++) {
				datastream.writeDouble(time[idx]);
				datastream.writeDouble(freq[idx]);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	/*
	 * Write out a scalar value.  Used for writing time or freq
	 */
	private void write_scalar(double scalar) {
		try {
			datastream.writeDouble(scalar);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	// Should confidence be present?
	private void checkConfidence(boolean expected) throws TonalBinaryFormatError {
		if (hdr.hasConfidence() && ! expected) {
			throw new TonalBinaryFormatError("Confidence not expected");
		}
		if (! hdr.hasConfidence() && expected) {
			throw new TonalBinaryFormatError("Confidence expected");
		}
	}

	private void checkScore(boolean expected) throws TonalBinaryFormatError {
		if (hdr.hasScore() && ! expected) {
			throw new TonalBinaryFormatError("Score not expected");
		}
		if (! hdr.hasScore() && expected) {
			throw new TonalBinaryFormatError("Score expected");
		}
	}

	/*
	 * Write out a tonal
	 * @parm - tonal structure
	 */
	public void write(tonal t) throws TonalBinaryFormatError {
		checkScore(false);
		checkConfidence(false);
		write_tonal(t);
	}
	
	/*
	 * Write out a tonal
	 * @param - list of times (s)
	 * @parm - list of frequencies (Hz)
	 */
	public void write(double time[], double freq[]) throws TonalBinaryFormatError {
		checkScore(false);
		checkConfidence(false);
		write_tonal(time, freq);
	}
	
	/*
	 * Write out a tonal with a confidence metric
	 * Include a confidence metric.
	 * @param - tonal
	 * @param - confidence
	 */
	public void write_c(tonal t, double confidence) throws TonalBinaryFormatError {
		checkScore(false);
		checkConfidence(true);
		write_scalar(confidence);
		write_tonal(t);
	}

	/*
	 * Write out a tonal with a confidence metric
	 * Include a confidence metric.
	 * @param - time
	 * @param - freq
	 * @param - confidence
	 */
	public void write_c(double time[], double freq[], double confidence) throws TonalBinaryFormatError {
		checkScore(false);
		checkConfidence(true);
		write_scalar(confidence);
		write_tonal(time, freq);
	}
	
	/*
	 * Write out a tonal with a score metric
	 * Include a score metric.
	 * @param - tonal
	 * @param - confidence
	 */
	public void write_s(tonal t, double score) throws TonalBinaryFormatError {
		checkScore(true);
		checkConfidence(false);
		write_scalar(score);
		write_tonal(t);
	}
	
	/*
	 * Write out a tonal specified by time and frequency arrays
	 * Include a score metric.
	 * @param - time (s) array
	 * @param - frequency (Hz) array
	 * @param - confidence
	 */
	public void write_s(double time[], double freq[], double score) throws TonalBinaryFormatError {
		checkScore(true);
		checkConfidence(false);
		write_scalar(score);
		write_tonal(time, freq);
	}


	/*
	 * Write out a tonal with a confidence metric
	 * Include confidence and score metrics.
	 * @param - tonal
	 * @param - confidence
	 * @param - score
	 */
	public void write_cs(tonal t, double confidence, double score) 
	throws TonalBinaryFormatError {
		checkScore(true);
		checkConfidence(true);
		write_scalar(confidence);
		write_scalar(score);
		write_tonal(t);
	}
	
	/*
	 * Write out a tonal specified by time and frequency arrays
	 * Include a confidence and score metric.
	 * @param - time (s) array
	 * @param - frequency (Hz) array
	 * @param - confidence
	 * @param - score
	 */
	public void write_cs(double time[], double freq[], double confidence, double score) 
	throws TonalBinaryFormatError {
		checkScore(true);
		checkConfidence(true);
		write_scalar(confidence);
		write_scalar(score);
		write_tonal(time, freq);
	}

	/*
	 * Close up shop, all done
	 */
	public void close() {
		try {
			datastream.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
