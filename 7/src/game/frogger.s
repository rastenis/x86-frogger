.file "src/game/frogger.s"

.global generate
.global render


.section .game.data

.equ    STATE_WIDTH, 30
.equ    STATE_HEIGHT, 10
.equ    VISIBLE_STATE_WIDTH, 20

gameStateArray: .skip (STATE_WIDTH*STATE_HEIGHT)*8  # larger than actual VISIBLE_STATE_WIDTHxSTATE_HEIGHT
shiftCounter:   .skip 8
shiftCeiling:   .skip 8
levelStarted:   .quad 0                             # indicates if the level has started

.section .game.text

# Generate the initial gamestate
generate: 

    # Preserve registers
    pushq   %rbp
    pushq   %r12
    pushq   %r13
    movq    %rsp, %rbp

    movq    $0, %r12    # outer loop counter for y coord

_generate_y:            # outer loop (y)

    movq    $0, %r13    # inner loop counter for x coord

_generate_x:            # inner loop (x)

    # Set current to 1
    movq    $STATE_WIDTH, %rax   # init with STATE_WIDTH as the number of columns
    mulq    %r12        # multiply with the current y coord (so: %rax = STATE_WIDTH*y)
    addq    %r13, %rax  # add the x coord (so now: %rax = STATE_WIDTH*y + x)
    movq    $1, gameStateArray(,%rax, 8)  # set the space as taken in the gameStateArray
   
    # Loop guards
    incq    %r13
    cmpq    $STATE_WIDTH, %r13
    jne     _generate_x
    incq    %r12
    cmpq    $STATE_HEIGHT, %r12
    jne     _generate_y

    # Restore
    movq    %rbp, %rsp
    popq    %r13
    popq    %r12
    popq    %rbp

    retq

#
# logic
#
# Core game logic handler. May set stateDirty to indicate that the screen needs to be redrawn.
#
logic:
    # Initiate the level if not initiated yet
    cmpq    $0, (levelStarted)      # compare the levelStarted flag
    jne     _level_generated        # skip if the current level has already been generated
    call    generate                # call the level generator
    
    # TEMP: put a blank space to test shifting impl
    movq    $0, (gameStateArray + 8*15/*x=15*/ + STATE_WIDTH*8*1/*y=1*/)
    
    movq    $1, (levelStarted)      # mark the level as started
    movq    $1, (stateDirty)        # mark the state as dirty
    _level_generated:

    # TODO: check for frogger movement

    # check shift counter and shift if needed
    incq    (shiftCounter)
    movq    (shiftCeiling), %rax
    cmpq    (shiftCounter), %rax 
    jne     _logic_no_shift

    movq    $0, (shiftCounter)
    movq    $1, (stateDirty)

    # shifting array...
    call    shiftAll

    _logic_no_shift:


    retq

#
# render
#
# Core game state rendering.
#
render: 

    cmpq    $0, (stateDirty)
    je      _skip_render

    # Preserve registers
    pushq   %rbp
    pushq   %r12
    pushq   %r13
    pushq   %r14
    movq    %rsp, %rbp

    # Clear the screen, because we're going to draw something new
    call    screenClear

    movq    $0, %r12    # outer loop counter for y coord

_render_y:              # outer loop (y, 0-9)

    movq    $0, %r13    # inner loop counter for x coord

_render_x:              # inner loop (x, 0-19)

    # Write pixel if current flag is 1
    movq    $STATE_WIDTH, %rax   # init with STATE_WIDTH as the number of columns
    mulq    %r12        # multiply with the current y coord (so: %rax = STATE_WIDTH*y)
    addq    %r13, %rax  # add the x coord (so now: %rax = STATE_WIDTH*y + x)
    
    movq    gameStateArray(,%rax, 8), %r14
    cmpq    $0, %r14
    je      _no_render

    # Write pixel at virtual resolion x and y
    movq    %r13, %rdi
    movq    %r12, %rsi
    call    setPixelAtScaled

_no_render:
   
    # Loop guards
    incq    %r13
    cmpq    $VISIBLE_STATE_WIDTH, %r13
    jne     _render_x
    incq    %r12
    cmpq    $STATE_HEIGHT, %r12
    jne     _render_y

    # Restore
    movq    %rbp, %rsp
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbp

_skip_render:

    retq



#
# shift
#
# game state shifter
# 
shiftAll: 

    # Preserve registers
    pushq   %rbp
    pushq   %r12
    movq    %rsp, %rbp

    # Clear the screen, because we're going to draw something new
    call    screenClear

    movq    $0, %r12    # outer loop counter for y coord

