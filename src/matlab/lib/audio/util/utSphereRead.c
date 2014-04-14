#include <mex.h>
#include <matrix.h>
#include <stdio.h>

#include <sp/sphere.h>
#include <snr/spfchar1.h>
#include <snr/snr.h>
#include <snr/speech_det.h>
#include <usr/Endpoint.h>
#include <usr/SignalAnalysis.h>

#include <Frame.h>
#include <CreateEndpointed.h>
#include <CreateEndpointedFrameEnergy.h>

/* gateway function
 *
 * LHS Arguments:
 *	Data
 *	DataInfo
 * RHS Arguments:
 *	FileName
 *	N -	Endpointing method, corresponds to enumerated types
 *		in the endpoint library header Endpoint.h.
 *		Currently (no guarantee that it has not changed)
 *			NO_ENDPOINTING,
 *			KUBALA,
 *			MURPHY,
 *	Frame -	Indicates whether framing should be done
 *		[]    - no framing
 *		[adv len] - Frame advance and length in MS
 *
 * Read a Sphere file.
 * 
 *	[Samples, SampleCount, SampleRate, Channels, BytesPerSample] = ...
 *		utSphereRead('audio.sph', N);
 *
 * Requires the NIST Sphere library and a custom version of the NIST SPQA
 * library.
 *
 * This code is copyrighted 1998,1999 by Marie Roch.
 * e-mail:  marie-roch@uiowa.edu
 *
 * Permission is granted to use this code for non-commercial research
 * purposes.  Use of this code, or programs derived from this code for
 * commercial purposes without the consent of the author is strictly
 * prohibited. 
 */

/* Fields in information structure.
 * Enumerations and field name must be in the same order.
 */
typedef enum {
  /* Field name position indicators start with F_ */ 
  F_SampleCount,
  F_SampleRate,
  F_Channels,
  F_BytesPerSample,
  F_DCbias,
  F_Signal,
  F_Noise,
  F_SNR,
  F_FrameAdvanceN,
  F_FrameLengthN,
  F_FrameRate,
  F_FrameEnergy,		/* Conditional field, must be last */
} InfoPositionIndicators;

const char *InfoNames[] = {
  "SampleCount",
  "SampleRate",
  "Channels",
  "BytesPerSample",
  "DCbias",
  "Signal",
  "Noise",
  "SNR",
  "FrameAdvanceN",
  "FrameLengthN",
  "FrameRate",
  "FrameEnergy"
};

#define InfoFieldCount (sizeof(InfoNames) / sizeof(char *))
  
