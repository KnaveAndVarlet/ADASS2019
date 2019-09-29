//
//                           c r s m a i n . r s
//
// Summary:
//    2D array access test main routine in Rust.
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
//    This version is for Rust. Rust supports multi-dimensional 'rectangular'
//    arrays as vectors of vectors, which can produce the same effect.
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
//    an input array and an output array. These can then be passed to a
//    subroutine, csub(), which is part of a separate module, crssub, that does
//    the actual work of setting the required values in the output array.
//
// Building:
//    It is enough to pass this one source file, crsmain.rs to the Rust
//    rustc compiler. It will automatically pick up the code for the crssub
//    module from a separate source file, crssub.rs, eg:
//
//    rustc crsmain.rs         or, for optimised code:
//    rustc -O -C target-cpu=native -C opt-level=3 crsmain.rs
//
// Invocation:
//    ./crsmain irpt nx ny
//
//    where:
//      irpt  is the number of times the subroutine is called - default 100000.
//      nx    is the number of columns in the array tested - default 2000.
//      ny    is the number of rows in the array tested - default 10.
//
//    Note that Rust use row-major order; arrays are stored in memory so that
//    the second index varies fastest. We want the array to be stored so that
//    elements of the same row are contiguous in memory, so we use the column
//    number (the X-value) as the second index when setting up the array.
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

use std::env;

mod crssub;

//  ----------------------------------------------------------------------------
//
//                             M a i n  P r o g r a m

fn main() {

   //  Set the array dimensions and repeat count either from the default values
   //  or values supplied on the command line. Collect the command line
   //  arguments into a string vector, then parse them if present, checking
   //  the results of the parsing. If invalid numbers are supplied, use the
   //  original default values.

   let mut nrpt = 100;
   let mut ny = 5;
   let mut nx = 4;
   let args: Vec<String> = env::args().collect();
   if args.len() > 1 {
      match args[1].parse::<usize>() {
         Ok(number) => nrpt = number,
         Err(_error) => println!("Repeats invalid, using {}",nrpt),
      };
      if args.len() > 2 {
         match args[2].parse::<usize>() {
            Ok(number) => ny = number,
            Err(_error) => println!("Rows invalid, using {}",ny),
         };
         if args.len() > 3 {
            match args[3].parse::<usize>() {
               Ok(number) => nx = number,
               Err(_error) => println!("Columns invalid, using {}",nx),
            };
         }
      }
   }
   println!("Arrays have {} rows of {} columns, repeats = {}",ny,nx,nrpt);

   //  Set up the input and output arrays, using single precision floating
   //  point values.

   let mut in_array = vec![vec![0.0f32; nx]; ny];
   let mut out_array = vec![vec![0.0f32; nx]; ny];

   //  We set the elements of the input array to some set of values - it doesn't
   //  matter what, just some values we can use to check the array manipulation
   //  on. This uses the sum of the row and column indices in descending order.
   //  We don't need to initialise the output array.

   for iy in 0..ny {
      for ix in 0..nx {
         in_array[iy][ix] = (nx - ix + ny - iy) as f32;
      }
   }

   //  Repeat the call to the manipulating subroutine.

   for _irpt in 1..=nrpt {
      crssub::csub (&in_array,nx,ny,&mut out_array);
   }

   //  Check that we got the expected results.

   'check_loop :
   for iy in 0..ny {
      for ix in 0..nx {
         if out_array[iy][ix] != (in_array[iy][ix] + (ix + iy) as f32) {
            println! ("Error {} {} {} {}",
                           ix,iy,out_array[iy][ix],in_array[iy][ix]);
            break 'check_loop;
         }
      }
   }

}

/*  ----------------------------------------------------------------------------

                  P r o g r a m m i n g   N o t e s

   o The code checks that the command line arguments are valid numbers, but
     doesn't check that they're not zero. It is only a test routine. It only
     checks they're valid numbers because I was trying to understand the
     way to do that, using match to check the parse() result.

   o The code can be made to run faster by using a 1D array and doing the
     index calculations in the code, but that seems to defeat the point of
     this test. (Indeed, I've seen comments that suggest this as the best
     way to speed up 2D array access in Rust. Perhaps this will change as
     the compiler matures, as it did with Swift.)

*/
