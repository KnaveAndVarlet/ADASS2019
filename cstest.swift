//
//                               c s t e s t . s w i f t
//
// Summary:
//    2D array access test main routine in Swift.
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
//    This version is for Swift. Swift does not support rectangular multi-
//    dimensional arrays as a specific type, but it does support arrays of
//    arrays, and it is possible to delcare a 2D array as an array of 1D arrays.
//    It is then possible to pass such an array to a subroutine and to address
//    individual elements using an Array[Iy][Ix] syntax. Early versions of
//    Swift were very inefficient in handling access to elements of such arrays,
//    and there were a number of workarounds that were faster, if more awkward.
//    However, from Swift 4, most of the inefficiencies seem to have been
//    dealt with, and this straightforward way of accessing array elements
//    now seems the best way to handle 2D arrays. (See the programming note
//    about -Ounchecked, however.)
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
//    subroutine, subr(), that does the actual work of setting the required
//    values in the output array. The main routine and the subroutine can be in
//    the same file, as Swift doesn't seem to attempt to optimise out the call
//    to the subroutine.
//
// Invocation:
//    swiftc -o cstest cstest.swift      (with optional flags, like -Ounchecked)
//    ./cstest irpt nx ny
//
//    where:
//      irpt  is the number of times the subroutine is called - default 1000.
//      nx    is the number of columns in the array tested - default 2000.
//      ny    is the number of rows in the array tested - default 10.
//
//    Note that Swift use row-major order; arrays are stored in memory so that
//    the second index varies fastest. (This follows naturally from the way
//    2D arrays are implemented as arrays of arrays - if you think of the
//    1D arrays as being the rows.)
//
// Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
//
// History:
//    22nd Aug 2019. First properly commented version. KS.
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

import Foundation

//  ----------------------------------------------------------------------------
//
//  The Subr() subroutine.
//
//  Subr() is a subroutine that is passed a two-dimensional floating point
//  array Input, with dimensions nx by ny, together with an output array, Output
//  of the same dimensions. It returns with each element of Output set to the
//  contents of the corresponding element if Input plus the sum of its two
//  indices. The intent is to try to see how well any given language handles
//  access to individual elements of a 2D array,

func Subr (Input: Array<Array<Float>>, Nx: Int, Ny : Int,
                         Output: inout Array<Array<Float>>) {
   for Iy in 0...Ny-1 {
      for Ix in 0...Nx-1 {
         Output[Iy][Ix] = Input[Iy][Ix] + Float(Ix + Iy)
      }
   }
}

//  ----------------------------------------------------------------------------
//
//                             M a i n  P r o g r a m

//  Set the array dimensions and repeat count either from the default values
//  or values supplied on the command line.

var Nrpt:Int = 1000
var Nx:Int = 2000;
var Ny:Int = 10;
if (CommandLine.argc > 1) {
    let argStr = CommandLine.arguments[1]
    if let argInt = Int(argStr) { Nrpt = argInt }
}
if (CommandLine.argc > 2) {
    let argStr = CommandLine.arguments[2]
    if let argInt = Int(argStr) { Nx = argInt }
}
if (CommandLine.argc > 3) {
    let argStr = CommandLine.arguments[3]
    if let argInt = Int(argStr) { Ny = argInt }
}
print("Arrays: \(Ny) rows of \(Nx) columns, repeats = \(Nrpt)")

//  Create the input and output arrays. We have to create the input and output
//  arrays as arrays Ny long that hold the Ny 1D arrays that form the rows
//  of the 2D arrays. We set the elements of the input array to some set of
//  values - it doesn't matter what, just some values we can use to check the
//  array manipulation on. This uses the sum of the row and column indices in
//  descending order. The output array is just set to zeros, although that
//  doesn't matter at all.

var array = Array(repeating:Array(repeating:Float(), count:Nx), count:Ny)
var output = Array(repeating:Array(repeating:Float(), count:Nx), count:Ny)

for Iy in 0...Ny-1 {
  for Ix in 0...Nx-1 {
      array[Iy][Ix] = Float(Nx - Ix + Ny - Iy)
  }
}

//  Call the subroutine that will do the real work, as many times as specified.

for _ in 0...Nrpt-1 {
   Subr(Input: array,Nx: Nx,Ny: Ny,Output: &output)
}

//  Check that we got the expected results.

check:
for Iy in 0...Ny-1 {
   for Ix in 0...Nx-1 {
      let Expected = array[Iy][Ix] + Float(Ix + Iy)
      if (output[Iy][Ix] != Expected) {
          print("""
           Error at \(Ix),\(Iy) Got \(output[Iy][Ix]) expected \(Expected)
           """)
          break check
      }
   }
}

/* -----------------------------------------------------------------------------

                         P r o g r a m m i n g  N o t e s
 
   o  Swift array element access is very slow by default as it checks the
      array index values against the size of the array each time an element is
      accessed. This is a good thing, but it is slow. The -Ounchecked compiler
      flag specifies optimisation for speed (as does the -O flag), but also
      suppresses this bounds checking. It makes a big difference to this code.
 
   o  You're supposed to think of the 'inout' qualifier used for the output
      array in the declaration of Subr() as indicating that Swift will use
      'copy-in, copy-out' semantics for the argument, which would be fairly
      inefficient. In practice, the compiler will usually simply use 'call
      by reference', which will be mush more efficient. However, Swift
      cautions that these two have different effects, particularly in edge
      cases using asynchronous operation or some contorted scheme like passing
      a global as the argument and having the subroutine modify both the global
      and its argument separately, and you should not make assumptions about
      how the compiler will actually handle the argument. Fortunately, none of
      this applies here.
 
*/
