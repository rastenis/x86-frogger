.file "src/game/frogger.s"

.global generate
.global render


.section .game.data

.equ    STATE_WIDTH, 30
.equ    STATE_HEIGHT, 10
.equ    VISIBLE_STATE_WIDTH, 20
.equ    FROGGER_START_POS_X, 10
.equ    FROGGER_START_POS_Y, 11

froggerPosX:            .quad 0
froggerPosY:            .quad 0
currentLevelFormat:     .asciz "Level: %u"
gameStateArray:         .skip (STATE_WIDTH*STATE_HEIGHT)*8  # larger than actual VISIBLE_STATE_WIDTHxSTATE_HEIGHT
shiftCounter:           .quad 0                             # shift counter for the gamestate
shiftCeiling:           .quad 0                             # shift ceiling for the gamestate
levelStarted:           .quad 0                             # indicates if the level has started
score:                  .quad 0                             # holds the score (amount of completed levels)
generationWritingCar:   .quad 0                             # indicates if we are writing a car currently
generationWritingCount: .quad 0                             # indicates how many pixels of the thing we have written
generationWritingMax:   .quad 0                             # indicates how many pixels of the thing we have to write total
generationCarLength:    .quad 0                             # indicates how many pixels a car is
generationSpaceLength:  .quad 0                             # indicates how many pixels a space is
generationEmptyLine:    .quad 0                             # indicates if line empty
generationDirection:    .quad 0                             # indicates direction



.align 16
logictbl:
    .skip 72*8
    .quad _logic_up
    .skip 8*2
    .quad _logic_left
    .skip 8*1
    .quad _logic_right
    .skip 8*2
    .quad _logic_down
    .skip (256-144)*8

.section .game.text

# Generate the initial gamestate
generate: 

    # Preserve registers
    pushq   %rbp
    pushq   %r12
    pushq   %r13
    movq    %rsp, %rbp

    movq    $1, (generationEmptyLine)       # first line empty (finish)

    movq    $0, %r12                        # outer loop counter for y coord

_generate_y:                                # outer loop (y)


    # checking if this line has to be written or empty
    cmpq    $0, (generationEmptyLine)
    je      _generation_write_line

    incq    %r12                            # move to next line
    movq    $0, (generationEmptyLine)       # next line will be filled

    _generation_write_line:

    movq    $1, (generationEmptyLine)       # next line will be empty

    movq    $0, %r13                        # inner loop counter for x coord

    # Get random length for cars
    call    rng16
    andq    $0x3, %rax
    incq    %rax                            # now %rax contains a value from 1 to 4 (inclusive)
    movq    %rax, (generationCarLength)

    # Get random length for spaces
    call    rng16
    andq    $0x3, %rax
    addq    $2, %rax                            # now %rax contains a value from 2 to 5 (inclusive)
    movq    %rax, (generationSpaceLength)
    movq    %rax, (generationWritingMax)

    movq    $0, (generationWritingCar)      # we're starting by writing a space
    movq    $0, (generationWritingCount)