void
mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray 
	    *prhs[])
{
  /* positional parameters */
# define		InFileName 0		/* in */
# define		InEndpoint 1
# define		InFrame	   2

# define		OutSamples 0
# define		OutInfo	1

# define		MaxStringLength 512
  char			FileName[MaxStringLength];
  char			String[MaxStringLength];	
  int			i;
  int			FrameAdvanceMS, FrameLengthMS;
  SignalProps		SignalInfo, SignalTmp;
  Signal		Sig;

  int			EndpointVerbose = 0;
  int			OutputFree = 0;		/* allocated mem for output */
  int			Error = 0;
  int			FrameResults, OutputFieldCount;

  EndpointFn		EndpointMethod;

  SP_INTEGER		BytesPerSample,
			ChannelCount,
			SampleCount,
			SampleRate;

  int			OutSampleCount;
  EndpointInfo		EP;
  SP_FILE		*SphereFile;

  if (nrhs < 1 || nrhs > InFrame + 1)
    mexErrMsgTxt("Invalid argument count");
      
  if (mxGetString(prhs[InFileName], FileName, MaxStringLength)) {
    mexErrMsgTxt("Filename not a string or too long");
  } 

  /* Retrieve endpointng scheme or use default */
  EndpointMethod = (nrhs > InEndpoint) ? /* caller provided endpoint method? */
    ((EndpointFn) mxGetScalar(prhs[InEndpoint])) : NO_ENDPOINTING;

  /* Retrieve framing scheme or use default (no framing) */
  if (nrhs > InFrame && (! mxIsEmpty(prhs[InFrame]))) {
    /* caller specifed framing */
    if (mxGetM(prhs[InFrame]) * mxGetN(prhs[InFrame]) == 2) {
      FrameAdvanceMS = (int) *(mxGetPr(prhs[InFrame]));
      FrameLengthMS = (int) *(mxGetPr(prhs[InFrame]) + 1);
      FrameResults = 1;
    } else
      mexErrMsgTxt("Framing parameters must be vector [AdvMS LenMS]");
  } else {
    FrameAdvanceMS = DefaultAdvanceMS;
    FrameLengthMS = DefaultLengthMS;
    FrameResults = 0;
  }

  /* Determine how many output fileds there should be.  If caller did
   * not request framing, we don't report frame energy
   */
  OutputFieldCount = (FrameResults) ?
    InfoFieldCount : InfoFieldCount - 1;
  
  if (! (SphereFile = sp_open(FileName, "r"))) {
    sprintf(String, "Unable to open Sphere file <%s>.", InFileName);
    mexErrMsgTxt(String);
  }

  (void) sp_h_get_field(SphereFile, SAMPLE_COUNT_FIELD,
			T_INTEGER, (void **) &SampleCount);
  (void) sp_h_get_field(SphereFile, CHANNEL_COUNT_FIELD,
			T_INTEGER, (void **) &ChannelCount);
  (void) sp_h_get_field(SphereFile, SAMPLE_RATE_FIELD,
			T_INTEGER, (void **) &SampleRate);
  (void) sp_h_get_field(SphereFile, SAMPLE_N_BYTES_FIELD,
			T_INTEGER, (void **) &BytesPerSample);

  Sig.Props.SampleRate = SampleRate;
  Sig.Props.SampleCount = SampleCount;
  
  if (sp_set_data_mode(SphereFile, "SE-PCM-2:SBF-N")) {
    sp_close(SphereFile);
    mexErrMsgTxt("Invalid Sphere data mode");
  }

  /* Warning:  We're using the Sphere library's memory management..
   * If a signal causes termintation before this Mex file exits,
   * a memory leak may occur.  Fortunately, this is a small window.
   */
  if (! (Sig.Data = (SIGNAL *) sp_data_alloc(SphereFile, SampleCount)))
    mexErrMsgTxt("Unable to allocate space for sample");
  
  if (! sp_read_data((void *) Sig.Data, SampleCount, SphereFile)) {
    sp_data_free(SphereFile, Sig.Data);
    mexErrMsgTxt("Unable to read file after obtaining file handle");
  }

  
  switch (EndpointMethod) {

  case NO_ENDPOINTING:
    /* Estimate energy and fake a single segment so that we can
     * treat everything alike
     */
    Sig.Props.Advance.MS = FrameAdvanceMS;
    Sig.Props.Length.MS = FrameLengthMS;
    SignalComputeWindowSize(&Sig, 1);
    EP.SignalLevels = signal_levels(&Sig);
    EP.SegmentCount = 1;
    FrameStart(EP.SegmentFrames[0]) = 0;
    FrameEnd(EP.SegmentFrames[0]) =
      (Sig.Props.SampleCount - Sig.Props.Length.N) / Sig.Props.Advance.N;
    break;

  case KUBALA:
    /* Use default frame advance and length for endpoint detection
     * then convert frame parameters to user values
     */
    FrameDefault(&Sig.Props);	/* use default settings for endpointing */
    SignalComputeWindowSize(&Sig, 1);

    EP = endpoint(&Sig, EndpointMethod, EndpointVerbose);

    if (Sig.Props.Advance.MS != FrameAdvanceMS ||
	Sig.Props.Length.MS != FrameLengthMS) {
      /* frame rate different than that used for endpointing - convert */
      Signal	Tmp;

      Tmp = Sig;
      Tmp.Props.Advance.MS = FrameAdvanceMS;
      Tmp.Props.Length.MS = FrameLengthMS;
      SignalComputeWindowSize(&Tmp, 1);
      
      endpoint_reframe(&Sig, &EP, &(Tmp.Props));
    }
    
    break;
    
  default:
    Sig.Props.Advance.MS = FrameAdvanceMS;
    Sig.Props.Length.MS = FrameLengthMS;
    SignalComputeWindowSize(&Sig, 1);
    EP = endpoint(&Sig, EndpointMethod, EndpointVerbose);
    if (! EP.SegmentCount) {
      sp_data_free(SphereFile, Sig.Data);
      mexErrMsgTxt("Unable to endpoint data");
    }
    
  }
  
  strcpy(String, "Unable to allocate:  ");
  switch (nlhs - 1) {
    /* fall through switch */
  case OutInfo:
    plhs[OutInfo] = mxCreateStructMatrix(1, 1, OutputFieldCount, InfoNames);
    if (plhs[OutInfo]) {

      /* Allocate & populate scalars */
      i = 0;
      while (i < F_FrameEnergy) {
	mxArray	*Scalar;
	Scalar = mxCreateDoubleMatrix(1, 1, mxREAL);
	if (Scalar) {
	  mxSetFieldByNumber(plhs[OutInfo], 0, i, Scalar);
	} else {
	  Error = 1;
	  strcat(String, "SignalInfo scalars ");
	  i = F_FrameEnergy;
	}
	i++;
      }

      if (! Error) {
	mxArray	*FrameEnergy;
	
#	define ScalarFieldN(Field) \
		(*mxGetPr(mxGetFieldByNumber(plhs[1], 0, (Field))))

        ScalarFieldN(F_SampleCount) = endpoint_samplecount(&Sig, &EP);
	ScalarFieldN(F_SampleRate) = Sig.Props.SampleRate;
	ScalarFieldN(F_Channels) = ChannelCount;
	ScalarFieldN(F_BytesPerSample) = BytesPerSample;
	ScalarFieldN(F_DCbias) = Sig.Props.DCbias;
	ScalarFieldN(F_Signal) = EP.SignalLevels.Signal;
	ScalarFieldN(F_Noise) = EP.SignalLevels.Noise;
	ScalarFieldN(F_SNR)= EP.SignalLevels.SNR;
	ScalarFieldN(F_FrameAdvanceN) = Sig.Props.Advance.N;
	ScalarFieldN(F_FrameLengthN) = Sig.Props.Length.N;
	ScalarFieldN(F_FrameRate) =
	  (double) Sig.Props.SampleRate / (double) Sig.Props.Advance.N;

	/* If user requested that frames be returned, create
	 * and populate the frame energy vector
	 */
	if (FrameResults) {
	  if ((FrameEnergy = CreateEndpointedFrameEnergy(&Sig, &EP)))
	    mxSetFieldByNumber(plhs[1], 0, F_FrameEnergy, FrameEnergy);
	  else {
	    Error = 1;
	    strcat(String, "FrameEnergy array ");
	  }
	}
      }
    } else {
      Error = 1;
      strcat(String, "Info ");
    }

    /* fall into next case */
    
  case OutSamples:
    if (FrameResults)
      plhs[OutSamples] = Frame(&Sig, &EP);
    else
      plhs[OutSamples] = CreateEndpointed(&Sig, &EP);
  };
  
  /* free resources */
  sp_data_free(SphereFile, Sig.Data);
  sp_close(SphereFile);
  free (EP.SignalLevels.FrameEnergy);
  
  if (Error)
    mexErrMsgTxt(String);
}
