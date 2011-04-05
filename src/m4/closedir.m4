dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2008 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ(2.13)

AC_DEFUN([CL_CLOSEDIR],
[AC_BEFORE([$0], [CL_FILECHARSET])dnl
# The following test is necessary, because Cygwin32 declares closedir()
# as returning int but the return value is unusable.
AC_CACHE_CHECK(for usable closedir return value, cl_cv_func_closedir_retval,[
AC_TRY_RUN([
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <sys/types.h>
#include <unistd.h>
#endif
/* Declare opendir(), closedir(). */
#include <dirent.h>
int main() { exit(closedir(opendir(".")) != 0); }],
cl_cv_func_closedir_retval=yes, cl_cv_func_closedir_retval=no,
# When cross-compiling, don't assume a return value.
cl_cv_func_closedir_retval="guessing no")])
case "$cl_cv_func_closedir_retval" in
  *no) AC_DEFINE(VOID_CLOSEDIR,,[closedir() return value is void or unusable]) ;;
esac
])
