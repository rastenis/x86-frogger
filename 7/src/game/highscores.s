.file "src/game/highscores.s"

.global showHighscores

.section .game.data

highscoresstring1: .asciz "Highscores"
highscoresstring2: .asciz "Press any key to return"

.section .game.text

showHighscores:

    # Check if the state i
    cmpq    $0, (stateDirty)
    je      _skip_highscores

    # Clear the screen
    call    screenClear

    # Print the title
    movq    $32, %rsi           # x = 32
    movq    $3, %rdx            # y = 7
    movq    $0x0f, %rcx         # black background, white foreground
    movq   	$highscoresstring1, %r8
    movq    $format, %rdi
    call    printf_coords

    # Print the exit notification
    movq    $27, %rsi           # x = 32
    movq    $20, %rdx            # y = 7
    movq    $0x0f, %rcx         # black background, white foreground
    movq   	$highscoresstring2, %r8
    movq    $format, %rdi
    call    printf_coords
   

    _skip_highscores:

    retq

listenHighscores:
    call	readKeyCode

    # something pressed:
    cmpq    $0, %rax
    je      _highscores_nothing_pressed

    # setting menu var to pressed key
    movq    $0, (gameStage)   # load the key as the game stage
    movq    $1, (switchStage)   # indicate that we switched stages

    _highscores_nothing_pressed:

    retq

