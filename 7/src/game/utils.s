.file "src/game/util.s"

.global screenClear

.section .game.data


screenClear:

    # Calling convention
	pushq   %rbp
    pushq   %r12
    pushq   %r13
	movq    %rsp, %rbp

    movq    $0, %r12    # outer loop counter for y coord

_screenClear_y:         # outer loop (y, 0-24)

    movq    $0, %r13    # inner loop counter for x coord

_screenClear_x:         # inner loop (x, 0-79)

    movq    $80, %rax   # init with 80 as the number of columns
    mulq    %r12        # multiply with the current y coord (so: %rax = 80*y)
    addq    %r13, %rax  # add the x coord (so now: %rax = 80*y + x)
    movw    $0x0F20, 0xB8000(,%rax, 2)  # write to the VGA text mode buffer: space with black background

    # Loop guards
    incq    %r13
    cmpq    $80, %r13
    jne     _screenClear_x
    incq    %r12
    cmpq    $25, %r12
    jne     _screenClear_y

    # Restore
    movq    %rbp, %rsp
    popq    %r13
    popq    %r12
    popq    %rbp
    retq


###############################################################################################
#############yoinked code######################################################################
###############################################################################################

#putChar:
#
#	# Write the character
#	movb	%dl, %al    # constant chat
#	movb	%cl, %ah    # const color
#    
#    
#	# The address to write to is 0xB8000 + 2 * (80 * y + x)
#	andq	$0xFF, %rdi     # x
#	andq	$0xFF, %rsi     # y
#	shlq	$4, %rsi		# RSI = 16 * y
#	movq	%rsi, %rax		# RAX = 16 * y
#	shlq	$2, %rsi		# RSI = 64 * y
#	addq	%rsi, %rax		# RAX = 80 * y
#	addq	%rdi, %rax
#
#	movq	$0xB8000, %rdi
#	shlq	$1, %rax
#	addq	%rax, %rdi		# RDI now holds the address at which the 
#
#	movw	%ax, (%rdi) # write the char
#
#	ret

