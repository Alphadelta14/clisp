/* vacall function for powerpc64 CPU */

/*
 * Copyright 1995-2006 Bruno Haible, <bruno@clisp.org>
 * Copyright 2000 Adam Fedor, <fedor@gnu.org>
 * Copyright 2004 Paul Guyot, <pguyot@kallisys.net>
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

#ifdef REENTRANT
#define __vacall __vacall_r
register struct { void (*vacall_function) (void*,va_alist); void* arg; }
         *		env	__asm__("r11");
#endif
register double		farg1	__asm__("fr1");
register double		farg2	__asm__("fr2");
register double		farg3	__asm__("fr3");
register double		farg4	__asm__("fr4");
register double		farg5	__asm__("fr5");
register double		farg6	__asm__("fr6");
register double		farg7	__asm__("fr7");
register double		farg8	__asm__("fr8");
register double		farg9	__asm__("fr9");
register double		farg10	__asm__("fr10");
register double		farg11	__asm__("fr11");
register double		farg12	__asm__("fr12");
register double		farg13	__asm__("fr13");
register __vaword	iret	__asm__("r3");
register float		fret	__asm__("fr1");
register double		dret	__asm__("fr1");

void /* the return type is variable, not void! */
__vacall (__vaword word1, __vaword word2, __vaword word3, __vaword word4,
          __vaword word5, __vaword word6, __vaword word7, __vaword word8,
          __vaword firstword)
{
  __va_alist list;
  /* When a parameter is passed in a register,
   * stack space is still allocated for it.
   */
  /* Move the arguments passed in registers to their stack locations. */
  (&firstword)[-8] = word1;
  (&firstword)[-7] = word2;
  (&firstword)[-6] = word3;
  (&firstword)[-5] = word4;
  (&firstword)[-4] = word5;
  (&firstword)[-3] = word6;
  (&firstword)[-2] = word7;
  (&firstword)[-1] = word8;
  list.farg[0] = farg1;
  list.farg[1] = farg2;
  list.farg[2] = farg3;
  list.farg[3] = farg4;
  list.farg[4] = farg5;
  list.farg[5] = farg6;
  list.farg[6] = farg7;
  list.farg[7] = farg8;
  list.farg[8] = farg9;
  list.farg[9] = farg10;
  list.farg[10] = farg11;
  list.farg[11] = farg12;
  list.farg[12] = farg13;
  /* Prepare the va_alist. */
  list.flags = 0;
  list.aptr = (long)(&firstword - 8);
  list.raddr = (void*)0;
  list.rtype = __VAvoid;
  list.memfargptr = &list.farg[0];
  /* Call vacall_function. The macros do all the rest. */
#ifndef REENTRANT
  (*vacall_function) (&list);
#else /* REENTRANT */
  (*env->vacall_function) (env->arg,&list);
#endif
  /* Put return value into proper register. */
  if (list.rtype == __VAvoid) {
  } else
  if (list.rtype == __VAchar) {
    iret = list.tmp._char;
  } else
  if (list.rtype == __VAschar) {
    iret = list.tmp._schar;
  } else
  if (list.rtype == __VAuchar) {
    iret = list.tmp._uchar;
  } else
  if (list.rtype == __VAshort) {
    iret = list.tmp._short;
  } else
  if (list.rtype == __VAushort) {
    iret = list.tmp._ushort;
  } else
  if (list.rtype == __VAint) {
    iret = list.tmp._int;
  } else
  if (list.rtype == __VAuint) {
    iret = list.tmp._uint;
  } else
  if (list.rtype == __VAlong) {
    iret = list.tmp._long;
  } else
  if (list.rtype == __VAulong) {
    iret = list.tmp._ulong;
  } else
  if (list.rtype == __VAlonglong) {
    iret = list.tmp._long;
  } else
  if (list.rtype == __VAulonglong) {
    iret = list.tmp._ulong;
  } else
  if (list.rtype == __VAfloat) {
    fret = list.tmp._float;
  } else
  if (list.rtype == __VAdouble) {
    dret = list.tmp._double;
  } else
  if (list.rtype == __VAvoidp) {
    iret = (long)list.tmp._ptr;
  } else
  if (list.rtype == __VAstruct) {
    /* __VA_PCC_STRUCT_RETURN and __VA_REGISTER_STRUCT_RETURN are ignored */
  }
}
