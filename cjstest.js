//                              c j s t e s t . j s
//
// Summary:
//    2D array access test main routine in Javascript.
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
//    This version is for Javascript. Like C, Javascript does not support mult-
//    dimensional arrays as a specific type. It does support arrays of arrays,
//    and it is possible to set up a 2D array in this way. The result is not
//    unlike the scheme used in 'Numerical Recipies in C' - what looks like a
//    2D array is actually an array of 1D arrays, but the Array[Iy][Ix] syntax
//    works nicely and is arguably easier to set up than in C++.
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
//    subroutine, subr() that does the actual work of setting the required
//    values in the output array. The main routine and the subroutine do not
//    have to be compiled separately, as Javascript does not appear to optimise
//    away the subroutine call.
//
// Invocation:
//    This can be run using Node.js (the 'node' utility) from the command line:
//
//    node cjstest.js irpt nx ny
//
//    where:
//      irpt  is the number of times the subroutine is called - default 1000.
//      nx    is the number of columns in the array tested - default 2000.
//      ny    is the number of rows in the array tested - default 10.
//
//    Note that Javascript uses row-major order; arrays are stored in memory so
//    that the second index varies fastest. (This follows from naturally from
//    'array of arrays' way of handling multi-dimensional arrays.
//
// Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
//
// History:
//    21st Aug 2019. First properly commented version. KS.
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

//  ----------------------------------------------------------------------------
//
//  The subr{} subroutine.
//
//  subr{} is a subroutine that is passed a two-dimensional floating point
//  array inp, with dimensions nx by ny, together with an output array, out,
//  of the same dimensions. It returns with each element of out set to the
//  contents of the corresponding element if inp plus the sum of its two
//  indices. The intent is to try to see how well any given language handles
//  access to individual elements of a 2D array,

function subr(inp,nx,ny,out) {
   for (var iy = 0; iy < ny; iy++) {
      for (var ix = 0; ix < nx; ix++) {
         out[iy][ix] = inp[iy][ix] + ix + iy;
      }
   }
}

//  ----------------------------------------------------------------------------
//
//                             M a i n  P r o g r a m

//  Set the array dimensions and repeat count either from the default values
//  or values supplied on the command line.

var nargs = process.argv.length;
var ny = 10;
var nx = 2000;
var nrpt = 1000;
if (nargs > 2) nrpt = parseInt(process.argv[2]);
if (nargs > 3) nx = parseInt(process.argv[3]);
if (nargs > 4) ny = parseInt(process.argv[4]);

console.log ("Arrays,",ny,"rows of",nx,"columns, repeat = ",nrpt);

//  Create the input and output arrays. We have to create the inp and out
//  arrays as arrays ny long that hold the ny 1D arrays that form the rows
//  of the 2D arrays. We set the elements of the input array to some set of
//  values - it doesn't matter what, just some values we can use to check the
//  array manipulation on. This uses the sum of the row and column indices in
//  descending order. The output array is just set to zeros, although that
//  doesn't matter at all.

var inp = new Array(ny);
var out = new Array(ny);
for (var iy = 0; iy < ny; iy++) {
   inp[iy] = new Array(nx);
   out[iy] = new Array(nx);
   for (var ix = 0; ix < nx; ix++) {
      inp[iy][ix] = nx - ix + ny - iy;
      out[iy][ix] = 0.0;
   }
}

//  Call the subroutine that will do the real work, as many times as specified.

for (var loop = 0; loop < nrpt; loop++) subr(inp,nx,ny,out);

//  Check that we got the expected results.

var Error = false;
TestLoop:
   for (var iy = 0; iy < ny; iy++) {
      for (var ix = 0; ix < nx; ix++) {
         if (out[iy][ix] != (inp[iy][ix] + ix + iy)) {
            console.log("Error:",out[iy][ix],iy,ix,inp[iy][ix]);
            Error = true;
            break TestLoop;
         }
      }
   }
