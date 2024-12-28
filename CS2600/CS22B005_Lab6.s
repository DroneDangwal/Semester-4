.section .text
.global main

main:
	li a0, 0x1800
	csrc mstatus, a0
	li a0, 0x0080
	csrs mstatus, a0
		# Enable interrupts
	li a0, 0x80
	csrs mie, a0
		# configure timer interrupt 
		# set the value of mtimecmp register
		# mtimecmp can be accessed at the address 0x2004000 and mtime can be accessed at the address 0x200bff8
	li a0, 0x2004000
	li a1, 10000
	sd a1, 0(a0)
	la a0, context_switch
	csrw mtvec, a0
	la a0, Task_A
	csrw mepc, a0
	li a0, 0
	mret

context_switch:

		# save the context of the interrupted task by looking at the task id (jump to relavent label)
	la a4, current
	ld a1, 0(a4)
	bnez a1, save_context_B
	beq a1, a1, save_context_A

save_context_A:
		# save all the registers and PC value in stack_a
		# mepc stores the value of PC at the time of interrupt
	la t0, stack_a
	ld t0, 0(t0)
	sd a0, 0(t0)
	csrr a1, mepc
	sd a1, 8(t0)
	j switch

save_context_B:
		# save all the registers and PC value in stack_b
	la t0, stack_b
	ld t0, 0(t0)
	sd a0, 0(t0)
	csrr a1, mepc
	sd a1, 8(t0)
	j switch

switch_to_A:
		# restore the values of registers and PC from stack_a
	li t2, 1
	sub t1, t2, t1
	sd t1, 0(t0)
	la t0, stack_a
	ld t0, 0(t0)
	ld a1, 8(t0)
	ld a0, 0(t0)
	csrw mepc, a1
	mret

switch_to_B:
		# restore the values of registers and PC from stack_b
	la t3, first_time_B
	ld t4, 0(t3)
	beqz t4, initial_switch_to_B
	li t2, 1
	sub t1, t2, t1
	sd t1, 0(t0)
	la t0, stack_b
	ld t0, 0(t0)
	ld a1, 8(t0)
	ld a0, 0(t0)
	csrw mepc, a1
	mret

initial_switch_to_B:
		# switching to Task B for the first time
	li t2, 1
	sub t1, t2, t1
	sd t1, 0(t0)
	addi t4, t4, 1
	sd t4, 0(t3)
	la t0, Task_B
	csrw mepc, t0
	li a0, 0x03ffffff
	mret

switch:
		# set the value of mtimecmp and switch to your preferred task
	li t0, 0x2004000
	ld t1, 0(t0)
	li t2, 10000
	add t1, t1, t2
	sd t1, 0(t0)
	la t0, current
	ld t1, 0(t0)
	beqz t1, switch_to_B
	beq t1, t1, switch_to_A

Task_A:
		# increment your reg value
	addi a0, a0, 1
	li a1, 0x0fffffff
	bge a0, a1, finish_a
	j Task_A

finish_a:
    j finish_a

Task_B:
		# decrement the reg value
	addi a0, a0, -1
	li a1, 0x03ffffff
	beq a0, a1, finish_b
	j Task_B

finish_b:
    j finish_b

.data
.align 8
stack_a: .dword 0xf0040000 # initialize stack for task A (You can choose a random address) 
stack_b:  .dword 0xf0050000 # initialize stack for task B
current:  .dword  0 # variable to identify the task 
first_time_B: .dword 0 # variable to identify if B is executed once or not
