dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2004 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ(2.57)

AC_DEFUN([RL_SELECT],
[dnl Not AC_CHECK_FUNCS(select) because it doesn't work when CC=g++.
AC_CACHE_CHECK([for select], ac_cv_func_select, [
AC_TRY_LINK([#include <sys/time.h>
]AC_LANG_EXTERN[
#ifdef __cplusplus
int select(int, fd_set*, fd_set*, fd_set*, struct timeval *);
#else
int select();
#endif
], [select(0,(fd_set*)0,(fd_set*)0,(fd_set*)0,(struct timeval *)0);],
ac_cv_func_select=yes, ac_cv_func_select=no)])
if test $ac_cv_func_select = yes; then
AC_DEFINE(HAVE_SELECT, 1, [Define if you have the select() function.])
CL_COMPILE_CHECK([sys/select.h], cl_cv_header_sys_select_h,
[#ifdef __BEOS__
#include <sys/socket.h>
#endif
#include <sys/time.h>
#include <sys/select.h>], ,
AC_DEFINE(HAVE_SYS_SELECT_H,,[have <sys/select.h>?]))dnl
fi
])

AC_DEFUN([CL_SELECT],
[AC_REQUIRE([CL_OPENFLAGS])dnl
dnl Not AC_CHECK_FUNCS(select) because it doesn't work when CC=g++.
AC_CACHE_CHECK([for select], ac_cv_func_select, [
AC_TRY_LINK([
#ifdef __BEOS__
#include <sys/socket.h>
#endif
#include <sys/time.h>
]AC_LANG_EXTERN[
#ifdef __cplusplus
int select(int, fd_set*, fd_set*, fd_set*, struct timeval *);
#else
int select();
#endif
], [select(0,(fd_set*)0,(fd_set*)0,(fd_set*)0,(struct timeval *)0);],
ac_cv_func_select=yes, ac_cv_func_select=no)])
if test $ac_cv_func_select = yes; then
AC_DEFINE(HAVE_SELECT, 1, [Define if you have the select() function.])
CL_COMPILE_CHECK([sys/select.h], cl_cv_header_sys_select_h,
[#ifdef __BEOS__
#include <sys/socket.h>
#endif
#include <sys/time.h>
#include <sys/select.h>], ,
AC_DEFINE(HAVE_SYS_SELECT_H,,[have <sys/select.h>?]))dnl
CL_PROTO([select], [
for z in '' 'const'; do
for y in 'fd_set' 'int' 'void' 'struct fd_set'; do
for x in 'int' 'size_t'; do
if test -z "$have_select"; then
CL_PROTO_TRY([
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <sys/types.h>
#ifdef __BEOS__
#include <sys/socket.h>
#endif
#include <sys/time.h>
#ifdef HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif
], [int select ($x width, $y * readfds, $y * writefds, $y * exceptfds, $z struct timeval * timeout);],
[int select();], [
cl_cv_proto_select_arg1="$x"
cl_cv_proto_select_arg2="$y"
cl_cv_proto_select_arg5="$z"
have_select=1])
fi
done
done
done
if test -z "$have_select"; then
  echo "*** Missing autoconfiguration support for this platform." 1>&2
  echo "*** Please report this as a bug to the CLISP developers." 1>&2
  echo "*** When doing this, please also show your system's select() declaration." 1>&2
  exit 1
fi
], [extern int select ($cl_cv_proto_select_arg1, $cl_cv_proto_select_arg2 *, $cl_cv_proto_select_arg2 *, $cl_cv_proto_select_arg2 *, $cl_cv_proto_select_arg5 struct timeval *);])
AC_DEFINE_UNQUOTED(SELECT_WIDTH_T,$cl_cv_proto_select_arg1,[type of `width' in select() declaration])
AC_DEFINE_UNQUOTED(SELECT_SET_T,$cl_cv_proto_select_arg2,[type of `* readfds', `* writefds', `* exceptfds' in select() declaration])
AC_DEFINE_UNQUOTED(SELECT_CONST,$cl_cv_proto_select_arg5,[declaration of select() needs const in the fifth argument])
# Now check whether select() works reliably on regular files, i.e. signals
# immediate readability and writability, both before EOF and at EOF.
AC_CACHE_CHECK([for reliable select()], cl_cv_func_select_reliable, [
AC_TRY_RUN([
/* Declare select(). */
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <sys/types.h>
#ifdef __BEOS__
#include <sys/socket.h>
#endif
#include <sys/time.h>
#ifdef HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif
]AC_LANG_EXTERN[
#if defined(__STDC__) || defined(__cplusplus)
int select (SELECT_WIDTH_T, SELECT_SET_T*, SELECT_SET_T*, SELECT_SET_T*, SELECT_CONST struct timeval *);
#else
int select();
#endif
/* Declare open(). */
#include <fcntl.h>
#ifdef OPEN_NEEDS_SYS_FILE_H
#include <sys/file.h>
#endif
int main ()
{ int fd = open("conftest.c",O_RDWR,0644);
  int correct_readability_nonempty, correct_readability_empty;
  int correct_writability_nonempty, correct_writability_empty;
  fd_set handle_set;
  struct timeval zero_time;
  {
    FD_ZERO(&handle_set); FD_SET(fd,&handle_set);
    zero_time.tv_sec = 0; zero_time.tv_usec = 0;
    correct_readability_nonempty =
      (select(FD_SETSIZE,&handle_set,NULL,NULL,&zero_time) == 1);
  }
  {
    FD_ZERO(&handle_set); FD_SET(fd,&handle_set);
    zero_time.tv_sec = 0; zero_time.tv_usec = 0;
    correct_writability_nonempty =
      (select(FD_SETSIZE,NULL,&handle_set,NULL,&zero_time) == 1);
  }
  lseek(fd,0,SEEK_END);
  {
    FD_ZERO(&handle_set); FD_SET(fd,&handle_set);
    zero_time.tv_sec = 0; zero_time.tv_usec = 0;
    correct_readability_empty =
      (select(FD_SETSIZE,&handle_set,NULL,NULL,&zero_time) == 1);
  }
  {
    FD_ZERO(&handle_set); FD_SET(fd,&handle_set);
    zero_time.tv_sec = 0; zero_time.tv_usec = 0;
    correct_writability_empty =
      (select(FD_SETSIZE,NULL,&handle_set,NULL,&zero_time) == 1);
  }
  exit(!(correct_readability_nonempty && correct_readability_empty
         && correct_writability_nonempty && correct_writability_empty));
}],
cl_cv_func_select_reliable=yes, cl_cv_func_select_reliable=no,
dnl When cross-compiling, don't assume anything.
cl_cv_func_select_reliable="guessing no")
])
case "$cl_cv_func_select_reliable" in
  *yes) AC_DEFINE(HAVE_RELIABLE_SELECT,,[have select() and it works reliably on files]) ;;
  *no) ;;
esac
fi
])
