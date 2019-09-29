#!/usr/bin/env python

#                              R u n . p y
#
#  Summary:
#     Test framework for 2D array access tests.
#
#  Introduction:
#     This is a test program written as part of a study into how well different
#     languages handle accessing elements of 2D rectangular arrays - the sort of
#     thing that are common in astronomy and similar scientific disciplines.
#     This program runs all the various test programs written for the study
#     automatically, building any that need to be built - ie those written in
#     compiled languages like C or Fortran - and timing them as they run.
#
#  Invocation:
#     ./Run.py ntests nx ny
#
#     or, depending on how Python and/or Python3 have been set up:
#
#     python Run.py ntests nx ny          or
#     python3 Run.py ntests nx ny
#
#     where
#        ntests  is how many times the full test set is repeated - default 1.
#        nx      is the number of columns in the array tested - default 2000.
#        ny      is the number of rows in the array tested - default 10.
#
#     This assumes that all the code files for the various test programs are
#     in the default directory. It also assumes that the various compilers
#     and interpreters have been installed so that the various commands
#     such as 'c++', 'g++', 'julia' etc all work. (They have to work when
#     run in a sub-process without a shell, as the commands are run through
#     the Python subprocess module. This is more restrictive than it may look,
#     as it generally means that commands defined as aliases - eg if 'julia' has
#     been aliased to '<some directory>/julia' - these will not work. In general
#     the solution is to make sure that, in this case, <some directory> is in
#     the default path.)
#
#  Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
#
#  History:
#     28th Aug 2019. First properly commented version. KS.
#     14th Sep 2019. Added PCL and Rust tests, and two more Python tests.
#                    All tests now have a single baseline run with one
#                    repeat to try to allow for startup and checking
#                    overheads. KS.
#
#  Copyright (c) 2019 Knave and Varlet
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#  SOFTWARE.
#
#  This code should run under either python 2 or python 3, so long as
#  the python 2 version supports the "from __future__ import" used here.
#  It has been tested under 2.7 and 3.6.
#

from __future__ import (print_function,division,absolute_import)

import subprocess
import datetime
import sys
import numpy

# ------------------------------------------------------------------------------

#                      E x e c u t e  C o m m a n d
#
#  ExecuteCommand() is a utility that runs a single command, waiting for it
#  to cpmplete. It returns a tuple, (Status,Output,Errors) where Status is
#  None if the command completed OK, or an error string - which includes
#  the command itself - if it completed with bad status, Output is what was
#  written to standard output by the command, and Error is what was written
#  to standard error by the command. Command should be a single string or a
#  list of strings, but if it is a single string it will be split (using
#  spaces as delimiters) into a list, rather than being passed to a shell to
#  interpret.
#
#  This is packaged as a separate routine because it's actually tricky to
#  get right, particularly using the subprocess module. (The recent routine
#  subprocess.call() does most of this, but only dates from Python 3.5. Also
#  note that a lot of the things this might be used for, like extracting
#  archives using tar, can be done using ordinary python modules.)
#
#  This routine is based on the RunCommand() code from AdassChecks.py in the
#  package written to process ADASS conference papers, but this returns the
#  output and error streams from the subprocess as well as just the status.
#

def ExecuteCommand (Command) :

   Status = None
   
   #  We don't want to use a shell to interpret the command, since that
   #  has security implications (if Command is built up using outside input
   #  nasty stuff can be embedded in it), so we need to pass Popen() an
   #  argument list rather than a command. (Note: in Python 2 the test
   #  should really be for basestring rather than str, as this misses
   #  unicode strings, but basestring isn't defined in Python 3). This
   #  isn't really important if all the strings being pased to this routine
   #  are embedded in the calling code, but if this is extracted and used
   #  as a general purpose routine it might matter.
   
   if (isinstance(Command,str)) : CommandList = Command.split()
   else : CommandList = Command
   
   #  Run the command, reading what it writes to standard output and standard
   #  error through pipes. The utf-8 decode step is because in Python 3
   #  Proc.communicate() returns bytes in UTF-8 rather than str strings,
   #  whereas Python2 doesn't make that distinction.
   
   Output = ""
   Errors = ""
   Result = ""
   try :
      Proc = subprocess.Popen(CommandList,stdout=subprocess.PIPE, \
                                                   stderr=subprocess.PIPE)
      (Output,Errors) = Proc.communicate()
      Output = Output.decode('utf-8')
      Errors = Errors.decode('utf-8')
      Proc.stdout.close()
      Proc.stderr.close()
      Result = Proc.wait()
      if (Result != 0) :
         Status = "Error executing '" + str(Command) + "'"
   except KeyboardInterrupt :
   
      #  Normally, ctrl-C would only terminate the subprocess. Here we
      #  trap it and terminate the whole program, which is probably what
      #  was intended.
      
      sys.exit(0)
   except :
      Status = "Error executing '" + str(Command) + "'"

   return (Status,Output,Errors)

# ------------------------------------------------------------------------------

