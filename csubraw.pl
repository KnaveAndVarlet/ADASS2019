#
#                          c s u b r a w . p l
#
#  Summary:
#     2D array access test in Perl, using standard Perl arrays.
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
#     This version is for Perl, and uses ordinary Perl arrays, accessing each
#     element using the [$iy][$ix] syntax.
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
#     called subroutine in the same piece of code, as Perl doesn't optimise
#     out the call in that case.
#
#  Invocation:
#     perl csubraw.pl irpt nx ny
#
#     where
#        irpt  is the number of times the subroutine is called - default 1000.
#        nx    is the number of columns in the array tested - default 2000.
#        ny    is the number of rows in the array tested - default 10.
#
#     Note that Perl uses row-major order; arrays are stored in memory so
#     that the second index varies fastest.
#
#  Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
#
#  History:
#     15th Sep 2019. First properly commented version. KS.
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
   my @Input = @{$_[0]};
   my $Nx = $_[1];
   my $Ny = $_[2];
   my @Output = @{$_[3]};
   for (my $iy=0; $iy < $Ny; $iy++) {
      for (my $ix=0; $ix < $Nx; $ix++) {
         $Output[$iy][$ix] = $Input[$iy][$ix] + $ix + $iy;
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

my @InArray;
my @OutArray;
$InArray[$ny][$nx] = 0.0;
$OutArray[$ny][$nx] = 0.0;
for (my $iy=0; $iy < $ny; $iy++) {
   for (my $ix=0; $ix < $nx; $ix++) {
      $InArray[$iy][$ix] = $nx - $iy + $ny - $ix;
      $OutArray[$iy][$ix] = 0.0;
   }
}

#  Call the subroutine the specified number of times.

for (my $irpt = 0; $irpt < $nrpt; $irpt++) {
   csub (\@InArray,$nx,$ny,\@OutArray);
}

#  Check the results.

Loop: {
   for (my $iy=0; $iy < $ny; $iy++) {
      for (my $ix=0; $ix < $nx; $ix++) {
         if ($OutArray[$iy][$ix] != $InArray[$iy][$ix] + $ix + $iy) {
            print "Error ",$ix," ",$iy," ",
                        $InArray[$iy][$ix]," ",$OutArray[$iy][$ix],"\n";
            last Loop;
         }
      }
   }
}
