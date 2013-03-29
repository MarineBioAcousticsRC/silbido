# GNU make makefile
# This makefile uses GNU make specific conditionals.
#
# make arch=XXX
# where XXX is the architecture type as specified Matlab mex extensions
# examples:
#	mexsg64		64 bit SGI 
#	mexhp7		Helwett Packard
#	mexsol		Sun Solaris
#	dll		Microsoft win32
# These names are subject to change, consult your Matlab external
# interface guide for details.
#
# If you do not have GNU make on your system and do not want to
#	install it, simply remove the ifeq/else/endif directives
#	leaving the appropriate conditional code.
#
# Note - some system administrators install GNU make as gmake.

# Make sure we know what platform to build for.
ifndef arch
$(error ERROR - architecture symbol mandatory - i.e. "make arch=dll")
endif

# util library
LIBUTNAME=ut$(arch)
LIBUTFILE=lib$(LIBUTNAME).a
LIBUTDIR=lib
LIBUTFILEPATH=$(LIBUTDIR)/$(LIBUTFILE)
DEBUG=-g

ifeq ($(arch),dll)

# Windows
.SUFFIXES: .obj
CC=mex.bat

# HARDCODED - NIST speech libraries - move into audio structure eventually
NISTDIR=e:/usr/mroch/speech/nist

LIBLINKCMD=$(LIBFILEPATH)
NISTDLLLIB=$(NISTDIR)/lib/Windows_NT
LIBLINKCMD=$(LIBUTFILEPATH) $(NISTDLLLIB)/libendpoint.a $(NISTDLLLIB)/libsp.a $(NISTDLLLIB)/libsnr.lib $(NISTDLLLIB)/libutil.lib

else

# UNIX - hooray!
CC=mex

# NIST speech libraries
NISTDIR=$(HOME)/speech/nist

LIBLINKCMD=-L$(LIBUTDIR) -L$(NISTDIR)/lib/$(arch) -l$(LIBUTNAME) -lendpoint -lsp -lsnr -lutil

endif

.SUFFIXES: .$(arch)

CCFLAGS=-g $(DEBUG) -I$(NISTDIR)/include -I$(LIBUTDIR)

.c.$(arch) :
	$(CC) $(CCFLAGS) $< $(LIBLINKCMD)


all : utSphereRead.$(arch) utSharedLibMgr.$(arch)

utSphereRead.$(arch) : utSphereRead.c

utSharedLibMgr.$(arch) : utSharedLibMgr.c

clean :
	rm *.o
