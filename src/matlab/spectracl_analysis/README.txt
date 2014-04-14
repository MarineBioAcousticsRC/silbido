To reproduce the results of the graph search algorithm (silbido) from:

M. A. Roch, T.S. Brandes, B. Patel, Y. Barkley, S. Baumann-Pickering,
M.S. Soldevilla (2011) Automated extraction of odontocete whistle
contours. J. Acous. Soc. Am., 130(4), 2212-2223.

(There may be minor differences between this version and the one we
used in the above publication, but the results should be very close.)

Retrieve the DCLMPPA 2011 development data and ground truth
	annotations from Moby Sound: www.mobysound.org
	Note that there were many files annotated after the completion
	of the work that was inlcuded in the above article, and this
	recipe does not test them.  

Add triton to your Matlab path 
Edit the variable corpus.rootdir in bhavesh_corpus.m to point to the
root directory of the audio and ground truth files that you
downloaded.

Run the following:

triton; close all
cd to_your_output_directory
batchdetect('.det', directory_with_audio_and_ground_truth)
results = scoreall('.det');
dtAnalyzeResults(results)

Remember that two of the bottlenose dolphin files are from the same
sighting.  To report results by species (or any other grouping), you
can run dtAnalyzeResults on a subset of the results structure which
contains one entry per file processed (results(i).file indicates the
filename).
