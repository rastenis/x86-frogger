.file "src/game/game.s"

.global gameInit
.global gameLoop

.section .game.data

string1: .asciz "Frogger v0.0.1"
string2: .asciz "      By:"
string3: .asciz "xx and xx"
string4: .asciz "1) Start game"


format: .asciz "%s"


.section .game.text

gameInit:
	# call generation for the first time
	ret

gameLoop:

	pushq   %rbp                # store the old base pointer
	movq    %rsp, %rbp          # store current stack pointer as base pointer

	# Print the title
	movq    $32, %rsi           # x = 32
	movq    $7, %rdx            # y = 7
	movq    $0x0f, %rcx         # black background, white foreground
	movq   	$string1, %r8
	movq    $format, %rdi
	call    printf_coords
	
    # Print the menu options
	movq    $32, %rsi           # x = 5
	movq    $8, %rdx            # y = 5
	movq    $0x0f, %rcx         # black background, white foreground
	movq   	$string2, %r8
	movq    $format, %rdi
	call    printf_coords
	# Prin
	movq    $32, %rsi           # x = 5
	movq    $9, %rdx            # y = 5
	movq    $0x0f, %rcx         # black background, white foreground
	movq   	$string3, %r8
	movq    $format, %rdi
	call    printf_coords
	# Prin
	movq    $32, %rsi           # x = 5
	movq    $15, %rdx            # y = 5
	movq    $0x0f, %rcx         # black background, white foreground
	movq   	$string4, %r8
	movq    $format, %rdi
	call    printf_coords

	# LEFTOFF: loop until enter or H or Q pressed (or esc) move this to menu.s

	movq    %rbp, %rsp          # discard local variables
	popq    %rbp                # restore the base pointer

	ret
