C
C                            c f m a i n . f
C
C  Summary:
C     2D array access test main routine in Fortran.
C
C  Introduction:
C     This is a test program written as part of a study into how well different
C     languages handle accessing elements of 2D rectangular arrays - the sort of
C     thing that are common in astronomy and similar scientific disciplines.
C     This can also be used to see how efficient different ways of coding the
C     same problem can be in the different languages, and to see what effect
C     such things as compilation options - particularly optimisation options -
C     have.
C
C     The problem chosen is a trivial one: given an 2D array, add to each
C     element the sum of its two indices and return the result in a second,
C     similarly-sized array. This is harder to optimise away than, for example,
C     simply doing an element by element copy of the array, but is generally
C     easy to code. It isn't a perfect test (something brought out by the
C     study), but it does produce some interesting results.
C
C  This version:
C     This version is for Fortran. Fortran has supported multi-dimensional
C     arrays of the sort used here from its very first implemetation. However,
C     support for dynamically allocated arrays (ones where the array size does
C     not have to be hard-coded) only came in with Fortran 90. This version
C     makes use of even more recent Fortran features (such as the I0) format
C     used for a print statement, but this is just for convenience for testing.
C     The subroutine this calls to do the work - see cfsub.f - is written in
C     standard Fortran 77.
C
C  Structure:
C     Most test progrsms in this study code the basic array manipulation in a
C     single subroutine, then create the original input array, and pass that,
C     together with the dimensions of the array, to that subroutine, repeating
C     that call a large number of times in oder to be able to get a reasonable
C     estimate of the time taken. Then the final result is checked against the
C     expected result.
C
C     This code follows that structure. This main routine sets up two 2D arrays,
C     an input array and an output array, of a size that can be controlled using
C     command line arguments. These arrays can then be passed to a subroutine,
C     subr() that does the actual work of setting the required values in the
C     output array. The main routine and the subroutine have to be in different
C     files and compiled separately, or at high levels of optimisation a
C     compiler may realise that it can optimise out the entire subroutine.
C
C  Building:
C     The file containing the implementation of the subr() routine has to be
C     compiled separately, using the compiler being tested and with the options
C     being tested. Then this main program needs to be linked against that
C     compiled subroutine. For example, something like:
C
C     gfortran -c -O -o cfsub.o cfsub.f
C     gfortran -o cfmain -O cfmain.f cfsub.o
C
C  Invocation:
C     ./cfmain irpt nx ny
C
C     where irpt  is the number of times the subroutine is called - default 1.
C           nx    is the number of columns in the array tested - default 2000.
C           ny    is the number of rows in the array tested - default 10.
C
C     Note that Fortran use column-major order; arrays are stored in memory so
C     that the first index varies fastest. We want the array to be stored so
C     that elements of the same row are contiguous in memory, and we use the
C     column number (the Y-value) as the first index when setting up the array.
C
C  Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
C
C  History:
C     5th Jul 2019. First properly commented version. KS.
C
C  Copyright (c) 2019 Knave and Varlet
C
C  Permission is hereby granted, free of charge, to any person obtaining a copy
C  of this software and associated documentation files (the "Software"), to deal
C  in the Software without restriction, including without limitation the rights
C  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
C  copies of the Software, and to permit persons to whom the Software is
C  furnished to do so, subject to the following conditions:
C
C  The above copyright notice and this permission notice shall be included in
C  all copies or substantial portions of the Software.
C
C  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
C  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
C  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
C  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
C  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
C  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
C  SOFTWARE.

C  -----------------------------------------------------------------------------
C
C                             M a i n  P r o g r a m

       program main
       implicit none
       character*64 string
       integer Nx,Ny,Nrpt
       real, allocatable :: In(:,:), Out(:,:)
       integer Ix,Iy,Loop

C      Set the array dimensions and repeat count either from the default values
C      or values supplied on the command line.

       Nx = 2000
       Ny = 10
       Nrpt = 100000
       if (iargc() > 0) then
          call getarg(1,string)
          read(string,*) Nrpt
       end if
       if (iargc() > 1) then
          call getarg(2,string)
          read(string,*) Nx
       end if
       if (iargc() > 2) then
          call getarg(3,string)
          read(string,*) Ny
       end if

C      Allocate the two arrays - input and output. We let the index values
C      default to the traditional Fortran convention of starting from 1, not
C      from zero. (Fortran uses index numbers for elements, not offsets, so the
C      first element is number 1.)

       allocate (In(Nx,Ny),Out(Nx,Ny))

C      Initialise the input array. It doesn't matter what values we use, just
C      some numbers we can use to check the array manipulation code. This uses
C      the sum of the row and column numbers in descending order. We don't need
C      to initialise the output array.

       do Iy = 1,Ny
          do Ix = 1,Nx
             In(Ix,Iy) = real(Nx - Ix + Ny - Iy)
          end do
       end do
       print
     :  '("Arrays have ",I0," rows of ",I0," columns, repeats = ",I0)',
     :                                                      Nx,Ny,Nrpt

C      Repeat the call to the manipulating subroutine. A compiler can't optimise
C      this out, as it doesn't know that the results will be the same every
C      time.

       do Loop = 1,Nrpt
          call sub(In,Nx,Ny,Out)
       end do

C      Check that we got the expected results.

       testloop: do Iy = 1,Ny
          do Ix = 1,Nx
             if (Out(Ix,Iy).ne.In(Ix,Iy) + (Ix + Iy)) then
                print *,"Error: ",Ix,Iy,Out(Ix,Iy)," not ",
     :                                        In(Ix,Iy) + Ix + Iy
                exit testloop
             end if
          end do
       end do testloop

C      Delete the allocated input and output arrays.

       deallocate (In,Out)
       end
       
