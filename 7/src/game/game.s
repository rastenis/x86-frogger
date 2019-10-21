.file "src/game/game.s"

.global gameInit
.global gameLoop

.section .game.data

.section .game.text

gameInit:
	# call generation for the first time
	ret

gameLoop:
	# Check if a key has been pressed
	call	readKeyCode
	cmpq	$0, %rax
	je		1f
	# If so, print a 'Y'
	movb	$'Y, %dl
	jmp		2f

1:
	# Otherwise, print a 'N'
	movb	$'N, %dl

2:
	movq	$0, %rdi
	movq	$0, %rsi
	movb	$0x0f, %cl
	call	putChar

	ret
