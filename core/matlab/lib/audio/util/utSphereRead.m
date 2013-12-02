% [PCM, PCMInfo] = 
%	utSphereRead(FileName, EndpointMethod)
% 
% C implemented file for reading SPHERE files This function is linked to the
% Sphere file format utiltities (v. 2.5) and portions of the NIST Speech
% Quality Assurance (SPQA v2.3) package.
%
% It reads Sphere data from the requested filename.
% If Endpoint is present and non zero, the NIST/Kubala endpointer
%	will be used to endpoint the data.
%
% If present as an output argument PCMInfo is a structure containing
% the following fields:
%
%	SampleCount, SampleRate, BytesPerSample
%	Signal, Noise, SNR - global energy estimates (dB)
%	FrameAdvanceN, FrameLengthN - Number of samples advanced
%		between frames and the length of each frame
%	FrameEnergy - Array of frame energy estimates (dB)
%
% Note that the C implementation does not appear to be working when
% compiling with Visual Studio as a dynamic linked library.  Call
% stack is to problem is:
%
%	fob_fread in sp/spread.c
%		if ( fobp->fp != FPNULL ) {
%			n = fread( p, size, nitems, fobp->fp );
%			if ( n > 0 )
%				fobp->length += n * size;
%		} else { ...
%		When reading, only 234 items were returned when
%		376575 were requested.  
%	read_data() in sp/spread.c
%	sp_mc_read_data()
%	mexFunction()




