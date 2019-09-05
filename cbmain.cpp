//
//                           c b m a i n . c p p
//
// Summary:
//    2D array access test main routine in C++, using Boost 2D arrays.
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
//    This version is for C++, and uses the Boost multi-dimensional array
//    facilities. This main program is intended to be used in conjunction with
//    the subroutine subr() whose code is found in cbsub.cpp. This main routine
//    creates two Boost Array2DType arrays. These allows elements to be accessed
//    simply as In[Iy][Ix] or Out[Iy][Ix], where Ix and Iy are of type
//    Index2dType, and this works both in this main code and in the called
//    subroutine.
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
//    an input array and an output array, both as Boost Array2DType arrays.
//    These can then be passed to a subroutine, subr() that does the actual work
//    of setting the required values in the output array. The main routine and
//    the subroutine have to be in different files and compiled separately, or
//    at high levels of optimisation a C++ compiler may optimise away the whole
//    subroutine. The called routine must have been written to expect to be
//    passed Array2DType arrays, just as the code in the matching cnrsub.cpp
//    has been.
//
// Building:
//    The file containing the implementation of the subr() routine has to be
//    compiled separately, using the compiler being tested and with the options
//    being tested. Then this main program needs to be linked against that
//    compiled subroutine. For example, something like:
//
//    c++ -c -O -o cbsub.o cbsub.cpp
//    c++ -o cbmain -O cbmain.cpp cbsub.o
//
// Invocation:
//    ./cbmain irpt nx ny
//
//    where irpt  is the number of times the subroutine is called - default 1.
//          nx    is the number of columns in the array tested - default 2000.
//          ny    is the number of rows in the array tested - default 10.
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
//    10th Aug 2019. First properly commented version. KS.
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

//#define BOOST_DISABLE_ASSERTS
#include "boost/multi_array.hpp"
#include <cassert>

typedef boost::multi_array<float,2> Array2DType;
typedef Array2DType::index Index2DType;

//  subr() is the subroutine that does the actual array manipulation. It has to
//  be compiled separately to prevent a compiler optimising it away entirely.

void subr (Array2DType& In, int Nx, int Ny, Array2DType& Out);

int main (int argc, char* argv[])
{
   //  Set the array dimensions and repeat count either from the default values
   //  or values supplied on the command line.
   
   int Nrpt = 1000;
   int Nx = 2000;
   int Ny = 10;
   if (argc > 1) Nrpt = atoi(argv[1]);
   if (argc > 2) Nx = atoi(argv[2]);
   if (argc > 3) Ny = atoi(argv[3]);

   //  Create the input and output 2D arrays.
   
   Array2DType In(boost::extents[Ny][Nx]);
   Array2DType Out(boost::extents[Ny][Nx]);
   
   //  We set the elements of the input array to some set of values - it doesn't
   //  matter what, just some values we can use to check the array manipulation
   //  on. This uses the sum of the row and column indices in descending order.
   //  We don't need to initialise the output array.

   for (Index2DType Iy = 0; Iy < Ny; Iy++) {
      for (Index2DType Ix = 0; Ix < Nx; Ix++) {
         In[Iy][Ix] = float(Nx - Ix + Ny - Iy);
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
   for (Index2DType Iy = 0; Iy < Ny; Iy++) {
      for (Index2DType Ix = 0; Ix < Nx; Ix++) {
         if (Out[Iy][Ix] != In[Iy][Ix] + Ix + Iy) {
            Error = true;
            printf ("Error Out[%ld][%ld] = %f, not %f\n",Iy,Ix,
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

   o The #define BOOST_DISABLE_ASSERTS line makes a big difference to the
     performance of the code in cbsub.cpp, but probably doesn't make much
     difference here. But if it's in cbsub.cpp it should probably be in this
     routine too. It will make the initial array initialisation and the final
     validation checks run much faster, although those shouldn't be significant
     except at very low values of the repeat count parameter. This is commented
     out here, but the same effect can be obtained by compiling with the flag
     -D BOOST_DISABLE_ASSERTS and this makes it easier to automate testing
     with this enabled and disabled.
 
*/
