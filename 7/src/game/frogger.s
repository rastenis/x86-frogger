.file "src/game/game.s"

.global showMenu

.section .game.data

stringgame: .asciz "You're now playing the game :)"

.section .game.text

generate:
	# Print temp.
	movq    $32, %rsi           # x = 32
	movq    $15, %rdx            # y = 15
	movq    $0xf3, %rcx         
	movq   	$stringgame, %r8
	movq    $format, %rdi
	call    printf_coords

	ret
