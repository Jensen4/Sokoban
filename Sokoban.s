.data
heappointer:		.word 0

gridsize:   		.byte 8, 8 # columns by rows (x, y)
character:  		.byte 0,0,0,0 # All of these are 4 bytes as the first two are the ones being changed by each move
box:        		.byte 0,0,0,0 # And the second two keep the starting coords
target:     		.byte 0,0

characterLetter:	.word 'P'
boxLetter: 			.word 'B'
targetLetter: 		.word 'X'
wallLetter: 		.word '@'
newline:			.word '\n'
empty:				.word '_'

boardsizeRowPrompt:	.string "Enter the # of rows for the board: "
boardsizeColPrompt:	.string "Enter the # of columns for the board: "

movePrompt:			.string "Enter either w/a/s/d/r: "
invalidPrompt:		.string "\nThe move you inputted is not valid. Please try again.\n"
invalidMovePrompt:	.string "\nThe move you inputted does not change the board.\n"
restartPrompt:		.string "\nGame is being restarted.\n\n"
completedPrompt:	.string " you have beat the game! Congratulations! \n\n"
numPlayerPrompt:	.string "Enter the number of players: "

titleLeaderboard:	.string "\nLeaderboard:\n"
playerLeaderboard:	.string "Player #"
movesLeaderboard:	.string " with total moves: "

replayPrompt:		.string "\nEnter a player number to replay their moves or 0 to exit: "
replayMove:			.string "->"

.text
.globl _start

