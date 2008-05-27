dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2008 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ(2.13)

dnl CL_MACHINE([MESSAGE], [PROGRAM_TO_RUN], [CROSS_MACRO], [DESTINATION], [CACHE_VAR])
AC_DEFUN([CL_MACHINE],
[AC_REQUIRE([AC_PROG_CC])dnl
AC_REQUIRE([AC_C_CHAR_UNSIGNED])dnl
cl_machine_file_c=$2
if test -z "$[$5]"; then
AC_MSG_NOTICE(checking for [$1])
cl_machine_file_h=$4
ORIGCC="$CC"
if test $ac_cv_prog_gcc = yes; then
# gcc -O (gcc version <= 2.3.2) crashes when compiling long long shifts for
# target 80386. Strip "-O".
CC=`echo "$CC " | sed -e 's/-O //g'`
fi
cl_machine_file_program=`cat "$cl_machine_file_c"`
AC_RUN_IFELSE([#include "confdefs.h"
$cl_machine_file_program],[AC_MSG_RESULT(creating $cl_machine_file_h)
if cmp -s "$cl_machine_file_h" conftest.h 2>/dev/null; then
  # The file exists and we would not be changing it
  rm -f conftest.h
else
  rm -f "$cl_machine_file_h"
  mv conftest.h "$cl_machine_file_h"
fi
[$5]=1],[AC_MSG_RESULT(creation of $cl_machine_file_h failed)],
[AC_MSG_RESULT(creating $cl_machine_file_h)
$3([$4])])
rm -f conftest.h
CC="$ORIGCC"
fi
])
