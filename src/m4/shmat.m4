dnl Copyright (C) 1993-2002 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels.

AC_PREREQ(2.13)

AC_DEFUN([CL_SHMAT],
[AC_REQUIRE([CL_SHM_H])dnl
AC_BEFORE([$0], [CL_SHM])dnl
if test "$ac_cv_header_sys_shm_h" = yes -a "$ac_cv_header_sys_ipc_h" = yes; then
CL_PROTO([shmat], [
CL_PROTO_RET([
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
], [
#ifdef __cplusplus
void* shmat(int, const void *, int);
#else
void* shmat();
#endif
], [void* shmat();],
cl_cv_proto_shmat_ret, [void*], [char*])
CL_PROTO_CONST([
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
], [$cl_cv_proto_shmat_ret shmat (int shmid, $cl_cv_proto_shmat_ret shmaddr, int shmflg);],
[$cl_cv_proto_shmat_ret shmat();], cl_cv_proto_shmat_arg2)
], [extern $cl_cv_proto_shmat_ret shmat (int, $cl_cv_proto_shmat_arg2 $cl_cv_proto_shmat_ret, int);])
AC_DEFINE_UNQUOTED(RETSHMATTYPE,$cl_cv_proto_shmat_ret)
AC_DEFINE_UNQUOTED(SHMAT_CONST,$cl_cv_proto_shmat_arg2)
fi
])
