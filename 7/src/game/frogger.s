.file "src/game/frogger.s"

.global generate
.global render


.section .game.data

gameStateArray: .skip (30*20)*8 # larger than actual 20x10
shiftCounter: .skip 8
shiftCeiling: .skip 8
levelStarted: .quad 0           # indicates if the level has started

.section .game.text

# Generate the initial gamestate
generate: 

    # Preserve registers
    pushq   %rbp
    pushq   %r12
    pushq   %r13
    movq    %rsp, %rbp

    movq    $0, %r12    # outer loop counter for y coord

_generate_y:            # outer loop (y, 0-9), skipping the bottom row

    movq    $0, %r13    # inner loop counter for x coord

_generate_x:            # inner loop (x, 0-30)

    # Set current to 1
    movq    $30, %rax   # init with 30 as the number of columns
    mulq    %r12        # multiply with the current y coord (so: %rax = 30*y)
    addq    %r13, %rax  # add the x coord (so now: %rax = 30*y + x)
    movq    $1, gameStateArray(,%rax, 8)  # set the space as taken in the gameStateArray
   
    # Loop guards
    incq    %r13
    cmpq    $30, %r13
    jne     _generate_x
    incq    %r12
    cmpq    $9, %r12
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
    movq    $0, (gameStateArray + 8*15/*x=15*/ + 30*8*1/*y=1*/)
    
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

    # shifting array...
    #call    shiftAll

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
    movq    $30, %rax   # init with 30 as the number of columns
    mulq    %r12        # multiply with the current y coord (so: %rax = 30*y)
    addq    %r13, %rax  # add the x coord (so now: %rax = 30*y + x)
    
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
    cmpq    $20, %r13
    jne     _render_x
    incq    %r12
    cmpq    $10, %r12
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

_shiftAll_y:            # outer loop (y, 0-9)

    # TODO: decide direction
    movq    %r12, %rdi  # line no.
    movq    $0, %rsi    # direction
    call    shiftLine

    incq    %r12
    cmpq    $10, %r12
    jne     _render_y

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

        movq    $30, %r12   # width is 30

        # Store the rightmost item temporarily
        # TODO
        #movq    

        _shiftLine_loop_right:
        
        # Calculate the target array index
        movq    $30, %rax   # init with 30 as the number of columns
        mulq    %rdi        # multiply with the current y coord (so: %rdi = 30*y)
        addq    %r12, %rax  # add the x coord (so now: %rax = 30*y + x)

        # Calculate the source array index (source = target - 1)
        movq    %rax, %r9
        decq    %r9
        
        movq    gameStateArray(,%r9, 8), %r8    # load the source value ...
        movq    %r8, gameStateArray(,%rax, 8)   # ... and put it at the target

        # Loop guard
        decq    %r12
        cmpq    $0, %r12
        jne     _shiftLine_loop_right

        # TODO: write the original rightmost value to the leftmost slot

        jmp     _shiftLine_end

    _shiftLine_left:

        # TODO: implement (finish right shift first)

    _shiftLine_end:
    
    # Restore
    movq    %rbp, %rsp
    popq    %r12
    popq    %rbp
    

    retq