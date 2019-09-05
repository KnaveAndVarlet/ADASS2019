//                          c s u b . j a v a
//
//  Summary:
//     2D array access test in Java.
//
//  Introduction:
//     This is a test program written as part of a study into how well different
//     languages handle accessing elements of 2D rectangular arrays - the sort
//     of thing that are common in astronomy and similar scientific disciplines.
//     This can also be used to see how efficient different ways of coding the
//     same problem can be in the different languages, and to see what effect
//     such things as compilation options - particularly optimisation options -
//     have.
//
//     The problem chosen is a trivial one: given an 2D array, add to each
//     element the sum of its two indices and return the result in a second,
//     similarly-sized array. This is harder to optimise away than, for example,
//     simply doing an element by element copy of the array, but is generally
//     easy to code. It isn't a perfect test (something brought out by the
//     study), but it does produce some interesting results.
//
//  This version:
//     This version is for Java. It's a very straightforward implementation.
//     Java supports 2D arrays pretty well and allows the convenient In[Iy][Ix]
//     form of accessing an element in a subroutine to work without the messing
//     aroundneeded in C/C++.
//
//  Structure:
//     Most test progrsms in this study code the basic array manipulation in a
//     single subrutine, then create the original input array, and pass that,
//     together with the dimensions of the array, to that subroutine, repeating
//     that call a large number of times in oder to be able to get a reasonable
//     estimate of the time taken. Then the final result is checked against the
//     expected result.
//
//     This code follows that structure, with both the main routine and the
//     called subroutine in the same piece of code, as Java doesn't optimise out
//     the call in that case.
//
//  Building and invocation:
//     javac csub.java
//     java csub irpt nx ny
//
//     where:
//       irpt  is the number of times the subroutine is called - default 1000.
//       nx    is the number of columns in the array tested - default 2000.
//       ny    is the number of rows in the array tested - default 10.
//
//     Note that R uses column-major order; arrays are stored in memory so that
//     the first index varies fastest.
//
//  Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
//
//  History:
//     5th Jul 2019. First properly commented version. KS.
//
//  Copyright (c) 2019 Knave and Varlet
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
//  We define a class csub, which includes a routine called subr() which is the
//  subroutine that does the work, and another called main() which sets up the
//  arrays and calls subr() as many times as are needed to get a decent handle
//  on the timing.

public class csub {

   //  The subr() subroutine.
   //
   //  subr() is a subroutine that is passed a two-dimensional floating point
   //  array in, with dimensions nx by ny, and another of the same size, out.
   //  It is also passed the number of rows in the arrays, ny, and the number
   //  of columns, nx. It sets each element of out to the contents of the
   //  corresponding element of in plus the sum of its two indices. The intent
   //  is to try to see how well any given language handles access to individual
   //  elements of a 2D array

   public static void subr(float in[][],int nx,int ny,float out[][]) {
      int ix,iy;
      for (iy = 0; iy < ny; iy++) {
         for (ix = 0; ix < nx; ix++) {
            out[iy][ix] = in[iy][ix] + iy + ix;
         }
      }
   }
   
   //  The main() routine.
   
   public static void main(String[] args) {
   
      //  Set the array dimensions and repeat count either from the default
      //  values or values supplied on the command line.
      
      int ny = 10;
      int nx = 2000;
      int nrpt = 1000;
      if (args.length > 0) nrpt = Integer.parseInt(args[0]);
      if (args.length > 1) nx = Integer.parseInt(args[1]);
      if (args.length > 2) ny = Integer.parseInt(args[2]);
      
      //  Create the in[][] and out[][] arrays, and initialise the elements of
      //  in to some set of values - it doesn't matter what, just some values
      //  we can use to check the array manipulation on. This uses the sum of
      //  the row and column indices in descending order. We don't need to
      //  initialise the output array.
      
      int ix,iy;
      float in[][] = new float[ny][nx];
      float out[][] = new float[ny][nx];
      for (iy = 0; iy < ny; iy++) {
         for (ix = 0; ix < nx; ix++) {
            in[iy][ix] = (nx - ix + ny - iy);
         }
      }
      System.out.println("Arrays have " +
                     ny + " rows of " + nx + " columns, repeats = " + nrpt);
      
      //  Repeat the call to the manipulating subroutine.
      
      int irpt;
      for (irpt = 0; irpt < nrpt; irpt++) {
         subr(in,nx,ny,out);
      }
      
      //  Check that we got the expected results.

      testloop: 
      for (iy = 0; iy < ny; iy++) {
         for (ix = 0; ix < nx; ix++) {
            if (out[iy][ix] != in[iy][ix] + (ix + iy)) {
               float val = out[iy][ix];
               System.out.println("Error " + " " + val + " " + ix + " " + iy);
               break testloop;
            }
         }
      }
   }
}
      
// -----------------------------------------------------------------------------

//                       P r o g r a m m i n g  N o t e s
//
//  o  Fun fact, discovered entirely by accident: if the line in the innermost
//     loop of csub() is changed from:
//        out[iy][ix] = in[iy][ix] + iy + ix;
//     to:
//        out[iy][ix] = in[iy][ix] + ix + iy;
//     The execution time goes up by almost a factor 2, at least with the
//     version of Java I was using. I must have hit some quirk of the code
//     generator, since all this does is change the order of addition of the
//     two indices. Isn't addition supposed to be commumative?
//     (I found this when I reversed the use of X amd Y in this code to be
//     consistent with the other examples. It took me a while to find out why
//     this slowed it down, and I spent some time convincing myself I wasn't
//     accessing the data against the grain of the memory, and finally tried
//     switching ix + iy to iy + ix, something I'd thought was pointless when
//     I reworked the code.)
