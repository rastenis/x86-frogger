.file "src/game/game.s"

.global gameInit
.global gameLoop

.section .game.data

f: .asciz "%u"
tick: .quad 0
gameStage: .skip 8
stateDirty: .skip 8                     # rendering flag
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
    movq    $1,	(stateDirty)

    movq    $0, (shiftCounter)      # setting initial shift counter+ceiling
    movq    $50, (shiftCeiling)

    #movq	$2993182, %rdi
    #call	setTimer

    retq

gameLoop:

    pushq   %rbp
    movq    %rsp, %rbp

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

    movq    %rbp, %rsp
    popq    %rbp

    retq

#########################
# Game stage offloaders #
#########################

    #
    # MENU STAGE
    #
    _menu: 

    call    listenMenu              # listen before showing, because a key may have been pressed which makes the state dirty
    call 	showMenu                # show the actual menu

    jmp     _stage_handler_done

    #
    # PLAY STAGE
    #
    _play_loop:
    call    logic
    call    render                  # render the current game state
    jmp     _stage_handler_done

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