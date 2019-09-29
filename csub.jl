
#                              c s u b . j l
#
#  Summary:
#     2D array access test in Julia.
#
#  Introduction:
#     This is a test program written as part of a study into how well different
#     languages handle accessing elements of 2D rectangular arrays - the sort of
#     thing that are common in astronomy and similar scientific disciplines.
#     This can also be used to see how efficient different ways of coding the
#     same problem can be in the different languages, and to see what effect
#     such things as compilation options - particularly optimisation options -
#     have.
#
#     The problem chosen is a trivial one: given an 2D array, add to each
#     element the sum of its two indices and return the result in a second,
#     similarly-sized array. This is harder to optimise away than, for example,
#     simply doing an element by element copy of the array, but is generally
#     easy to code. It isn't a perfect test (something brought out by the
#     study), but it does produce some interesting results.
#
#  This version:
#     This version is for Julia. Julia looks a lot like Fortran when it comes to
#     array handling, and the implementation here is pretty straightforward.
#
#  Structure:
#     Most test programs in this study code the basic array manipulation in a
#     single subroutine, then create the original input array, and pass that,
#     together with the dimensions of the array, to that subroutine, repeating
#     that call a large number of times in oder to be able to get a reasonable
#     estimate of the time taken. Then the final result is checked against the
#     expected result.
#
#     This code follows that structure, with both the main routine and the
#     called subroutine in the same piece of code. Julia doesn't seem to support
#     separate compliation without getting into modules, but in any case doesn't
#     seem to optimise out the whole subroutine, so this is convenient.
#
#  Invocation:
#     julia csub.jl irpt nx ny
#
#     where:
#       irpt  is the number of times the subroutine is called - default 100000.
#       nx    is the number of columns in the array tested - default 2000.
#       ny    is the number of rows in the array tested - default 10.
#
#     Note that Julia uses column-major order; arrays are stored in memory so
#     that the first index varies fastest, so we use the number of columns as
#     the first dimension when we create the arrays. Just like Fortran.
#
#  Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
#
#  History:
#     6th Jul 2019. First properly commented version. KS.
#
#  Copyright (c) 2019 Knave and Varlet
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#  SOFTWARE.

# ------------------------------------------------------------------------------

#  subr() is a subroutine that is passed a two-dimensional floating point array
#  in, with dimensions nx by ny. It returns a two dimensional array of the same
#  dimensions with each element set to the contents of the corresponding element
#  in ina plus the sum of its two indices.

function subr!(in,nx,ny,out)
   for iy = 1:ny
      for ix = 1:nx
         out[ix,iy] = in[ix,iy] + ix + iy
      end
   end
   return
end

# ------------------------------------------------------------------------------

#                            M a i n  p r o g r a m

#  Get the command line arguments, and determine the array size and the number
#  of times to repeat the subroutine call.

nrpt = 100000
nx = 2000
ny = 10
if (length(ARGS) > 0); nrpt = parse(Int,ARGS[1]) end
if (length(ARGS) > 1); nx = parse(Int,ARGS[2]) end
if (length(ARGS) > 2); ny = parse(Int,ARGS[3]) end
println("Arrays have ",ny," rows of ",nx," columns, repeats = ",nrpt)

#  Create the input array and initialise it to a set of values we can use to
#  test that the array manipulation in subr() works. The values don't matter, so
#  this just uses the sum of the index values in descending order. The output
#  array is just created as an array of zeros.

const in = zeros(Float32,nx,ny)
const out = zeros(Float32,nx,ny)
for iy = 1:ny, ix = 1:nx
   in[ix,iy] = nx - ix + ny - iy
end

#  Call the array manipulation subroutine the specified number of times.

for irpt = 1:nrpt
   subr!(in,nx,ny,out)
end

#  Check the results.

for iy = 1:ny, ix = 1:nx
   if out[ix,iy] != in[ix,iy] + ix + iy
      println("error ",out[ix,iy]," ",ix," ",iy)
      break
   end
end

#= -----------------------------------------------------------------------------

                        P r o g r a m m i n g  N o t e s

   o  I still find the expanded form of the loops used in the subroutine more
      natural, but the single for statement with both loops is quite neat. I did
      see if this version of subr() made any difference to the timing, but - as
      I expected - it didn't.

      function subr!(in,nx,ny,out)
         for iy = 1:ny, ix = 1:nx
            out[ix,iy] = in[ix,iy] + ix + iy
         end
         return
      end

   o  You can set up the input array using:
      const in = Matrix(undef,nx,ny)
      instead of:
      const in = zeros(Float32,nx,ny)

      But the resuting code is much, much slower - about 2 orders of magnitude.
      Clearly a Matrix of elements of initially undefined type has a lot of
      overheads. It works, it's just much slower.

   o  The 'const' in the declarations of in and out doesn't imply that the
      contents of the arrays are immutable; it just means in and out - the
      variable names - aren't going to be reused for something quite different.
=#
