/* vacall function for mips CPU */

/*
 * Copyright 1995-1997 Bruno Haible, <haible@clisp.cons.org>
 *
 * This is free software distributed under the GNU General Public Licence
 * described in the file COPYING. Contact the author if you don't have this
 * or can't live with it. There is ABSOLUTELY NO WARRANTY, explicit or implied,
 * on this software.
 */

#ifndef REENTRANT
#include "vacall.h.in"
#else /* REENTRANT */
#include "vacall_r.h.in"
#endif

#ifndef REENTRANT
typedef void (*func_pointer)(va_alist);
#else /* REENTRANT */
#define vacall __vacall_r
typedef void (*func_pointer)(void*,va_alist);
register struct { func_pointer vacall_function; void* arg; }
         *	env	__asm__("$2");
#endif
register func_pointer t9 __asm__("$25");
register void*	sp	__asm__("$sp");
register long	iarg0	__asm__("$4");
register long	iarg1	__asm__("$5");
register long	iarg2	__asm__("$6");
register long	iarg3	__asm__("$7");
register long	iarg4	__asm__("$8");
register long	iarg5	__asm__("$9");
register long	iarg6	__asm__("$10");
register long	iarg7	__asm__("$11");
register float	farg0	__asm__("$f12");
register float	farg1	__asm__("$f13");
register float	farg2	__asm__("$f14");
register float	farg3	__asm__("$f15");
register float	farg4	__asm__("$f16");
register float	farg5	__asm__("$f17");
register float	farg6	__asm__("$f18");
register float	farg7	__asm__("$f19");
register double	darg0	__asm__("$f12");
register double	darg1	__asm__("$f13");
register double	darg2	__asm__("$f14");
register double	darg3	__asm__("$f15");
register double	darg4	__asm__("$f16");
register double	darg5	__asm__("$f17");
register double	darg6	__asm__("$f18");
register double	darg7	__asm__("$f19");
register long	iret	__asm__("$2");
register long	iret2	__asm__("$3");
register float	fret	__asm__("$f0");
register float	fret2	__asm__("$f2");
register double	dret	__asm__("$f0");
register double	dret2	__asm__("$f2");

