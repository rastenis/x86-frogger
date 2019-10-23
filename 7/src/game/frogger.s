.file "src/game/frogger.s"

.global generate
.global render


.section .game.data

gameStateArray: .skip (25*20)	# larger than actual 20x10

.section .game.text

# Generate the initial gamestate
generate: 

    # Preserve registers
    pushq   %rbp
    pushq   %r12
    pushq   %r13
    movq    %rsp, %rbp

    movq    $0, %r12    # outer loop counter for y coord

_generate_y:         	# outer loop (y, 0-9)

    movq    $0, %r13    # inner loop counter for x coord

_generate_x:         	# inner loop (x, 0-19)

    # Set current to 1
    movq    $25, %rax   # init with 20 as the number of columns
    mulq    %r12        # multiply with the current y coord (so: %rax = 20*y)
    addq    %r13, %rax  # add the x coord (so now: %rax = 20*y + x)
    movb    $1, (gameStateArray)(,%rax, 1)  # set the space as taken in the gameStateArray
   
    # Loop guards
    incq    %r13
    cmpq    $25, %r13
    jne     _generate_x
    incq    %r12
    cmpq    $19, %r12
    jne     _generate_y

    # Restore
    movq    %rbp, %rsp
    popq    %r13
    popq    %r12
    popq    %rbp

    ret

#
# logic
#
# Core game logic handler. May set stateDirty to indicate that the screen needs to be redrawn.
#
logic:
    # TEMP: always mark screen dirty
    movq    $1, (stateDirty)

    # TODO: init level if just landed at this level
    # TODO: check for frogger movement
    # TODO: handle 'ceiling counter'

    retq

#
# render
#
# Core game state rendering.
#
render: 

    cmpq	$0, (stateDirty)
    je		_skip_render

    # Preserve registers
    pushq   %rbp
    pushq   %r12
    pushq   %r13
    pushq   %r14
    movq    %rsp, %rbp

    # Clear the screen, because we're going to draw something new
    call	screenClear

    movq    $0, %r12    # outer loop counter for y coord

_render_y:         	# outer loop (y, 0-9)

    movq    $0, %r13    # inner loop counter for x coord

_render_x:         	# inner loop (x, 0-19)

    # Write pixel if current flag is 1
    movq    $20, %rax   # init with 20 as the number of columns
    mulq    %r12        # multiply with the current y coord (so: %rax = 20*y)
    addq    %r13, %rax  # add the x coord (so now: %rax = 20*y + x)
    
    movq	$0, %r14
    movb	(gameStateArray)(%rax), %r14b
    cmpq	$0, %r14
    je		_no_render

    # Write pixel at virtual resolion x and y
    movq	%r13, %rdi
    movq	%r12, %rsi
    call 	setPixelAtScaled

_no_render:
   
    # Loop guards
    incq    %r13
    cmpq    $20, %r13
    jne     _render_x
    incq    %r12
    cmpq    $10, %r12
    jne     _render_y

    # Restore
    movq    %rbp, %rsp
    popq   	%r14
    popq    %r13
    popq    %r12
    popq    %rbp

_skip_render:

    ret
