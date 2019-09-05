#! /usr/bin/env Rscript

#                          c s u b r e f . r
#
#  Summary:
#     2D array access test in R, using a reference class containing an array.
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
#     This version is for R. It isn't a good way of coding the problem in R, but
#     it is something of an object lesson in how the way a problem is coded can
#     affect the efficiency. It was written in good faith, hoping to get a small
#     speed improvement over the straightforward R code in csub.r. Originally,
#     csub.r created an output array in the main program and passed that to the
#     csub() routine to receive the result. This is how a C or Fortran
#     programmer (ie me) naturally thinks of implementing this. However, as R
#     does not modify its arguments, this doesn't work. If you modify a passed
#     array, R actually modifies a local copy, and if you want the calling
#     routine to see the results, you have to pass it back as the function
#     result. R does however provide the concept of reference classes, and if
#     you pass one of these it is in fact passed 'by reference' and the
#     subroutine can modify it in situ. It seemed this might speed up the
#     process slightly, but avoiding generation of the local array. In fact, it
#     slows things down hugely. See the programming notes at the end for more.
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
#     the call in that case. In this case, the subroutine is passed an instance
#     of a reference class that contains the output array to be modified by the
#     subroutine. The input array is passed quite normally.
#
#  Invocation:
#     ./csubref irpt nx ny
#
#     where irpt  is the number of times the subroutine is called - default 1.
#           nx    is the number of columns in the array tested - default 2000.
#           ny    is the number of rows in the array tested - default 10.
#
#     Note that R uses column-major order; arrays are stored in memory so that
#     the first index varies fastest.
#
#  Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
#
#  History:
#     2nd Jul 2019. First properly commented version. KS.
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
#  The csub() subroutine.
#
#  csub is a subroutine that is passed a two-dimensional floating point array
#  ina, with dimensions nx by ny. It returns a two dimensional array of the same
#  dimensions with each element set to the contents of the corresponding element
#  in ina plus the sum of its two indices. The intent is to try to see how well
#  any given language handles access to individual elements of a 2D array.
#
#  This version is passed an instance of a reference class called 'out', which
#  has an element called 'data' which is an array that is set to the result of
#  the operation. This avoids dynamic creation of a local array that can be
#  passed back to the calling routine as the return value of the subroutine, but
#  it turns out to be horribly slow.

csub <- function(ina,nx,ny,out) {
   for (iy in 1:ny) {
      for (ix in 1:nx) {
         out$data[ix,iy] <- ina[ix,iy] + ix + iy
      }
   }
}

#  -----------------------------------------------------------------------------

#  The main routine.

#  Get the command line arguments, and determine the array size and the number
#  of times to repeat the subroutine call.

args <- commandArgs(TRUE)
nx = 2000
ny = 10
nrpt = 1
if (length(args) > 0) {
   nrpt = as.integer(args[1])
   if (length(args) > 1) {
      nx = as.integer(args[2])
      if (length(args) > 2) {
         ny = as.integer(args[3])
      }
   }
}
cat ("Arrays have",ny,"rows of",nx,"columns, repeats = ",nrpt,"\n")

#  Create the input array. We set the elements of the input array to some set
#  of values - it doesn't matter what, just some values we can use to check the
#  array manipulation on. This uses the sum of the row and column indices in
#  descending order.

ina <- matrix(0.0,nx,ny)
for (iy in 1:ny) {
   for (ix in 1:nx) {
      ina[ix,iy] = nx - ix + ny - iy;
   }
}

#  Create the output array as an element of a member of a reference class,
#  so there should only be one instance of it that will be passed to csub()
#  by reference.

ref_matrix <- setRefClass(
   "ref_matrix",fields = list(data  = "matrix"),
   methods = list(
      setData = function(ix,iy,value) {
         data[ix,iy] <<- value
      }
   )
)
out <- ref_matrix(data = matrix(0.0,nx,ny))

#  Unommenting this tracemem() call will show just how much copying actually
#  does take place - and this scheme was inteded to avoid the need to copy
#  the out array.
#
#  tracemem(out$data)

#  Call the subroutine the specified number of times.

for (irpt in 1:nrpt) {
   csub(ina,nx,ny,out)
}

#  Check the results.

error = FALSE
for (iy in 1:ny) {
   for (ix in 1:nx) {
      if (out$data[ix,iy] != ina[ix,iy] + ix + iy) {
         cat("Error",ix,iy,out$data[ix,iy],"\n")
         error = TRUE
         break
      }
   }
   if (error) { break }
}

#  -----------------------------------------------------------------------------

#                     P r o g r a m m i n g  N o t e s
#
#  o  I tried using access methods defined as part of the class to access
#     the array elements, but that made no obvious improvement on the execution
#     time. That's what the setData() method is doing in the class definition -
#     it isn't actually used by this code and could be removed.
#
#  o  Note that the checking loop runs fast, whereas the loop in csub() - which
#     modifies the elements of the array as opposed to just reading them - is
#     very slow. I suspect that at some point the implementation is copying the
#     whole matrix in order to modify one element and then copying it back!
#     When I say slow, I mean really slow. I had to set nrpt = 1 to get this to
#     run in a sensible amount of time. What's more, it goes up almost linearly
#     if I make the out array bigger - eg using
#         out <- ref_matrix(data = matrix(0.0,nx * 10,ny))
#     but still only access the nx by ny subset of the array. It looks as if the
#     WHOLE array is being copied each time a value is assigned to an element of
#     the array! Adding the #tracemem(out$data) call actually shows this
#     happening. I think this must be a candidate for 'slowest' way of
#     implementing the csub function in any language.
#
#  o  The problem is to do with modifying the elements of the reference class,
#     not with passing it to a subroutine. If I in-line the csub() call by hand,
#     ie replacing it by:
#        for (iy in 1:ny) {
#           for (ix in 1:nx) {
#              out$data[ix,iy] <- ina[ix,iy] + ix + iy
#           }
#        }
#     it runs just as slowly.
#
#  o  There is something of an explanation here:
#     https://r-devel.r-project.narkive.com/8KtYICjV/
#                       rd-copy-on-assignment-to-large-field-of-reference-class
#     Note that I split up the URL so the line isn't too long.
#
#  o  I have a StackOverflow question relating to this behaviour, but so far
#     nobody has suggested a way to bypassing the copying that takes place.
#     https://stackoverflow.com/questions/56746989/
#                 how-to-speed-up-writing-to-a-matrix-in-a-reference-class-in-r
