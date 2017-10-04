dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2007, 2017 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ([2.57])

AC_DEFUN([CL_SOCKLEN_T],
[
  AC_CACHE_CHECK([for socklen_t in sys/socket.h], [cl_cv_type_socklen_t],
    [AC_EGREP_HEADER([socklen_t], [sys/socket.h],
       [cl_cv_type_socklen_t=yes],
       [cl_cv_type_socklen_t=no])
    ])
  if test $cl_cv_type_socklen_t = yes; then
    AC_DEFINE([CLISP_SOCKLEN_T], [socklen_t],
      [socklen_t (if defined in <sys/socket.h>) or int otherwise])
  else
    AC_DEFINE([CLISP_SOCKLEN_T], [int])
  fi
])
