#!/usr/bin/env wish

#                              c t e s t . t c l
#
#  Summary:
#     2D array access test in Tcl, using simple array element access.
#
#  Introduction:
#     This is a test program written as part of a study into how well different
#     languages handle accessing elements of 2D rectangular arrays - the sort of
#     thing that are common in astronomy and similar scientific disciplines.
#     This can also be used to see how efficient different ways of coding the
#     same problem can be in the different languages, and to see what effect
#     such things as compilation options - particularly optimisation options -
#     have.
#
#     The problem chosen is a trivial one: given an 2D array, add to each
#     element the sum of its two indices and return the result in a second,
#     similarly-sized array. This is harder to optimise away than, for example,
#     simply doing an element by element copy of the array, but is generally
#     easy to code. It isn't a perfect test (something brought out by the
#     study), but it does produce some interesting results.
#
#  This version:
#     This version is for Tcl, and is a relatively straightforward
#     implementation, using the most basic Tcl array facilities - the ability
#     to refer to a variable with index values, eg $array($iy,$ix). This is
#     not particularly efficient.
#
#  Structure:
#     Most test programs in this study code the basic array manipulation in a
#     single subrutine, then create the original input array, and pass that,
#     together with the dimensions of the array, to that subroutine, repeating
#     that call a large number of times in oder to be able to get a reasonable
#     estimate of the time taken. Then the final result is checked against the
#     expected result.
#
#     This code follows that structure, with both the main routine and the
#     called subroutine in the same piece of code, as Tcl certainly doesn't
#     optimise out the call in that case. The mechanism of passing the arrays
#     to the subroutine using 'upvar' is a bit awkward.
#
#  Invocation:
#     ./ctest.tcl irpt nx ny
#
#     or:
#
#     wish ctest.tcl irpt nx ny
#
#     where
#        irpt  is the number of times the subroutine is called - default 100.
#        nx    is the number of columns in the array tested - default 2000.
#        ny    is the number of rows in the array tested - default 10.
#
#  Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
#
#  History:
#     21st Aug 2019. First properly commented version. KS.
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

#  -----------------------------------------------------------------------------
#
#  The subr{} subroutine.
#
#  subr{} is a subroutine that is passed a two-dimensional floating point array
#  inary, with dimensions nx by ny, together with an output array, outary,
#  of the same dimensions. It returns with each element of outary set to the
#  contents of the corresponding element if inary plus the sum of its two
#  indices. The intent is to try to see how well any given language handles
#  access to individual elements of a 2D array,

proc subr { inary nx ny outary } {
   upvar $inary in
   upvar $outary out
   for {set iy 0} {$iy < $ny} {incr iy} {
      for {set ix 0} {$ix < $nx} {incr ix} {
         set inelem $in($iy,$ix)
         set out($iy,$ix) [expr $inelem + $ix + $iy]
      }
   }
}

#  -----------------------------------------------------------------------------

#  The main routine.

#  Get the command line arguments, and determine the array size and the number
#  of times to repeat the subroutine call.

set ny 10
set nx 2000
set nrpt 100
if { $argc > 0 } { set nrpt [lindex $argv 0] }
if { $argc > 1 } { set nx [lindex $argv 1] }
if { $argc > 2 } { set ny [lindex $argv 2] }

#  Create the input array and output arrays. We set the elements of the input
#  array to some set of values - it doesn't matter what, just some values we
#  can use to check the array manipulation on. This uses the sum of the row and
#  column indices in descending order. The values in the output array don't
#  matter, so we fill it with zeros.

for {set iy 0} {$iy < $ny} {incr iy} {
   for {set ix 0} {$ix < $nx} {incr ix} {
      set in($iy,$ix) [expr $nx - $ix + $ny - $iy]
      set out($iy,$ix) 0.0
   }
}
puts "Arrays $ny rows by $nx columns, repeat = $nrpt"

#  Call the subroutine the specified number of times.

for {set loop 0} { $loop < $nrpt} {incr loop} { subr in $nx $ny out }

#  Check the results.

set error 0
for {set iy 0} {$iy < $ny} {incr iy} {
   for {set ix 0} {$ix < $nx} {incr ix} {
      if { $out($iy,$ix) != ($in($iy,$ix) + $ix + $iy) } {
         set error 1
         puts "Error: $out($iy,$ix) $ix $iy $in($iy,$ix)"
         break;
      }
   }
   if { $error } { break }
}

exit

# ------------------------------------------------------------------------------
#
#                     P r o g r a m m i n g  N o t e s
#
#  o  Tcl doesn't really do multi-dimensional arrays, so they're emulated
#     using element names of the form "ix,iy". Tcl can't really pass arrays
#     to procedures nicely, so you have to use upvar. It might be that lists
#     would work better, but I've not tried them. There may well be some neat
#     tcl tricks that would make this run much faster, but I don't know them.
#
#  o  In particular, there is a 'matrix' package in tcllib, which I have not
#     tried.
#
#  o  It isn't entirely clear to me it it makes sense to think of Tcl using
#     column-major or row-major ordering for this sort of array. In any case,
#     changing the order of the loops in the subr{} routine makes very little
#     difference to execution time.
