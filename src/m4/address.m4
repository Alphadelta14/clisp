dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2008, 2011, 2017 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ(2.57)

AC_DEFUN([CL_ADDRESS_RANGE],
[AC_REQUIRE([AC_PROG_CC])dnl
address_range_prog='
#include <stdio.h>
int printf_address (unsigned long addr) {
  FILE* out = fopen("conftest.h","w");
  if (sizeof(unsigned long) <= 4)
    fprintf(out,"0x%08X\n", (unsigned int)addr);
  else
    fprintf(out,"0x%08X%08X\n",(unsigned int)(addr>>32),(unsigned int)(addr&0xFFFFFFFF));
  return ferror(out) || fclose(out);
}
#define chop_address(addr) ((unsigned long)(char*)(addr) & ~0x00FFFFFFL)
'
AC_CACHE_CHECK(for the code address range, cl_cv_address_code, [dnl
AC_RUN_IFELSE([AC_LANG_PROGRAM([#include "confdefs.h"
$address_range_prog],[
dnl printf_address(chop_address(&main)); doesn't work in C++.
return printf_address(chop_address(&printf_address));])],
[cl_cv_address_code=`cat conftest.h`],[cl_cv_address_code='guessing 0'],
[cl_cv_address_code='guessing 0'])
rm -f conftest.h
])
x=`echo $cl_cv_address_code | sed -e 's,^guessing ,,'`"UL"
AC_DEFINE_UNQUOTED(CODE_ADDRESS_RANGE,$x,[address range of program code (text+data+bss)])
dnl
AC_CACHE_CHECK(for the malloc address range, cl_cv_address_malloc, [dnl
AC_RUN_IFELSE([AC_LANG_PROGRAM([#include "confdefs.h"
#include <sys/types.h>
/* declare malloc() */
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
$address_range_prog],[return printf_address(chop_address(malloc(10000)));])],
[cl_cv_address_malloc=`cat conftest.h`],[cl_cv_address_malloc='guessing 0'],
[cl_cv_address_malloc='guessing 0'])
rm -f conftest.h
])
x=`echo $cl_cv_address_malloc | sed -e 's,^guessing ,,'`"UL"
AC_DEFINE_UNQUOTED(MALLOC_ADDRESS_RANGE,$x,[address range of malloc() memory])
dnl
AC_CACHE_CHECK(for the shared library address range, cl_cv_address_shlib, [dnl
AC_RUN_IFELSE([AC_LANG_PROGRAM([#include "confdefs.h"
$address_range_prog
/* Declare tmpnam(). */
#ifdef __cplusplus
extern "C" char* tmpnam (char*);
#else
extern char* tmpnam (char*);
#endif
],[
/* With normal simple DLLs, &printf is in the shared library. Fine.
   But with ELF, &printf is a trampoline function allocated near the
   program's code range. errno and other global variables - such as
   &stdout - are allocated near the program's code and bss as well.
   However, the return value of tmpnam(NULL) is a pointer to a static
   buffer in the shared library. (This buffer is unlikely to be named
   by a global symbol.) */
  char* addr;
  addr = (char*) tmpnam((char*)0);
  if (!addr) addr = (char*) &printf;
  return printf_address(chop_address(addr));
])],[cl_cv_address_shlib=`cat conftest.h`],[cl_cv_address_shlib='guessing 0'],
[cl_cv_address_shlib='guessing 0'])
rm -f conftest.h
])
x=`echo $cl_cv_address_shlib | sed -e 's,^guessing ,,'`"UL"
AC_DEFINE_UNQUOTED(SHLIB_ADDRESS_RANGE,$x,[address range of shared library code])

AC_CACHE_CHECK(for the stack address range, cl_cv_address_stack, [dnl
AC_RUN_IFELSE([AC_LANG_PROGRAM([#include "confdefs.h"
#include "confdefs.h"
$address_range_prog],[int dummy; return printf_address(chop_address(&dummy));])],
[cl_cv_address_stack=`cat conftest.h`],[cl_cv_address_stack='guessing ~0'],
[cl_cv_address_stack='guessing ~0'])
rm -f conftest.h
])
x=`echo "$cl_cv_address_stack" | sed -e 's,^guessing ,,'`"UL"
AC_DEFINE_UNQUOTED(STACK_ADDRESS_RANGE,$x,[address range of the C stack])
])