_start:
	la sp, 0x80000000 # initializing stack pointer
	la s0, gridsize # loading the board size in register s0
	
	la a0, heappointer
	li t0, 0x10000000
	sw t0, 0(a0)
	
	
	li a7, 30
	ecall
	mv a5, a0
	
	li a7, 4 # Setting the number of columns
	la a0, boardsizeColPrompt
	ecall
	
	li a7, 5
	ecall
	
	sb a0, 0(s0)
	
	li a7, 4 # Setting the number of rows
	la a0, boardsizeRowPrompt
	ecall
	
	li a7, 5
	ecall
	
	sb a0, 1(s0)
	
	li a7, 4
	la a0, numPlayerPrompt
	ecall
	
	li a7, 5
	ecall
	
	sb a0, 0(sp) # Store the number of players into the top of stack
				 
	li a7, 4
	la a0, newline
	ecall
	
	lb a3, 0(sp) # Store number of players
	li a2, 0 # Store number of players gone
	li a4, 0 # Store player move count
	j PlayerCoord
	forGame:
		addi sp, sp, -4 # The order goes #players -> P1 #Moves -> Player 1 Number
		sw a4, 0(sp)	# -> P2 #Moves -> Player 2 Number ....
		addi sp, sp, -4
		sw a2, 0(sp)
		beq a3, a2, leaderboard
		
		j restartGame
		
    # TODO: Generate locations for the character, box, and target. Static
    # locations in memory have been provided for the (x, y) coordinates 
    # of each of these elements.
    # 
    # There is a notrand function that you can use to start with. It's 
    # really not very good; you will replace it with your own rand function
    # later. Regardless of the source of your "random" locations, make 
    # sure that none of the items are on top of each other and that the 
    # board is solvable.
	
	# Player Coordinate Generator
	PlayerCoord:
		la s1, character
		lb a0, 0(s0)
		jal lfsr
		sb a0, 0(s1)
		sb a0, 2(s1) # Store starting coords
		lb a0, 1(s0)
		jal lfsr
		sb a0, 1(s1)
		sb a0, 3(s1) # Store starting coords
	
	# Box Coordinate Generator
	BoxCoord:
		la s2, box
		lb a0, 0(s0)
		jal lfsr
		sb a0, 0(s2)
		sb a0, 2(s2) # Store starting coords
		lb t3, 1(s1) # This loop is used to ensure character and box do not have same coords and also to check that the box is not in a corner
		WHILE:
			lb a0, 1(s0)
			jal lfsr
			bne t3, a0, DONE
			j WHILE
		DONE:
		sb a0, 1(s2)
		sb a0, 3(s2) # Store starting coords
	BoxWhile:
		jal cornerCheckBox
		bne a0, x0, BoxWhileDone
		j BoxCoord
	BoxWhileDone:
	
	# Target Coordinate Generator
	targetCoord:
		la s3, target
		lb a0, 0(s0)
		jal lfsr
		sb a0, 0(s3)
		lb t3, 1(s1) # This loop is used to ensure target does not have same coordinates as box and character
		lb t4, 1(s2)
		WHILE2:
			lb a0, 1(s0)
			jal lfsr
			bne t3, a0, CHECK
			j WHILE2
		CHECK:
			bne t4, a0, DONE2
			j WHILE2
		DONE2:
		sb a0, 1(s3)

		jal wallCheckBox # Setting target coordinate to respective box coordinate if box is hugging wall
		li t0, 1 		 # Doing so ensures the game is solvable
		beq a0, t0, fixTargetX
		li t0, 2
		beq a0, t0, fixTargetY
		j fixTargetDone
		fixTargetX:
			lb t0, 0(s2)
			sb t0, 0(s3)
			lb t0, 1(s2)
			lb t1, 1(s3)
			bne t0, t1, fixTargetDone
			j targetCoord
		fixTargetY:
			lb t0, 1(s2)
			sb t0, 1(s3)
			lb t0, 0(s2)
			lb t1, 0(s3)
			bne t0, t1, fixTargetDone
			j targetCoord
		fixTargetDone:
	
    # TODO: Now, print the gameboard. Select symbols to represent the walls,
    # character, box, and target. Write a function that uses the location of
    # the various elements (in memory) to construct a gameboard and that 
    # prints that board one character at a time.
    # HINT: You may wish to construct the string that represents the board
    # and then print that string with a single syscall. If you do this, 
    # consider whether you want to place this string in static memory or 
    # on the stack. 
	# @@@@@@@@@@
	# @P       @
	# @   B    @
	# @        @
	# @        @ @ is the wall
	# @        @ P is the player
	# @        @ B is the box
	# @        @ X is the target
	# @       X@
	# @@@@@@@@@@
	printBoard:
		loopinit:
			jal longWall
			li t0, 0 # Counter for # rows
			lb t1, 0(s0)
			li t2, 0 # Counter for # columns
			lb t3, 1(s0)
		for1:
			beq t2, t3, done1
			la a0, wallLetter
			li a7, 4
			ecall
			j for2
		for2:
			beq t0, t1, done2
			jal currentLetter
			li a7, 4
			ecall
			addi t0, t0, 1
			j for2
		done2:
			la a0, wallLetter
			li a7, 4
			ecall

			la a0, newline
			li a7, 4
			ecall

			li t0, 0
			addi t2, t2, 1
			j for1
		done1:
			jal longWall
			bne t6, x0, whileReplay
	
    # TODO: Enter a loop and wait for user input. Whenever user input is
    # received, update the gameboard state with the new location of the 
    # player (and if applicable, box and target). Print a message if the 
    # input received is invalid or if it results in no change to the game 
    # state. Otherwise, print the updated game state. 
    #
    # You will also need to restart the game if the user requests it and 
    # indicate when the box is located in the same position as the target.
    # For the former, it may be useful for this loop to exist in a function,
    # to make it cleaner to exit the game loop.
	
	whileUser: # Regarding multi-player mode, use stack to store each player's total moves.
		li a7, 4
		la a0, movePrompt
		ecall
		
		li a7, 12
		ecall
		
		li t0, 'w'
		beq a0, t0, upMove
		
		li t0, 'a'
		beq a0, t0, leftMove
		
		li t0, 's'
		beq a0, t0, downMove
		
		li t0, 'd'
		beq a0, t0, rightMove
		
		li t0, 'r'
		beq a0, t0, restartGame
		
		upMove:
			jal moveIntoHeap
			
			lb t0, 1(s1) # Checking for invalid move (out of range)
			addi t0, t0, -1
			blt t0, x0, invalidMove
			lb t2, 0(s1)
			lb t1, 0(s2)
			bne t1, t2, noBoxMoveW
			lb t1, 1(s2)
			bne t0, t1, noBoxMoveW # Checking if the box will be moved
			beq t1, x0, invalidMove
			addi t1, t1, -1
			sb t1, 1(s2)
			
			noBoxMoveW:
			sb t0, 1(s1)
			j doneMove
		leftMove:
			jal moveIntoHeap
		
			lb t0, 0(s1) # Check if out of range
			addi t0, t0, -1
			blt t0, x0, invalidMove
			
			lb t1, 1(s2) # Check if box moved
			lb t2, 1(s1)
			bne t1, t2, noBoxMoveA
			lb t1, 0(s2)
			bne t0, t1, noBoxMoveA
			beq t1, x0, invalidMove
			addi t1, t1, -1
			sb t1, 0(s2)
			
			noBoxMoveA:
			sb t0, 0(s1)
			j doneMove
		rightMove:
			jal moveIntoHeap
		
			lb t0, 0(s1) # Check for out of range
			addi t0, t0, 1
			lb t1, 0(s0)
			bge t0, t1, invalidMove
			
			lb t1, 1(s2) # Check if box is moved
			lb t2, 1(s1)
			bne t1, t2, noBoxMoveD
			lb t1, 0(s2)
			bne t0, t1, noBoxMoveD
			
			lb t2, 0(s0)
			addi t2, t2, -1
			beq t1, t2, invalidMove
			addi t1, t1, 1
			sb t1, 0(s2)
		
			noBoxMoveD:
			sb t0, 0(s1)
			j doneMove
		downMove:
			jal moveIntoHeap
			
			lb t0, 1(s1) # Checking for invalid move (out of range)
			addi t0, t0, 1
			lb t1, 1(s0)
			bge t0, t1, invalidMove
			
			lb t1, 0(s2) # Checking if the box will be moved
			lb t2, 0(s1)
			bne t1, t2, noBoxMoveS
			lb t1, 1(s2)
			bne t0, t1, noBoxMoveS 
			
			lb t2, 1(s0)
			addi t2, t2, -1
			beq t1, t2, invalidMove # Check if box hugging wall
			addi t1, t1, 1
			sb t1, 1(s2)
			
			noBoxMoveS:
			sb t0, 1(s1)
		doneMove: # Check box on target if yes jump to doneUser, else go to printBoard
			addi a4, a4, 1 # Add 1 to move counter
			
			lb t0, 0(s2)
			lb t1, 0(s3)
			bne t0, t1, notDone
			lb t0, 1(s2)
			lb t1, 1(s3)
			bne t0, t1, notDone # later add a beq statement regarding # of players. If still
			j doneUser			# players left, jump to restartGame and store # of moves in stack
			notDone:
			la a0, newline
			li a7, 4
			ecall
			j printBoard
	invalidInput:
		la a0, invalidPrompt
		li a7, 4
		ecall
		j whileUser
	invalidMove:		
		la a0, invalidMovePrompt
		li a7, 4
		ecall
		j whileUser
	restartGame:
		la a0, restartPrompt
		li a7, 4
		ecall
		
		lb t0, 2(s1) # Reset player coords to starting coords
		sb t0, 0(s1)
		lb t0, 3(s1)
		sb t0, 1(s1)
		
		lb t0, 2(s2) # Reset box coords to starting coords
		sb t0, 0(s2)
		lb t0, 3(s2)
		sb t0, 1(s2)
		
		bne x0, t6, printBoard # Checks if replay called restart or not
		
		whileHeap:
			beq a4, x0, doneHeap # resets the heap address to previous address
			la a0, heappointer # and also resets the values to 0
			lw t0, heappointer
			sb x0, 0(t0)
			addi t0, t0, -1
			sw t0, 0(a0)
			addi a4, a4, -1
			j whileHeap
		doneHeap:
		
		j printBoard
	doneUser:
		li a0, 'n'
		jal moveIntoHeap
	
		la a0, newline
		li a7, 4
		ecall
		
		la a0, playerLeaderboard
		li a7, 4
		ecall
		
		addi a2, a2, 1 # incriment players gone by 1
		mv a0, a2
		li a7, 1
		ecall
		
		la a0, completedPrompt
		li a7, 4
		ecall
		j forGame

    # TODO: That's the base game! Now, pick a pair of enhancements and
    # consider how to implement them.

	# Printing out the final leaderboard
	leaderboard:
		sortLeaderboard:
			# a3: number of players
			mv t3, a3
			addi t3, t3, -1 # subtract 2 since bubble sort does not iterate fully
			li t2, 0 # counter
			whileSort:
				beq t3, x0, doneWhileSort
				whileSort2:
					beq t2, t3, doneWhileSort2
					jal sortThisAndNext # bubble sort on this and next
					addi sp, sp, 8 # setup for next swap
					addi t2, t2, 1
					j whileSort2
				doneWhileSort2:
				slli t2, t2, 3 
				sub sp, sp, t2 # reset stack pointer back to bottom
				addi t3, t3, -1 # reduce the number of swap iterations
				li t2, 0 # reset counter
				j whileSort
			doneWhileSort:
		la a0, titleLeaderboard
		li a7, 4
		ecall
		forLeaderboard:
			beq a2, x0, replayManager
			
			li a7, 4
			la a0, playerLeaderboard
			ecall

			lw a0, 0(sp)
			li a7, 1
			ecall

			addi sp, sp, 4
			li a7, 4
			la a0, movesLeaderboard
			ecall

			lw a0, 0(sp)
			li a7, 1
			ecall

			addi sp, sp, 4
			addi a2, a2, -1

			la a0, newline
			li a7, 4
			ecall

			j forLeaderboard
	replayManager:	
		li a7, 4
		la a0, newline
		ecall
		
		li a7, 4
		la a0, replayPrompt
		ecall
		
		li a7, 5
		ecall
		
		beq a0, x0, exit # if user entered 0, game will exit
		
		jal adjustHeapPointer # t6 now contains proper pointer
		
		j restartGame
		
		whileReplay:
			lb t1, 0(t6)
			li t0, 'n'
			beq t1, t0, doneReplay
			
			li a7, 4
			la a0, replayMove
			ecall
			
			li a7, 11
			mv a0, t1
			ecall
			
			addi t6, t6, 1
			j whileReplay
		doneReplay:
		li a7, 4
		la a0, newline
		ecall
		li t6, 0 # Reset t6 to 0 since it is used to check in printBoard
		mv a2, a3 # reset total number of players gone to print leaderboard properly
		j replayManager
			
