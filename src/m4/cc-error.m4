dnl Copyright (C) 1993-2002 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels.

AC_PREREQ(2.13)

AC_DEFUN([CL_CC_NEED_DEERROR],
[AC_REQUIRE([AC_PROG_CPP])
dnl Bug in autoconf-2.1: If we put the # literally there, AC_FD_MSG doesn't get expanded.
sharp='#error'
AC_CACHE_CHECK([whether CPP understands $sharp], cl_cv_prog_cc_error, [
AC_TRY_CPP([#if 0
#error "bla"
#endif],
cl_cv_prog_cc_error=yes, cl_cv_prog_cc_error=no)
])
if test $cl_cv_prog_cc_error = yes; then
  CC_NEED_DEERROR=false
else
  CC_NEED_DEERROR=true
fi
AC_SUBST(CC_NEED_DEERROR)dnl
])
