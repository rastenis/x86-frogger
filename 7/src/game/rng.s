.file "src/game/rng.s"

.global rngSetSeed
.global rng16

.section .game.data

rngPrev: .quad 0

.section .game.text

#
# u64 _rngNext()
#
# Get the next RNG base value.
# next_base = prev_base * 1103515245 + 12345
#
_rngNext:
    movq    $0, %rdx            # clear %rdx
    movq    (rngPrev), %rax     # init %rax with previous rng value
    movq    $1103515245, %r8    # init %r8 (the value to multiply with)
    mulq    %r8                 # %rax = %rax*%r8 = (rngPrev)*1103515245
    addq    $12345, %rax        # %rax += 12345
    movq    %rax, (rngPrev)     # store back in rngPrev
    retq                        # %rax still contains the return value

#
# void rngSetSeed(u64)
#
# Set the seed for the RNG.
#
# Parameters:
#  %rdi new seed
#
rngSetSeed:
    movq    %rdi, (rngPrev)     # set the seed
    retq

#
# u64 rng()
#
# Generate a 16 bit pseudo-random random number.
# random_number = (next_base / 0x1FFFF) % 0xFFFF
#
rng16:
    call    _rngNext            # get the next RNG base value (res in %rax)
    movq    $0x1FFFF, %r8       # prep $0x1FFFF
    movq    $0, %rdx            # clear %rdx
    divq    %r8                 # %rax /= $0x1FFFF
    movq    $0x0FFFF, %r8       # prep $0x0FFFF
    movq    $0, %rdx            # clear %rdx from previous calculation
    divq    %r8                 # %rdx == %rax % $0x0FFFF
    movq    %rdx, %rax          # return %rdx, so %rax = %rdx
    retq
