#
#                          c s u b p d l . p l
#
#  Summary:
#     2D array access test in Perl, using PDL single element access.
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
#     This version is for Perl, and uses the PDL (Perl Data Language)
#     sub-system to work with multi-dimensional arrays. PDL is akin to numpy
#     for Python, in that it is designed to provide relatively fast operations
#     on arrays, and it has a very flexible syntax for slicing arrays. This
#     code does not show PDL at its best, as it uses it to create @D arrays,
#     and then uses the PDL slicing syntax to work on 'slices' that contain
#     a single array element at a time. This is not what PDL was designed for,
#     but it shows it can be done.
#
#  Structure:
#     Most test programs in this study code the basic array manipulation in a
#     single subroutine, then create the original input array, and pass that,
#     together with the dimensions of the array, to that subroutine, repeating
#     that call a large number of times in oder to be able to get a reasonable
#     estimate of the time taken. Then the final result is checked against the
#     expected result.
#
#     This code follows that structure, with both the main routine and the
#     called subroutine in the same piece of code, as Perl/PDL doesn't optimise
#     out the call in that case.
#
#  Invocation:
#     perl csubpdl.pl irpt nx ny
#
#     where
#        irpt  is the number of times the subroutine is called - default 3.
#        nx    is the number of columns in the array tested - default 2000.
#        ny    is the number of rows in the array tested - default 10.
#
#     This assumes that the Perl installation supports PDL.
#
#     Note that Perl/PDL uses column-major order; arrays are stored in memory so
#     that the first index varies fastest.
#
#  Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
#
#  History:
#     14th Sep 2019. First properly commented version. (Written with some
#                    much appreciated help from Karl Glazebrook.) KS.
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

use PDL;

#  --------------------------------------------------------------------------------
#
#  The csub() subroutine.
#
#  csub is a subroutine that is passed a two-dimensional floating point array
#  Input, with dimensions Nx by Ny, together with a second, array, Output,
#  of the same dimensions. It returns with each element of Output set to the
#  contents of the corresponding element of Input plus the sum of its two
#  indices. The intent is to try to see how well any given language handles
#  access to individual elements of a 2D array,

sub csub {
   my ($Input,$Nx,$Ny,$Output) = @_;
   for (my $iy=0; $iy < $Ny; $iy++) {
      for (my $ix=0; $ix < $Nx; $ix++) {
         $Output->slice($ix,$iy) .= $Input->slice($ix,$iy) + $ix + $iy;
      }
   }
}

#  -----------------------------------------------------------------------------

#  The main routine.

#  Get the command line arguments, and determine the array size and the number
#  of times to repeat the subroutine call.

$nx = 2000;
$ny = 10;
$nrpt = 3;
if ($#ARGV >= 0) {
   $nrpt = $ARGV[0];
   if ($#ARGV >= 1) {
      $nx = $ARGV[1];
      if ($#ARGV >= 2) {
         $ny = $ARGV[2];
      }
   }
}
print ("Arrays ",$nx," columns by ",$ny," rows, repeats = ",$nrpt,"\n");

#  Create the input array and output arrays. We set the elements of the input
#  array to some set of values - it doesn't matter what, just some values we
#  can use to check the array manipulation on. This uses the sum of the row and
#  column indices in descending order. The values in the output array don't
#  matter, so we fill it with zeros.

$InArray = zeroes($nx,$ny);
$OutArray = zeroes($nx,$ny);
for (my $iy=0; $iy < $ny; $iy++) {
   for (my $ix=0; $ix < $nx; $ix++) {
      $InArray->slice($ix,$iy) .= $nx - $ix + $ny - $iy;
   }
}

#  Call the subroutine the specified number of times.

for (my $irpt = 0; $irpt < $nrpt; $irpt++) {
   csub ($InArray,$nx,$ny,$OutArray);
}

#  Check the results.

Loop: {
   for (my $iy=0; $iy < $ny; $iy++) {
      for (my $ix=0; $ix < $nx; $ix++) {
         if ($OutArray->slice($ix,$iy)
                            != $InArray->slice($ix,$iy) + $ix + $iy) {
            print "Error ",$ix," ",$iy," ",$InArray->slice($ix,$iy)," ",
                                          $OutArray->slice($ix,$iy),"\n";
            last Loop;
         }
      }
   }
}

#  --------------------------------------------------------------------------------

#                       P r o g r a m m i n g  N o t e s
#
#  o The loops that set up the input array, and test the output array after the
#    opearation has been performed as many times as requested, use the very
#    slow PDL single element access method. For small repeat counts, these
#    could well have a significant overhead, and this needs to be allowed for
#    in the timeing - probably by measuring the time for a run with nrpt set
#    to one, repeating for the full repeat count and adjusting the time taken.
#
#  o There are almost cerrtainly some neat PDL ways of speeding up the array
#    initialisation and testing using vector operations, but this works as
#    it is and the whole point of optimisation is only to spend time on what
#    really needs to be optimised.

