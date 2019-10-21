.file "src/game/game.s"

.global showMenu

.section .game.data

string1: .asciz "Frogger v0.0.1"
string2: .asciz "      By:"
string3: .asciz "xx and xx"
string4: .asciz "1) Start game"

format: .asciz "%s"

.section .game.text

showMenu:

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
	# Print
	movq    $32, %rsi           # x = 5
	movq    $9, %rdx            # y = 5
	movq    $0x0f, %rcx         # black background, white foreground
	movq   	$string3, %r8
	movq    $format, %rdi
	call    printf_coords
	# Print
	movq    $32, %rsi           # x = 5
	movq    $15, %rdx            # y = 5
	movq    $0x0f, %rcx         # black background, white foreground
	movq   	$string4, %r8
	movq    $format, %rdi
	call    printf_coords

	ret

listenMenu:
	call	readKeyCode
	cmpq	$0, %rax
	je		_menu_nothing_pressed

	# something pressed:
	cmpq	$48, %rax
	jle		_menu_nothing_pressed

	# setting menu var to pressed key
	subq	$48, %rax
	movq	%rax, %rbx

	_menu_nothing_pressed:

	ret
