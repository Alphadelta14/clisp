dnl Copyright (C) 1993-2002, 2017 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels.

AC_PREREQ([2.13])

AC_DEFUN([CL_MUNMAP],
[
  AC_REQUIRE([CL_MMAP])
  if test -z "$no_mmap"; then
    AC_CHECK_FUNCS([munmap])
  fi
])
