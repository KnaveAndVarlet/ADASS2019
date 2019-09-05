//
//                           c s u b . c p p
//
// Summary:
//    2D array access test subroutine in C++, using static C arrays.
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
//    This version is for C++, and is designed for the case where each of the In
//    and Out arguments it is passed is simply the address of the start of an
//    area of memory that holds Nx by Ny floating point numbers. This would be
//    the case, for example, if the arrays in question were allocated statically
//    in the calling routine, eg as float In[NY][NX], Out[NY][NX] where NX and
//    NY were constants known at the time of compilation. Note that in this case
//    the calling routine is able to refer to individual elements using code
//    such as In[Iy][Ix], but a subroutine it calls cannot do this. (This is one
//    of the frustrating things about handing multi-dimensional arrays in C/C++
//    subroutines.) It would also be the case if the arrays were allocated
//    dynamically using a call to a routine such as malloc(). This routine is
//    designed to be called from the main test program in cmain.cpp (which uses
//    malloc(), simply to allow easier testing with different arrays sizes, but
//    could equally well have used static arrays. See the comments in cmain.cpp
//    for more details.
//
//    Note that C/C++ use row-major order; arrays are stored in memory so that
//    the second index varies fastest. We want the array to be stored so that
//    elements of the same row are contiguous in memory, so we use the column
//    number (the X-value) as the second index when setting up the array. (At
//    least, that's how we'd do it in the main routine if the array were
//    declared statically. As far as this subroutine is concerned, all we have
//    is a block of memory whose start address we know, and we have to handle
//    the addressing ourselves.)
//
// Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
//
// History:
//     7th Aug 2019. First properly commented version. KS.
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

void subr (float* In, int Nx, int Ny, float* Out)
{
   //  We have to handle the array element access ourselves. Assuming row-major
   //  order, the In[Iy][Ix] has an offset ((Iy * Nx) + Ix) from the start of
   //  the array. We have to use that, and hope the compiler can optimise this.
   
   for (int Iy = 0; Iy < Ny; Iy++) {
      for (int Ix = 0; Ix < Nx; Ix++) {
         Out[Iy * Nx + Ix] = In[Iy * Nx + Ix] + Ix + Iy;
      }
   }
}
