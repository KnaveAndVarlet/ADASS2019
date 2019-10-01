//
//                           c k m a i n . c p p
//
// Summary:
//    2D array access test main routine in C++, using an ArrayManager class.
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
//    This version is for C++. C++ does not support multi-dimensional arrays
//    as a specific type. It does support arrays of arrays, and it is possible
//    to declare a 2D array as, for example, float Array[NY][NX] (although NX &
//    NY have to be constants). However, even in this case, although the routine
//    that declares such an array can then access individual elements using
//    for example, Array[Iy][Ix], C++ provides no way to pass such an array to
//    a subroutine and allow the code in the subroutine to do the same. There
//    are a number of ways around this, and this main routine uses an
//    ArrayManager class that packages up the method popularised in the book
//    'Numerical Recipes in C', where what is passed to the subroutine is the
//    address of an array whose elements contain the addresses of the start of
//    each row of the 2D array. This allows the called routine to refer to
//    elements of the 2D array using the convenient Array[Iy][Ix] form. The
//    advantage of the ArrayManager is that it simplifies the potentially
//    error-prone setting up of the address arrays. Note that 2D C/C++ arrays
//    are held in memory so that the data for each row is in contiguous memory
//    locations.
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
//    an input array and an output array, and also sets up the arrays of row
//    addresses for each. These can then be passed to a subroutine, subr()
//    that does the actual work of setting the required values in the output
//    array. The main routine and the subroutine have to be in different files
//    and compiled separately, or at high levels of optimisation a C++ compiler
//    may realise that it can optimise out the entire subroutine. The subroutine
//    must have been written to suit the Numerical Recipes way of handling
//    arrays, such as the code in nrsub.cpp, which works just the same with
//    this test routine as it does with cnrmain.cpp - which isn't surprising, as
//    both are implementing the same Numerical Recipes scheme.
//
// Building:
//    The file containing the implementation of the subr() routine has to be
//    compiled separately, using the compiler being tested and with the options
//    being tested. Then this main program needs to be linked against that
//    compiled subroutine. For example, something like:
//
//    c++ -c -O -o cnrsub.o cnrsub.cpp
//    c++ -o ckmain -O ckmain.cpp cnrsub.o
//
// Invocation:
//    ./ckmain irpt nx ny
//
//    where
//       irpt  is the number of times the subroutine is called - default 1000.
//       nx    is the number of columns in the array tested - default 2000.
//       ny    is the number of rows in the array tested - default 10.
//
//    Note that C/C++ use row-major order; arrays are stored in memory so that
//    the second index varies fastest. We want the array to be stored so that
//    elements of the same row are contiguous in memory, so we use the column
//    number (the X-value) as the second index when setting up the array.
//
// Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
//
// History:
//    16th Aug 2019. First properly commented version. KS.
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

#include "ArrayManager.h"

typedef float** Array2DType; 
typedef int Index2DType;

//  subr() is the subroutine that does the actual array manipulation. It has to
//  be compiled separately to prevent a compiler optimising it away entirely.

void subr (Array2DType In, int Nx, int Ny, Array2DType Out);

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
   
   //  Create the input and output 2D arrays, using the ArrayManager class
   //  defined in ArrayManager.h/.cpp.
   
   ArrayManager Manager;
   Array2DType In = (Array2DType) Manager.Malloc2D(sizeof(float),Ny,Nx);
   Array2DType Out= (Array2DType) Manager.Malloc2D(sizeof(float),Ny,Nx);
   
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

   o I did originally write a cksub.cpp to make a pair with this test routine,
     but then realised it was exactly the same code as in cnrsub.cpp, which
     isn't surprising, as they're both intended to handle the same type of
     arrays. Also unsurprising is that both ckmain/cnrsub and cnrmain/cnrsub
     produce identical timings (within the margin of error - no two runs ever
     give exactly the same clock on the wall time).
 
   o The prototype given for subr(), namely:
     void subr (Array2DType In, int Nx, int Ny, Array2DType Out);
     isn't exactly the same as that in cnrsub.cpp, which is:
     void subr (float* In[], int Nx, int Ny, float* Out[]);
     but functionally they are exactly the same.
 
   o I see this code defines Array2DType and Index2DType, just for tidiness,
     and it may be confusing that these happen to be exactly the same type names
     as are used by Boost. However, the definitions are different, and I
     probably ought to use different type names in this code. (I can't remember
     if using the same names was deliberate or just coincidence.)

*/