#                   B u i l d  A n d  T i m e  P r o g r a m
#
#  This routine handles the building and running of one of the various test
#  programs. This assumes that building the program requires at most two
#  steps, and running it only requires a single command with the three
#  parameters giving the size of the arrays to use (as Nx by Ny) and the
#  number of repeats. A Python script does not require any build step,
#  while a C++ program may require two compilation steps, one for the
#  subroutine that does most of the work and one to build the main program.
#  If no build staps are required, the build strings should be null strings.
#  This routine will build the program by executing the build commands, then
#  will run it, putting together a command line formed from the command
#  string and the parameters and timing the execution of that line. If a
#  non-null cleanup command is passed, it will then run that to remove any
#  intermediate files, such as the built object files and executable. It
#  returns the total time taken for the test in seconds, together with
#  a status code and any error output, in a (Status,Secs,Errors) tuple.
#  Normal output from the build and execution stages is ignored. The cleanup
#  command is always run, even if earlier commands fail, but its status
#  and errors are always ignored in this case.

def BuildAndTimeProgram (
      BuildCommand1,BuildCommand2,ExecCommand,Nrpt,Nx,Ny,CleanupCommand) :

   Status = None
   Secs = 0.0
   
   #  We need at least two repeats, or we can't subtract off the overheads
   #  associated with starting the test and checking the results.
   
   if (Nrpt < 2) : Nrpt = 2

   #  We run through the varius stages of the process, the build stage(s)
   #  and then the execution of the test program. If there is a failure, we
   #  stop there, and Errors and Status will be as returned by the failing
   #  stage.
   
   #  Run the two build commands, if these are needed.
   
   if (BuildCommand1 != "") :
      (Status,Output,Errors) = ExecuteCommand(BuildCommand1)
      if (Status == None) :
         if (BuildCommand2 != "") :
            (Status,Output,Errors) = ExecuteCommand(BuildCommand2)
   if (Status == None) :
   
      #  No problems with the build, if any. Run the command that runs the
      #  test program, forming the command to be executed from the supplied
      #  command and the three parameters, Nrpt,Nx,Ny. Get the time at start
      #  and end and compute the elapsed time.
      
      Command = "%s %d %d %d" % (ExecCommand,Nrpt,Nx,Ny)
      
      Start = datetime.datetime.now()
      (Status,Output,Errors) = ExecuteCommand(Command)
      End = datetime.datetime.now()
      Elapsed = End - Start
      Secs = Elapsed.total_seconds()

      #  One wrinkle. If Nrpt is very low, say less than 10, it suggests the
      #  code being tested is quite slow, and this means the time to setup and
      #  check the results may be a significant fraction of the measured time.
      #  In this case, do one run with Nrpt set to 1, and allow for the time
      #  this takes to adjust the measured value of Secs. In fact, we might
      #  as well do this for all cases - the faster PDL tests, for example,
      #  still have very slow checking code.

      Command = "%s %d %d %d" % (ExecCommand,1,Nx,Ny)
      Start = datetime.datetime.now()
      (Status,Output,Errors) = ExecuteCommand(Command)
      End = datetime.datetime.now()
      Elapsed = End - Start
      Secs = (Secs - Elapsed.total_seconds()) * float(Nrpt) / float(Nrpt - 1)

   #  If a cleanup command is supplied, we run it no matter what, but only
   #  report its errors if everything else has gone fine so far.

   if (CleanupCommand != "") :
      (CleanStatus,Output,CleanErrors) = ExecuteCommand(CleanupCommand)
      if (Status == None) :
         Status = CleanStatus
         Errors = CleanErrors

   return (Status,Secs,Errors)

# ------------------------------------------------------------------------------

#                        L i s t  V e r s i o n
#
#  This lists the version of a compiler or language, given a command string
#  that can be used to get the version number, eg "c++ --version" which works
#  for both clang and gcc. This is also passed the name of the compiler/
#  language, and puts out one line to the terminal with the version number.

def ListVersion (Lang,Command) :

   (Status,Output,Errors) = ExecuteCommand(Command)

   #  For every example we work with in this program, the version number will
   #  be in the first line of what is returned, but some put write this to
   #  standard output and some to standard error. We try to see what we've got.

   if (Status) :
      print ("Unable to get version for",Lang,":",Status);
   else :
      OutputLines = Output.split("\n")
      ErrorLines = Errors.split("\n")
      if (len(OutputLines) > 0) :
         if (OutputLines[0] != "") :
            print (Lang,":",OutputLines[0])
      if (len(ErrorLines) > 0) :
         if (ErrorLines[0] != "") :
            print (Lang,":",ErrorLines[0])

# ------------------------------------------------------------------------------

#                        T e s t  D e s c r i p t i o n s
#
#  Each test is specified by a list containing the following items:
#  o A description of the language and any particular coding technique used.
#  o A description of the compiler and any compilation options used.
#  o A command used to build the test executable, or a null string.
#  o Any second command needed to build the test executable, or a null string.
#  o The command (without parameters) used to run the test.
#  o The number of repetitions to run - chosen to run for at least some seconds.
#  o A command used to clean up after the test, or a null string.
#
#  Adding a new test is a simple as creating a new list that defines it, and
#  then adding its name to the list of tests held in FullTests.
#
#  Note: Neither of the descriptions should contain commas, as they are written
#  out using a CSV (comma separated variable) format, and having commas in the
#  items confuses things. Note that the number of repetitions must be more than
#  one.

