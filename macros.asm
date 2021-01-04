.macro print_int(%x)
	li	$v0, 1
	add	$a0, $zero, %x
	syscall
.end_macro

.macro print_char(%x)
	li	$v0, 11
	lb	$a0, (%x)
	syscall
.end_macro

.macro print_string(%x)
	li	$v0, 4
	la	$a0, (%x)
	syscall
.end_macro

.macro get_string(%x)
	li	$v0, 8
	move	$a0, %x
	li	$a1, 80
	syscall
.end_macro

.macro openFile(%x, %y)
	li	$v0, 13
	la	$a0, (%x)
	li	$a1, 0
	li	$a2, 0
	syscall
	move 	%y, $v0
.end_macro

.macro closeFile(%x)
	li	$v0, 16
	la	$a0, (%x)
	syscall
.end_macro

.macro readFile(%x, %y, %z)
	li	$v0, 14
	move	$a0, %x
	la	$a1, (%y)
	li	$a2, 1024
	syscall
	move	%z, $v0
.end_macro

.macro allocateMemory(%x)
	li	$v0, 9
	li	$a0, 1024
	syscall
	move 	%x, $v0
.end_macro
