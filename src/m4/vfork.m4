dnl Copyright (C) 1993-2002 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels.

AC_PREREQ(2.13)

AC_DEFUN([CL_VFORK],
[CL_PROTO([vfork], [
CL_PROTO_TRY([
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <sys/types.h>
#ifdef HAVE_VFORK_H
#include <vfork.h>
#endif
], [pid_t vfork (void);], [pid_t vfork();],
cl_cv_proto_vfork_ret="pid_t", cl_cv_proto_vfork_ret="int")
], [extern $cl_cv_proto_vfork_ret vfork (void);])
AC_DEFINE_UNQUOTED(RETVFORKTYPE,$cl_cv_proto_vfork_ret)
])
