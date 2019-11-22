//
//                           c r s s u b _ u n s a f e . r s
//
// Summary:
//    2D array access test subroutine in Rust, using unsafe code.
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
//    the straightforward array[iy][ix] syntax. This version is rather faster
//    uses Rust's 'unsafe' mode to access the elements of the arrays much
//    more efficiently.
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

pub fn csub (input_array: &Vec<Vec<f32>>,nx: usize,ny: usize,
                                      output_array: &mut Vec<Vec<f32>>) {

   //  The code is trivial, but note that the order of the loops matters, as
   //  the elements of each row are contiguous in memory so we want to work
   //  along them. This is generally more efficient. The code uses Rust's
   //  get_unchecked() array access method to access the array elements as
   //  efficiently as possible.

   unsafe{
      for iy in 0..ny as i32 {
         for ix in 0..nx as i32 {
            *output_array.get_unchecked_mut(iy as usize)
                                 .get_unchecked_mut(ix as usize) =
                 input_array.get_unchecked(iy as usize).
                                 get_unchecked(ix as usize) + (ix + iy) as f32;
         }
      }
   }
}

/*  ----------------------------------------------------------------------------

                  P r o g r a m m i n g   N o t e s

   o Thanks to Francois-Xavier Pineau for suggesting this code. Although he
     told me he wasn't a Rust expert, he clearly knows the language much better
     than I do.

   o It isn't really necessary to pass the array dimensions, as these are
     available using len() on the vectors. And doing so would make the code
     safer, too, given that no bounds checking is going to be performed.

*/
