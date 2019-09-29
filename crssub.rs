//
//                           c r s s u b . r s
//
// Summary:
//    2D array access test subroutine in Rust.
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
//    memory so that the second index varies fastest.
//
// Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
//
// History:
//    13th Sep 2019. First properly commented version. KS.
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
   //  along them. This is generally more efficient.

    for iy in 0..ny {
       for ix in 0..nx {
          output_array[iy][ix] = input_array[iy][ix] + (ix + iy) as f32;
       }
    }
}

/*  ----------------------------------------------------------------------------

                  P r o g r a m m i n g   N o t e s

   o The Rust compiler appears to generate bounds checking even when the code
     is flagged as unsafe, and even under optimisation. This is in keeping with
     the 'safety first' nature of Rust. Looking at the generated assembler, it
     doesn't look as if the checks are a large overhead, but this may change
     as the compiler matures and improves and the gemerated code gets faster.
     It may even be that the checks are only done at the start of each loop
     I've not gone deep enough into the generated assembler to be sure.

   o It isn't really necessary to pass the array dimensions, as these are
     available using len() on the vectors. In fact, in principle using len()
     to get the loop limits might convince the compiler that bounds checking
     isn't necessary.

*/