exit:
    li a7, 10
    ecall
    
    
# --- HELPER FUNCTIONS ---
# Feel free to use, modify, or add to them however you see fit.

# Changes the heap pointer to the beginning of a player's moves
# Arguements: a0 contains a player
# Return: t6 with proper heappointer
adjustHeapPointer:
	li t6, 0x10000000
	lw a1, 0(sp)
	slli t0, a3, 3
	addi a1, a1, 4 # stack now points to last player's number of moves
	addi a0, a0, -1
	mv t0, a0
	whileAdjustHeap:
		beq x0, a0, whileAdjustHeapDone # Adds 8 to sp to add previous player's moves
		addi a1, a1, 8
		lw t1, 0(a1)
		add t2, t1, t2
		addi a0, a0, -1
		j whileAdjustHeap
	whileAdjustHeapDone:
	ret
	

# Stores current character into heap
# Arguements: a0 contains the current character
# Return: an updated heappointer (added 1 byte)
moveIntoHeap:
	la a1, heappointer # load address of heappointer to be updated
	lw t0, heappointer # load area in memory to store move 
	sb a0, 0(t0)
	addi t0, t0, 1
	sw t0, 0(a1)
	ret
	

# Sort current and next element in stack (from bottom to top). Part of bubble sort
# Uses t0 and t1 for sorting
# Arguements: sp points to valid PLAYER NUMBER element
# Return: a sorted stack for two elements
sortThisAndNext:
	lw t0, 4(sp) 
	lw t1, 12(sp)
	blt t0, t1, noSwap
	sw t0, 12(sp) # Swap the number of moves
	sw t1, 4(sp)
	
	lw t0, 0(sp) # Swap player numbers
	lw t1, 8(sp)
	sw t0, 8(sp)
	sw t1, 0(sp)
	noSwap:
	ret

