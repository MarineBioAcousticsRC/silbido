package tonals;

import java.io.EOFException;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.DataInputStream;
import java.io.BufferedInputStream;
import java.util.Collections;
import java.util.LinkedList;

public class TonalBinaryInputStream {

	TonalHeader hdr;

	private FileInputStream filestream;
	private BufferedInputStream buffstream;
	public DataInputStream datastream;

	short fbit_mask = 0x0;	// initialize internal feature bit-mask
	public LinkedList<tonal> tonals;
	
	public LinkedList<tonal> getTonals() {
		return tonals;
	}
	
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
			datastream.mark(10);  
			
			hdr = new TonalHeader(datastream);

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


	public LinkedList<tonal> readTonalStream(short featBitMask) 
	throws IOException, EOFException
	{

		// Initialize linked list
		LinkedList<tonal> tonals = new LinkedList<tonal>();
		double time = 0.0, freq = 0.0, snr = 0.0, phase  = 0.0;	
		fbit_mask = featBitMask;
		// Read in time and freq from the file and create list of tonals
		try {
			while(true){
				tonal t = null;
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
					tfnodes.add(new tfnode(time, freq, snr, phase));
					N--;			
				}
				t = new tonal(tfnodes);
				tonals.add(t);
			}
			
		} catch (EOFException e) {
			// all done 
		} 

		Collections.sort(tonals, tonal.TimeOrder);	// sort by start time
		return tonals;
		
	}




}