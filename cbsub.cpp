//
//                              c b s u b . c p p
//
// Summary:
//    2D array access test subroutine in C++, using Boost 2D arrays.
//
// Introduction:
//    This is a test routine written as part of a study into how well different
//    languages handle accessing elements of 2D rectangular arrays. This routine
//    is passed a 2D array (In) with Ny rows and Nx columns, and another 2D
//    array of the same size (Out). It modifies Out so so each element of Out
//    is set to the value of the corresponding element of In, plus the sum of
//    the two index values for the element - ie plus the row number and the
//    column number. The idea is trivial, but the operation isn't completely
//    trivial to optimise, and the intention is to see how well this runs when
//    compiled using different compilers, or using different options.
//
// This version:
//    This version is for C++, and uses the Boost multi-dimensional array
//    facilities. This routine expects to be passed two arrays created as Boost
//    Array2DType arrays. This allows elements to be accessed simply
//    as In[Iy][Ix] or Out[Iy][Ix], where Ix and Iy are of type Index2dType.
//    This routine is designed to be called from the main test program in
//    cbmain.cpp. See the comments in that code for more details.
//
//    Note that C/C++ use row-major order; arrays are stored in memory so that
//    the second index varies fastest. Boost is flexible and can use either
//    row-major or column-major order, but defaults to row-major order and this
//    routine assumes this is the order being used. This means the array is
//    stored so that elements of the same row are contiguous in memory, and we
//    expect sequential accesses to contiguous elements to be more effcient - ie
//    when the second array index varies fastest.
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

void subr (Array2DType& In, int Nx, int Ny, Array2DType& Out)
{
   for (Index2DType Iy = 0; Iy < Ny; Iy++) {
      for (Index2DType Ix = 0; Ix < Nx; Ix++) {
         Out[Iy][Ix] = In[Iy][Ix] + Ix + Iy;
      }
   }
}

// -----------------------------------------------------------------------------

/*                    P r o g r a m m i n g  N o t e s

   o The #define BOOST_DISABLE_ASSERTS line makes a big difference to the
     performance. Without it, Boot inserts 'assert' line that essentially
     perform bounds checking when an array element is accessed. This is
     great for testing, but terrible for performance, especially at low levels
     of optimisation. This is commented out here, but the same effect can be
     obtained by compiling with the flag -D BOOST_DISABLE_ASSERTS and this
     makes it easier to automate testing with asserts enabled and disabled.
 
   o The use of templates puts most of the burden for generating efficient code
     on the shouldrs of the compiler. It makes the optimisation settings quite
     critical for good performance.
 
*/