# Prints out a long line of wall to outline the game board.
# Used for the top and bottom of the walls.
# Return: a wall of @
longWall:
	lb t0, 0(s0)
	addi t0, t0, 2
	li t1, 0
	longWallFor:
		beq t0, t1, longWallDone
		la a0, wallLetter
		li a7, 4
		ecall
		addi t1, t1, 1
		j longWallFor
	longWallDone:
	la a0, newline
	li a7, 4
	ecall
	ret

# Uses t4 to check. This helper checks which character is at the current (x,y) for the game board.
# Arguements: t0 holds X value, t2 holds Y value, s1 holds character coord, s2 holds box coords, s3 holds target coords
# Return: a0 with corresponding letter value
currentLetter:
	onPlayerCheck:
		lb t4, 0(s1)
		bne t4, t0, onBoxCheck
		lb t4, 1(s1)
		bne t4, t2, onBoxCheck
		la a0, characterLetter
		ret
	onBoxCheck:
		lb t4, 0(s2)
		bne t4, t0, onTargetCheck
		lb t4, 1(s2)
		bne t4, t2, onTargetCheck
		la a0, boxLetter
		ret
	onTargetCheck:
		lb t4, 0(s3)
		bne t4, t0, onEmpty
		lb t4, 1(s3)
		bne t4, t2, onEmpty
		la a0, targetLetter
		ret
	onEmpty:
	la a0, empty
	ret

