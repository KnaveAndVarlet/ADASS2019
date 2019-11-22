//
//                           c r s s u b _ i t e r . r s
//
// Summary:
//    2D array access test subroutine in Rust, using iterators.
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
//    This version is for Rust, and uses vectors of 1D vectors to implement
//    a 2D array. Note that Rust uses row-major order; arrays are stored in
//    memory so that the second index varies fastest. The original version of
//    this routine, in crssub.rs, accessed the individual array elements using
//    the straightforward array[iy][ix] syntax. This version is rather more
//    idiomatic and uses Rust's iterator facilities, including zip, which
//    zips up two iterators, to work through two iterable items together.
//
// Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
//
// History:
//    28th Oct 2019. Original version. KS (based on code supplied by
//                   Francois-Xavier Pineau).
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

pub fn csub (input_array: &Vec<Vec<f32>>,_nx: usize,_ny: usize,
                                      output_array: &mut Vec<Vec<f32>>) {

   //  This code has two nested loops each of which uses two Rust iterators
   //  'zipped' together to work through the elements of the input and output
   //  vectors. In the outer loop the loop goes through the 1D vectors in
   //  the input and output arrays, and in the inner loop it goes through the
   //  individual elements of those 1D vectors.

   for (iy, (vx, rx)) in
           input_array.iter().zip(output_array.iter_mut()).enumerate() {
      for (ix, (e, r)) in vx.iter().zip(rx.iter_mut()).enumerate() {
         *r = (ix + iy) as f32 + *e;
      }
   }
}

/*  ----------------------------------------------------------------------------

                  P r o g r a m m i n g   N o t e s

   o Thanks to Francois-Xavier Pineau for suggesting this code. Although he
     told me he wasn't a Rust expert, he clearly knows the language much better
     than I do.

   o It isn't really necessary to pass the array dimensions, as these are
     available directly from the vectors. To keep the calling code for all
     the various Rust versions of this code, they've been left in, but are
     called _nx and _ny so the compiler doesn't complain about them being
     unused.

*/
