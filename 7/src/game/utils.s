.file "src/game/game.s"

.global screenClear

.section .game.data

clearstring: .asciz "                                                                                   "

screenClear:
	# Print temp.

	pushq   %rbp                # store the old base pointer
	movq    %rsp, %rbp          # store current stack pointer as base pointer

	pushq	%r12
	movq	$0,	%r12			# loop counter and static params

	_clear_loop:
	
	movq	%r12, %rdx			# setting params for empty string with dynamic y coord
	movq    $0x0f, %rcx   		      
	movq    $format, %rdi
	movq   	$clearstring, %r8
	movq    $0, %rsi           	
	call    printf_coords

	incq	%r12				# incrementing wipe counter and jumping back
	cmpq	$100, %r12
	jle		_clear_loop

	popq	%r12				# restoring 

	movq    %rbp, %rsp          # discard local variables
	popq    %rbp                # restore the base pointer

	retq
	