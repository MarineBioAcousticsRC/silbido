package tonals;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;

import org.joda.time.DateTime;  // www.joda.org time classes Java < v8
import org.joda.time.DateTimeZone;
import org.joda.time.format.ISODateTimeFormat;
import org.joda.time.format.DateTimeFormatter;

public class TonalHeader {

	// define header and version
	public static final String HEADER_STR = 
		new String("silbido!");  // magic string
	
	public static DateTimeZone UTC = DateTimeZone.UTC;
	
	/*
	 * VERSIONS
	 * 3:
	 * 	Added ridge, score, confidence
	 * 4:
	 * 	Added timestamp, species, call
	 */
	public static final short DET_VERSION = 4; 

	// feature bit-mask - describes what has been populated and allows
	// backward compatibility
	
	// features produced for every point
	public static final short TIME = 1;
	public static final short FREQ = 1 << 1;
	public static final short SNR = 1 << 2;
	public static final short PHASE = 1 << 3;
	
	public static final short RIDGE = 1 << 6;
	
	// general information about set
	public static final short TIMESTAMP = 1 << 7;  // base timestamp for detections
	public static final short USERCOMMENT = 1 << 8;  // user comment field
	
	// features produced once per call
	public static final short SCORE = 1 << 4;
	public static final short CONFIDENCE = 1 << 5;
	public static final short SPECIES = 1 << 9;
	public static final short CALL = 1 << 10;

	// default
	public static final short DEFAULT = TIME | FREQ;

	// length of header identifier string
	public static final int magicLen = HEADER_STR.length();

	String comment;
	DateTime timestamp;
	DateTimeFormatter timeFormatter;  
	
	short userVersion;
	short bitMask;
	int headerSize;
	short version;

	/*
	 * TonalHeader - Read a tonal header from an input stream
	 */
	public TonalHeader(DataInputStream dataInStream) throws IOException {

		// object to marshal DateTime objects to ISO 8601
		timeFormatter = ISODateTimeFormat.dateTime();
		
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

			// Figure out number of bytes remaining
			int remainingLen = headerSize - headerUsed;
			
			timestamp = null;
			if (remainingLen > 0) {
				// Versions < 4 that supported comments did not have a specific
				// field.  If none of the string flags are set, read a comment.
				if ((bitMask & (this.USERCOMMENT | this.TIMESTAMP)) > 0) {
					// format specifies included fields
					
					// Read user comment if applicable
					if ((bitMask & this.USERCOMMENT) > 0)
						comment = dataInStream.readUTF();						
					else 
						comment = new String();
					
					// Read base timestamp (UTC ISO8601) if applicable
					if ((bitMask & this.TIMESTAMP) > 0) {
						String iso8601 = dataInStream.readUTF();
						timestamp = new DateTime(iso8601, UTC);						
					}
				} else 
					// No header information for these fields, assume only a comment
					// for backwards compatibility
					comment = dataInStream.readUTF();  						
				}
		} else {
			// No Silbido header.
			// Perhaps it can be read in the old headerless format.
			bitMask = DEFAULT;
			userVersion = -1;
		}
	}

	/**
	 * TonalHeader - Write a tonal header to an output stream
	 * version 4 interface
	 * @param dataOutStream - stream where header will be written
	 * @param userVersion - Number representing user version
	 * @param UserComment - String
	 * @param timestamp - All detections are relative to this ISO8601 timestamp string
	 * @param featBitmask - features that will be written for each tonal
	 */
	public TonalHeader(DataOutputStream dataOutStream,
			short userVersion, String UserComment, String timestamp,
			short featBitmask) {

		initializeOut(dataOutStream, userVersion, UserComment, timestamp, featBitmask);
	}
	
	/**
	 * TonalHeader - Write a tonal header to an output stream
	 * version 3 interface, no support for timestamp
	 * @param dataOutStream - stream where header will be written
	 * @param userVersion - Number representing user version
	 * @param UserComment - String
	 * @param featBitmask - features that will be written for each tonal
	 */
	public TonalHeader(DataOutputStream dataOutStream,
			short userVersion, String userComment,
			short featBitmask) {
		initializeOut(dataOutStream, userVersion, userComment, new String(), featBitmask);
	}
	
	/**
	 * initializeOut - Called by output constructors (brings all signatures together)
	 * @param dataOutStream - stream where header will be written
	 * @param userVersion - Number representing user version
	 * @param UserComment - String
	 * @param start - Base time of detections, all detection are relative to this time in s
	 * 	      must be specified in ISO8601, assumed to be UTC (offsets permitted for local time
	 * 		  specifications, but times all stored in UTC
	 * @param featBitmask - features that will be written for each tonal
	 */
	private void initializeOut(DataOutputStream dataOutStream,
			short userVersion, String userComment, String start,
			short featBitmask) {

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
		
		// Check for strings that go in the header.  Set header flags, write
		// and adjust header length appropriately.  
		int lenbytes = 2;  // UTF strings require the length of the string + a short 
		
	
		boolean hasComment = userComment != null && userComment.length() > 0;
		if (hasComment)
			header_length += lenbytes + userComment.length();
		boolean hasTimestamp = start != null && start.length() > 0;
		
		// object to marshall DateTime objects to ISO 8601
		timeFormatter = ISODateTimeFormat.dateTime();

		String iso8601 = null;
		if (hasTimestamp) {
			// validate and put timestamp in standard format
			timestamp = new DateTime(start, UTC);
			iso8601 = timeFormatter.print(timestamp);
			header_length += lenbytes + iso8601.length();
		}
		
		
		headerSize = header_length;
		
		try {
			// Write the header size field now that we know it
			dataOutStream.writeInt(header_length);
			// Write out any string fields describing the detections
			if (hasComment)
				dataOutStream.writeUTF(userComment);
			if (hasTimestamp)
				dataOutStream.writeUTF(iso8601);
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
	 * Is time available for each tonal?
	 */
	public boolean hasRidge() {
		return (bitMask & RIDGE) > 0;
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
	
	/*
	 * Is there a species entry for each tonal (might be an empty string)
	 */
	public boolean hasSpecies() {
		return (bitMask & SPECIES) > 0;
	}
	
	/*
	 * Is there a call for each species (might be an empty string)
	 */
	public boolean hasCall() {
		return (bitMask & CALL) > 0;
	}
	

}




