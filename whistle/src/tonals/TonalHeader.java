package tonals;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;

public class TonalHeader {

	// define header and version
	public static final String HEADER_STR = 
		new String("silbido!");  // magic string
	public static final short DET_VERSION = 2; 

	// for constructing feature bit-mask
	// features produced for every point
	public static final short TIME = 1;
	public static final short FREQ = 1 << 1;
	public static final short SNR = 1 << 2;
	public static final short PHASE = 1 << 3;
	// features produced once per call
	public static final short SCORE = 1 << 4;
	public static final short CONFIDENCE = 1 << 5;
	// default
	public static final short DEFAULT = TIME | FREQ;

	// length of header identifier string
	public static final int magicLen = HEADER_STR.length();

	String comment;
	short userVersion;
	short bitMask;
	int headerSize;
	short version;

	/*
	 * TonalHeader - Read a tonal header from an input stream
	 */
	public TonalHeader(DataInputStream dataInStream) throws IOException {

		// Read the magic string to see if right type of hdr
		byte[] magicBytes = new byte[magicLen];		
		dataInStream.read(magicBytes);
		String magicStr = new String(magicBytes);
		
		if (magicStr.equals(HEADER_STR)) {
			// found magic string, looks like a valid header

			version = dataInStream.readShort();
			bitMask = dataInStream.readShort();
			userVersion = dataInStream.readShort();
			headerSize = dataInStream.readInt();

			// Figure out how much of the header has already been read
			int headerUsed = 2 + 2 + 2 + 4 + magicLen; // Length read in up till now in bytes

			// Figure out how long the user comments must be
			int commentLen = headerSize - headerUsed;

			// Read the rest of the file header into userComment byte array
			if (commentLen > 0) {
				comment = dataInStream.readUTF();
			} else
				comment = new String();
		}
		else {
			// Not a current Silbido header.
			// Perhaps it can be read in the old headerless format.
			bitMask = DEFAULT;
			userVersion = -1;
		}
	}

	/*
	 * TonalHeader - Write a tonal header to an output stream
	 */
	public TonalHeader(DataOutputStream dataOutStream,
			short userVersion, String UserComment, short featBitmask) {

		version = DET_VERSION;
		bitMask = featBitmask;
		this.userVersion = userVersion;
		
		try {
			dataOutStream.writeBytes(HEADER_STR);  	// Magic identifier
			dataOutStream.writeShort(DET_VERSION); 	// Silbido format version						
			dataOutStream.writeShort(featBitmask);  // What are we storing						
			dataOutStream.writeShort(userVersion); 	// User version of file
		} catch (IOException e) {
			e.printStackTrace();
		} 	
		// Header is at least as long as where we are now + the
		// number of bytes to write the header length
		int header_length = dataOutStream.size() + 4;
		boolean hasComment = UserComment != null && UserComment.length() > 0;
		if (hasComment){
			// Add length for UTF comment (length + 2 bytes)
			header_length += UserComment.length() + 2;
		}
		headerSize = header_length;
		
		try {
			dataOutStream.writeInt(header_length);
			if (hasComment){
				dataOutStream.writeUTF(UserComment);
			}
		} catch (IOException e) {
			e.printStackTrace();
		} 		

	}

	/*
	 * Return any comment specified by the user
	 */
	public String getComment() {
		return comment;
	}
	
	/*
	 * Return a version specified by the user.
	 */
	public int getUserVersion() {
		return userVersion;
	}
	
	/*
	 * Return the version of the file format
	 */
	public int getFileFormatVersion() {
		return version;
	}
	
	/*
	 * Return the tonal descriptor mask
	 */
	public short getMask() {
		return bitMask;
	}
	
	/*
	 * Are scores available for each tonal?
	 */
	public boolean hasScore() {
		return (bitMask & SCORE) > 0;
	}
	
	/*
	 * Are confidences available for each tonal?
	 */
	public boolean hasConfidence() {
		return (bitMask & CONFIDENCE) > 0;
	}
	
	/*
	 * Is time available for each tonal?
	 */
	public boolean hasTime() {
		return (bitMask & TIME) > 0;
	}

	/*
	 * Is frequency available for each tonal?
	 */
	public boolean hasFreq() {
		return (bitMask & FREQ) > 0;
	}

	/*
	 * Is signal to noise ratio available for each tonal?
	 */
	public boolean hasSNR() {
		return (bitMask & SNR) > 0;
	}

	/*
	 * Is phase available for each tonal?
	 */
	public boolean hasPhase() {
		return (bitMask & PHASE) > 0;
	}

}




