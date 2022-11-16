	.ORIG	x3000

	LEA	R0, ASCII_ART_0
	PUTS
	LEA	R0, ASCII_ART_1
	PUTS
	LEA	R0, ASCII_ART_2
	PUTS
	LEA	R0, ASCII_ART_3
	PUTS
ASCII_ART_0	.STRINGZ	" _______  __   __  _______  _______  _______  ___      _______ \n"
ASCII_ART_1	.STRINGZ	"|       ||  | |  ||       ||       ||       ||   |    |       |\n"
ASCII_ART_2	.STRINGZ	"|    ___||  | |  ||    ___||  _____||  _____||   |    |    ___|\n"
ASCII_ART_3	.STRINGZ	"|   | __ |  |_|  ||   |___ | |_____ | |_____ |   |    |   |___ \n"
ASCII_ART_4	.STRINGZ	"|   ||  ||       ||    ___||_____  ||_____  ||   |___ |    ___|\n"
ASCII_ART_5	.STRINGZ	"|   |_| ||       ||   |___  _____| | _____| ||       ||   |___ \n"
ASCII_ART_6	.STRINGZ	"|_______||_______||_______||_______||_______||_______||_______|\n"
	LEA	R0, ASCII_ART_4
	PUTS
	LEA	R0, ASCII_ART_5
	PUTS
	LEA	R0, ASCII_ART_6
	PUTS

; Prompt for any keypress, and seed LCRNG
ANY_KEY	.STRINGZ	"Press any key to continue...\n"
	LEA	R0, ANY_KEY
	PUTS
	AND	R1, R1, #0
RESTART	AND	R0, R0, #0
SEED	ADD	R0, R0, #1
	BRnz	RESTART
	LDI	R2, KBSR0
	BRzp	SEED
	ST	R0, RAND_SEED
	LDI	R0, KBDR0
	BRnzp	INTRO

; Keyboard Registers
; These are stored in multiple locations to account for distance (9bit offset for many instructions)
KBSR0	.FILL	xFE00
KBDR0	.FILL	xFE02

; Function to load pseudo-random number (LCRNG). A random number from 0-32767 is returned in R0
RAND		LD	R0, RAND_SEED
		LD	R1, RAND_CONST
RAND_RET	.BLKW	#1
		ST	R7, RAND_RET
		JSR	MULT
		AND	R0, R0, #0
		ADD	R0, R0, R2
		LD	R1, RAND_MOD
		JSR	DIV
		ST	R0, RAND_SEED
		LD	R7, RAND_RET
		AND	R6, R6, #0
		ST	R6, RAND_RET
		RET
RAND_CONST	.FILL	X0007
RAND_MOD	.FILL	x7FFF
RAND_SEED	.BLKW	#1


; Start with intro and give instructions
STR_INTRO_1	.STRINGZ	"\nWelcome to GUESSLE the word guessing game!\n"
STR_INTRO_2	.STRINGZ	"\nI'm thinking of a 5-letter word.\nYour goal is to guess it in as few guesses as possible\n"
STR_INTRO_3	.STRINGZ	"I will give hints for each of your guesses.\n\n"
INTRO	LEA	R0, STR_INTRO_1
	PUTS
	LEA	R0, STR_INTRO_2
	PUTS
	LEA	R0, STR_INTRO_3
	PUTS
	BRnzp	INIT


; initialize
INIT	JSR	RAND_WORD
	JSR	CLEAR_GUESS
	JSR	RESET_GUESS_COUNT
	BRnzp	GUESS_PROMPT

; Pick a random word from the list	
RAND_WORD	NOP
RAND_WORD_RET	.BLKW	#1			; A place to store current R7 so other subroutines don't lose our place
WORD_COUNT	.FILL	x0028			; The count of words in the list (40)
LETTER_COUNT	.FILL	x0005			; The number of letters in each word (5)
		ST	R7, RAND_WORD_RET
		JSR	RAND
		LD	R1, WORD_COUNT
		JSR	DIV
		LD	R1, LETTER_COUNT
		JSR	MULT
		JSR	LOAD_WORD_LIST
		ADD	R0, R0, R2
		LEA	R2, TARGET_WORD
LOOP_WORD_LOAD	LDR	R3, R0, #0
		STR	R3, R2, #0
		ADD	R2, R2, #1
		ADD	R0, R0, #1
		ADD	R1, R1, #-1
		BRnp	LOOP_WORD_LOAD
		LD	R7, RAND_WORD_RET
		AND	R0, R0, #0
		ST	R0, RAND_WORD_RET
		RET

; Prompt for a guess
GUESS_PROMPT	.STRINGZ	"Guess #"
PROMPT_GUESS	LEA	R0, GUESS_PROMPT
		PUTS

