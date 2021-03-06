package tonals;

import java.io.EOFException;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.DataInputStream;
import java.io.BufferedInputStream;
import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.Vector;
import java.lang.Double;
import java.util.NoSuchElementException;

public class TonalBinaryInputStream {

	public TonalHeader hdr;

	public enum ReadMode {
		ITERATED,  // Read tonals one at a time
		LINKEDLIST, // Read all tonals
		UNDECIDED  // User has not yet decided
	};
	
	private ReadMode mode; 
	
	private FileInputStream filestream;
	private BufferedInputStream buffstream;
	public DataInputStream datastream;
	
	private final static String emptyString = new String("");

	short fbit_mask = 0x0;	// initialize internal feature bit-mask
	public LinkedList<tonal> tonals = null;
	
	
	private static class TonalIterator implements Iterator<tonal> {
		private TonalBinaryInputStream bis;
		
		// Current tonal (we always read one ahead)
		public tonal t;
;

		
		public boolean valid;  // Is there a currently valid tonal to be fetched?
		
		public long count = 0;	// Number of tonals read

		
		public TonalIterator(TonalBinaryInputStream bstream) {
			bis = bstream;
			valid = false;  // No valid tonal yet...
			readone(); // Try to read first tonal
		}
		
		public boolean hasNext() {
			return valid;
		}
		
		private void readone() {
			/* readone() - read one tonal element from the stream 
			 * Private methods that stores in instance variable t
			 */
			
			double confidence = 0.0;  // confidence
			double score = 0.0;  // score
			String call = emptyString;
			String species = emptyString;
			long graphId = -1;
			
			try {				
				count = count + 1;  // one more...
				
				double time = Float.NaN, freq = Float.NaN, 
						phase = Float.NaN ,  snr = Float.NaN;
				boolean ridge = false;
				

				// Read in metadata about this tonal if specified
				if (bis.hdr.hasConfidence()) {
					confidence = bis.datastream.readDouble();
				}
				if (bis.hdr.hasScore()) {
					score = bis.datastream.readDouble();
				}

				if (bis.hdr.hasSpecies())
					species = bis.datastream.readUTF();
				
				if (bis.hdr.hasCall())
					call = bis.datastream.readUTF();
					
				// Read tonal itself

				if (bis.hdr.version > 2) {  // information about the graph this came from
					graphId = bis.datastream.readLong();
				}
				
				// Read current tonal
				int N = bis.datastream.readInt();   // number of nodes
				LinkedList<tfnode> tfnodes = new LinkedList<tfnode>();
				while (N > 0) {
					if ((bis.hdr.bitMask & TonalHeader.TIME) != 0)
						time = bis.datastream.readDouble();
					if ((bis.hdr.bitMask & TonalHeader.FREQ) != 0)
						freq = bis.datastream.readDouble();
					if ((bis.hdr.bitMask & TonalHeader.SNR) != 0)
						snr = bis.datastream.readDouble();
					if ((bis.hdr.bitMask & TonalHeader.PHASE) != 0)
						phase = bis.datastream.readDouble();
					if ((bis.hdr.bitMask & TonalHeader.RIDGE) != 0)
						ridge = bis.datastream.readBoolean();
					tfnodes.add(new tfnode(time, freq, snr, phase, ridge));
					N--;		
				}
				// construct the tonal object
				t = new tonal(tfnodes, graphId);
				
				// set the metadata if needed
				// Read in metadata about this tonal if specified
				
				if (bis.hdr.hasConfidence())
					t.setConfidence(confidence);

				if (bis.hdr.hasScore())
					t.setScore(score);

				if (bis.hdr.hasSpecies())
					t.setSpecies(species);
				
				if (bis.hdr.hasCall())
					t.setCall(call);
				
				valid = true;
			} catch (EOFException e) {
			} catch (IOException e) {
			}
		}

		public tonal next() throws NoSuchElementException {
			/* tonal next() - next object in iterator */
			if (! valid) {
				// Last readone caused an IOException, report
				throw new NoSuchElementException("No more items");				
			} 

			tonal current = t;  // grab a copy of the current tonal before it is overwritten
			
			// Mark tonal as consumed and try to grab another one
			valid = false;
			readone();

			return current;
		}
		
		public tonal peek() throws NoSuchElementException {
			/* tonal peek()
			 * Return the next element to be iterated.
			 */
			if (! valid) {
				// Last readone caused an IOException, report
				throw new NoSuchElementException("No more items");				
			} else {
				return t;				
			}
		}
		
		public void remove() {
			/* remove() - Remove an element:  unsupported */
			throw new UnsupportedOperationException();
		}
	}
	
	/*
	 * Return linked list of tonals
	 */
	public LinkedList<tonal> getTonals() throws IOException {
		switch (mode) { 
		case UNDECIDED:
			tonals = new LinkedList<tonal>();
			// Read the tonals
			Iterator<tonal> iterator = this.iterator();
			while (iterator.hasNext()) {
				tonal t = iterator.next();  // side effect: build conf/score
				tonals.add(t);
			}
			// tidy up
			mode = ReadMode.LINKEDLIST;
			datastream.close();
			
			Collections.sort(tonals, tonal.TimeOrder);  // Sort by start time
			break;
		case ITERATED:
			throw new UnsupportedOperationException("Cannot getTonals() when iterating");
		case LINKEDLIST:
			// Already read, do nothing
			break;
		}

		return tonals;
	}

	public Iterator<tonal> iterator() {
		mode = ReadMode.ITERATED;
		return new TonalIterator(this);
	}

	/*
	 * Return the header associated with the tonals
	 */
	public TonalHeader getHeader() {
		return hdr;
	}
	
	public TonalBinaryInputStream(String Filename) throws IOException
	{ 
		try{
			filestream = new FileInputStream(Filename);
			buffstream = new BufferedInputStream(filestream);  // mark support
			datastream = new DataInputStream(buffstream);
			
			// Remember this position until N more bytes are read
			// (after that, we can forget about it)
			// We may need to seek back to the beginning if there's no header.
			datastream.mark(TonalHeader.magicLen + 1);  
			
			hdr = new TonalHeader(datastream);
			
			if (hdr.userVersion == -1){
				// No header was present, rewind file and use default assumptions
				datastream.reset();
			}
			mode = ReadMode.UNDECIDED;
			
		} catch(IOException e) {
			e.printStackTrace();
		}

	}
}
