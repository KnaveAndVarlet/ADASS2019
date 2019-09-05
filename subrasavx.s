#
#                           s u b r a s a v x . s
#
#   This is a hand-optimised routine, written mainly as a learning exercise,
#   that provides a plug-in replacement for the following C++ code:
#
#   void subr (float* In[], int Nx, int Ny, float* Out[])
#   {
#      for (int Iy = 0; Iy < Ny; Iy++) {
#         for (int Ix = 0; Ix < Nx; Ix++) {
#            Out[Iy][Ix] = In[Iy][Ix] + Ix + Iy;
#         }
#      }
#   }
#
#   This adds the two index values of each input array element to the contents
#   of the array element and stores the result in the corresponding element of
#   the output array.
#
#   In and Out are assumed to be the addresses of two arrays that hold the
#   addresses of the start of the lines (rows) of two 2D arrays. This is the
#   way access to a 2D array is set up using the scheme in, for example,
#   Numerical Recipies in C. Each of the In and Out arrays will have Ny
#   elements (Ny being the number of rows in the 2D array), and each row
#   will have Nx elements (Nx being the length of each row, ie the number of
#   columns in the array), In practice, when 2D arrays are accessed in this
#   way, the elements of the 2D array will actually be continuous in memory -
#   one row will follow immediately on from the next, and assuming that would
#   make this code marginally simpler, but this code does in fact look at each
#   element of IN and OUT to get the start address of each row.
#
#   This is a plug-in replacement for the routine defined in cnrsub.cpp,
#   intended to be called from the main routine defined in cnrmain.cpp.
#
#  Linking:
#   c++ -c -o subrasavx.o subrasavx.s
#   c++ -o cnrmain -O cnrmain.cpp subrasavx.o
#
#  NOTE:
#   This code uses the AVX 256-bit vector instructions defined as an extension
#   to the X86 instruction set. Not all processors support this, and it will
#   probably fail in nasty ways if run on a processor that does not support AVX.
#   It's an example piece of code, and doesn't check for AVX support before
#   trying to use it.
#
#  Author(s): Keith Shortridge, Keith@KnaveAndVarlet.com.au
#
#  History:
#     2nd Jul 2019. First properly commented version. KS.
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
#
# ------------------------------------------------------------------------------
#
#  Internals:
#
#   This code works by recognising that the numbers that are actually added
#   to each element in In have a simple pattern:
#
#      Ix =  0   1   2   3   4   5   6  .....
#   Iy = 0:  0   1   2   3   4   5   6  .....
#   Iy = 1:  1   2   3   4   5   6   7  .....
#   Iy = 2:  2   3   4   5   6   7   8  .....
#   Iy = 3:  3   4   5   6   7   8   9  .....
#
#   The AVX vector instructions defined for X86_64 can handle eight 32-bit
#   floating point data values at a time. For the first row (Iy=0), the first
#   set of numbers added to the first eight data elements are (0,1,2,..7) and
#   once those have been done, the values added to the next four are (8,9,10,
#   ..15) - which are each (4,4,4,4,4,4,4,4) more than the values added to the
#   previous eight. This allows a very efficient vector loop through that line.
#
#   For the next line (Iy = 1), the first set of numbers to be added are (1,2,3,
#   ..8) which is (1,1,1,1,1,1,1,1) more than the values used at the start of
#   the previous line. That makes it easy to start that fast loop again for the
#   next line.
#
#   Obviously, if Ix is not a multiple of 8, there will be some data elements
#   at the end of the line that cannot be processed using eight-element vectors,
#   and these have to be done one by one. But there will only be seven at most.
#
#   To speed up the fast inner loop further, this code unrolls the loop to
#   handle four groups of eight elements each time through the loop, simply
#   repeating the required sequence four times within the loop body. This
#   reduces the loop overheads, but means that each pass through the loop
#   handles 32 array elements, and there may be up to 31 that have to be
#   processed one by one. There are some trade-offs here.
#
#   Note that the AVX 256-bit instructions are not supported by all X86
#   processors, and this code does not test to see if they are. It will not
#   run - probably getting an invalid instruction crash - on a processor that
#   does not support AVX. See programming notes at the end of this file.

# ------------------------------------------------------------------------------

   #  This is intended to be called from C++, so has a name that combines 'subr'
   #  with an encoded description of the parameter types.

	.text
	.align 4,0x90
	.globl __Z4subrPPfiiS0_