; Increment the GUESS_COUNT, which acts as user score.
ADD_GUESS	LD	R0, GUESS_COUNT
		ADD	R0, R0, #1
		ST	R0, GUESS_COUNT
		JSR	PRINT_NUM
		AND	R0, R0, #0
		ADD	R0, R0, #10
		OUT
		BRnzp	INPUT

; Negated ASCII codes for input validation
LWR_START	.FILL	XFF9F
LWR_END		.FILL	XFF86
UPR_START	.FILL	XFFBF
UPR_END		.FILL	XFFA6

; Keyboard Registers
; These are stored in multiple locations to account for distance (9bit offset for many instructions)
KBSR1	.FILL	xFE00
KBDR1	.FILL	xFE02

; Get user input
INPUT		LDI	R1, KBSR1
		BRzp	INPUT
VALIDATE	LDI	R0, KBDR1
		LD	R1, UPR_START
		ADD	R1, R0, R1
		BRn	INPUT
		LD	R1, UPR_END
		ADD	R1, R0, R1
		BRnz	VALID_UPPER
		LD	R1, LWR_START
		ADD	R1, R0, R1
		BRn	INPUT
		LD	R1, LWR_END
		ADD	R1, R0, R1
		BRp	INPUT
		JSR	TO_UPPER		
VALID_UPPER	JSR	ADD_TO_USER_WORD
		JSR	PRINT_USER_WORD
		JSR	CHECK_LETTER_COUNT
		BRnp	INPUT
		BRz	EOT_MESSAGE

; Convert a lowercase letter in R0 to a capital in place
TO_UPPER	ADD	R0, R0, #-16
		ADD	R0, R0, #-16
		RET

; Check user input against target word and print results
EOT_MESSAGE	.STRINGZ	"\nGood guess! Here's how it compared with the target word.\n\t-Hyphens are in the location where your guess is wrong.\n\t-If the letter is written, it is correct!\n\n"
		LEA	R0, EOT_MESSAGE
		PUTS
CHECK_INPUT	AND	R3, R3, #0
		ADD	R3, R3, #5
		LEA	R5, TARGET_WORD
		LEA	R6, USER_WORD
CHECK_LETTER	LDR	R1, R5, #0
		BRz	END_CHECK
		LDR	R2, R6, #0
		NOT	R2, R2
		ADD	R2, R2, #1
		ADD	R1, R1, R2
		BRnp	INCORRECT
		BRz	CORRECT
WRONG_LETTER	.STRINGZ	"-"
INCORRECT	LEA	R0, WRONG_LETTER
		PUTS
		BRnzp	INCREMENT_CHECK
CORRECT		AND	R0, R0, #0
		LDR	R0, R5, #0
		OUT
		ADD	R3, R3, #-1
		BRz	WIN
INCREMENT_CHECK	ADD	R5, R5, #1
		ADD	R6, R6, #1
		BRnzp	CHECK_LETTER
END_CHECK	AND	R0, R0, #0
		ADD	R0, R0, #10
		OUT
		JSR	CLEAR_GUESS
		BRnzp	PROMPT_GUESS

; Constants for target word and current guess locations.
; Placed in the middle of .asm for accessibility by
; subroutines below and main program above.
TARGET_WORD	.BLKW #6
USER_WORD	.BLKW #6

; Win sequence
GUESS_COUNT	.FILL	X0000
CONGRATS	.STRINGZ	"\n\nThat's the right word! You win!"
Y_KEY_UPPER	.FILL	XFFA7	; The opposite of the ASCII value for 'Y'
Y_KEY_LOWER	.FILL	xFF87	; The opposite of the ASCII value for 'y'
WIN		LEA	R0, CONGRATS
		PUTS
SCORE_MSG	.STRINGZ	"\nIt took you this many guesses: "
		LEA	R0, SCORE_MSG
		PUTS
		LD	R0, GUESS_COUNT
		JSR	PRINT_NUM
AGAIN_MSG	.STRINGZ	"\n\nWanna play again? ('y' to play again, any other key to exit)\n"
		LEA	R0, AGAIN_MSG
		PUTS
WAIT_USER_AGAIN	LDI	R1, KBSR2
		BRzp	WAIT_USER_AGAIN
		LDI	R0, KBDR2
		LD	R1, Y_KEY_UPPER
		ADD	R1, R0, R1
		BRz	RESTART_GAME
		LD	R1, Y_KEY_LOWER
		ADD	R1, R0, R1
		BRnp	END
RESTART_GAME	JSR	INIT

; Keyboard Registers
; These are stored in multiple locations to account for distance (9bit offset for many instructions)
KBSR2		.FILL	xFE00
KBDR2		.FILL	XFE02

