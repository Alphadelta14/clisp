dnl Copyright (C) 1993-2002 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels.

AC_PREREQ(2.13)

AC_DEFUN([CL_CADDR_T],
[AC_CACHE_CHECK(for caddr_t in sys/types.h, cl_cv_type_caddr_t, [
AC_EGREP_HEADER(caddr_t, sys/types.h,
cl_cv_type_caddr_t=yes, cl_cv_type_caddr_t=no)
])
if test $cl_cv_type_caddr_t = yes; then
  AC_DEFINE(CADDR_T, caddr_t)
else
  AC_DEFINE(CADDR_T, void*)
fi
]
)
