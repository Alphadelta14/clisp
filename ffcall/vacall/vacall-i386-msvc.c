#ifdef _MSC_VER
#include "vacall.h"
#endif
#include "asmi386.h"
TEXT()
	ALIGN(2)
GLOBL(C(__vacall))
	DECLARE_FUNCTION(__vacall)
FUNBEGIN(__vacall)
	INSN2(sub,l	,NUM(36),R(esp))
	INSN2(mov,l	,NUM(0),X4 MEM(esp))
	INSN2(lea,l	,X4 MEM_DISP(esp,40),R(ecx))
	INSN2(mov,l	,R(ecx),X4 MEM_DISP(esp,4))
	INSN2(mov,l	,NUM(0),X4 MEM_DISP(esp,8))
	INSN2(mov,l	,NUM(0),X4 MEM_DISP(esp,12))
	INSN2(mov,l	,R(ebx),X4 MEM_DISP(esp,32))
	INSN2(mov,l	,R(esp),R(edx))
	INSN1(push,l	,R(edx))
	INSN2(mov,l	,C(vacall_function),R(edx))
	INSN1(call,_	,INDIR(R(edx)))
	INSN2(add,l	,NUM(4),R(esp))
	INSN2(cmp,l	,NUM(0),X4 MEM_DISP(esp,12))
	INSN1(je,_	,L3)
	INSN2(cmp,l	,NUM(1),X4 MEM_DISP(esp,12))
	INSN1(je,_	,L45)
	INSN2(cmp,l	,NUM(2),X4 MEM_DISP(esp,12))
	INSN1(jne,_	,L6)
L45:
	INSN2MOVX(movs,b	,X1 MEM_DISP(esp,24),R(eax))
	INSN1(jmp,_	,L3)
L6:
	INSN2(cmp,l	,NUM(3),X4 MEM_DISP(esp,12))
	INSN1(jne,_	,L8)
	INSN2MOVX(movz,b	,X1 MEM_DISP(esp,24),R(eax))
	INSN1(jmp,_	,L3)
L8:
	INSN2(cmp,l	,NUM(4),X4 MEM_DISP(esp,12))
	INSN1(jne,_	,L10)
	INSN2MOVX(movs,w	,X2 MEM_DISP(esp,24),R(eax))
	INSN1(jmp,_	,L3)
L10:
	INSN2(cmp,l	,NUM(5),X4 MEM_DISP(esp,12))
	INSN1(jne,_	,L12)
	INSN2MOVX(movz,w	,X2 MEM_DISP(esp,24),R(eax))
	INSN1(jmp,_	,L3)
L12:
	INSN2(cmp,l	,NUM(6),X4 MEM_DISP(esp,12))
	INSN1(je,_	,L46)
	INSN2(cmp,l	,NUM(7),X4 MEM_DISP(esp,12))
	INSN1(je,_	,L46)
	INSN2(cmp,l	,NUM(8),X4 MEM_DISP(esp,12))
	INSN1(je,_	,L46)
	INSN2(cmp,l	,NUM(9),X4 MEM_DISP(esp,12))
	INSN1(je,_	,L46)
	INSN2(mov,l	,X4 MEM_DISP(esp,12),R(edx))
	INSN2(add,l	,NUM(-10),R(edx))
	INSN2(cmp,l	,NUM(1),R(edx))
	INSN1(ja,_	,L22)
	INSN2(mov,l	,X4 MEM_DISP(esp,24),R(eax))
	INSN2(mov,l	,X4 MEM_DISP(esp,28),R(edx))
	INSN1(jmp,_	,L3)
L22:
	INSN2(cmp,l	,NUM(12),X4 MEM_DISP(esp,12))
	INSN1(jne,_	,L24)
	INSN1(fld,s	,X4 MEM_DISP(esp,24))
	INSN1(jmp,_	,L3)
L24:
	INSN2(cmp,l	,NUM(13),X4 MEM_DISP(esp,12))
	INSN1(jne,_	,L26)
	INSN1(fld,l	,X8 MEM_DISP(esp,24))
	INSN1(jmp,_	,L3)
L26:
	INSN2(cmp,l	,NUM(14),X4 MEM_DISP(esp,12))
	INSN1(jne,_	,L28)
L46:
	INSN2(mov,l	,X4 MEM_DISP(esp,24),R(eax))
	INSN1(jmp,_	,L3)
L28:
	INSN2(cmp,l	,NUM(15),X4 MEM_DISP(esp,12))
	INSN1(jne,_	,L3)
	INSN2(test,b	,NUM(1),X1 MEM(esp))
	INSN1(jne,_	,L47)
	INSN2(test,b	,NUM(4),X1 MEM_DISP(esp,1))
	INSN1(je,_	,L33)
	INSN2(cmp,l	,NUM(1),X4 MEM_DISP(esp,16))
	INSN1(jne,_	,L34)
	INSN2(mov,l	,X4 MEM_DISP(esp,8),R(edx))
	INSN2MOVX(movz,b	,X1 MEM(edx),R(eax))
	INSN1(jmp,_	,L3)
L34:
	INSN2(cmp,l	,NUM(2),X4 MEM_DISP(esp,16))
	INSN1(jne,_	,L37)
	INSN2(mov,l	,X4 MEM_DISP(esp,8),R(edx))
	INSN2MOVX(movz,w	,X2 MEM(edx),R(eax))
	INSN1(jmp,_	,L3)
L37:
	INSN2(cmp,l	,NUM(4),X4 MEM_DISP(esp,16))
	INSN1(jne,_	,L39)
	INSN2(mov,l	,X4 MEM_DISP(esp,8),R(edx))
	INSN2(mov,l	,X4 MEM(edx),R(eax))
	INSN1(jmp,_	,L3)
L39:
	INSN2(cmp,l	,NUM(8),X4 MEM_DISP(esp,16))
	INSN1(jne,_	,L33)
	INSN2(mov,l	,X4 MEM_DISP(esp,8),R(edx))
	INSN2(mov,l	,X4 MEM(edx),R(eax))
	INSN2(mov,l	,X4 MEM_DISP(esp,8),R(edx))
	INSN2(mov,l	,X4 MEM_DISP(edx,4),R(edx))
	INSN1(jmp,_	,L3)
L33:
	INSN2(test,b	,NUM(24),X1 MEM(esp))
	INSN1(jne,_	,L42)
	INSN2(add,l	,NUM(36),R(esp))
	ret NUM(4)
L42:
	INSN2(test,b	,NUM(16),X1 MEM(esp))
	INSN1(je,_	,L3)
L47:
	INSN2(mov,l	,X4 MEM_DISP(esp,8),R(eax))
L3:
	INSN2(test,b	,NUM(2),X1 MEM_DISP(esp,1))
	INSN1(je,_	,L44)
	INSN2(mov,l	,X4 MEM_DISP(esp,36),R(ecx))
	INSN2(mov,l	,X4 MEM_DISP(esp,4),R(esp))
	INSN1(jmp,_	,INDIR(R(ecx)))
L44:
	INSN2(add,l	,NUM(36),R(esp))
	ret
FUNEND()

