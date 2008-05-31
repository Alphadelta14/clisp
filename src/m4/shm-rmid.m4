dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2008 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ(2.57)

AC_DEFUN([CL_SHM_RMID],
[AC_REQUIRE([CL_SHM])dnl
if test -n "$have_shm"; then
AC_CACHE_CHECK(for attachability of removed shared memory, cl_cv_func_shmctl_attachable, [
AC_TRY_RUN([
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#ifdef HAVE_SYS_SYSMACROS_H
#include <sys/sysmacros.h>
#endif
int main ()
{ unsigned int pagesize = 8192; /* should be a multiple of SHMLBA */
  unsigned long addr = (unsigned long) malloc(2*pagesize);
  addr += pagesize-1; addr = (addr/pagesize)*pagesize;
 {unsigned long addr1 = addr + 0x100000;
  unsigned long addr2 = addr + 0x200000;
  int id = shmget(IPC_PRIVATE,pagesize,IPC_CREAT|0600);
  if (id<0)
    { exit(1); }
  if (shmat(id,(void*)addr1,0) == (void*)(-1))
    { shmctl(id,IPC_RMID,NULL); exit(1); }
  if (shmctl(id,IPC_RMID,NULL) < 0)
    { exit(1); }
  if (shmat(id,(void*)addr2,0) == (void*)(-1))
    { shmctl(id,IPC_RMID,NULL); exit(1); }
  shmctl(id,IPC_RMID,NULL);
  exit(0);
}}
], cl_cv_func_shmctl_attachable=yes, cl_cv_func_shmctl_attachable=no,
dnl When cross-compiling, don't assume anything.
cl_cv_func_shmctl_attachable="guessing no")
])
case "$cl_cv_func_shmctl_attachable" in
  *yes) AC_DEFINE(SHM_RMID_VALID,,[attaching removed (but alive!) shared memory segments works]) ;;
  *no)  ;;
esac
fi
])
