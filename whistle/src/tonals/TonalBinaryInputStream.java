package tonals;

import java.io.EOFException;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.DataInputStream;
import java.io.BufferedInputStream;
import java.util.Collections;
import java.util.LinkedList;
import java.util.Vector;
import java.lang.Double;

public class TonalBinaryInputStream {

	TonalHeader hdr;

	private FileInputStream filestream;
	private BufferedInputStream buffstream;
	public DataInputStream datastream;

	short fbit_mask = 0x0;	// initialize internal feature bit-mask
	public LinkedList<tonal> tonals;
	
	private Vector<Double> confidence;
	private Vector<Double> score;
	
	/*
	 * Return linked list of tonals
	 */
	public LinkedList<tonal> getTonals() {
		return tonals;
	}
	
	/* 
	 * Return array of confidences for read tonals
	 */
	public double[] getConfidences() {
		double[] conf = null;
		
		if (hdr.hasConfidence()) {
			int N = confidence.size();
			conf = new double[N];
			for (int idx=0; idx < N; idx++) {
				conf[idx] = confidence.get(idx).doubleValue();
			}
		} else {
			conf = null;
		}
		return conf;				
	}
	
	/*
	 * Return array of scores for read tonals
	 */
	public double[] getScores() {
		double[] scr = null;
		
		if (hdr.hasScore()) {
			int N = score.size();
			scr = new double[N];
			for (int idx=0; idx < N; idx++) {
				scr[idx] = score.get(idx).doubleValue();
			}
		}
		return scr;		
	}

	/*
	 * Return the header associated with the tonals
	 */
	public TonalHeader getHeader() {
		return hdr;
	}

	
	public  void tonalBinaryInputStream(String Filename) throws IOException
	{ 
		try{
			filestream = new FileInputStream(Filename);
			buffstream = new BufferedInputStream(filestream);  // mark support
			datastream = new DataInputStream(buffstream);
			
			// Remember this position until N more bytes are read
			// (after that, we can forget about it)
			datastream.mark(TonalHeader.magicLen + 1);  
			
			hdr = new TonalHeader(datastream);

			// Allocate confidence & score vectors if needed.
			if (hdr.hasConfidence()) {
				confidence = new Vector<Double>(100, 100);
			} else {
				confidence = null;				
			}
			if (hdr.hasScore()) {
				score = new Vector<Double>(100,100);				
			} else {
				score = null;
			}
			
			if (hdr.userVersion == -1){
				// No header was present, rewind file and default assumptions
				datastream.reset();
			}
			tonals = readTonalStream(hdr.bitMask);
			datastream.close();
			
		} catch(IOException e) {
			e.printStackTrace();
		}

	}


	/*
	 * Read in tonals
	 */
	private LinkedList<tonal> readTonalStream(short featBitMask) 
	throws IOException, EOFException
	{

		// Initialize linked list
		LinkedList<tonal> tonals = new LinkedList<tonal>();
		double time = 0.0, freq = 0.0, snr = 0.0, phase  = 0.0;
		boolean ridge = false;
		
		fbit_mask = featBitMask;
		// Read in time and freq from the file and create list of tonals
		try {
			while(true){
				
				// Read in metadata about this tonal if specified
				if (hdr.hasConfidence()) {
					confidence.add(datastream.readDouble());
				}
				if (hdr.hasScore()) {
					score.add(datastream.readDouble());
				}
				
				// Read tonal itself
				tonal t = null;
				double graphId = -1;
				
				if (hdr.version > 2) {
					graphId = datastream.readDouble();
				}
				int N = datastream.readInt();
				LinkedList<tfnode> tfnodes = new LinkedList<tfnode>();
				while (N > 0) {
					if ((fbit_mask & TonalHeader.TIME) != 0)
						time = datastream.readDouble();
					if ((fbit_mask & TonalHeader.FREQ) != 0)
						freq = datastream.readDouble();
					if ((fbit_mask & TonalHeader.SNR) != 0)
						snr = datastream.readDouble();
					if ((fbit_mask & TonalHeader.PHASE) != 0)
						phase = datastream.readDouble();
					if ((fbit_mask & TonalHeader.RIDGE) != 0)
						ridge = datastream.readBoolean();
					tfnodes.add(new tfnode(time, freq, snr, phase, ridge));
					N--;			
				}
				t = new tonal(tfnodes, graphId);
				tonals.add(t);
			}
			
		} catch (EOFException e) {
			// all done 
		} 

		Collections.sort(tonals, tonal.TimeOrder);	// sort by start time
		return tonals;
		
	}
}