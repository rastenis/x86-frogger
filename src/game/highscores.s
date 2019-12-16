.file "src/game/highscores.s"

.global showHighscores

.section .game.data

highscoresstring1: .asciz "Highscores"
highscoresstring2: .asciz "Press any key to return"
highscoresstring3: .asciz "%u. %u"


highscoreArray:    .skip 100*8                          # allocate space for highscore storage
highscoreCurrent:  .quad 0                              # current highscore index

.section .game.text

showHighscores:

    # Preserve registers
    pushq   %rbp
    pushq   %r12
    movq    %rsp, %rbp

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
    movq    $27, %rsi           
    movq    $20, %rdx            
    movq    $0x0f, %rcx             # black background, white foreground
    movq   	$highscoresstring2, %r8
    movq    $format, %rdi
    call    printf_coords
   
    cmpq    $0, (highscoreCurrent)
    je      _skip_highscores        # nothing to show

    # Print all scores
    movq    $0, %r12

    _highscores_print_next:

    # Print a single highscore in the format:  (index). (score)
    movq    $6, %rax
    addq    %r12, %rax
    movq    $32, %rsi           
    movq    %rax, %rdx            
    movq    $0x0f, %rcx         
    movq    %r12, %r8
    movq    highscoreArray(,%r12, 8), %r9
    movq    $highscoresstring3, %rdi
    call    printf_coords

    # Looper for printing all highscores
    incq    %r12
    cmpq    %r12, (highscoreCurrent)
    jne     _highscores_print_next

    _skip_highscores:

    movq    %rbp, %rsp
    popq    %r12
    popq    %rbp

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