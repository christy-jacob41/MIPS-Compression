# Homework 8
# Christy Jacob

.include 	"macros.asm"

.data
fileName:			.space 80
fileNameRequestPrompt: 		.asciiz	"Please enter the filename to compress or <enter> to exit: "
readText:			.space	1024
errorOpeningFileMessage:	.asciiz "\nError opening file. Program terminating."
hi:				.asciiz "hi"
newLine:			.asciiz	"\n"
emptyString:			.asciiz	""
compressedDataBytes:		.word	1
originalDataBytes:		.word	1
uncompressedData:		.space 1024
originalDataMessage:		.asciiz	"\nOriginal data:\n"
compressedDataMessage:		.asciiz	"Compressed data:\n"
uncompressedDataMessage:	.asciiz	"Uncompressed data: \n"
originalSizeMessage:		.asciiz	"Original file size: "
compressedSizeMessage:		.asciiz	"Compressed file size: "

.text
main:
	allocateMemory($s0) # $s0 is pointer to allocated memory
mainLoop:	
	la	$t5, fileNameRequestPrompt
	print_string($t5) # prints prompt for file name
	la	$t0, fileName #$t0 contains fileName address
	get_string($t0) # gets and stores fileName
	
	li	$s2, 0
	li	$s3, 0
	
	# removing new line from file name
	lb	$t7, newLine	# loading newline character into $t7
	li	$t9, 0 # setting first index to 0
	lb	$t8, fileName($t9) # loading the first byte
	beq	$t8, $t7, exit # if user entered <enter>, then exit program
	addi	$t9, $t9, 1 # increasing the index to next character
	
findNewLine: # looping to find new line character in file name
	lb	$t8, fileName($t9)	# loading byte at each indes to compare
	addi	$t9, $t9, 1	# increasing the index every iteration
	bne	$t8, $t7, findNewLine	# comparing the byte at each index to the new line character and loop if not equal

removeNewLine: # replacing new line character with null terminator in file name
	addi	$t9, $t9, -1	# last loop will cause index to go one past the index of the new line character so subtract 1
	sb	$zero, fileName($t9) # store the null terminator in the place of the new line character
	
	openFile($t0, $s1) # opens file and $s1 contains file descriptor
	slt	$t2, $s1, $zero
	bne	$t2, $zero, printErrorAndExit # if $t2 is non-zero($s1 is negative), print an error and terminate the program
	
	la	$t3, readText # loads address of input buffer into $t3
	readFile($s1, $t3, $s2) # $s1 is file descriptor, $t3 is the address of the input buffer, $s2 contains the number of characters read
	sw	$s2, originalDataBytes # store size of original data
	closeFile($s1) # file is closed using file descriptor $s1
	
	la	$t0, originalDataMessage
	print_string($t0)
	la	$t0, readText
	print_string($t0)
	
	la	$a0, readText # moving address of original data into $a0
	move	$a1, $s0 # moving compression buffer address into $a1
	move	$a2, $s2 # moving size of original data into $a2
	jal	compressFunction # calling compress function
	move	$s3, $v0 # store size of compression buffer into $s3
	
	# print a new line to format output
	la	$t8, newLine
	print_string($t8)
	
	la	$t8, compressedDataMessage
	print_string($t8) # printing compressed data message
	
	move	$a0, $s0 # moving compression buffer address into $a0
	move	$a1, $s3 # moving size of compressed data into $a1
	jal 	printCompressedData # calling print compressed data function
	
	# print a new line to format output
	la	$t8, newLine
	print_string($t8)
	
	la	$t8, uncompressedDataMessage
	print_string($t8) # printing uncompressed data message
	
	la	$a0, uncompressedData # moving address of space to store uncompressed data to $a0
	move	$a1, $s0 # moving compression buffer address into $a1
	move	$a2, $s3 # store size of compression buffer into $a2
	jal	uncompressFunction
	
	move	$a1, $s0 # moving compression buffer address into $a1
	move	$a2, $s3 # store size of compression buffer into $a2
	jal	printUncompressedDataFunction
	
	# print a new line to format output
	la	$t8, newLine
	print_string($t8)
	
	la	$t8, originalSizeMessage
	print_string($t8) # printing original size message
	
	# printing the original file size
	print_int($s2)
	
	# print a new line to format output
	la	$t8, newLine
	print_string($t8)
	
	la	$t8, compressedSizeMessage
	print_string($t8) # printing compressed size message
	
	# printing the compressed file size
	print_int($s3)
	
	# print a new line to format output
	la	$t9, newLine
	print_string($t9)
	
	li	$t1, 1024
	la	$t0, readText
	la	$t2, uncompressedData
clearBuffer:
	sb	$zero, ($t0)
	sb	$zero, ($t2)
	addi	$t0, $t0, 1
	addi	$t1, $t1, -1
	bne	$t1, $zero, clearBuffer
	
	j	mainLoop # loop back to main

