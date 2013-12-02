% [Status, Message] = utSharedLibMgr(Action, Arguments)
% Utility for loading/unloading a shared library which can be
% accessed across Mex files.
%
% Only one library may currently be open at any time, but this could
% easily be extended to handle multiple libraries if needed.
%
% Valid actions:
%
%	'open', LibraryName
%	Opens the shared library.  The library will remain open until
%	a 'close' call is made.  
%
%	'close', LibraryName
%	Closes the open library.  LibraryName is not currently used
%	but should be provided to avoid breakage should this function
%	ever be expanded to handle multiple libraries.  The LibraryName
%	'all' is reserved.  
%
%	'status', LibraryName
%	Returns 1 if a library is loaded, 0 if the library is not currently
%       open.  If LibraryName is 'all' returns all open libraries (if
%	any) in Message and 1 means that 1 or more libraries are loaded.
%	
% Notes on shared libraries:
%
%	Creation --------------------
%	Shared libraries may be created using the GNU C compiler by:
%	gcc -fPIC -shared -o mysharedlib.so shared1.c ... sharedN.C
%
%	Usage --------------------
%	Load the library:
%		utSharedLibMgr('open', 'mysharedlib.so');
%
%	Invoke a Mex function that uses the library.
%	The Mex function should open the library with dlopen().
%	As it is already open, the open library is accessed, with
%	its data intact.  Use dlsym() to get function handles.
%
%	This can be done as many times as desired and provides
%	a good way to share data across Mex files without having
%	to pass the data back & forth to/from Matlab.
%
%	Each Mex file *must* close the shared library.  Make sure
%	that you close the library when an error occurs.  dlclose()
%
%	When done, close the shared library with:
%		utSharedLibMgr('close', 'mysharedlib.so');
%
% CAVEATS:  If the path to the shared library is not complete,
% the system loader will search the LD_LIBRARY_PATH environment
% pathvariable.
%
% This code is copyrighted 2003 by Marie Roch.
% e-mail:  marie.roch@ieee.org
%
% Permission is granted to use this code for non-commercial research
% purposes.  Use of this code, or programs derived from this code for
% commercial purposes without the consent of the author is strictly
% prohibited. 
