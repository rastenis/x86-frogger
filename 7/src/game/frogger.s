.file "src/game/frogger.s"

.global showMenu

.section .game.data

gameStateArray: .skip 200

stringgame: .asciz "You're now playing the game :)"

.section .game.text

# Generate the initial gamestate
generate: 

	# Preserve registers
	pushq   %rbp
    pushq   %r12
    pushq   %r13
	movq    %rsp, %rbp

    movq    $0, %r12    # outer loop counter for y coord

_generate_y:         	# outer loop (y, 0-9)

    movq    $0, %r13    # inner loop counter for x coord

_generate_x:         	# inner loop (x, 0-19)

	# Set current to 1
	movq    $20, %rax   # init with 20 as the number of columns
    mulq    %r12        # multiply with the current y coord (so: %rax = 20*y)
    addq    %r13, %rax  # add the x coord (so now: %rax = 20*y + x)
    movb    $1, (gameStateArray)(,%rax, 1)  # set the space as taken in the gameStateArray
   
    # Loop guards
    incq    %r13
    cmpq    $19, %r13
    jne     _generate_x
    incq    %r12
    cmpq    $9, %r12
    jne     _generate_y

    # Restore
    movq    %rbp, %rsp
    popq    %r13
    popq    %r12
    popq    %rbp


	ret