RawCclang = [
   "C : raw",
   "clang",
   "c++ -c csub.cpp -o csub.o",
   "c++ -o cmain cmain.cpp csub.o",
   "./cmain",
   100000,
   "rm -f cmain csub.o"]

RawCclangO = [
   "C : raw",
   "clang -O",
   "c++ -c -O csub.cpp -o csub.o",
   "c++ -o cmain -O cmain.cpp csub.o",
   "./cmain",
   1000000,
   "rm -f cmain csub.o"]

RawCclangO1 = [
   "C : raw",
   "clang -O1",
   "c++ -c -O1 csub.cpp -o csub.o",
   "c++ -o cmain -O1 cmain.cpp csub.o",
   "./cmain",
   1000000,
   "rm -f cmain csub.o"]

RawCclangO2 = [
   "C : raw",
   "clang -O2",
   "c++ -c -O2 csub.cpp -o csub.o",
   "c++ -o cmain -O2 cmain.cpp csub.o",
   "./cmain",
   1000000,
   "rm -f cmain csub.o"]

RawCclangO3 = [
   "C : raw",
   "clang -O3",
   "c++ -c -O3 csub.cpp -o csub.o",
   "c++ -o cmain -O3 cmain.cpp csub.o",
   "./cmain",
   1000000,
   "rm -f cmain csub.o"]

RawCclangO3native = [
   "C : raw",
   "clang -O3 native",
   "c++ -c -O3 -march=native csub.cpp -o csub.o",
   "c++ -o cmain -O3 -march=native cmain.cpp csub.o",
   "./cmain",
   5000000,
   "rm -f cmain csub.o"]

RawCgcc = [
   "C : raw",
   "g++",
   "g++ -c csub.cpp -o csub.o",
   "g++ -o cmain cmain.cpp csub.o",
   "./cmain",
   100000,
   "rm -f cmain csub.o"]

RawCgccO = [
   "C : raw",
   "g++ -O",
   "g++ -c -O csub.cpp -o csub.o",
   "g++ -o cmain -O cmain.cpp csub.o",
   "./cmain",
   1000000,
   "rm -f cmain csub.o"]

RawCgccO1 = [
   "C : raw",
   "g++ -O1",
   "g++ -c -O1 csub.cpp -o csub.o",
   "g++ -o cmain -O1 cmain.cpp csub.o",
   "./cmain",
   1000000,
   "rm -f cmain csub.o"]

RawCgccO2 = [
   "C : raw",
   "g++ -O2",
   "g++ -c -O2 csub.cpp -o csub.o",
   "g++ -o cmain -O2 cmain.cpp csub.o",
   "./cmain",
   1000000,
   "rm -f cmain csub.o"]

RawCgccO3 = [
   "C : raw",
   "g++ -O3",
   "g++ -c -O3 csub.cpp -o csub.o",
   "g++ -o cmain -O3 cmain.cpp csub.o",
   "./cmain",
   1000000,
   "rm -f cmain csub.o"]

RawCgccO3native = [
   "C : raw",
   "g++ -O3 native",
   "g++ -c -O3 -march=native csub.cpp -o csub.o",
   "g++ -o cmain -O3 -march=native cmain.cpp csub.o",
   "./cmain",
   5000000,
   "rm -f cmain csub.o"]

BoostCclang = [
   "C++ : Boost",
   "clang",
   "c++ -c cbsub.cpp -o cbsub.o",
   "c++ -o cbmain cbmain.cpp cbsub.o",
   "./cbmain",
   5000,
   "rm -f cbmain cbsub.o"]

BoostCclangO = [
   "C++ : Boost",
   "clang -O",
   "c++ -c -O cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCclangO1 = [
   "C++ : Boost",
   "clang -O1",
   "c++ -c -O1 cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O1 cbmain.cpp cbsub.o",
   "./cbmain",
   5000,
   "rm -f cbmain cbsub.o"]

BoostCclangO2 = [
   "C++ : Boost",
   "clang -O2",
   "c++ -c -O2 cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O2 cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCclangO3 = [
   "C++ : Boost",
   "clang -O3",
   "c++ -c -O3 cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O3 cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCclangO3native = [
   "C++ : Boost",
   "clang -O3 native",
   "c++ -c -O3 -march=native cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O3 -march=native cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCgcc = [
   "C++ : Boost",
   "g++",
   "g++ -c cbsub.cpp -o cbsub.o",
   "g++ -o cbmain cbmain.cpp cbsub.o",
   "./cbmain",
   5000,
   "rm -f cbmain cbsub.o"]

BoostCgccO = [
   "C++ : Boost",
   "g++ -O",
   "g++ -c -O cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCgccO1 = [
   "C++ : Boost",
   "g++ -O1",
   "g++ -c -O1 cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O1 cbmain.cpp cbsub.o",
   "./cbmain",
   3000,
   "rm -f cbmain cbsub.o"]

BoostCgccO2 = [
   "C++ : Boost",
   "g++ -O2",
   "g++ -c -O2 cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O2 cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCgccO3 = [
   "C++ : Boost",
   "g++ -O3",
   "g++ -c -O3 cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O3 cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCgccO3native = [
   "C++ : Boost",
   "g++ -O3 native",
   "g++ -c -O3 -march=native cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O3 -march=native cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCclangNoAssert = [
   "C++ : Boost no assert",
   "clang",
   "c++ -c -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   5000,
   "rm -f cbmain cbsub.o"]

