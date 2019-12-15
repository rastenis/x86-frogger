.file "src/game/printf.s"

.global printf_coords

.section .game.data

# printf special character jump table (quadword aligned)
.align 16
jmptbl:
    .skip 8*'$ + 8
    .quad special_case_percent          # %
    .skip 8*('c - '&) + 8
    .quad special_case_d                # d
    .skip 8*('r - 'e) + 8
    .quad special_case_s                # s
    .skip 8                             # skip t
    .quad special_case_u                # u 
    .skip 8*(256 - 'v) + 8

.section .game.text

#
# _write_char
#
# Write a single char to the screen at the given coordinates using the given color information.
# Delegates the call to putChar.
# 
# Increments %r14 by one.
#
# Parameters:
#  %rdi char to print
#  %rsi color
#
_write_char:
  movq    %rdi, %rdx
  movq    -8(%rbp), %rcx
  movq    %r14, %rdi
  movq    %r15, %rsi

  pushq   %r8
  pushq   %r9
  call    putChar
  popq    %r9
  popq    %r8
  
  incq    %r14
  retq

#
# printf_coords
#
# Printf subroutine. Implements the following format specifiers:
#  %s   string
#  %d   signed integer
#  %u   unsigned integer
#  %%   escape pattern for the percent sign (%)
#
# Parameters:
#  %rdi  format string
#  %rsi  start x coord
#  %rdx  y coord
#  %rcx  color information
#  %r8   1st value
#  %r9   2nd value
#  stack 3rd-4th values (pushed in reverse order)
#
printf_coords:
    # 
    # registers used:
    #  %rbx     special case flag
    #  %r8      holds current char (in %r8b)
    #  %r9      number of used format values
    #  %r12     format string pointer
    #
    pushq   %rbp                # store the old base pointer
    pushq   %rbx                # store %rbx, because it is callee-saved
    pushq   %r12                # same for %r12
    pushq   %r13                # ... and for %r13
    pushq   %r14                # ... and for %r14
    pushq   %r15                # ... and for %r15
    movq    %rsp, %rbp          # store current stack pointer as base pointer

    # Store the color as a local variable on the s
    pushq   %rcx

    # Push all other register arguments to the stack in reverse order.
    pushq   %r9
    pushq   %r8
    #pushq   %rcx
    #pushq   %rdx
    #pushq   %rsi
    
    movq    %rsi, %r14          # store the x coord
    movq    %rdx, %r15          # store the y coord
    
    movq    $0, %rbx            # clear %rbx because we're going to use it
    movq    $0, %r9             # clear %r9 because we're going to use it
    movq    %rdi, %r12          # store the format string in %r12 for later reference

    # Loop over each character in the format string
    _format_read_loop:
    
        # 1. Check whether the end of the format string is reached, if so, jump to end of this loop
        movq    (%r12), %r8
        cmpb    $0, %r8b              # compare current char to 0 (end of string, C string convention)
        je      _format_read_loop_end # break out the loop if current char was null
    
        # 2. Check whether the special case flag has been set (%rbx)
        cmpq    $1, %rbx            # check if special case flag is set
        jne     _special_case_end   # skip special case handling if special case flag is not set
        movq    $0, %rbx            # reset the special case flag
    
        # 3. Do a lookup in the jumptable and jump to the handler
        movq    $0, %rdx                # clear %rdx
        movb    %r8b, %dl               # move lower byte of %r8 to lower byte of %rdx (%dl)
        movq    jmptbl(,%rdx,8), %rdx   # do the lookup in the jump table
        testq   %rdx, %rdx              # check if the current char is a valid action
        jz      special_case_unknown    # if not, perform the 'unknown' action

        # 4. Get the next format value (either from the register arguments or the stack arguments)
        cmpq    $special_case_percent, %rdx # check if the handler is the handler for a percent sign
        je      _jmp_handler            # if so, skip getting the next format value, because this handler doens't consume a value
        incq    %r9                     # increment r9 - special case counter, because the handler will consume one value
        cmpq    $3, %r9                 # compare %r9 to 6
        jge     _stack_arg

        movq    -32(%rbp, %r9, 8), %rax # from reg args
        jmp     _jmp_handler
        _stack_arg:
        movq    32(%rbp, %r9, 8), %rax  # from stack args

        _jmp_handler:
        jmpq    *%rdx                   # finally jump to the action handler
    _special_case_end:
    
        # 3. Else: compare the current char to "%". If it is a percent sign, set the special case flag, otherwise print the current char
        cmpb    $'%, %r8b           # compare the current char to a percent sign
        jne     _not_percent        # jump to _not_percent (which prints the current char) if current char is not a percent sign
        movq    $1, %rbx            # set the special case flag
        jmp     _case_handled       # skip over the rest of step 3, we can continue to the next iteration of the format read loop
    _not_percent:
        movq    $0, %rdi
        movb    (%r12), %dil        # prepare the first argument for _write_char
        movq    $0, %rax            # clearing the rax register before calling function
        call    _write_char          # call the _write_char function to print out the char
    
    _case_handled:                  # jump to this when special case was handled, to make sure step 3 is skipped
    
        incq    %r12                # increase the format string pointer for the
        jmp     _format_read_loop   # repeat the format string read loop
    _format_read_loop_end:
    
        movq    %rbp, %rsp          # discard local stack space
        popq    %r15                # restore old %r15
        popq    %r14                # restore old %r14
        popq    %r13                # restore old %r13
        popq    %r12                # restore old %r12
        popq    %rbx                # restore old %rbx
        popq    %rbp                # restore the base pointer
        retq


#main:
#	pushq   %rbp                # store the old base pointer
#	  movq    %rsp, %rbp          # store current stack pointer as base pointer
#
#	  # Preparing a simulation of a out_printf call
#	  movq    $5, %rsi            # x = 5
#	  movq    $5, %rdx            # y = 5
#	  movq    $0x0f, %rcx         # black background, white foreground
#	  movq    $-1, %r8
#	  movq    $91, %r9
#	  pushq   $string1
#	  movq    $format, %rdi
#	  call    printf_coords
#
#	  movq    %rbp, %rsp          # discard local variables
#	  popq    %rbp                # restore the base pointer
#	  retq
  
# Special cases


special_case_percent:           # print out one percent signs
    # print a percent
    movq    $'%, %rdi
    call    _write_char

    jmp     _case_handled

special_case_d:                 # print out corresponding parameter as signed integer

    # check sign bit
    testq   %rax, %rax
    jns     _special_case_d_positive

    # print a minus sign
    pushq   %rax
    movq    $'-, %rdi
    call    _write_char
    popq    %rax

    negq    %rax                        # make the number positive
    jmp     special_case_u              # jump to the unsigned handler

    _special_case_d_positive:
    jmp     special_case_u
    
    
special_case_s:                         # print out corresponding parameter as string

    movq    %rax, %r10

    _special_case_s_loop:
        movq    $0, %rdi
        movb    (%r10), %dil        # prepare the first argument for _write_char
        cmpb    $0, %dil            # do a quick check to see if we're at the end of the string
        jz      _case_handled       # if so (if we're at the end), jump back to _case_handled
        movq    $0, %rax            # clearing %rax before calling function
        call    _write_char          # call the _write_char function to print out the char

        incq    %r10
        jmp     _special_case_s_loop


special_case_u:                     # print out corresponding parameter as unsigned integer

    movq    $0, %r13                # init digit counter
    movq    $10, %r10               # init constant to divide with

    _special_case_u_loop_divide:
        movq    $0, %rdx            # clear %rdx in this iteration, needs to be zero before dividing, we don't want to do any 128 bit division
        divq    %r10                # divide the current value with 10
        pushq   %rdx                # push the remainder (in %rdx), that is what we need to print later on, but in reverse order
        incq    %r13                # increment the digit counter
        cmpq    $0, %rax            # check if we reached the end of this loop
        jz      _special_case_u_loop_print      # if so, jump to the print step when the number is fully converted
        jmp     _special_case_u_loop_divide     # else, keep dividing 
    
    _special_case_u_loop_print:
        movq    $0, %rdi
        popq    %rdi
        addq    $'0, %rdi
        call    _write_char
        decq    %r13
        jnz     _special_case_u_loop_print

    jmp     _case_handled

special_case_unknown:               # print out the current character, preceded by a %

    # print a percent
    movq    $'%, %rdi
    call    _write_char

    # print the current char
    movq    $0, %rdi
    movb    %r8b, %dil
    call    _write_char

    jmp     _case_handled
