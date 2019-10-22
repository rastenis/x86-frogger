.file "src/game/display.s"

.global setPixelAt
.global setPixelAtScaled
.global initiateDisplay

.section .game.data

.section .game.text

#
# setPixelAt
#
# Sets a pixel at the given X and Y to space witwhite background.
#
# Parameters:
#  %rdi     x
#  %rsi     y
#
setPixelAt:
    movq    $80, %rax   # init with 80 as the number of columns
    mulq    %rsi        # multiply with the current y coord (so: %rax = 80*y)
    addq    %rdi, %rax  # add the x coord (so now: %rax = 80*y + x)
    movw    $0xFF20, 0xB8000(,%rax, 2)  # write to the VGA text mode buffer
    retq

#
# Sets a scaled pixel (2 x 4)
#
# Parameters:
#  %rdi     virtual x (x*4)
#  %rsi     virtual y (y*2)
#
setPixelAtScaled:
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    pushq   %rbp
	movq    %rsp, %rbp

    shlq    $2, %rdi    # scaling coords
    shlq    $1, %rsi

    movq    %rdi, %r14  # x
    movq    %rsi, %r15  # y

    movq    $0, %r12

_setPixelAtScaled_y:

    movq    $0, %r13

_setPixelAtScaled_x:

    movq    %r13, %rdi      # x coord
    addq    %r14, %rdi      # x += scaled x
    movq    %r12, %rsi      # y coord
    addq    %r15, %rsi      # y += scaled y
    call    setPixelAt

    incq    %r13
    cmpq    $4, %r13
    jne     _setPixelAtScaled_x
    incq    %r12
    cmpq    $2, %r12
    jne     _setPixelAtScaled_y

    movq    %rbp, %rsp
    popq    %rbp
    popq   %r15
    popq   %r14
    popq    %r13
    popq    %r12

    retq


#
# Initiate the display into VESA mode 4 (from mode 3) ?
#
initiateDisplay:

    pushq   %rbp
    pushq   %rbx
    movq    %rsp, %rbp

    #movq    $0x4F02, %rax
    #movq    $0x4118, %rbx
    #int     $0x10
#
	#movq    $0, %rsi           # x = 32
	#movq    $0, %rdx            # y = 15
	#movq    $0x0f, %rcx         
	#movq   	%rax, %r8
	#movq    $f, %rdi
	#call    printf_coords

    movq   %rbp, %rsp
    popq   %rbx
    popq   %rbp
    
    retq