_shiftAll_y:            # outer loop (y)

    # TODO: decide direction
    movq    %r12, %rdi  # line no.
    movq    $1, %rsi    # direction
    call    shiftLine

    incq    %r12
    cmpq    $STATE_HEIGHT, %r12
    jne     _shiftAll_y

    # Restore
    movq    %rbp, %rsp
    popq    %r12
    popq    %rbp

    retq


#
# shiftLine
# 
# shift one line
#
# Parameters:
#  %rdi - line y to be shifted
#  %rsi - direction of the shift, 0=right, 1=left
#   
shiftLine:

    # Preserve registers
    pushq   %rbp
    pushq   %r12
    movq    %rsp, %rbp

    # Decide which direction to use
    cmpq    $1, %rsi
    je      _shiftLine_left
    # just continues to _shiftLine_right otherwise

    _shiftLine_right:

        movq    $STATE_WIDTH, %r12   # width is STATE_WIDTH

        # Store the rightmost item temporarily (in %r10)
        movq    $STATE_WIDTH, %rax              # init with the number of columns
        mulq    %rdi                            # multiply with the current y coord (so: %rax = cols*y)
        addq    $(STATE_WIDTH - 1), %rax        # add $STATE_WIDTH as the x coord (so now: %rax: cols*y + cols)
        movq    gameStateArray(,%rax, 8), %r10  # finally load it into %r10

        _shiftLine_loop_right:
        
        decq    %r12
        
        # Calculate the target array index
        movq    $STATE_WIDTH, %rax   # init with STATE_WIDTH as the number of columns
        mulq    %rdi        # multiply with the current y coord (so: %rdi = STATE_WIDTH*y)
        addq    %r12, %rax  # add the x coord (so now: %rax = STATE_WIDTH*y + x)

        # Calculate the source array index (source = target - 1)
        movq    %rax, %r9
        decq    %r9
        
        movq    gameStateArray(,%r9, 8), %r8    # load the source value ...
        movq    %r8, gameStateArray(,%rax, 8)   # ... and put it at the target

        # Loop guard
        cmpq    $0, %r12
        jne     _shiftLine_loop_right

        # Store the temporary rightmost item (stored in %r10) in the leftmost slot
        movq    $STATE_WIDTH, %rax              # init with the number of columns
        mulq    %rdi                            # multiply with the current y coord (so: %rax = cols*y), and x=0
        movq    %r10, gameStateArray(,%rax, 8)  # finally store the temporary value back in the leftmost slot

        jmp     _shiftLine_end

    _shiftLine_left:

        movq    $0, %r12                        # start y at 0

        # Store the left item temporarily (in %r10)
        movq    $STATE_WIDTH, %rax              # init with the number of columns
        mulq    %rdi                            # multiply with the current y coord (so: %rax = cols*y)
        movq    gameStateArray(,%rax, 8), %r10  # finally load it into %r10

        _shiftLine_loop_left:
        
        # Calculate the target array index
        movq    $STATE_WIDTH, %rax   # init with STATE_WIDTH as the number of columns
        mulq    %rdi        # multiply with the current y coord (so: %rdi = STATE_WIDTH*y)
        addq    %r12, %rax  # add the x coord (so now: %rax = STATE_WIDTH*y + x)

        # Calculate the source array index (source = target - 1)
        movq    %rax, %r9
        incq    %r9
        
        movq    gameStateArray(,%r9, 8), %r8    # load the source value ...
        movq    %r8, gameStateArray(,%rax, 8)   # ... and put it at the target

        # Loop guard
        incq    %r12
        cmpq    $STATE_WIDTH, %r12
        jne     _shiftLine_loop_left

        # Store the temporary left item (stored in %r10) in the rightmost slot
        movq    $STATE_WIDTH, %rax              # init with the number of columns
        mulq    %rdi                            # multiply with the current y coord (so: %rax = cols*y), and x=0
        addq    $(STATE_WIDTH - 1), %rax        # add $STATE_WIDTH as the x coord (so now: %rax: cols*y + cols)
        movq    %r10, gameStateArray(,%rax, 8)  # finally store the temporary value back in the leftmost slot

        jmp     _shiftLine_end

    _shiftLine_end:
    
    # Restore
    movq    %rbp, %rsp
    popq    %r12
    popq    %rbp
    
    retq