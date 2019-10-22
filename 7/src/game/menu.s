.file "src/game/game.s"

.global showMenu

.section .game.data

menustring1: .asciz "Frogger v0.0.1"
menustring2: .asciz "      By:"
menustring3: .asciz "   xx and xx"
menustring4: .asciz "1) Start game"
menustring5: .asciz "2) Highscores"
menustring6: .asciz "3) Quit"

format: .asciz "%s"

.section .game.text

showMenu:

	# Print the title
	movq    $32, %rsi           # x = 32
	movq    $7, %rdx            # y = 7
	movq    $0x0f, %rcx         # black background, white foreground
	movq   	$menustring1, %r8
	movq    $format, %rdi
	call    printf_coords
	
    # Print the author data 1
	movq    $32, %rsi           # x = 5
	movq    $8, %rdx            # y = 5
	movq    $0x0f, %rcx         # black background, white foreground
	movq   	$menustring2, %r8
	movq    $format, %rdi
	call    printf_coords
	# Print the author data 2
	movq    $32, %rsi           # x = 5
	movq    $9, %rdx            # y = 5
	movq    $0x0f, %rcx         # black background, white foreground
	movq   	$menustring3, %r8
	movq    $format, %rdi
	call    printf_coords
	# Print 1) Start game
	movq    $32, %rsi           # x = 5
	movq    $15, %rdx            # y = 5
	movq    $0x0f, %rcx         # black background, white foreground
	movq   	$menustring4, %r8
	movq    $format, %rdi
	call    printf_coords
	# Print 2) Highscores
	movq    $32, %rsi           # x = 5
	movq    $16, %rdx            # y = 5
	movq    $0x0f, %rcx         # black background, white foreground
	movq   	$menustring5, %r8
	movq    $format, %rdi
	call    printf_coords
	# Print 3) Quit
	movq    $32, %rsi           # x = 5
	movq    $17, %rdx            # y = 5
	movq    $0x0f, %rcx         # black background, white foreground
	movq   	$menustring6, %r8
	movq    $format, %rdi
	call    printf_coords

	ret

listenMenu:
	call	readKeyCode

	# something pressed:
	cmpq	$5, %rax	
	jl		_menu_nothing_pressed	# TODO: this does not work; every key gets written to rbx, not only 1234

	# setting menu var to pressed key
	movq	%rax, %rbx

	_menu_nothing_pressed:

	ret
