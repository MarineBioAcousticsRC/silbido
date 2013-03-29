README.txt

Java classes for supporting cetacean tonal extraction
Authors:  Marie Roch & Bhavesh Patel


Use ----------------------------------------
Designed to be integrated with Matlab code.

Java class directories must be added to the Matlab path
before the they are usable.

e.g.:  javaaddpath('c:\usr\mroch\eclipse\whistle\bin')

Heap space ---------------------------------------
Should you need to increase the Java heap space,
use:

-Xmx256m

in the java.opts file (see debugging for how to find the java.opts file)
Remember that increasing Java heap space decreases Matlab's as they run
in the same process space.

Debugging ----------------------------------------

Eclipse must be configured as a remote debugger.  On Eclipse 3.4.1,
this is done by first opening the project that will be debugged and
then selecting debug configurations from the run menu.

Select Remote Java Applications from the sidebar and create a new
configuration using the project to be debugged.  Select a port or use
the default one.  I have been using port 7253.  Regardless of which
port you use, let's call it PORT_ID for now.  

For the next step, you need to create or edit the java.opts file.  If
you wish to do this for all users, you must have administrative
privileges.  

For all users:  Edit the java.opts file (which may not exist) by
typing:
  "edit(fullfile(matlabroot, 'bin', computer('arch'), 'java.opts'))"

For a single user:  Place the java.opts file in Matlab's startup
directory.  If you wish to change the directory where Matlab starts in
Windows, you can create a shortcut and edit the Start In property of
the shortcut.

Regardless of where you choose to have the java.opts file, add the
following line:

Prior to java 1.5 (type "version -java" in Matlab for your Java version)
use:
-Xdebug
-Xrunjdwp:transport=dt_socket,address=PORT_ID,server=y,suspend=n

In Java 1.5 and later, use:
-agentlib:jdwp=transport=dt_socket,address=PORT_ID,server=y,suspend=n
or in my case:
-agentlib:jdwp=transport=dt_socket,address=7253,server=y,suspend=n

where PORT_ID is the port you selected.  Depending upon your firewall
rules, you may have to unblock the port.  If you are running on
Windows XP, you will be asked when Matlab starts if you would like to
unblock the port.  

Restart Matlab so that it reads your new options.

To use the debugger, select the debug configuration that you just created
and click debug.

Changes to java file in eclipse ------------------------------

Once you make changes to java files and save it execute command "clear java" 
in Matlab to have the effect of the changes you made.

 Profiling ---------------------------------------------------
 

Install the Test & Performance Tools Platform (TPTP) package via eclipse updater
Download and install in a separate directory the Agent Controller

::: configuring the agent controller :::
When a program is to be launched by a process other than eclipse,
it must have an agent enabled in order to perform profiling.  A corresponding
agent controller is run separately which permits eclipse to talk to the
executing program. The AgentController expects to be able to open TCP connections
on ports 10002, 10003, 10005, 10006.  It appears that the old protocol uses 02 for 
client connections, 03 for secure client connections, and 05 for client ftp.
The new protocol uses 06 for everything.  My version of eclipse (ganymede) seems
to be using 10003.  

The agent controller is configured by first setting environment variables:

TPTP_AC_HOME=c:/apps/develop/AgentController
JAVA_PROFILER_HOME=c:/apps/develop/eclipse/plugins/org.eclipse.tptp.platform.jvmti.runtime_4.4.201.v200902180100/agent_files/win_ia32
PATH=%JAVA_PROFILER_HOME%;%TPTP_AC_HOME%\bin;c:\apps\develop\matlab\r2008b\sys\java\jre\win32\jre\bin

On Windows, Java uses the system path to look for libraries instead of UNIX load library
path, so the path has to have the Java profiler home directory on it.  In addition, it
needs to have the agent controller bin directory and the bin for the Java runtime.

On my system, there were two java virtual machines installed (common situation), one
for general use (e.g. browser plugins) and the other for Matlab.  It's not clear to me
if it makes a difference which one is on the system path when the agent controller is
configured.  In the example above, we played it safe and put Matlab's Java.

Once this is done, we can configure the server by executing SetConfig.bat
(SetConfig.sh on UNIX) from %TPTP_AC_HOME%\bin.

Test the server by starting ACServer and running SampleClient (which is in
the same directory).  

::: Testing with a Java program :::

Next, try running a sample program.  Here, we test a simple program that was compiled
on eclipse in package first, class boo.  We cd to the bin directory created by eclipse.
It contains:  first/boo.class.  We run it as follows:

java -agentlib:JPIBootLoader=JPIAgent:server=enabled;CGProf -classpath . first/boo

If all goes well, the program will execute.

::: Profiling java methods in Matlab :::

Profiling Matla code requires that the java.opts file (described in 
the debugging section of this document) be modified.  I do not think
that you can debug while you are profiling unless it is possible to 
run two different agent libraries.  Put the following line in java.opts

-agentlib:JPIBootLoader=JPIAgent:server=enabled;CGProf

being certain that it replaces any other agentlib declaration.

Earler virtual machines used a different interface for profiling.

To profile, create a new profile configuration and select the agent controller
to run with.  The defaults should be sufficient.


-----------------------------------------------------------------------

Finally got it to run on spinner with standalone java:

and in Matlab by modifying java.opts to have:
-agentlib:JPIBootLoader=JPIAgent:server=enabled;CGProf

Here was the path for the working version:
C:\Program Files\Windows Resource Kits\Tools\
c:\usr\mroch\bin
C:\apps\develop\perl\bin
c:\apps\develop\htk\htk-3.4\bin.win32
c:\apps\develop\python-2.5.1\
c:\apps\develop\tcl\bin
C:\WINDOWS\system32
C:\WINDOWS
C:\WINDOWS\system32\wbem
c:\apps\cygwin\bin
c:\program files\microsoft sql server\90\tools\binn\
c:\usr\mroch\bin-htk
C:\apps\cygwin\bin
C:\apps\develop\matlab\r2008b\bin
C:\apps\develop\matlab\r2008b\bin\win32
C:\apps\develop\matlab\r2007b\bin
C:\apps\develop\matlab\r2007b\bin\win32
C:\apps\develop\matlab\r2006a\bin\win32
C:\apps\develop\BerkeleyOracle-DB-XML\bin
c:\apps\develop\AgentController\bin
c:\apps\develop\matlab\r2008b\sys\java\jre\win32\jre\bin



---------------------------------------------------------------------
Acknowledgments:
Thanks to Dave Mellinger for sending us his tonal code form which we
took the idea of using a line fit (which we extended to a general
polynomial fit) and predicting the next entry.

The least squares polynomial fit code is from the textbook:

JavaTech: An Introduction to Scientific and Technical Computing with Java
By Clark S. Lindsey, Johnny S. Tolliver, and Thomas Lindblad
Cambridge University Press,  2005.

and relies on the NIST/Mathworks package availble at:  
http://math.nist.gov/javanumerics/jama/
(last accessed May 8, 2009).