__Z4subrPPfiiS0_:

   #  Note the calling convention for passing arguments.
   #  %rdi  contains In - the first argument
   #  %esi  contains Nx - the second argument
   #  %edx  contains Ny - the third argument
   #  %rcx  contains Out - the fourth argument

   #  Save any registers we use and which we have to save. The 'callee 
   #  saved' registers we use are r10 through r14. This routine uses no
   #  stack space, so doesn't have to concern itself with manipulating the
   #  stack.
   
   pushq    %r10
   pushq    %r11
   pushq    %r12
   pushq    %r13
   pushq    %r14
   pushq    %r15
   
   #  This code has three loops. There is an overall loop through the
   #  lines of the input array, that is from Iy = 0 to Iy = Ny - 1.
   #  Each time through that loop, we handle a line of the input array.
   #  We have a very efficient loop through the elements of that line,
   #  which handles the elements sixteen at a time, in four groups of four,
   #  using the 128 bit xmm registers. If the number of elements in a line
   #  (Nx) is not a multiple of 16, then an extra loop is needed to go
   #  through those extra elements.
   
   testl    %esi,%esi      # Is Nx zero or negative?
   jle      Return         # If so, return immediately.
   testl    %edx,%edx      # Similarly for Ny.
   jle      Return
   
   #  Some initial values.
   #  %ymm2 starts by holding the eight integers 0,1,2,..,7. These are the
   #        values that will be added to the elements at the start of the very
   #        first line, that is, they are the values of Ix+Iy when Iy = 0 for
   #        0 <= Ix <= 7. As the program progresses, %ymm2 is incremented in
   #        the fast loop through each line, and then reset to the starting
   #        eight values for the next line.
   #  %ymm6 is set to eight floating point values, all 8.0, for the
   #        duration of the program. Once eight elements have been incremented
   #        in the fast loop, the floating point Ix+Iy values for the next eight
   #        are each 8.0 more, as Ix has gone up by 8 in each case. The fast
   #        loop handles four groups of eight elements, incrementing the eight
   #        Ix+Iy values by 8.0 after each group is processed.
   #  %ymm8 is set to eight integers, each 32, for the duration of the
   #        program. Each time through the fast loop, %ymm8 is added to %ymm2
   #        to produce the starting integer Ix+Iy values for the next 32
   #        elements.
   #  %ymm7 is set to eight integers, each 1, for the duration of the
   #        program. The start Ix+Iy values for the start of one line are all
   #        one more than for the start of the the previous line - since Iy has
   #        gone up by one as you move from one line to the next. (Those initial
   #        value for the start of each line are saved in %ymm3.)

   vmovdqa       ZeroThroughEight(%rip),%ymm2
   vpbroadcastd  Eight(%rip),%ymm7
   vpbroadcastd  ThirtyTwo(%rip),%ymm8
   vbroadcastss  FloatEight(%rip),%ymm6

   xorq     %r10,%r10      # Iy (index through IyLoop) = 0.
   movq     %rsi,%r9       # Nx (rsi is the 64-bit whole of esi, so holds Nx).
   movq     %r9,%r12       # r12 is Nextra - the number of elements we can't
   andq     $8,%r12        # handle in the fast IxLoop. Nextra = Nx & 0x10
   subq     %r12,%r9       # r9 is now Nx - Nextra
   shlq     $2,%r9         # (Nx - Nextra) * 4 (Bytes in the part of the line we
                           # will handle in the fast IxLoop.)

   #  Iyloop is the outer loop through the rows of the data.

   .p2align 4

