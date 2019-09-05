C
C                                c f s u b . f
C
C  Summary:
C     2D array access test subroutine in Fortran.
C
C  Introduction:
C     This is a test routine written as part of a study into how well different
C     languages handle accessing elements of 2D rectangular arrays. This routine
C     is passed a 2D array (In) with Ny rows and Nx columns, and another 2D
C     array of the same size (Out). It modifies Out so so each element of Out
C     is set to the value of the corresponding element of In, plus the sum of
C     the two index values for the element - ie plus the row number and the
C     column number. The idea is trivial, but the operation isn't completely
C     trivial to optimise, and the intention is to see how well this runs when
C     compiled using different compilers, or using different options.
C
C  This version:
C     This version is for Fortran, and is valid Fortran 77, although it makes
C     more sense to call it from a more modern version of Fortran that provides
C     a standard way of allocating arrays dynamically. This routine is designed
C     to be called from a main test program like that in cfsub.f. The code
C     itself is completely trivial.
C
C     Note that Fortran uses column-major order; arrays are stored in memory so
C     that the first index varies fastest. We want the array to be stored so
C     that elements of the same row are contiguous in memory, and we use the
C     column number (the X-value) as the first index when setting up the array.
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

       subroutine sub (In,Nx,Ny,Out)
       implicit none
       integer Nx,Ny
       real In(Nx,Ny),Out(Nx,Ny)
       integer Ix,Iy
       do Iy = 1,Ny
          do Ix = 1,Nx
             Out(Ix,Iy) = In(Ix,Iy) + Ix + Iy
          end do
       end do
       end

