.file "src/game/game.s"

.global gameInit
.global gameLoop

.section .game.data

.section .game.text

gameInit:
	# call generation for the first time
	movq	$0,	%rbx
	ret


gameLoop:
	# 
	# registers used:
	# 	%rbx   program stage counter; 0 is the initial value (menu stage), 1 is the game stage, 2 is high score, 3 is exit.
	# 	...
	#

	# MENU STAGE:
	_menu: 
	call showMenu

	# GAME STAGE
	_game_loop:
	# ... call game loop

	ret
