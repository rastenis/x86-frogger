.file "src/game/game.s"

.global gameInit
.global gameLoop

.section .game.data


.section .game.text

gameInit:
	# call generation for the first time
	ret

gameLoop:

	pushq   %rbp                # store the old base pointer
	movq    %rsp, %rbp          # store current stack pointer as base pointer

	# Preparing a simulation of a out_printf call
	movq    $5, %rsi            # x = 5
	movq    $5, %rdx            # y = 5
	movq    $0x0f, %rcx         # black background, white foreground
	movq    $-1, %r8
	movq    $91, %r9
	pushq   $string1
	movq    $format, %rdi
	call    printf_coords

	movq    %rbp, %rsp          # discard local variables
	popq    %rbp                # restore the base pointer

	ret
