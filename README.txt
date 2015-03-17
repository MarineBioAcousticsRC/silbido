 Silbido README
----------------


## Introduction ##

This package contains the Silbido Whislte / Tonal detector.  Silbido is an 
automated whistle extraction system for toothed whales and dolphins.


The software can be dowloaded from here:

   http://roch.sdsu.edu/Software.shtml



## Dependencies ##

    - Java 1.6 or later
    - MATLAB 2010a or later
    - Apache Ant 1.9 or later


## Building ##

Silbido uses Apache Ant as the build system.  Ant is a cross platform build
system. It can be found here: 
    
    http://ant.apache.org/

After ant is installed, there are three main build targets:


1. Distribution Build (default)

  The distribution build actually builds the distribution for a release. It
can be executed by simply:

    ant

 - Or -

    ant dist

The "dist" target is the default build, so simply running "ant" works.


2. Development Build

  The development build simply compiles the java files and places them in a
location that the init scripts look for them.  It can be run using:

    ant dev


3. Clean Up

  Finally to clean up a previous build and remove the build files you can
run:

    ant clean