; End routine - Print message and halt
END	NOP
END_MSG	.STRINGZ	"\nThanks for playing!\n"
	LEA	R0, END_MSG
	PUTS
	HALT

; Function to reset GUESS_COUNT to 0
RESET_GUESS_COUNT	AND	R0, R0, #0
			ST	R0, GUESS_COUNT
			RET

; Function to output current user word and a newline
PRINT_USER_WORD AND	R6, R6, #0
		ADD	R6, R6, R7
		LEA	R0, USER_WORD
		PUTS
		AND	R0, R0, #0
		ADD	R0, R0, #10
		OUT
		AND	R7, R7, #0
		ADD	R7, R7, R6
		RET

; Adds the value at R0 to the USER_WORD string
ADD_TO_USER_WORD	LEA	R5, USER_WORD
MOVE_TO_NEXT		LDR	R4, R5, #0 
			BRz	ADD_HERE
			ADD	R5, R5, #1
			BRnzp	MOVE_TO_NEXT
ADD_HERE		STR	R0, R5, #0
			RET

; Checks the count of letters in USER_WORD and sets z flag if there are 5 letters
CHECK_LETTER_COUNT	LEA	R5, USER_WORD
			AND	R0, R0, #0
CHECK_NEXT_LETTER	LDR	R4, R5, #0
			BRz	EXIT_LETTER_COUNT
ADD_ONE			ADD	R5, R5, #1
			ADD	R0, R0, #1
			BRnzp	CHECK_NEXT_LETTER
EXIT_LETTER_COUNT	ADD	R0, R0, #-5
			RET

; Clear the current guess to start another round
CLEAR_GUESS	AND	R0, R0, #0	; set R0 to 5, used as loop counter
		ADD	R0, R0, #5	; 
		LEA	R1, USER_WORD	; set R1 to the start of USER_WORD
		AND	R2, R2, #0	; set R2 to 0, used to replace USER_WORD chars
CLEAR_NEXT	STR	R2, R1, #0	;
		ADD	R1, R1, #1	; move to next memory location
		ADD	R0, R0, #-1	; decrement loop counter
		BRp	CLEAR_NEXT
		RET

; Because of the WORD_LIST size there is a subroutine to load it into R0
; Many instructions have only a 9bit offset for addressability, 
; so there is a struggle to access things on the other side of it.
; JSR has an 11bit offset, so we can safely stash this at the bottom
LOAD_WORD_LIST	.STRINGZ	"ALLOYALOFTAPHIDBELCHBILGEBOASTBOOZEBOSSYBRISKCINCHCOVENCRANEDECALDISCODRIVEEBONYFLAREFRIARGLAZEGLOBEHAVENIONICLINENMAJORNEVEROTHERPERKYPRIDERAYONREEDYRISENRUMBASENSESNIFFSPOKESTILLSUITESWISHUNFITWORDY"
		LEA	R0, LOAD_WORD_LIST
		RET

; Function to multiply. Params: R0, R1. Returns: product in R2
MULT		AND	R2, R2, #0
STORE_R1_MULT	.BLKW	#1
		ST	R1, STORE_R1_MULT
CONTINUE_MULT	ADD	R1, R1, XFFFF
		BRn	EXIT_MULT
		ADD	R2, R2, R0
		BRnzp	CONTINUE_MULT
EXIT_MULT	LD	R1, STORE_R1_MULT
		RET

; Function to divide. Params: R0=dividend, R1=divisor. Returns: modulus in R0, quotient in R2
DIV		AND	R2, R2, #0
		NOT	R1, R1
		ADD	R1, R1, #1
CONTINUE_DIV	ADD	R0, R0, R1
		BRn	EXIT_DIV
		ADD	R2, R2, #1
		BRnzp	CONTINUE_DIV

EXIT_DIV	NOT	R1, R1
		ADD	R1, R1, #1
		ADD	R0, R0, R1
		RET		

; Function to print a two-digit number to the console. Params: R0 (number to be printed)
ASCII_NM_OFFSET	.FILL	X0030
PRINT_NUM	AND	R6, R6, #0
		ADD	R6, R6, R7
		AND	R1, R1, #0
		ADD	R1, R1, #10
		JSR	DIV
		AND	R1, R1, #0
		ADD	R1, R1, R0
		AND	R0, R0, #0
		ADD	R0, R0, R2
		LD	R3, ASCII_NM_OFFSET
		ADD	R0, R0, R3
		OUT
		AND	R0, R0, #0
		ADD	R0, R0, R1
		ADD	R0, R0, R3
		OUT
		AND	R7, R7, #0
		ADD	R7, R7, R6
		RET

; EL FIN
	.END