compressFunction:
	move	$t0, $a0 # address of input buffer is in $t0
	move	$t1, $a1 # address of compression buffer is in $t1
	move	$t2, $a2 # size of original file is in $t2

	li	$t7, 0 # first index of compression buffer is 0
	li	$t3, 0 # first index is set to 0
	li	$t4, 0 # original bytes in compression buffer is 0
	la	$t6, newLine
	lb	$t9, ($t6)
loadCurrentChar:
	li	$t5, 0 # current character count starts at 0
	add	$t0, $t0, $t3
	lb	$t8, ($t0) # load current char into $t8
	sub	$t0, $t0, $t3
	addi	$t3, $t3, 1 # add 1 to the address offset
	
loadNextChar:
	addi	$t5, $t5, 1 # add 1 to the character count for each character
	add	$t0, $t0, $t3
	lb	$t6, ($t0) # load next character
	sub	$t0, $t0, $t3
	beq	$t3, $t2, endCompressionFunction # if the offset equals the size of the original file, end the compresson function
	addi	$t3, $t3, 1 # add 1 to the address offset
	beq	$t8, $t6, loadNextChar # repeat loop if next char is same as current char
	addi	$t3, $t3, -1
	
storeCurrentChar:
	add	$t1, $t1, $t7
	sb 	$t8, ($t1) # store current character in heap
	sub	$t1, $t1, $t7
	addi	$t7, $t7, 1 # add 1 to heap index
	add	$t1, $t1, $t7
	sb 	$t5, ($t1) # store current character count in heap
	sub	$t1, $t1, $t7
	addi	$t7, $t7, 1 # add 1 to heap index
	addi	$t4, $t4, 2 # add 2 to the size of the compression buffer
	j	loadCurrentChar
	
endCompressionFunction:
	add	$t1, $t1, $t7
	sb 	$t8, ($t1)# store last character in heap 
	sub	$t1, $t1, $t7
	addi	$t7, $t7, 1 # add 1 to heap index
	add	$t1, $t1, $t7
	sb 	$t5, ($t1) # store last character count in heap
	sub	$t1, $t1, $t7
	addi	$t7, $t7, 1 # add 1 to heap index
	addi	$t4, $t4, 2 # add 2 to the size of the compression buffer
	move	$v0, $t4 # store size of compression buffer in $v0
	jr	$ra # return to main
	
printCompressedData:
	move	$t0, $a0
	move 	$t3, $a0
	move	$t1, $a1
	
printCompressedDataLoop:
	# printing each character in compression buffer
	print_char($t0)
	addi	$t0, $t0, 1 # add 1 to address of compression buffer
	# printing count of each character in compression buffer
	lb	$a0, ($t0)
	print_int($a0)
	addi	$t0, $t0, 1 # add 1 to address of compression buffer
	sub	$t2, $t0, $t3 # find number of characters printed 
	bne	$t2, $t1, printCompressedDataLoop # if number of characters printed isn't equal to total size of the compression, keep looping
	jr	$ra # return to main

uncompressFunction:
	move	$t0, $a0 # address of space to hold uncompressed data is in $t0
	move	$t1, $a1 # address of compression buffer is in $t1
	move	$t2, $a2 # size of compressed file is in $t2
	
uncompressionLoop:
	lb	$t3, ($t1) # load current character into $t3
	addi	$t1, $t1, 1 # add to address of compression buffer
	lb	$t4, ($t1) # load current character count
	addi	$t1, $t1, 1 # add to address of compression buffer
	
storeUncompressedData:
	sb	$t3, ($t0) # store character into uncompressed data buffer
	addi	$t0, $t0, 1 # add to address of uncompressed data buffer
	addi	$t4, $t4, -1 # subtract 1 from current character count
	bne	$t4, $zero, storeUncompressedData  # keep storing character while current character count isn't 0
	addi	$t2, $t2, -2 # subtract 2 from compression file size
	bne	$t2, $zero, uncompressionLoop # while compression file size isn't zero so there are characters left to store, store the characters
	jr	$ra
	
printUncompressedDataFunction:
	move	$t1, $a1 # address of compression buffer is in $t1
	move	$t2, $a2 # size of compressed file is in $t2
	
loadToPrintLoop:
	move	$t3, $t1 # load address of current character into $t3
	addi	$t1, $t1, 1 # add to address of compression buffer
	lb	$t4, ($t1) # load current character count
	addi	$t1, $t1, 1 # add to address of compression buffer
	
printUncompressedData:
	# looping and printing the current character
	print_char($t3)
	addi	$t4, $t4, -1 # subtract 1 from current character count
	bne	$t4, $zero, printUncompressedData  # keep storing character while current character count isn't 0
	addi	$t2, $t2, -2 # subtract 2 from compression file size
	bne	$t2, $zero, loadToPrintLoop # while compression file size isn't zero so there are characters left to store, store the characters
	jr	$ra
	
printErrorAndExit: # print error opening file message and then exit
	la	$t5, errorOpeningFileMessage # loads address of error opening file message into $t5
	print_string($t5) # printing error opening file message

exit: # exit program
	li	$v0, 10
	syscall