BoostCclangONoAssert = [
   "C++ : Boost no assert",
   "clang -O",
   "c++ -c -O -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCclangO1NoAssert = [
   "C++ : Boost no assert",
   "clang -O1",
   "c++ -c -O1 -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O1 -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   3000,
   "rm -f cbmain cbsub.o"]

BoostCclangO2NoAssert = [
   "C++ : Boost no assert",
   "clang -O2",
   "c++ -c -O2 -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O2 -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCclangO3NoAssert = [
   "C++ : Boost no assert",
   "clang -O3",
   "c++ -c -O3 -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O3 -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCclangO3nativeNoAssert = [
   "C++ : Boost no assert",
   "clang -O3 native",
   "c++ -c -O3 -march=native -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "c++ -o cbmain -O3 -march=native -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCgccNoAssert = [
   "C++ : Boost no assert",
   "g++",
   "g++ -c -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   5000,
   "rm -f cbmain cbsub.o"]

BoostCgccONoAssert = [
   "C++ : Boost no assert",
   "g++ -O",
   "g++ -c -O -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCgccO1NoAssert = [
   "C++ : Boost no assert",
   "g++ -O1",
   "g++ -c -O1 -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O1 -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCgccO2NoAssert = [
   "C++ : Boost no assert",
   "g++ -O2",
   "g++ -c -O2 -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O2 -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCgccO3NoAssert = [
   "C++ : Boost no assert",
   "g++ -O3",
   "g++ -c -O3 -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O3 -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

BoostCgccO3nativeNoAssert = [
   "C++ : Boost no assert",
   "g++ -O3 native",
   "g++ -c -O3 -march=native -DBOOST_DISABLE_ASSERTS cbsub.cpp -o cbsub.o",
   "g++ -o cbmain -O3 -march=native -DBOOST_DISABLE_ASSERTS cbmain.cpp cbsub.o",
   "./cbmain",
   100000,
   "rm -f cbmain cbsub.o"]

CNumRclang = [
   "C : Num. rec.",
   "clang",
   "c++ -c cnrsub.cpp -o cnrsub.o",
   "c++ -o cnrmain cnrmain.cpp cnrsub.o",
   "./cnrmain",
   100000,
   "rm -f cnrmain cnrsub.o"]

CNumRclangO = [
   "C : Num. rec.",
   "clang -O",
   "c++ -c -O cnrsub.cpp -o cnrsub.o",
   "c++ -o cnrmain -O cnrmain.cpp cnrsub.o",
   "./cnrmain",
   1000000,
   "rm -f cnrmain cnrsub.o"]

CNumRclangO1 = [
   "C : Num. rec.",
   "clang -O1",
   "c++ -c -O1 cnrsub.cpp -o cnrsub.o",
   "c++ -o cnrmain -O1 cnrmain.cpp cnrsub.o",
   "./cnrmain",
   1000000,
   "rm -f cnrmain cnrsub.o"]

CNumRclangO2 = [
   "C : Num. rec.",
   "clang -O2",
   "c++ -c -O2 cnrsub.cpp -o cnrsub.o",
   "c++ -o cnrmain -O2 cnrmain.cpp cnrsub.o",
   "./cnrmain",
   1000000,
   "rm -f cnrmain cnrsub.o"]

CNumRclangO3 = [
   "C : Num. rec.",
   "clang -O3",
   "c++ -c -O3 cnrsub.cpp -o cnrsub.o",
   "c++ -o cnrmain -O3 cnrmain.cpp cnrsub.o",
   "./cnrmain",
   1000000,
   "rm -f cnrmain cnrsub.o"]

CNumRclangO3native = [
   "C : Num. rec.",
   "clang -O3 native",
   "c++ -c -O3 -march=native cnrsub.cpp -o cnrsub.o",
   "c++ -o cnrmain -O3 -march=native cnrmain.cpp cnrsub.o",
   "./cnrmain",
   5000000,
   "rm -f cnrmain cnrsub.o"]

CNumRgcc = [
   "C : Num. rec.",
   "g++",
   "g++ -c cnrsub.cpp -o cnrsub.o",
   "g++ -o cnrmain cnrmain.cpp cnrsub.o",
   "./cnrmain",
   100000,
   "rm -f cnrmain cnrsub.o"]

CNumRgccO = [
   "C : Num. rec.",
   "g++ -O",
   "g++ -c -O cnrsub.cpp -o cnrsub.o",
   "g++ -o cnrmain -O cnrmain.cpp cnrsub.o",
   "./cnrmain",
   500000,
   "rm -f cnrmain cnrsub.o"]

CNumRgccO1 = [
   "C : Num. rec.",
   "g++ -O1",
   "g++ -c -O1 cnrsub.cpp -o cnrsub.o",
   "g++ -o cnrmain -O1 cnrmain.cpp cnrsub.o",
   "./cnrmain",
   500000,
   "rm -f cnrmain cnrsub.o"]

CNumRgccO2 = [
   "C : Num. rec.",
   "g++ -O2",
   "g++ -c -O2 cnrsub.cpp -o cnrsub.o",
   "g++ -o cnrmain -O2 cnrmain.cpp cnrsub.o",
   "./cnrmain",
   1000000,
   "rm -f cnrmain cnrsub.o"]

CNumRgccO3 = [
   "C : Num. rec.",
   "g++ -O3",
   "g++ -c -O3 cnrsub.cpp -o cnrsub.o",
   "g++ -o cnrmain -O3 cnrmain.cpp cnrsub.o",
   "./cnrmain",
   1000000,
   "rm -f cnrmain cnrsub.o"]

CNumRgccO3native = [
   "C : Num. rec.",
   "g++ -O3 native",
   "g++ -c -O3 -march=native cnrsub.cpp -o cnrsub.o",
   "g++ -o cnrmain -O3 -march=native cnrmain.cpp cnrsub.o",
   "./cnrmain",
   5000000,
   "rm -f cnrmain cnrsub.o"]

VecCclang = [
   "C : vectors",
   "clang",
   "c++ -c cvsub.cpp -o cvsub.o",
   "c++ -o cvmain cvmain.cpp cvsub.o",
   "./cvmain",
   100000,
   "rm -f cvmain cvsub.o"]

VecCclangO = [
   "C : vectors",
   "clang -O",
   "c++ -c -O cvsub.cpp -o cvsub.o",
   "c++ -o cvmain -O cvmain.cpp cvsub.o",
   "./cvmain",
   1000000,
   "rm -f cvmain cvsub.o"]

VecCclangO1 = [
   "C : vectors",
   "clang -O1",
   "c++ -c -O1 cvsub.cpp -o cvsub.o",
   "c++ -o cvmain -O1 cvmain.cpp cvsub.o",
   "./cvmain",
   1000000,
   "rm -f cvmain cvsub.o"]

VecCclangO2 = [
   "C : vectors",
   "clang -O2",
   "c++ -c -O2 cvsub.cpp -o cvsub.o",
   "c++ -o cvmain -O2 cvmain.cpp cvsub.o",
   "./cvmain",
   1000000,
   "rm -f cvmain cvsub.o"]

VecCclangO3 = [
   "C : vectors",
   "clang -O3",
   "c++ -c -O3 cvsub.cpp -o cvsub.o",
   "c++ -o cvmain -O3 cvmain.cpp cvsub.o",
   "./cvmain",
   1000000,
   "rm -f cvmain cvsub.o"]

VecCclangO3native = [
   "C : vectors",
   "clang -O3 native",
   "c++ -c -O3 -march=native cvsub.cpp -o cvsub.o",
   "c++ -o cvmain -O3 -march=native cvmain.cpp cvsub.o",
   "./cvmain",
   5000000,
   "rm -f cvmain cvsub.o"]

VecCgcc = [
   "C : vectors",
   "g++",
   "g++ -c cvsub.cpp -o cvsub.o",
   "g++ -o cvmain cvmain.cpp cvsub.o",
   "./cvmain",
   100000,
   "rm -f cvmain cvsub.o"]

VecCgccO = [
   "C : vectors",
   "g++ -O",
   "g++ -c -O cvsub.cpp -o cvsub.o",
   "g++ -o cvmain -O cvmain.cpp cvsub.o",
   "./cvmain",
   1000000,
   "rm -f cvmain cvsub.o"]

VecCgccO1 = [
   "C : vectors",
   "g++ -O1",
   "g++ -c -O1 cvsub.cpp -o cvsub.o",
   "g++ -o cvmain -O1 cvmain.cpp cvsub.o",
   "./cvmain",
   1000000,
   "rm -f cvmain cvsub.o"]

VecCgccO2 = [
   "C : vectors",
   "g++ -O2",
   "g++ -c -O2 cvsub.cpp -o cvsub.o",
   "g++ -o cvmain -O2 cvmain.cpp cvsub.o",
   "./cvmain",
   1000000,
   "rm -f cvmain cvsub.o"]

VecCgccO3 = [
   "C : vectors",
   "g++ -O3",
   "g++ -c -O3 cvsub.cpp -o cvsub.o",
   "g++ -o cvmain -O3 cvmain.cpp cvsub.o",
   "./cvmain",
   1000000,
   "rm -f cvmain cvsub.o"]

VecCgccO3native = [
   "C : vectors",
   "g++ -O3 native",
   "g++ -c -O3 -march=native cvsub.cpp -o cvsub.o",
   "g++ -o cvmain -O3 -march=native cvmain.cpp cvsub.o",
   "./cvmain",
   5000000,
   "rm -f cvmain cvsub.o"]

Fortran = [
   "Fortran",
   "gfortran",
   "gfortran -c -o cfsub.o cfsub.f",
   "gfortran -o cfmain cfmain.f cfsub.o",
   "./cfmain",
   100000,
   "rm -f cfmain cfsub.o"]

FortranO = [
   "Fortran",
   "gfortran -O",
   "gfortran -c -o cfsub.o -O cfsub.f",
   "gfortran -o cfmain -O cfmain.f cfsub.o",
   "./cfmain",
   500000,
   "rm -f cfmain cfsub.o"]

FortranO1 = [
   "Fortran",
   "gfortran -O1",
   "gfortran -c -o cfsub.o -O1 cfsub.f",
   "gfortran -o cfmain -O1 cfmain.f cfsub.o",
   "./cfmain",
   500000,
   "rm -f cfmain cfsub.o"]

FortranO2 = [
   "Fortran",
   "gfortran -O2",
   "gfortran -c -o cfsub.o -O2 cfsub.f",
   "gfortran -o cfmain -O2 cfmain.f cfsub.o",
   "./cfmain",
   500000,
   "rm -f cfmain cfsub.o"]

FortranO3 = [
   "Fortran",
   "gfortran -O3",
   "gfortran -c -o cfsub.o -O3 cfsub.f",
   "gfortran -o cfmain -O3 cfmain.f cfsub.o",
   "./cfmain",
   500000,
   "rm -f cfmain cfsub.o"]

FortranO3native = [
   "Fortran",
   "gfortran -O3 native",
   "gfortran -c -o cfsub.o -O3 -march=native cfsub.f",
   "gfortran -o cfmain -O3 -march=native cfmain.f cfsub.o",
   "./cfmain",
   5000000,
   "rm -f cfmain cfsub.o"]

Assembler = [
   "Assembler",
   "clang",
   "c++ -c -o subrasavx.o subrasavx.s",
   "c++ -o assmain -O cnrmain.cpp subrasavx.o",
   "./assmain",
   5000000,
   "rm -f assmain subrasavx.o"]

Java = [
   "Java",
   "Java",
   "javac -g:none csub.java",
   "",
   "java csub",
   500000,
   "rm -f csub.class"]

Tcl = [
   "Tcl : raw",
   "tclsh",
   "",
   "",
   "tclsh ctest.tcl",
   200,
   ""]

Julia = [
   "Julia",
   "julia",
   "",
   "",
   "julia csub.jl",
   500000,
   ""]

JuliaO0 = [
   "Julia",
   "julia -O0",
   "",
   "",
   "julia -O0 csub.jl",
   50000,
   ""]

JuliaO1 = [
   "Julia",
   "julia -O1",
   "",
   "",
   "julia -O1 csub.jl",
   200000,
   ""]

JuliaO2 = [
   "Julia",
   "julia -O2",
   "",
   "",
   "julia -O2 csub.jl",
   200000,
   ""]

JuliaO3 = [
   "Julia",
   "julia -O3",
   "",
   "",
   "julia -O3 csub.jl",
   200000,
   ""]

RawR = [
   "R : raw",
   "Rscript",
   "",
   "",
   "Rscript csub.r",
   5000,
   ""]

Rref = [
   "R : ref class",
   "Rscript",
   "",
   "",
   "Rscript csubref.r",
   3,
   ""]

Router = [
   "R : outer",
   "Rscript",
   "",
   "",
   "Rscript csubouter.r",
   20000,
   ""]

Perl = [
   "Perl",
   "Perl",
   "",
   "",
   "perl csubraw.pl",
   1000,
   ""]

PerlPDLraw = [
   "Perl/PDL : raw",
   "Perl/PDL",
   "",
   "",
   "perl csubpdl.pl",
   10,
   ""]

PerlPDLvec = [
   "Perl/PDL : vectors",
   "Perl/PDL",
   "",
   "",
   "perl csubpdlvec.pl",
   30000,
   ""]

PerlPDLary = [
   "Perl/PDL : arrays",
   "Perl/PDL",
   "",
   "",
   "perl csubpdlary.pl",
   100000,
   ""]

Python2 = [
   "Python : lists",
   "Python2",
   "",
   "",
   "python csubraw.py",
   1000,
   ""]

Python2np = [
   "Python : numpy raw",
   "Python2",
   "",
   "",
   "python csubnp.py",
   200,
   ""]

Python2vec = [
   "Python : vectors",
   "Python2",
   "",
   "",
   "python csubnpv.py",
   50000,
   ""]

Python2ary = [
   "Python : arrays",
   "Python2",
   "",
   "",
   "python csubnpna.py",
   50000,
   ""]

Python3 = [
   "Python : lists",
   "Python3",
   "",
   "",
   "python3 csubraw.py",
   1000,
   ""]

Python3np = [
   "Python : numpy raw",
   "Python3",
   "",
   "",
   "python3 csubnp.py",
   200,
   ""]

Python3vec = [
   "Python : vectors",
   "Python3",
   "",
   "",
   "python3 csubnpv.py",
   50000,
   ""]

Python3ary = [
   "Python : arrays",
   "Python3",
   "",
   "",
   "python3 csubnpna.py",
   50000,
   ""]

Rust = [
   "Rust",
   "Rustc",
   "rustc crsmain.rs ",
   "",
   "./crsmain",
   1000,
   "rm -f crsmain"]

RustO = [
   "Rust",
   "Rustc -O",
   "rustc -O crsmain.rs ",
   "",
   "./crsmain",
   100000,
   "rm -f crsmain"]

RustO3 = [
   "Rust",
   "Rustc -O3",
   "rustc -C opt-level=3 crsmain.rs ",
   "",
   "./crsmain",
   100000,
   "rm -f crsmain"]

RustO3native = [
   "Rust",
   "Rustc -O3 native",
   "rustc -C target-cpu=native -C opt-level=3 crsmain.rs ",
   "",
   "./crsmain",
   100000,
   "rm -f crsmain"]

Javascript = [
   "Javascript",
   "Node.js",
   "",
   "",
   "node cjstest.js",
   100000,
   ""]

JavascriptNoopt = [
   "Javascript",
   "Node.js --no-opt",
   "",
   "",
   "node --no-opt cjstest.js",
   6000,
   ""]

Swift = [
   "Swift",
   "Swiftc",
   "xcrun swiftc -o cstest cstest.swift",
   "",
   "./cstest",
   1000,
   "rm -f cstest"]

SwiftOnone = [
   "Swift",
   "Swiftc -Onone",
   "xcrun swiftc -o cstest -Onone cstest.swift",
   "",
   "./cstest",
   1000,
   "rm -f cstest"]

SwiftO = [
   "Swift",
   "Swiftc -O",
   "xcrun swiftc -o cstest -O cstest.swift",
   "",
   "./cstest",
   300000,
   "rm -f cstest"]

SwiftOunchecked = [
   "Swift",
   "Swiftc -Ounchecked",
   "xcrun swiftc -o cstest -Ounchecked cstest.swift",
   "",
   "./cstest",
   500000,
   "rm -f cstest"]

#  FullTests is simply a list of all the structures that define tests to
#  be run. The order is not particularly important.

FullTests = [
   Swift,SwiftOnone,SwiftO,SwiftOunchecked,
   Assembler,
   Fortran,FortranO,FortranO1,FortranO2,FortranO3,FortranO3native,
   RawR, Rref, Router,
   Perl,PerlPDLraw,PerlPDLvec,PerlPDLary,
   Python2,Python2np,Python2vec,Python2ary,
   Python3,Python3np,Python3vec,Python3ary,
   Rust,RustO,RustO3,RustO3native,
   Java,
   Tcl,
   Julia,JuliaO0,JuliaO1,JuliaO2,JuliaO3,
   Javascript,JavascriptNoopt,
   RawCclang,RawCclangO,RawCclangO1,RawCclangO2,RawCclangO3,RawCclangO3native,
   RawCgcc,RawCgccO,RawCgccO1,RawCgccO2,RawCgccO3,RawCgccO3native,
   VecCclang,VecCclangO,VecCclangO1,VecCclangO2,VecCclangO3,VecCclangO3native,
   VecCgcc,VecCgccO,VecCgccO1,VecCgccO2,VecCgccO3,VecCgccO3native,
   BoostCclang,BoostCclangO,BoostCclangO1,
   BoostCclangO2,BoostCclangO3,BoostCclangO3native,
   BoostCgcc,BoostCgccO,BoostCgccO1,BoostCgccO2,BoostCgccO3,BoostCgccO3native,
   BoostCclangNoAssert,BoostCclangONoAssert,BoostCclangO1NoAssert,
   BoostCclangO2NoAssert,BoostCclangO3NoAssert,BoostCclangO3nativeNoAssert,
   BoostCgccNoAssert,BoostCgccONoAssert,BoostCgccO1NoAssert,
   BoostCgccO2NoAssert,BoostCgccO3NoAssert,BoostCgccO3nativeNoAssert,
   CNumRclang,CNumRclangO,CNumRclangO1,
   CNumRclangO2,CNumRclangO3,CNumRclangO3native,
   CNumRgcc,CNumRgccO,CNumRgccO1,CNumRgccO2,CNumRgccO3,CNumRgccO3native,
  ]

# ------------------------------------------------------------------------------
#
#                          M a i n   P r o g r a m

#  First, list the versions of all the compilers, interpreters, etc. that
#  are being used.

print ("")
print ("Versions:")
print ("")
ListVersion("Clang    ","c++ --version")
ListVersion("Assembler","c++ --version")
ListVersion("Gcc      ","g++ --version")
ListVersion("Gfortran ","gfortran --version")
ListVersion("R        ","Rscript --version")
ListVersion("Python2  ","python --version")
ListVersion("Python3  ","python3 --version")
ListVersion("Java     ","java -version")
ListVersion("Node.js  ","node --version")
ListVersion("Tcl      ","tclsh ver.tcl")
ListVersion("Swift    ","xcrun swiftc --version")
ListVersion("Julia    ","julia --version")
ListVersion("Rust     ","rustc --version")
ListVersion("Perl/PDL ","pdl -V")


#  Set the size of the array to be used for the test. There isn't much of a
#  good reason for using 10 rows of 2000 elements, but the repeat counts
#  in the tests were set up assuming that, so making the array much bigger
#  will increase the time taken unless the repeat counts are adjusted.
#  Note that 2000 is not a multiple of 16 or any higher power of 2, and some
#  highly optimised implementations using vector operations may run faster
#  if given a size that is a multiple of the largest vector the CPU can
#  handle. But using 2000 makes that a bit harder for them, which may be no
#  bad thing. Also set the number of times the full set of tests is to be
#  repeated - if the test set is repeated, the lowest measured time for any
#  individual test is used.

Nx = 2000
Ny = 10
Ntests = 1

if (len(sys.argv) > 1):
   Ntests = int(sys.argv[1])
   if (len(sys.argv) > 2):
      Nx = int(sys.argv[2])
      if (len(sys.argv) > 3):
         Ny = int(sys.argv[3])

#  Build up a list of all the different language/techniques we have.
#  Ditto a list of all the compilers/option combinations we have.

LangTechList = []
CompOptList = []
for Test in FullTests :
   LangTech = Test[0]
   CompOpt = Test[1]
   if (not LangTech in LangTechList) : LangTechList.append(LangTech)
   if (not CompOpt in CompOptList) : CompOptList.append(CompOpt)
LangTechList = sorted(LangTechList,key = lambda s : s.lower())
CompOptList = sorted(CompOptList,key = lambda s : s.lower())
NLangTech = len(LangTechList)
NCompOpt = len(CompOptList)

#  Now, set up a 2D array NLangTech by NCompOpt which will contain the matrix
#  of relative times for each test. Most of the elements will be null (we use
#  zero), since most Language/Compiler combinations just don't work. But this
#  is a good way to lay out the results, and can form the basis of the
#  spreadsheet data this program will create.

Results = numpy.zeros((NLangTech,NCompOpt))

#  We can run the full set of tests a number of times, to try to even out
#  any variations.

for ITest in range(Ntests) :

   print ("")
   if (Ntests > 1) :
      print ("Starting pass",ITest + 1,"of",Ntests,"through full set of tests")
   else :
      print ("Running through full set of timing tests")
   print ("")
   print ("Arrays used:",Nx,"columns,",Ny,"rows")
   print ("")

   #  Run each test in turn. That's really all we do.

   for Test in FullTests :

      #  Test[0] is language/technique, Test[1] the compiler/interpreter & flags.
      #  Test[2] and Test[3] are the build commands, Test[4] is the command
      #  to run the test, Test[5] is the number of iterations, and Test[6] is
      #  the cleanup command.
      
      LangTech = Test[0]
      CompOpt = Test[1]
      Nrpt = Test[5]
      (Status,Secs,Errors) = \
         BuildAndTimeProgram(Test[2],Test[3],Test[4],Nrpt,Nx,Ny,Test[6])
      if (Status) :
         print (LangTech,CompOpt,"Error:",Status,Errors)
      else :
         KIterSecs = (Secs / float(Nrpt)) * 1000.0
         print ("%24s %20s Rept: %8d Elap: %10.2f 1K Iter: %10.2g" %
                                   (LangTech,CompOpt,Nrpt,Secs,KIterSecs))

         #  Record the result (the time to perform 1000 iterations) in the
         #  Results array, using the indices for the language and compiler used.
         #  If we are running more than one iteration of the full test loop,
         #  we take the lowest (non-zero) number we get from any one iteration.

         LangTechIndex = LangTechList.index(LangTech)
         CompOptIndex = CompOptList.index(CompOpt)
         if (KIterSecs > 0.0) :
            LowestSoFar = Results[LangTechIndex,CompOptIndex]
            if (LowestSoFar <= 0.0) :
               Results[LangTechIndex,CompOptIndex] = KIterSecs
            else :
               if (KIterSecs < LowestSoFar) :
                  Results[LangTechIndex,CompOptIndex] = KIterSecs

#  Find the benchmark result - the lowest number in the results table (ignoring
#  the zeros from non-existent or failed tests)

First = True
FastestLangTech = ""
FastestCompOpt = ""
BenchKIterSecs = 1.0
for LangTechIndex in range(NLangTech) :
   for CompOptIndex in range(NCompOpt) :
      Result = Results[LangTechIndex,CompOptIndex]
      FastestSoFar = False
      if (Result > 0.0) :
         if (First) :
            FastestSoFar = True
            First = False
         else :
            if (Result < BenchKIterSecs) : FastestSoFar = True
      if (FastestSoFar) :
         BenchKIterSecs = Result
         FastestLangTech = LangTechList[LangTechIndex]
         FastestCompOpt = CompOptList[CompOptIndex]
print ("Fastest combination is ",FastestLangTech,"and",FastestCompOpt)

#  Now that we know the benchmark speed, output a final list of results, this
#  time including the relative speed for each test.

print ("")
print ("Summary of relative speeds:")
print ("")
for Test in FullTests :
   LangTech = Test[0]
   CompOpt = Test[1]
   LangTechIndex = LangTechList.index(LangTech)
   CompOptIndex = CompOptList.index(CompOpt)
   KIterSecs = Results[LangTechIndex,CompOptIndex]
   RelativeSpeed = KIterSecs / BenchKIterSecs
   print ("%24s %20s 1K Iter: %10.2g, Relative time %12.2f" %
                                (LangTech,CompOpt,KIterSecs,RelativeSpeed))

#  Finally, output the summary table of relative speeds in a .csv format that
#  can be read by most spreadsheet programs.

print ("")
Line = "Compiler"
for LangTech in LangTechList :
   Line = Line + ',' + LangTech
print (Line)
for CompOpt in CompOptList :
   CompOptIndex = CompOptList.index(CompOpt)
   Line = CompOpt
   for LangTechIndex in range(NLangTech) :
      Result = Results[LangTechIndex,CompOptIndex] / BenchKIterSecs
      ResultString = ""
      if (Result > 0.0) : ResultString = ("%.2f" % Result)
      Line = Line + ',' + ResultString
   print (Line)




