.file "src/game/game.s"

.global gameInit
.global gameLoop

.section .game.data

f: .asciz "%u"


.align 16
menutbl:
	.quad _menu					        # 0 (for gameInit spillover)
	.quad _menu					        # 1
	.quad _play_loop          			# 2 - 1 on top key row
	.quad _highscores_loop          	# 3 - 2 on top key row
	.quad quit          				# 4 - 3 on top key row
	.skip 251*8

.section .game.text

gameInit:
	# setting program stage to 0, menu.
	# NOTE: rbx spill over, gameInit is not always first
	movq	$1,	%r12
	ret

gameLoop:
	call screenClear	# per-gameloop screen wipe

	# JUMP STAGE: go to the appropriate section of the game loop
	movq    menutbl(,%r12,8), %rax   # do the lookup in the jump table
	testq   %rax, %rax              # check if the current char is a valid action
	jz      _end_game_loop    # if not, perform the 'unknown' action
	jmpq    *%rax  

	# MENU STAGE:
	_menu: 
	call showMenu
	call listenMenu

	jmp _end_game_loop

	# GAME STAGE (play loop instead of game loop for clarity)
	_play_loop:
	# ... call game loop
	call generate

	_highscores_loop:

	
	_end_game_loop:

	ret


quit:
# TODO: close qemu?