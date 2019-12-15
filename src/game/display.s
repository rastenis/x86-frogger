.file "src/game/display.s"

.global setPixelAt
.global setPixelAtScaled
.global initiateDisplay

.section .game.data

.section .game.text

#
# setPixelAt
#
# Sets a pixel at the given X and Y to space character and the given color info.
#
# Parameters:
#  %rdi     x
#  %rsi     y
#  %rdx     color info (only lower byte)
#
setPixelAt:
    movq    %rdx, %r8               # move %rdx to %r8, because %rdx will be overwritten by multiplication below
    andq    $0xFF, %r8              # make sure only the lower byte is used
    movq    $80, %rax               # init with 80 as the number of columns
    mulq    %rsi                    # multiply with the current y coord (so: %rax = 80*y)
    addq    %rdi, %rax              # add the x coord (so now: %rax = 80*y + x)
    shlq    $8, %r8                 # color info should go in bits 8-15, so %r8 <<= 8
    orq     $0x0020, %r8            # set the character to a space
    movw    %r8w, 0xB8000(,%rax, 2) # write to the VGA text mode buffer
    retq

#
# Sets a scaled pixel (2 x 4) at the given coordinates to white.
#
# Parameters:
#  %rdi     virtual x (x*4)
#  %rsi     virtual y (y*2)
#  %rdx     color info
#
setPixelAtScaledColor:
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    pushq   %rbp
	movq    %rsp, %rbp

    pushq   %rdx        # store the pixel color on the local stack frame

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
    movq    -8(%rbp), %rdx  # load color info into %rdx, prep for setPixelAt
    call    setPixelAt

    incq    %r13
    cmpq    $4, %r13
    jne     _setPixelAtScaled_x
    incq    %r12
    cmpq    $2, %r12
    jne     _setPixelAtScaled_y

    movq    %rbp, %rsp
    popq    %rbp
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12

    retq

#
# Sets a scaled pixel (2 x 4) at the given coordinates to white.
#
# Parameters:
#  %rdi     virtual x (x*4)
#  %rsi     virtual y (y*2)
#
setPixelAtScaled:
    movq    $0xFF, %rdx             # set color to bg=white, fg=white
    call    setPixelAtScaledColor   # propagate arguments
    retq