_generate_x:                                # inner loop (x)
  

    # wriitng either a part of car or space
    cmpq    $1, (generationWritingCar)
    je      _generation_writing_car

    _generation_writing_space:

    # Set current to 0 (space)
    movq    $STATE_WIDTH, %rax              # init with STATE_WIDTH as the number of columns
    mulq    %r12                            # multiply with the current y coord (so: %rax = STATE_WIDTH*y)
    addq    %r13, %rax                      # add the x coord (so now: %rax = STATE_WIDTH*y + x)
    movq    $0, gameStateArray(,%rax, 8)    # set the space as taken in the gameStateArray
   
    jmp _generation_done_writing

    _generation_writing_car:

    # Set current to 1 (car)
    movq    $STATE_WIDTH, %rax              # init with STATE_WIDTH as the number of columns
    mulq    %r12                            # multiply with the current y coord (so: %rax = STATE_WIDTH*y)
    addq    %r13, %rax                      # add the x coord (so now: %rax = STATE_WIDTH*y + x)
    movq    $1, gameStateArray(,%rax, 8)    # set the space as taken in the gameStateArray

    _generation_done_writing:


    incq    generationWritingCount          # inc the generationWriting count
    movq    (generationWritingMax), %r8
    cmpq    %r8,(generationWritingCount)    # if everything is written, switch. If not, don't 
    jl      _generation_no_switch

    # Toggling car/space
    cmpq    $0, (generationWritingCar) 
    je      _generation_toggle_car

    _generation_toggle_space:

    movq    $0, (generationWritingCar)      # we're gonna be writing a space next
    movq    $0, (generationWritingCount)
    movq    (generationSpaceLength), %r8
    movq    %r8, (generationWritingMax)

    jmp _generation_no_switch

    _generation_toggle_car:

    movq    $1, (generationWritingCar)      # we're gonna be writing a car next
    movq    $0, (generationWritingCount)
    movq    (generationCarLength), %r8
    movq    %r8, (generationWritingMax)

    _generation_no_switch:

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

    # 1. Level initialization

    # Initiate the level if not initiated yet
    cmpq    $0, (levelStarted)      # compare the levelStarted flag
    jne     _level_generated        # skip if the current level has already been generated

    movq    (tick), %rdi
    call    rngSetSeed

    call    generate                # call the level generator
    
    movq    $FROGGER_START_POS_X, (froggerPosX) # reset frogger's X position
    movq    $FROGGER_START_POS_Y, (froggerPosY) # reset frogger's Y position
    
    movq    $1, (levelStarted)      # mark the level as started
    movq    $1, (stateDirty)        # mark the state as dirty
    _level_generated:

    # 2. Game state shifting

    # check shift counter and shift if needed
    incq    (shiftCounter)          # increase the shift counter
    movq    (shiftCeiling), %rax    # load the shift ceiling
    cmpq    %rax, (shiftCounter)    # compare the shift counter value to the shift ceiling
    jl      _logic_no_shift         # don't shift if we haven't reached the ceiling yet

    movq    $0, (shiftCounter)      # clear the shift counter
    movq    $1, (stateDirty)        # mark the state as dirty, because we're shifting the game state

    call    shiftAll                # do the game state shifting

    _logic_no_shift:

    # 3. Frogger state update (arrow pressing detection)

    call    readKeyCode             # read the current keycode
    cmpq    $0, %rax                # check if pressed anything
    je      _logic_arrow_handled    # if not, skip part 3

    movq    logictbl(,%rax, 8), %rax# do handler lookup in table
    testq   %rax, %rax              # check if any handler is in place
    je      _logic_arrow_handled    # if not, skip handler
    # note: handler will set stateDirty if applicable
    jmp     *%rax                   # jump to handler

    _logic_arrow_handled:

    # 4. Hit detection

    movq    (froggerPosX), %r8              # load frogger's x coord into %r8
    movq    (froggerPosY), %r9              # load frogger's y coord into %r9
    cmpq    $STATE_HEIGHT, %r9              # compare frogger's y coord to the state height
    jge     _logic_no_hit                   # if y >= STATE_HEIGHT, then frogger can't have hit anything

    movq    $STATE_WIDTH, %rax              # init with STATE_WIDTH as the number of columns
    mulq    %r9                             # multiply with frogger's y coord (so: %rax = STATE_WIDTH*y)
    addq    %r8, %rax                       # add frogger's x coord (so now: %rax = STATE_WIDTH*y + x)
    movq    gameStateArray(,%rax, 8), %rax  # load the state at the position of frogger

    testq   %rax, %rax                      # check if we hit something
    jz      _logic_no_hit                   # if not, skip the game over logic

    # TODO: *Game Over*
    # - display final score (?)
    # - store score in highscores list
    movq    $1, (gameStage)                 # switch game stage to menu
    movq    $1, (switchStage)               # indicate that we're switching stage (makes sure the menu actually appears)
    movq    $0, (score)                     # reset the score
    movq    $0, (levelStarted)              # reset the levelStarted flag

    _logic_no_hit:

    # 5. Level win detection

    cmpq    $0, (froggerPosY)               # compare frogger's y coord with 0
    jne     _logic_no_win                   # if not zero, no win

    incq    (score)                         # increase the score
    movq    $0, (levelStarted)              # mark level to be restarted
    movq    $1, (stateDirty)                # screen needs to be redrawn

    _logic_no_win:

    retq

# Handlers for the arrow logic
_logic_up:
    # bounds (y >= 0)
    cmpq    $0, (froggerPosY)
    je      _logic_arrow_handled
    # y--
    movq    $1, (stateDirty)
    decq    (froggerPosY)
    jmp     _logic_arrow_handled
_logic_down:
    # bounds (y < STATE_HEIGHT + 2)
    # +2 because player has 2 rows of space at the bottom
    cmpq    $(STATE_HEIGHT + 2 - 1), (froggerPosY)
    je      _logic_arrow_handled
    # y++
    movq    $1, (stateDirty)
    incq    (froggerPosY)
    jmp     _logic_arrow_handled
_logic_left:
    # bounds (x >= 0)
    cmpq    $0, (froggerPosX)
    je      _logic_arrow_handled
    # x--
    movq    $1, (stateDirty)
    decq    (froggerPosX)
    jmp     _logic_arrow_handled
_logic_right:
    # bounds (x < VISIBLE_STATE_WIDTH)
    cmpq    $(VISIBLE_STATE_WIDTH - 1), (froggerPosX)
    je      _logic_arrow_handled
    # x++
    movq    $1, (stateDirty)
    incq    (froggerPosX)
    jmp     _logic_arrow_handled

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

    # 1. Display the current level in the top left corner
    movq    $0, %rsi            # x = 0
    movq    $0, %rdx            # y = 0
    movq    $0x03, %rcx         # black background, cyan foreground
    movq    (score), %r8        # load the score as the format value
    incq    %r8                 # current level is score+1
    movq    $currentLevelFormat, %rdi
    call    printf_coords

    # 2. Render the cars

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

    # 3. Render FROGGAR

    movq    (froggerPosX), %rdi     # load frogger's X position
    movq    (froggerPosY), %rsi     # load frogger's Y position
    movq    $0x20, %rdx             # color info: bg=green, fg=black
    call    setPixelAtScaledColor   # draw the frogger as a scaled pixel with custom color

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


    cmpq    $0, (generationDirection)
    je      _generation_direction_1
    
    decq    (generationDirection)       # next line will be filled
    jmp     _generation_direction_done

    _generation_direction_1:

    movq    $2, (generationDirection)       # next line will be empty

    _generation_direction_done:

    movq    (generationDirection), %rsi   # direction
    movq    %r12, %rdi  # line no.
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
        movq    $STATE_WIDTH, %rax              # init wi