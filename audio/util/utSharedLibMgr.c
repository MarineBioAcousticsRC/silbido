#include <mex.h>
#include <matrix.h>

#include <dlfcn.h>

#include <sys/types.h>
#include <unistd.h>

#include <string.h>

#define MAXSTRING	256
static char	LibraryName[MAXSTRING];

/* what type of action to take */
typedef enum {
  SHLIB_OPEN,
  SHLIB_CLOSE,
  SHLIB_STATUS
} SHLIB_ACTION;

typedef enum {
  SHLIB_ERROR = 0,
  SHLIB_OK = 1,
} SHLIB_RESULT;

#define soERRORCHECK(result, message) \
	(result) = ((error = dlerror()) == NULL) ? SHLIB_OK : SHLIB_ERROR; \
	if (error) \
		sprintf(message, "%s", error)

/*
 * utSharedLibMgr
 * Utility for loading/unloading a shared library which can be
 * accessed across Mex files.
 *
 * see utSharedLibMgr.m for calling patterns
 */
void
mexFunction(int nlhs, mxArray *plhs[],
	    int nrhs, const mxArray *prhs[])
{

  /* in */
  const int	InputAction = 0;
  const int	InputSharedLibName = 1;
  const int	InputArgCount = 2;

  /* out */
  const int	OutputStatus = 0;
  const int	OutputMessage = 1;
  const int	OutputArgCount = 2;

  /* locals */
  char		*error;
  char		LibraryArg[MAXSTRING];
  char		Message[MAXSTRING];
  SHLIB_ACTION	action;
  SHLIB_RESULT	status = SHLIB_OK;

  /* current open library */
  static void	*soLib = NULL;
  static char	soOpenLib[MAXSTRING];

  
  /* parse the arguments -------------------- */
  
  if (nrhs != InputArgCount) {
    mxErrMsgTxt("Bad arguments");
  }

  /* Determine action */
  if (mxIsChar(prhs[InputAction])) {

    char	ActionString[MAXSTRING];
    if (mxGetString(prhs[InputAction], ActionString, MAXSTRING))
      mxErrMsgTxt("String argument too long");

    if (! strcmp(ActionString, "open"))
      action = SHLIB_OPEN;
    else if (! strcmp(ActionString, "close"))
      action = SHLIB_CLOSE;
    else if (! strcmp(ActionString, "status"))
      action = SHLIB_STATUS;
    else
      mxErrMsgTxt("Bad action");

  } else
    mxErrMsg("Action must be a string");
  
  if (mxIsChar(prhs[InputSharedLibName])) {
    if (mxGetString(prhs[InputSharedLibName], LibraryArg, MAXSTRING))
      mxErrMsgTxt("LibraryName too long");
  } else
    mxErrMsg("LibraryName must be a string");


  /* Process -------------------- */

  sprintf(Message, "");	 /* Null message default */

  switch (action) {

  case SHLIB_OPEN:

    if (soLib != NULL) {
      /* library already open and we don't support multiple libraries yet */
      status = SHLIB_ERROR;
      sprintf(Message, "Library already open");
    } else {
      /* open a new library */
      soLib = dlopen(LibraryArg, RTLD_LAZY);
      soERRORCHECK(status, Message);

      if (status == SHLIB_OK) {

	sprintf(soOpenLib, LibraryArg);	/* save lib name */

	if (! mexIsLocked())	/* if not already locked, lock */
	  mexLock();
      }
      
    }
    break;
    
  case SHLIB_CLOSE:

    if (soLib) {
      /* library open */
      dlclose(soLib);

      soLib = NULL;
      /* mex file should always be locked, but better safe than sorry  */
      if (mexIsLocked())	
	mexUnlock();

      sprintf(Message, "%s has been closed", soOpenLib);
    } else {
      status = SHLIB_ERROR;
      sprintf(Message, "No open library.");
    }
    break;
    
  case SHLIB_STATUS:
    if (soLib) {
      /* library open, return name */
      status = SHLIB_OK;
      sprintf(Message, "%s", soOpenLib);
    } else {
      status = SHLIB_ERROR;
      sprintf(Message, "No open library.");
    }
    break;
      
  default:
    /* If we reach this, it is due to programmer error.  User
     * error should have already been caught.
     */
    status = SHLIB_ERROR;
    sprintf(Message, "mex file internal error");
  }

  plhs[OutputStatus] = mxCreateScalarDouble(status);
  plhs[OutputMessage] = mxCreateString(Message);
}
  