# Uses t0, t1 for checking. This helper checks if the box is in a corner or not.
# Arguements: s2 contains box coordinates, s0 contains board dimensions
# Return: 0 if in corner, 1 if not in corner
cornerCheckBox:
	lb t0, 1(s0)
	addi t0, t0, -1 # since coords start at 0
	lb t1, 0(s2)
	beq t1, x0, checkHoriz # Checks x coordinate equal 0
	beq t1, t0, checkHoriz # Checks x coordinate equal max row
	j valid
	
	checkHoriz:
		lb t0, 0(s0)
		addi t0, t0, -1
		lb t1, 1(s2)
		beq t1, x0, invalid
		beq t1, t0, invalid
		j valid
	invalid:
		li a0, 0
		ret
	valid:
		li a0, 1
	ret

# Uses t0, t1 for checking. Checks if the box is hugging a wall or not.
# Arguements: s2 contains box coordinates, s0 contains board dimensions
# Return: 0 if not on wall, 1 if hugging side wall, 2 if hugging top/bottom wall
wallCheckBox:
	lb t0, 0(s2) # Checks if box hugging side walls
	lb t1, 0(s0)
	addi t1, t1, -1 # Since coords start at 0
	beq t0, x0, vertWall 
	beq t0, t1, vertWall
	
	lb t0, 1(s2) # Checks if box hugging top / bottom walls
	lb t1, 1(s0)
	addi t1, t1, -1
	beq t0, x0, horizWall 
	beq t0, t1, horizWall
	
	li a0, 0 # Not hugging wall
	ret
	vertWall:
		li a0, 1
		ret
	horizWall:
		li a0, 2
	ret

# Uses registers t0, t1, t2, a0.
# This algorithm is called a linear-feedback shift register. It essentially takes the current
# time in milliseconds (as a seed), then shifts a couple of selected bits to create a new seed.
# The seed is then modulus by the dimension of the game board to return a valid coordinate.
# Source: https://en.wikipedia.org/wiki/Linear-feedback_shift_register
# Author: Unknown Wikipedia page editor
# Arguements: a0 contains integer MAX, a5 contains the SEED
# Return: Return: A number from 0 (inclusive) to MAX (exclusive) to a0
lfsr:
	srli t1, a5, 1 	# Shift a0 by 1 and store in t1
	xor t1, t1, a5	# Change up bits using xor
	
	srli t2, a5, 15 # Shift a0 by 15 and store in t2
	xor t1, t1, t2	# Change up bits using xor on t1 and t2
		
	srli t2, a5, 31
	xor t1, t1, t2
	
	andi t1, t1, 1
	
	srli a5, a5, 1
	slli t1, t1, 31
	or a5, a5, t1	# Use or to change up bits again
	
	remu a0, a5, a0	# Get coordinate by using modulus with MAX
	jr ra
	

# Arguments: an integer MAX in a0
# Return: A number from 0 (inclusive) to MAX (exclusive)
notrand:
    mv t0, a0
    li a7, 30
    ecall             # time syscall (returns milliseconds)
    remu a0, a0, t0   # modulus on bottom bits 
    li a7, 32
    ecall             # sleeping to try to generate a different number
    jr ra
