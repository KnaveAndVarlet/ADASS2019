#! /usr/bin/env Rscript

#                          c s u b o u t e r . r
#
#  Summary:
#     2D array access test in R, using the outer() function provided by R.
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
#     This version is for R, and isn't really a proper test of how well R
#     handles access to individual array elements, as it gets the required
#     result by explicitly generating an array of the increment values and then
#     adding the two arrays together. So this is not an example of how to code
#     the basic array element access in R, but it is a demonstration of how that
#     can be bypassed in R to get a more efficient result.
#
#  Structure:
#     Most test progrsms in this study code the basic array manipulation in a
#     single subrutine, then create the original input array, and pass that,
#     together with the dimensions of the array, to that subroutine, repeating
#     that call a large number of times in oder to be able to get a reasonable
#     estimate of the time taken. Then the final result is checked against the
#     expected result.
#
#     This code follows that structure, with both the main routine and the
#     called subroutine in the same piece of code, as R doesn't optimise out
#     the call in that case. The only unusual aspect of the subroutine here is
#     the resulting output array is not passed to the subroutine, as it is in
#     most implementations, as it's better in R to let the subroutine create it
#     as the return value from the subroutine.
#
#  Invocation:
#     ./csubouter irpt nx ny
#
#     where:
#       irpt  is the number of times the subroutine is called - default 1000.
#       nx    is the number of columns in the array tested - default 2000.
#       ny    is the number of rows in the array tested - default 10.
#
#     Note that R uses column-major order; arrays are stored in memory so that
#     the first index varies fastest.
#
#  Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
#
#  History:
#     4th Jul 2019. First properly commented version. KS.
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
#  ina, with dimensions nx by ny. It returns a two dimensional array of the same
#  dimensions with each element set to the contents of the corresponding element
#  in ina plus the sum of its two indices. The intent is to try to see how well
#  any given language handles access to individual elements of a 2D array,
#
#  Note that in general R does not pass arguments by reference (conceptually,
#  at least - in practice, an array like ina which is not changed by the routine
#  will be passed by reference just for efficiency). This means a routine such
#  as csub() has to return the result array as the function value, and there is
#  no point in passing it an output array as an argument. (If we did, the
#  routine would simply make a local copy of it, any changes would not be
#  reflected in the copy maintained by the calling routine, and all this does is
#  add overhead.)
#
#  This particular implementation of csub() actually subverts the point of the
#  test, since it uses a quite neat use of the outer() function to get the
#  required effect, which shows what can be done if you know your way around R
#  (and thanks to Hong Ooi who pointed this out in an answer to my question on
#  StackOverflow.
#  See: stackoverflow.com/questions/56746989/
#               how-to-speed-up-writing-to-a-matrix-in-a-reference-class-in-r ).
#  However, it bypasses individual access to the array elements rather than
#  providing a way of testing how well R handles that.
#
#  outer() generates an array whose values depend on the ranges passed to it as
#  arguments, in this case the sum of the index values for each element. Add
#  that element by element to the input array (ina) and return the result.
#  Job done.
#
#  This is the fastest way of implementing this function I've found so far in R
#  without resorting to calling a C routine to do the job (which is what you
#  would do if you really cared about speed). However, I'm not an R expert and
#  there may be even better ways.

csub <- function(ina,nx,ny) {
   return (ina + outer(1:nx,1:ny,'+'))
}

#  -----------------------------------------------------------------------------

#  The main routine.

#  Get the command line arguments, and determine the array size and the number
#  of times to repeat the subroutine call.

args <- commandArgs(TRUE)
nx = 2000
ny = 10
nrpt = 1000
if (length(args) > 0) {
   nrpt = as.integer(args[1])
   if (length(args) > 1) {
      nx = as.integer(args[2])
      if (length(args) > 2) {
         ny = as.integer(args[3])
      }
   }
}
cat ("Arrays",nx,"by",ny,"repeat = ",nrpt,"\n")

#  Create the input array. We set the elements of the input array to some set
#  of values - it doesn't matter what, just some values we can use to check the
#  array manipulation on. This uses the sum of the row and column indices in
#  descending order. We don't need to create an output array, as we use the
#  return value from csub().

ina <- matrix(0.0,nx,ny)
for (iy in 1:ny) {
   for (ix in 1:nx) {
      ina[ix,iy] = nx - ix + ny - iy;
   }
}

#  Call the subroutine the specified number of times.

for (irpt in 1:nrpt) {
   out <- csub(ina,nx,ny)
}

#  Check the results.

error = FALSE
for (iy in 1:ny) {
   for (ix in 1:nx) {
      if (out[ix,iy] != ina[ix,iy] + ix + iy) {
         cat("Error",ix,iy,ina[ix,iy],out[ix,iy],"\n")
         error = TRUE
         break
      }
   }
   if (error) { break }
}

