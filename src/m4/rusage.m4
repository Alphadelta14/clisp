dnl Copyright (C) 1993-2002 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Peter Burwood.

AC_PREREQ(2.13)

AC_DEFUN([CL_RUSAGE],
[AC_CHECK_HEADERS(sys/resource.h sys/times.h)dnl
if test $ac_cv_header_sys_resource_h = yes; then
  dnl HAVE_SYS_RESOURCE_H defined
  AC_CACHE_CHECK(whether getrusage works, cl_cv_func_getrusage_works, [
  CL_LINK_CHECK([getrusage], cl_cv_func_getrusage,
[#include <sys/types.h> /* NetBSD 1.0 needs this */
#include <sys/time.h>
#include <sys/resource.h>],
    [struct rusage x; int y = RUSAGE_SELF; getrusage(y,&x); x.ru_utime.tv_sec;])dnl
  if test $cl_cv_func_getrusage = yes; then
    CL_PROTO([getrusage], [
    CL_PROTO_TRY([
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <sys/types.h> /* NetBSD 1.0 needs this */
#include <sys/time.h>
#include <sys/resource.h>
],
[int getrusage (int who, struct rusage * rusage);],
[int getrusage();],
[cl_cv_proto_getrusage_arg1="int"],
[cl_cv_proto_getrusage_arg1="enum __rusage_who"])
], [extern int getrusage ($cl_cv_proto_getrusage_arg1, struct rusage *);])dnl
    AC_TRY_RUN([
#include <stdio.h>
#include <sys/types.h> /* NetBSD 1.0 needs this */
#include <sys/time.h>
#include <sys/resource.h>
int main ()
{
  struct rusage used, prev;
  int count = 0;

  /* getrusage is defined but not do anything. */
  if (!(getrusage(RUSAGE_SELF, &prev) == 0)) exit(1);
  sleep (1);

  while (++count < 10000)
    {
      getrusage(RUSAGE_SELF, &used);
      if ((used.ru_utime.tv_usec != prev.ru_utime.tv_usec)
          || (used.ru_utime.tv_sec != prev.ru_utime.tv_sec)
          || (used.ru_stime.tv_usec != prev.ru_stime.tv_usec)
          || (used.ru_stime.tv_sec != prev.ru_stime.tv_sec))
        exit (0);
    }
  /* getrusage is defined but does not work. */
  exit (1);
}],
cl_cv_func_getrusage_works=yes,
cl_cv_func_getrusage_works=no,
dnl When cross-compiling, don't assume anything.
cl_cv_func_getrusage_works="guessing no")
  fi
])
  if test $cl_cv_func_getrusage_works = yes; then
    AC_DEFINE(HAVE_GETRUSAGE)
    AC_DEFINE_UNQUOTED(RUSAGE_WHO_T,$cl_cv_proto_getrusage_arg1)
  fi
fi
])