void /* the return type is variable, not void! */
vacall (__vaword word1, __vaword word2, __vaword word3, __vaword word4,
        __vaword word5, __vaword word6, __vaword word7, __vaword word8,
        __vaword firstword)
{
  /* gcc-2.6.3 behaves as if stack space were already allocated for
   * word1,...,word8, but it isn't.
   */
  sp -= 8*sizeof(__vaword);
  __asm__ __volatile__ ("");
  /* Move the arguments passed in registers to their stack locations. */
  (&firstword)[-8] = iarg0; /* word1 */
  (&firstword)[-7] = iarg1; /* word2 */
  (&firstword)[-6] = iarg2; /* word3 */
  (&firstword)[-5] = iarg3; /* word4 */
  (&firstword)[-4] = iarg4; /* word5 */
  (&firstword)[-3] = iarg5; /* word6 */
  (&firstword)[-2] = iarg6; /* word7 */
  (&firstword)[-1] = iarg7; /* word8 */
 {__va_alist list;
  list.darg[0] = darg0;
  list.darg[1] = darg1;
  list.darg[2] = darg2;
  list.darg[3] = darg3;
  list.darg[4] = darg4;
  list.darg[5] = darg5;
  list.darg[6] = darg6;
  list.darg[7] = darg7;
  list.farg[0] = farg0;
  list.farg[1] = farg1;
  list.farg[2] = farg2;
  list.farg[3] = farg3;
  list.farg[4] = farg4;
  list.farg[5] = farg5;
  list.farg[6] = farg6;
  list.farg[7] = farg7;
  /* Prepare the va_alist. */
  list.flags = 0;
  list.aptr = (long)(&firstword - 8);
  list.raddr = (void*)0;
  list.rtype = __VAvoid;
  list.memargptr = (long)&firstword;
  list.anum = 0;
  /* Call vacall_function. The macros do all the rest. */
#ifndef REENTRANT
  (*(t9 = vacall_function)) (&list);
#else /* REENTRANT */
  (*(t9 = env->vacall_function)) (env->arg,&list);
#endif
  /* Put return value into proper register. */
  switch (list.rtype)
    {
      case __VAvoid:	  break;
      case __VAchar:	  iret = list.tmp._char; break;
      case __VAschar:	  iret = list.tmp._schar; break;
      case __VAuchar:	  iret = list.tmp._uchar; break;
      case __VAshort:	  iret = list.tmp._short; break;
      case __VAushort:	  iret = list.tmp._ushort; break;
      case __VAint:	  iret = list.tmp._int; break;
      case __VAuint:	  iret = list.tmp._uint; break;
      case __VAlong:	  iret = list.tmp._long; break;
      case __VAulong:	  iret = list.tmp._ulong; break;
      case __VAlonglong:  iret = list.tmp._long; break;
      case __VAulonglong: iret = list.tmp._ulong; break;
      case __VAfloat:	  fret = list.tmp._float; break;
      case __VAdouble:	  dret = list.tmp._double; break;
      case __VAvoidp:	  iret = (long)list.tmp._ptr; break;
      case __VAstruct:
        if (list.flags & __VA_PCC_STRUCT_RETURN)
          { /* pcc struct return convention */
            iret = (long) list.raddr;
          }
        else
          { /* normal struct return convention */
            if (list.flags & __VA_REGISTER_STRUCT_RETURN)
              {
                if (list.flags & __VA_GCC_STRUCT_RETURN)
                  /* gcc returns structs of size 1,2,4,8 in registers. */
                    switch (list.rsize)
                      {
                        case sizeof(char):  iret = *(unsigned char *) list.raddr; break;
                        case sizeof(short): iret = *(unsigned short *) list.raddr; break;
                        case sizeof(int):   iret = *(unsigned int *) list.raddr; break;
                        case sizeof(long):  iret = *(unsigned long *) list.raddr; break;
                        default:            break;
                      }
                else
                  { /* cc returns structs of size <= 16 in registers. */
                    /* Maybe this big switch(){} could be replaced by
                     * if (list.rsize > 0 && list.rsize <= 16)
                     *   __asm__ ("ldl $2,%0 ; ldr $2,%1"
                     *            : : "m" (((unsigned char *) list.raddr)[0]),
                     *                "m" (((unsigned char *) list.raddr)[7]));
                     */
                    switch (list.rsize)
                      {
                        case 1:
                          iret =   (__vaword)((unsigned char *) list.raddr)[0] << 56;
                          break;
                        case 2:
                          iret =  ((__vaword)((unsigned char *) list.raddr)[0] << 56)
                                | ((__vaword)((unsigned char *) list.raddr)[1] << 48);
                          break;
                        case 3:
                          iret =  ((__vaword)((unsigned char *) list.raddr)[0] << 56)
                                | ((__vaword)((unsigned char *) list.raddr)[1] << 48)
                                | ((__vaword)((unsigned char *) list.raddr)[2] << 40);
                          break;
                        case 4:
                          iret =  ((__vaword)((unsigned char *) list.raddr)[0] << 56)
                                | ((__vaword)((unsigned char *) list.raddr)[1] << 48)
                                | ((__vaword)((unsigned char *) list.raddr)[2] << 40)
                                | ((__vaword)((unsigned char *) list.raddr)[3] << 32);
                          break;
                        case 5:
                          iret =  ((__vaword)((unsigned char *) list.raddr)[0] << 56)
                                | ((__vaword)((unsigned char *) list.raddr)[1] << 48)
                                | ((__vaword)((unsigned char *) list.raddr)[2] << 40)
                                | ((__vaword)((unsigned char *) list.raddr)[3] << 32)
                                | ((__vaword)((unsigned char *) list.raddr)[4] << 24);
                          break;
                        case 6:
                          iret =  ((__vaword)((unsigned char *) list.raddr)[0] << 56)
                                | ((__vaword)((unsigned char *) list.raddr)[1] << 48)
                                | ((__vaword)((unsigned char *) list.raddr)[2] << 40)
                                | ((__vaword)((unsigned char *) list.raddr)[3] << 32)
                                | ((__vaword)((unsigned char *) list.raddr)[4] << 24)
                                | ((__vaword)((unsigned char *) list.raddr)[5] << 16);
                          break;
                        case 7:
                          iret =  ((__vaword)((unsigned char *) list.raddr)[0] << 56)
                                | ((__vaword)((unsigned char *) list.raddr)[1] << 48)
                                | ((__vaword)((unsigned char *) list.raddr)[2] << 40)
                                | ((__vaword)((unsigned char *) list.raddr)[3] << 32)
                                | ((__vaword)((unsigned char *) list.raddr)[4] << 24)
                                | ((__vaword)((unsigned char *) list.raddr)[5] << 16)
                                | ((__vaword)((unsigned char *) list.raddr)[6] << 8);
                          break;
                        case 8:
                        case 9: case 10: case 11: case 12: case 13: case 14: case 15: case 16:
                          iret =  ((__vaword)((unsigned char *) list.raddr)[0] << 56)
                                | ((__vaword)((unsigned char *) list.raddr)[1] << 48)
                                | ((__vaword)((unsigned char *) list.raddr)[2] << 40)
                                | ((__vaword)((unsigned char *) list.raddr)[3] << 32)
                                | ((__vaword)((unsigned char *) list.raddr)[4] << 24)
                                | ((__vaword)((unsigned char *) list.raddr)[5] << 16)
                                | ((__vaword)((unsigned char *) list.raddr)[6] << 8)
                                |  (__vaword)((unsigned char *) list.raddr)[7];
                          break;
                        default: break;
                      }
                    /* Maybe this big switch(){} could be replaced by
                     * if (list.rsize > 8 && list.rsize <= 16)
                     *   __asm__ ("ldl $3,%0 ; ldr $3,%1"
                     *            : : "m" (((unsigned char *) list.raddr)[8]),
                     *                "m" (((unsigned char *) list.raddr)[15]));
                     */
                    switch (list.rsize)
                      {
                        case 9:
                          iret2 =   (__vaword)((unsigned char *) list.raddr)[8] << 56;
                          break;
                        case 10:
                          iret2 =  ((__vaword)((unsigned char *) list.raddr)[8] << 56)
                                 | ((__vaword)((unsigned char *) list.raddr)[9] << 48);
                          break;
                        case 11:
                          iret2 =  ((__vaword)((unsigned char *) list.raddr)[8] << 56)
                                 | ((__vaword)((unsigned char *) list.raddr)[9] << 48)
                                 | ((__vaword)((unsigned char *) list.raddr)[10] << 40);
                          break;
                        case 12:
                          iret2 =  ((__vaword)((unsigned char *) list.raddr)[8] << 56)
                                 | ((__vaword)((unsigned char *) list.raddr)[9] << 48)
                                 | ((__vaword)((unsigned char *) list.raddr)[10] << 40)
                                 | ((__vaword)((unsigned char *) list.raddr)[11] << 32);
                          break;
                        case 13:
                          iret2 =  ((__vaword)((unsigned char *) list.raddr)[8] << 56)
                                 | ((__vaword)((unsigned char *) list.raddr)[9] << 48)
                                 | ((__vaword)((unsigned char *) list.raddr)[10] << 40)
                                 | ((__vaword)((unsigned char *) list.raddr)[11] << 32)
                                 | ((__vaword)((unsigned char *) list.raddr)[12] << 24);
                          break;
                        case 14:
                          iret2 =  ((__vaword)((unsigned char *) list.raddr)[8] << 56)
                                 | ((__vaword)((unsigned char *) list.raddr)[9] << 48)
                                 | ((__vaword)((unsigned char *) list.raddr)[10] << 40)
                                 | ((__vaword)((unsigned char *) list.raddr)[11] << 32)
                                 | ((__vaword)((unsigned char *) list.raddr)[12] << 24)
                                 | ((__vaword)((unsigned char *) list.raddr)[13] << 16);
                          break;
                        case 15:
                          iret2 =  ((__vaword)((unsigned char *) list.raddr)[8] << 56)
                                 | ((__vaword)((unsigned char *) list.raddr)[9] << 48)
                                 | ((__vaword)((unsigned char *) list.raddr)[10] << 40)
                                 | ((__vaword)((unsigned char *) list.raddr)[11] << 32)
                                 | ((__vaword)((unsigned char *) list.raddr)[12] << 24)
                                 | ((__vaword)((unsigned char *) list.raddr)[13] << 16)
                                 | ((__vaword)((unsigned char *) list.raddr)[14] << 8);
                          break;
                        case 16:
                          iret2 =  ((__vaword)((unsigned char *) list.raddr)[8] << 56)
                                 | ((__vaword)((unsigned char *) list.raddr)[9] << 48)
                                 | ((__vaword)((unsigned char *) list.raddr)[10] << 40)
                                 | ((__vaword)((unsigned char *) list.raddr)[11] << 32)
                                 | ((__vaword)((unsigned char *) list.raddr)[12] << 24)
                                 | ((__vaword)((unsigned char *) list.raddr)[13] << 16)
                                 | ((__vaword)((unsigned char *) list.raddr)[14] << 8)
                                 |  (__vaword)((unsigned char *) list.raddr)[15];
                          break;
                        default: break;
                      }
                    if (list.flags & __VA_REGISTER_FLOATSTRUCT_RETURN)
                      { if (list.rsize == sizeof(float))
                          { fret = *(float*)list.raddr; }
                        else if (list.rsize == 2*sizeof(float))
                          { fret = *(float*)list.raddr; fret2 = *(float*)((char*)list.raddr + 4); }
                      }
                    if (list.flags & __VA_REGISTER_DOUBLESTRUCT_RETURN)
                      { if (list.rsize == sizeof(double))
                          { dret = *(double*)list.raddr; }
                        else if (list.rsize == 2*sizeof(double))
                          { dret = *(double*)list.raddr; dret2 = *(double*)((char*)list.raddr + 8); }
                      }
                  }
              }
          }
        break;
    }
  __asm__ __volatile__ ("");
  sp += 8*sizeof(__vaword);
}}
