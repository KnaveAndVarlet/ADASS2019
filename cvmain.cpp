//
//                           c v m a i n . c p p
//
// Summary:
//    2D array access test main routine in C++, using STL vectors.
//
// Introduction:
//    This is a test program written as part of a study into how well different
//    languages handle accessing elements of 2D rectangular arrays - the sort of
//    thing that are common in astronomy and similar scientific disciplines.
//    This can also be used to see how efficient different ways of coding the
//    same problem can be in the different languages, and to see what effect
//    such things as compilation options - particularly optimisation options -
//    have.
//
//    The problem chosen is a trivial one: given an 2D array, add to each
//    element the sum of its two indices and return the result in a second,
//    similarly-sized array. This is harder to optimise away than, for example,
//    simply doing an element by element copy of the array, but is generally
//    easy to code. It isn't a perfect test (something brought out by the
//    study), but it does produce some interesting results.
//
// This version:
//    This version is for C++, and uses STL vectors, implementing a 2D array
//    using a vector of a vector of floats. This routine expects to be passed
//    two arrays created as "<vector<vector<float> >" (C++ requires the space
//    between the two '>' characters. This allows elements to be accessed
//    simply as In[Iy][Ix] or Out[Iy][Ix], and this works both in the calling
//    routine and the subroutine.
//
// Structure:
//    Most test progrsms in this study code the basic array manipulation in a
//    single subroutine, then create the original input array, and pass that,
//    together with the dimensions of the array, to that subroutine, repeating
//    that call a large number of times in oder to be able to get a reasonable
//    estimate of the time taken. Then the final result is checked against the
//    expected result.
//
//    This code follows that structure. This main routine sets up two 2D arrays,
//    an input array and an output array, both as vectors of vectors of floats.
//    These can then be passed to a subroutine, subr() that does the actual work
//    of setting the required values in the output array. The main routine and
//    the subroutine have to be in different files and compiled separately, or
//    at high levels of optimisation a C++ compiler may optimise away the whole
//    subroutine. The called routine must have been written to expect to be
//    passed these "<vector<vector<float> >" arrays, and this is the case for
//    the code in the matching cvrsub.cpp file.
//
// Building:
//    The file containing the implementation of the subr() routine has to be
//    compiled separately, using the compiler being tested and with the options
//    being tested. Then this main program needs to be linked against that
//    compiled subroutine. For example, something like:
//
//    c++ -c -O -o cvsub.o cvsub.cpp
//    c++ -o cvmain -O cvmain.cpp cvsub.o
//
// Invocation:
//    ./cvmain irpt nx ny
//
//    where
//      irpt  is the number of times the subroutine is called - default 100000.
//      nx    is the number of columns in the array tested - default 2000.
//      ny    is the number of rows in the array tested - default 10.
//
//    Note that C/C++ use row-major order; arrays are stored in memory so that
//    the second index varies fastest. We want the array to be stored so that
//    elements of the same row are contiguous in memory, and although Boost can
//    set up arrays with either row-major or column-major order, row-major is
//    the default and is used here.
//
// Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
//
// History:
//    22nd Sep Jul 2019. Original version. KS.
//
// Copyright (c) 2019 Knave and Varlet
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <stdlib.h>
#include <stdio.h>
#include <vector>

using std::vector;

//  subr() is the subroutine that does the actual array manipulation. It has to
//  be compiled separately to prevent a compiler optimising it away entirely.

void subr (vector<vector<float> > &In,
               int Nx,int Ny,vector<vector<float> >&Out);

int main (int argc, char* argv[])
{
   //  Set the array dimensions and repeat count either from the default values
   //  or values supplied on the command line.
   
   int Nrpt = 100000;
   int Nx = 2000;
   int Ny = 10;
   if (argc > 1) Nrpt = atoi(argv[1]);
   if (argc > 2) Nx = atoi(argv[2]);
   if (argc > 3) Ny = atoi(argv[3]);

   //  Create the input and output 2D arrays. This uses the fill constructor
   //  for the vector container, setting each element of the In and Out arrays
   //  to a 1D vector Nx elements long. Initialise the input rows - it doesn't
   //  matter what, just some values we can use to check the array manipulation
   //  on. This uses the sum of the row and column indices in descending order.
   //  We don't need to initialise the output array rows.
   
   vector< vector<float> > In(Ny,vector<float>(Nx));
   vector< vector<float> > Out(Ny,vector<float>(Nx));
   for (int Iy = 0; Iy < Ny; Iy++) {
      for (int Ix = 0; Ix < Nx; Ix++) {
         In[Iy][Ix] = Nx - Ix + Ny - Iy;
      }
   }
   printf ("Arrays have %d rows of %d columns, repeats = %d\n",Ny,Nx,Nrpt);

   //  Repeat the call to the manipulating subroutine. A compiler can't optimise
   //  this out, as it doesn't know that the results will be the same every
   //  time.

   for (int Loop = 0; Loop < Nrpt; Loop++) {
      subr (In,Nx,Ny,Out);
   }

   //  Check that we got the expected results.
   
   bool Error = false;
   for (int Iy = 0; Iy < Ny; Iy++) {
      for (int Ix = 0; Ix < Nx; Ix++) {
         if (Out[Iy][Ix] != In[Iy][Ix] + Ix + Iy) {
            Error = true;
            printf ("Error Out[%d][%d] = %f, not %f\n",Iy,Ix,
                                   Out[Iy][Ix],float(In[Iy][Ix] + Ix + Iy));
            break;
         }
      }
      if (Error) break;
   }

   return 0;
}

// -----------------------------------------------------------------------------

/*                    P r o g r a m m i n g  N o t e s

   o  Note that this code creates all the row vectors separately. The data for
      all the rows will not be contiguous - or at least, there's no reason to
      suppose it will be. This doesn't seem to affect the optimisations
      possible in the subr() routine, which are mostly to do with handling
      single rows efficiently, but it might limit what can be done with
      different processing code. (A straight copy of one array to another
      couldn't collapse down to a single memcpy() call, for example.)
 
*/
