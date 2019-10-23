.file "src/game/game.s"

.global gameInit
.global gameLoop

.section .game.data

f:          .asciz "%u"
tick:       .quad 0
gameStage:  .quad 0
stateDirty: .quad 0                     # rendering flag
switchStage:.quad 0                     # set to 1 if switching stages
number:     .asciz "%u"

.align 16
menutbl:
    .quad _menu					        # 0 (for gameInit spillover)
    .quad _menu					        # 1
    .quad _play_loop          			# 2 - 1 on top key row
    .quad _highscores_loop          	# 3 - 2 on top key row
    .quad quit          				# 4 - 3 on top key row
    .skip 251*8

.section .game.text

gameInit:
    # setting program stage to 0, menu.
    # NOTE: spill over, gameInit is not always first
    movq    $1,	(gameStage)

    movq    $0, (shiftCounter)      # setting initial shift counter+ceiling
    movq    $50, (shiftCeiling)

    #call    generate

    #movq	$2993182, %rdi
    #call	setTimer

    # Set the RNG seed
    # TODO: set the RNG seed based on the tick in which the user starts the game
    movq    $29384902834239087, %rdi
    call    rngSetSeed

    retq

gameLoop:
    call    screenClear	        # clear the screen before each screen update

    pushq   %rbp
    movq    %rsp, %rbp

    # Set stateDirty if we just switched the stage
    cmpq    $0, (switchStage)
    je      _gameLoop_no_stage_switch
    movq    $1, (stateDirty)
    movq    $0, (switchStage)
    _gameLoop_no_stage_switch:

    # Decide on the game stage
    movq	(gameStage), %rax
    movq    menutbl(,%rax,8), %rax  # do the lookup in the jump table
    testq   %rax, %rax              # check if the current char is a valid action
    jz      _stage_handler_done     # if not, act like we did nothing
    jmpq    *%rax

    _stage_handler_done:

    movq    $0, (stateDirty)        # at the end of the tick, must reset stateDirty, because everything should have been rendered by now

    # Debug tick counter (draw over everything)
    movq    $0, %rsi            # x = 0
    movq    $0, %rdx            # y = 0
    movq    $0x0F, %rcx         # black background, white foreground
    movq    (tick), %r8
    movq    $number, %rdi
    call    printf_coords
    incq    (tick)

    # JUMP STAGE: go to the appropriate section of the game loop
    movq	(gameStage), %rax
    movq    menutbl(,%rax,8), %rax  # do the lookup in the jump table
    testq   %rax, %rax              # check if the current char is a valid action
    jz      _end_game_loop    		# if not, perform the 'unknown' action
    jmpq    *%rax  

    # MENU STAGE:
    _menu: 

    # TEMP 
    movq	$2, %rdi
    movq	$2, %rsi
    call 	setPixelAtScaled

    call 	showMenu
    call 	listenMenu

    jmp _end_game_loop

    # GAME STAGE (play loop instead of game loop for clarity)
    _play_loop:
    # ... call game loop
    call generate

    _highscores_loop:

    
    _end_game_loop:

    retq

    #
    # HIGHSCORE STAGE
    #
    _highscores_loop:
    # TODO
    jmp     _stage_handler_done

quit:
    # TODO: close qemu?
    # TEMP:
    jmp     _stage_handler_done