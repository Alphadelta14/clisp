@ Generated by gcc 2.6.3 for ARM/RISCiX
rfp	.req	r9
sl	.req	r10
fp	.req	r11
ip	.req	r12
sp	.req	r13
lr	.req	r14
pc	.req	r15
gcc2_compiled.:
___gnu_compiled_c:
.text
	.align	0
LC0:
	.word	_vacall_function
	.align	0
LC1:
	.word	L30
	.align	0
	.global	_vacall
_vacall:
	@ args = 4, pretend = 0, frame = 48
	@ frame_needed = 0, current_function_anonymous_args = 0
	stmfd	sp!, {lr}
	sub	sp, sp, #48
	ldr	ip, [sp, #48]
	str	ip, [sp, #28]
	str	r0, [sp, #36]
	str	r1, [sp, #40]
	str	r2, [sp, #44]
	str	r3, [sp, #48]
	mov	r2, #0
	str	r2, [sp, #0]
	add	r3, sp, #36
	str	r3, [sp, #4]
	str	r2, [sp, #8]
	str	r2, [sp, #12]
	mov	r0, sp
	ldr	r3, [pc, #LC0 - . - 8]
	mov	lr, pc
	ldr	pc, [r3, #0]
	ldr	r2, [sp, #12]
	cmp	r2, #15
	bhi	L2
	ldr	r3, [pc, #LC1 - . - 8]
	ldr	pc, [r3, r2, asl #2]	@ table jump, label L30
L30:
	.word	L2
	.word	L6
	.word	L5
	.word	L6
	.word	L7
	.word	L8
	.word	L17
	.word	L17
	.word	L17
	.word	L17
	.word	L14
	.word	L14
	.word	L15
	.word	L16
	.word	L17
	.word	L18
L5:
	ldrb	r3, [sp, #20]
	mov	r3, r3, asl #24
	mov	r0, r3, asr #24
	b	L2
L6:
	ldrb	r0, [sp, #20]	@ zero_extendqisi2
	b	L2
L7:
	ldr	r3, [sp, #20]	@ movhi
	mov	r3, r3, asl #16
	mov	r0, r3, asr #16
	b	L2
L8:
	ldr	r3, [sp, #20]	@ movhi
	b	L32
L14:
	ldr	r0, [sp, #20]
	ldr	r1, [sp, #24]
	b	L2
L15:
	ldfs	f0, [sp, #20]
	b	L2
L16:
	ldfd	f0, [sp, #20]
	b	L2
L17:
	ldr	r0, [sp, #20]
	b	L2
L18:
	ldr	r3, [sp, #0]
	tst	r3, #1
	ldrne	r0, [sp, #8]
	bne	L2
L19:
	tst	r3, #512
	beq	L2
	ldr	r3, [sp, #16]
	cmp	r3, #2
	beq	L24
	bhi	L29
	cmp	r3, #1
	beq	L23
	b	L2
L29:
	cmp	r3, #4
	beq	L25
	cmp	r3, #8
	beq	L26
	b	L2
L23:
	ldr	r3, [sp, #8]
	ldrb	r0, [r3, #0]	@ zero_extendqisi2
	b	L2
L24:
	ldr	r3, [sp, #8]
	ldr	r3, [r3, #0]	@ movhi
L32:
	mov	r3, r3, asl #16
	mov	r0, r3, lsr #16
	b	L2
L25:
	ldr	r3, [sp, #8]
	ldr	r0, [r3, #0]
	b	L2
L26:
	ldr	r3, [sp, #8]
	ldr	r0, [r3, #0]
	ldr	r1, [r3, #4]
L2:
	ldr	r3, [sp, #28]
	str	r3, [sp, #48]
	add	sp, sp, #48
	ldmfd	sp!, {pc}^
