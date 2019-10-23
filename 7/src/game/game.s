.file "src/game/game.s"

.global gameInit
.global gameLoop

.section .game.data

f: .asciz "%u"
tick: .quad 0
gameStage: .skip 8
stateDirty: .quad 0                     # rendering flag
number: .asciz "%u"

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
    movq    $500, (shiftCeiling)

    call    generate

    #movq	$2993182, %rdi
    #call	setTimer

    # Set the RNG seed
    # TODO: set the RNG seed based on the tick in which the user starts the game
    movq    $29384902834239087, %rdi
    call    rngSetSeed

    retq

gameLoop:
    call    screenClear	        # clear the screen before each screen update

    # Debug tick counter
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