IyLoop:
   movq     (%rdi),%r11    # r11 is addr held in In[Iy], start of input line
   movq     (%rcx),%r15    # R15 is addr held in Out[Iy], start of output line
   vmovaps  %ymm2,%ymm3    # Save initial Ix+Iy values for this line.
   testq    %r9,%r9        # If there are no elements to handle in the fast 
   jle      Extras         # loop (ie if Nx < 4), just do the extras.
   movq     %r11,%r8       # rdi is the address of the start of line (In[Iy])
   addq     %r9,%r8        # r8 is now address immediately following those
                           # elements we handle in the fast IxLoop.

   #  IxLoop is the fast loop that does most of the work. It runs through
   #  a line of the array from In[Iy][0] to In[Iy][Nx - Nextra - 1] where
   #  Nextra is the number of elements at the end that don't divide by 32.
   #  (Nextra has to be in the range 0 to 31).
   #
   #  At this point:
   #  %ymm2  contains the eight integers Iy,Iy+1,Iy+2,Iy+3,..Iy+7
   #         These are the values to be added to the first eight elements.
   #         These will be converted to floating point in %ymm4, which will
   #         be incremented as each of the four groups is processed in one
   #         pass through the fast loop. After one pass through the fast
   #         loop, each value in %ymm2 is incremented by 32, ready for the
   #         next pass through the fast loop.
   #  %ymm3  contains a saved copy of %ymm2. Adding 1 to each element of
   #         this will eventually provide the starting values for the next line.
   #  %ymm6  contains eight floating point values each 8.0.
   #         Note that if you add %ymm6 to %ymm2 you get the values to be
   #         added to the next four elements.
   #  %rdi   is the address of In[Iy]
   #         On exit, this will be the address of In[Iy][Nx - Nextra]
   #  %r11   holds the address contained in In[Iy], that is the address of
   #         the start of that line of data, ie the address of the array
   #         element In[Iy][0].
   #  %rcx   is the address of Out[Iy]
   #  %r15   holds the address contained in Out[Iy], that is the address of
   #         the start of that line of data, ie the address of the array
   #         element Out[Iy][0].
   #         On exit, this will be the address of Out[Iy][Nx - Nextra]
   #  %r8    contains the address of In[Ix][Nx - Nextra] - ie the address
   #         of the element following those we handle in this loop.
   #
   #  An original version of the fast loop only handled one group of four
   #  elements. However, it turns out to be noticeably faster to handle
   #  more elements than this before taking the test and branch overheads of
   #  the loop. Doing two groups of four gives a significant improvement,
   #  doubling that to four groups of four provides a slight improvement, and
   #  then it diminishing returns - the code gets longer and messier, and
   #  the extra loop will have to handle more and more elements.
   #
   #  As we go through the fast loop:
   #
   #  %ymm0,%ymm1,%ymm12,%ymm13 are used as scratch vectors holding the sums
   #         of each group of eight In array values plus their respective
   #         IX+Iy increments. They are then written to the corresponding Out
   #         array locations.
   #  %ymm4,%ymm9,%ymm10,%ymm11 are used a scratch vectors holding the floating
   #         point Ix+Iy values for each of the four groups of eight In values.
   #         These are calculated by starting with the initial integer Ix+Iy
   #         increment values (in %ymm2) converted to float, and then
   #         incremented by the vector of 8.0 values held in %ymm6.
   #
   #   Using this many vector registers is over the top, but it does allow
   #   easy experimentation. It makes it easy to move the calculation of
   #   increments (the register-based vaddps instructions) and the 'load and
   #   add' (vaddps) instructions, and the store instructions to see if any
   #   reorganisation improves the speed, perhaps by allowing memory I/O to
   #   overlap with other things. (Spoiler - it really doesn't seem to make
   #   much difference, although the sequence here of precalculating the
   #   increments, then two load and adds, two stores, two load and adds, two
   #   stores, may be marginally better than just four consecutive sequences of
   #   load and add, new increment, store. (Although the latter can be done
   #   using far fewer registers.) This sequence is very similar to that
   #   generated by Clang, except that here the Ix+Iy increments are pre-
   #   calculated, and they are calculated in floating point directly instead
   #   of being incremented as integers and converted to floating point.

   .p2align 4

IxLoop:
   vcvtdq2ps %ymm2,%ymm4           # Convert 1st set of Ix+Iy values to floats.

   vaddps   %ymm6,%ymm4,%ymm9      # Add 8.0 to each Ix+Iy value. (2nd set of 8)
   vaddps   %ymm6,%ymm9,%ymm10     # Add 8.0 to each Ix+Iy value. (3rd set of 8)
   vaddps   %ymm6,%ymm10,%ymm11    # Add 8.0 to each Ix+Iy value. (4th set of 8)

   vaddps   (%r11),%ymm4,%ymm0     # Add Ix+Iy values to 1st input value set.
   vaddps   32(%r11),%ymm9,%ymm1   # Add Ix+Iy values to 2nd input value set.
   vmovups  %ymm0,(%r15)           # Store the 1st set of results in Out.
   vmovups  %ymm1,32(%r15)         # Store the 2nd set of results in Out.
   vaddps   64(%r11),%ymm10,%ymm12 # Add Ix+Iy values to 3rd input value set.
   vaddps   96(%r11),%ymm11,%ymm13 # Add Ix+Iy values to 4th input value set.
   vmovups  %ymm12,64(%r15)        # Store the 3rd set of results in Out.
   vmovups  %ymm13,96(%r15)        # Store the 4th set of results in Out.

   vpaddd   %ymm8,%ymm2,%ymm2      # Add 32 to each of initial Ix+Iy increments.

   addq     $128,%r11              # Increment pointers to In and Out by 128,
   addq     $128,%r15              # ready for the next 32 elements.
   cmpq     %r8,%r11               # Have we reached the end of this line yet?
   jb       IxLoop                 # If not, do another 32 elements.

