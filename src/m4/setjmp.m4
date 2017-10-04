dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2003, 2017 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ([2.57])

AC_DEFUN([CL_SETJMP],
[
  AC_CHECK_FUNC([_setjmp], , [no__jmp=1])
  if test -z "$no__jmp"; then
    AC_CHECK_FUNC([_longjmp], , [no__jmp=1])
  fi
  if test -z "$no__jmp"; then
    AC_DEFINE([HAVE__JMP],,[have _setjmp() and _longjmp()])
  fi
  AC_EGREP_HEADER([void.* longjmp], [setjmp.h], ,
    [AC_DEFINE(LONGJMP_RETURNS,,[longjmp() may return])])
])
