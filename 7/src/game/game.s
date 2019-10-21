.file "src/game/game.s"

.global gameInit
.global gameLoop

.section .game.data

# TODO: table for game loop section jumps

.section .game.text

gameInit:
	# setting program stage to 0, menu
	movq	$0,	%rbx
	ret

gameLoop:
	# 
	# registers used:
	# 	%rbx   program stage counter; 0 is the initial value (menu stage), 1 is the game stage, 2 is high score, 3 is exit.
	# 	...
	#

	# TODO: fix %rbx spillover (gameLoop gets executed before gameInit, BAD).

	# JUMP STAGE: go to the appropriate section of the game loop
	# TODO: expand with table
	cmpq $0, %rbx
	jne _play_loop

	# MENU STAGE:
	_menu: 
	call showMenu
	call listenMenu

	jmp _end_game_loop

	# GAME STAGE (play loop instead of game loop for clarity)
	_play_loop:
	# ... call game loop
	call generate

	_end_game_loop:

	ret
