//
//                           c v s u b . c p p
//
// Summary:
//    2D array access test subroutine in C++, using an STL vector of vectors.
//
// Introduction:
//    This is a test routine written as part of a study into how well different
//    languages handle accessing elements of 2D rectangular arrays. This routine
//    is passed a 2D array (In) with Ny rows and Nx columns, and another 2D
//    array of the same size (Out). It modifies Out so so each element of Out
//    is set to the value of the corresponding element of In, plus the sum of the
//    two index values for the element - ie plus the row number and the column
//    number. The idea is trivial, but the operation isn't completely trivial
//    to optimise, and the intention is to see how well this runs when compiled
//    using different compilers, or using different options.
//
// This version:
//    This version is for C++, and uses STL vectors, implementing a 2D array
//    using a vector of a vector of floats. This routine expects to be passed
//    two arrays created as "<vector<vector<float> >" (C++ requires the space
//    between the two '>' characters. This allows elements to be accessed
//    simply as In[Iy][Ix] or Out[Iy][Ix]. This routine is designed to be
//    called from the main test program in cvmain.cpp. See the comments in that
//    code for more details.
//
//    Note that C/C++ use row-major order; arrays are stored in memory so that
//    the second index varies fastest. We want the array to be stored so that
//    elements of the same row are contiguous in memory, so we use the column
//    number (the X-value) as the second index when setting up the 'array'.
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
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <vector>

using std::vector;

void subr (vector<vector<float> > &In,
             int Nx,int Ny,vector<vector<float> > &Out)
{
   for (int Iy = 0; Iy < Ny; Iy++) {
      for (int Ix = 0; Ix < Nx; Ix++) {
         Out[Iy][Ix] = In[Iy][Ix] + Ix + Iy;
      }
   }
}

// -----------------------------------------------------------------------------

/*                    P r o g r a m m i n g  N o t e s

   o This code was only added to the series of tests towards the very end. I'd
     assumed anything using STL templates would be relatively slow because of
     the overheads of the containers and template code can be hard for a
     compiler to optimise. As it turned out - to my surprise - it was very
     fast. I assume once the compiler realises it's dealing with a row of
     floats all contiguous in memory (which I'd thought it might not) then it
     can generate quite efficient code - as efficient as any other code for
     dealing with a contiguous row of floats.
 
*/
