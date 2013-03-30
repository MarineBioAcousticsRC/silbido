package tonals;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;

public class TonalHeader {

	// define header and version
	public static final String HEADER_STR = new String("silbido!");
	public static final short DET_VERSION = 1; 

	// for constructing feature bit-mask
	public static final short TIME = 1;
	public static final short FREQ = 1 << 1;
	public static final short SNR = 1 << 2;
	public static final short PHASE = 1 << 3;
	public static final short DEFAULT = TIME | FREQ;


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
		int magicLen = HEADER_STR.length();
		byte[] magicStr = new byte[magicLen];		
		dataInStream.read(magicStr);
		
		if (new String(magicStr, "US-ASCII").equals(HEADER_STR)) {
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
			byte[] commentBytes = new byte[commentLen];;
			dataInStream.read(commentBytes);

			comment = new String(commentBytes, "utf-8");
		}
		else {
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
		if (UserComment != null){
			// Add length for unicode comment
			header_length += (2*UserComment.length());
		}
		headerSize = header_length;
		
		try {
			dataOutStream.writeInt(header_length);
			if (UserComment != null){
				dataOutStream.writeChars(UserComment);
			}
		} catch (IOException e) {
			e.printStackTrace();
		} 		

	}



}