Extras: 
   testl    %r12d,%r12d    # If there were no extra elements,
   je       NextLine       # move on to next line now.
   
   xorl     %r14d,%r14d    # Used as index through the extra elements
   movl     %esi,%r13d     # Ix value for first extra element is
   subl     %r12d,%r13d    # Nx - Nextra. r13 is now Ix for that element.
   addl     %r10d,%r13d    # And now r13 is Ix + Iy for that element.
   
   #  ExLoop is the loop through the extra values at the end of the line.
   #  Since there are at most 31 of these, this doesn't have to be
   #  efficient and I've not tried hard to optimise this, although that could
   #  be done - first see how many we coud do 16 at a time, then 8 at at
   #  time, then do up to 7 in a final loop.
   
   .p2align 4
ExLoop:
   xorps    %xmm0,%xmm0    # Clear out all of xmm0, including high order part.
   cvtsi2ss %r13d,%xmm0    # Convert the Ix + Iy value to float,
   addss    (%r11),%xmm0   # Add next 'extra' element from input array.
   movss    %xmm0,(%r15)   # And store it in the output array.
   addq     $4,%r11        # Now increment the input array pointer
   addq     $4,%r15        # and the output array pointer.
   incl     %r13d          # Increment the Ix + Iy value for the next element.
   incl     %r14d          # Increment the loop counter through the extra
   cmpl     %r14d,%r12d    # elements and carry on until all the extra
   jne      ExLoop         # elements have been handled.

NextLine:
   
   vmovaps  %ymm3,%ymm2    # The initial Ix+Iy values for the next line are
   vpaddd   %ymm7,%ymm2,%ymm2    # the values we saved for this line, each + 1.
   addq     $8,%rcx        # rcx now points to address of next element of Out
   addq     $8,%rdi        # rdi now points to address of next element of In
   incl     %r10d          # Increment Iy,
   cmpl     %r10d,%edx     # compare with Ny, keep looping
   jne      IyLoop         # until all lines done.

Return:

   #  Restore any saved registers, and return.
     
   popq     %r15
   popq     %r14
   popq     %r13
   popq     %r12
   popq     %r11
   popq     %r10
   ret
   
   .align 8
   
ZeroThroughEight:
   .long    0
   .long    1
   .long    2
   .long    3
   .long    4
   .long    5
   .long    6
   .long    7

Eight:
   .long    1

ThirtyTwo:
   .long    32

FloatEight:
   .float    8.0

# ------------------------------------------------------------------------------

#                      P r o g r a m m i n g  N o t e s
#
#  o  This code is intended to illustrate how this routine can be implemented in
#     assembler. It isn't intended as proper production code. If it were, it
#     should test for the presence of the AVX instructions and fall back on the
#     128-bit SSE instructions if that is all the processor supports. Note that
#     gcc or clang will normally generate code that uses SSE at a high enough
#     level of optimisation, but will not normally generate AVX isntructions.
#     They can be made to using the -march=native flag if the compiler is
#     running on a machine that supports AVX. (On a suitable machine, they may
#     even use the AVX-512 512-bit vector istructions in this case.)
#
#  o  With the mail loop unrolled to the point that it handles 32 elements at a
#     time, the extra loop that handles the remaining (up to 31) elements in
#     each line should probably be made cleverer - at the very least, it could
#     do some elements in batches of eight using single 256-bit vector
#     instructions, or even in batches of four using the 128-bit SSE
#     instructions, leaving at most three array elements to be handled
#     individually. But that's a lot of error-prone code to introduce by hand,
#     given that even then you're unlikely to do better than a modern compiler
#     does.
#
#  o  I've ended up with a bit of a mixture of longword (32 bit) and quadword
#     (64 bit instructions. This is mainly because Nx and Ny - the arguments -
#     are declared as int and so it makes sense to use longword instructions
#     with anything to do with them. The only place this looks odd is that Nx is
#     passed in rsi but only the low 4 bytes is used in most places, ie using
#     esi (which is the low 4 bytes of rsi) but in one place rsi is used in code
#     that uses the Nx value to do address calculations. This caught me at one
#     point when I modified the register usage for Nx and Ny and only changed
#     the lognword code and missed the quadword, forgetting rsi and esi were
#     parts of the same thing.
#
#  o  In fact, most of what this exercise demonstrates is that it's really
#     hard to beat - or even draw with - a modern optimising compiler so long
#     as it's given the right optimisation flags.
