#!/usr/bin/env python
#                           c s u b n p - n u m b a . p y
#
#  Summary:
#     2D array access test in Python, using numpy array element access & numba.
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
#     This version is for Python, using numba jit compilation, and is a
#     relatively straightforward implementation, accessing the individual
#     elements of a numpy array directly using the standard (but usually
#     inefficient) array[iy,ix] syntax that numpy supports. However, in this
#     case, the subbroutine doing the bulk of the work is given the numba
#     jit decorator, meaning it will be sped up using the LLVM compiler for
#     just-in-time compilation. This code can be run under Python3 or any
#     version of Python2 that supports the 'from __future__ import' line at
#     the start of the code, so long as the system has numba installed. Note
#     that this is not really how you should be using numpy, which is designed
#     to provide efficient operations on arrays and vectors, not on individual
#     array elements, but it turns out that numba speeds this up remarkably,
#     enough to make it a very feasible way to use numpy.
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
#     called subroutine in the same piece of code, as Python doesn't optimise
#     out the call in that case.
#
#  Invocation:
#     ./csubnp-numba.py irpt nx ny
#
#     or, depending on how Python and/or Python3 have been set up:
#
#     python csubnp.py irpt nx ny          or
#     python3 csubnp.py irpt nx ny
#
#     where
#        irpt  is the number of times the subroutine is called - default 500000.
#        nx    is the number of columns in the array tested - default 2000.
#        ny    is the number of rows in the array tested - default 10.
#
#     Note that Python uses row-major order, at least by default in numpy;
#     arrays are stored in memory so that the second index varies fastest.
#
#  Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
#
#  History:
#     23rd Oct 2019. Original version, based on csubnp.py with numba decorator
#                    added to the subr() routine, as suggested by Francesco
#                    Pierfederici. KS.
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

#  This line provides support for the Python 3 features in the code (mainly
#  just the use of print() as a function call) when Python2 is being used.

from __future__ import (print_function,division,absolute_import)

import numba
import numpy
import sys

#  --------------------------------------------------------------------------------
#
#  The subr() subroutine.
#
#  subr is a subroutine that is passed a two-dimensional floating point array
#  ina, with dimensions nx by ny, together with a second, output array, out,
#  of the same dimensions. It returns with each element of out set to the
#  contents of the corresponding element if ina plus the sum of its two indices.
#  The intent is to try to see how well any given language handles access to
#  individual elements of a 2D array,

@numba.jit
def subr(ina,nx,ny,out):
   for iy in range(ny):
      for ix in range(nx):
         out[iy,ix] = ina[iy,ix] + ix + iy

#  -----------------------------------------------------------------------------

#  The main routine.

#  Get the command line arguments, and determine the array size and the number
#  of times to repeat the subroutine call.

ny = 10
nx = 2000
nrpt = 100
if (len(sys.argv) > 1):
   nrpt = int(sys.argv[1])
   if (len(sys.argv) > 2):
      nx = int(sys.argv[2])
      if (len(sys.argv) > 3):
         ny = int(sys.argv[3])

#  Create the input array and output arrays. We set the elements of the input
#  array to some set of values - it doesn't matter what, just some values we
#  can use to check the array manipulation on. This uses the sum of the row and
#  column indices in descending order. The values in the output array don't
#  matter, so we fill it with zeros.

ina = numpy.zeros((ny,nx))
for iy in range(ny):
   for ix in range(nx):
      ina[iy,ix] = nx - ix + ny - iy

out = numpy.zeros((ny,nx))

print ("Arrays",nx,"by",ny,"count",nrpt)

#  Call the subroutine the specified number of times.

for irpt in range(nrpt):
   subr(ina,nx,ny,out)

#  Check the results.

error = False
for iy in range(ny):
   for ix in range(nx):
      if (out[iy,ix] != (ina[iy,ix] + (ix + iy))):
         print ("Error: ",out[iy,ix],ix,iy,ina[iy,ix])
         error = True
         break
   if (error) : break

#  -----------------------------------------------------------------------------

#                        P r o g r a m m i n g  N o t e s
#
#  o  I only have numba installed on my test machine for Python3, so this code
#     has not been tested under Python 2.

