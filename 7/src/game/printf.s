.global print

.data

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

.text

#
# write_char
#
# Write a single char to stdout using a syscall
#
# Parameters:
#  %rdi the char to print
write_char:
    pushq   %rbp
    movq    %rsp, %rbp

    pushq   %rdi

    leaq    -8(%rbp), %rsi  # load the effective address of the char into %rsi
    movq    $1, %rdi        # indicates stdout
    movq    $1, %rax        # system call 1 equates to sys_write
    movq    $1, %rdx        # indicates the length, just one char
    syscall                 # do the syscall

    movq    %rbp, %rsp
    popq    %rbp
    retq

#
# printf
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
our_printf:
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
    movq    %rsp, %rbp          # store current stack pointer as base pointer

    # Push all other register arguments to the stack in reverse order.
    pushq   %r9
    pushq   %r8
    #pushq   %rcx
    #pushq   %rdx
    #pushq   %rsi
    
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

        movq    -24(%rbp, %r9, 8), %rax # from reg args
        jmp     _jmp_handler
        _stack_arg:
        movq    16(%rbp, %r9, 8), %rax  # from stack args

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
        movb    (%r12), %dil        # prepare the first argument for write_char
        movq    $0, %rax            # clearing the rax register before calling function
        call    write_char          # call the write_char function to print out the char
    
    _case_handled:                  # jump to this when special case was handled, to make sure step 3 is skipped
    
        incq    %r12                # increase the format string pointer for the
        jmp     _format_read_loop   # repeat the format string read loop
    _format_read_loop_end:
    
        movq    %rbp, %rsp          # discard local stack space
        popq    %r13                # restore old %r13
        popq    %r12                # restore old %r12
        popq    %rbx                # restore old %rbx
        popq    %rbp                # restore the base pointer
        retq

#
# Main subroutine
#
#main:
#    pushq   %rbp                # store the old base pointer
#    movq    %rsp, %rbp          # store current stack pointer as base pointer
#
#    # Preparing a simulation of a out_printf call
#    movq    $-123, %rsi
#    movq    $456, %rdx
#    movq    $string1, %rcx
#    movq    $-1, %r8
#    movq    $91, %r9
#    pushq   $string3
#    pushq   $string2
#    movq    $format, %rdi
#    call    our_printf
#
#    popq    %rbp                # restore the base pointer
#    movq    $0, %rdi            # the program is returning a 0
#    call    exit                # call the exit


# Special cases


special_case_percent:           # print out one percent signs
    # print a percent
    movq    $'%, %rdi
    call    write_char

    jmp     _case_handled

special_case_d:                 # print out corresponding parameter as signed integer

    # check sign bit
    testq   %rax, %rax
    jns     _special_case_d_positive

    # print a minus sign
    pushq   %rax
    movq    $'-, %rdi
    call    write_char
    popq    %rax

    negq    %rax                        # make the number positive
    jmp     special_case_u              # jump to the unsigned handler

    _special_case_d_positive:
    jmp     special_case_u
    
    
special_case_s:                         # print out corresponding parameter as string

    movq    %rax, %r10

    _special_case_s_loop:
        movq    $0, %rdi
        movb    (%r10), %dil        # prepare the first argument for write_char
        cmpb    $0, %dil            # do a quick check to see if we're at the end of the string
        jz      _case_handled       # if so (if we're at the end), jump back to _case_handled
        movq    $0, %rax            # clearing %rax before calling function
        call    write_char          # call the write_char function to print out the char

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
        call    write_char
        decq    %r13
        jnz     _special_case_u_loop_print

    jmp     _case_handled

special_case_unknown:               # print out the current character, preceded by a %

    # print a percent
    movq    $'%, %rdi
    call    write_char

    # print the current char
    movq    $0, %rdi
    movb    %r8b, %dil
    call    write_char

    jmp     _case_handled
