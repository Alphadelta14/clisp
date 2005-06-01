dnl -*- Autoconf -*-
dnl Copyright (C) 2004-2005 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible.

AC_PREREQ(2.57)

AC_DEFUN([CL_POLL],
[AC_REQUIRE([CL_OPENFLAGS])dnl
AC_CHECK_FUNC(poll,
  [# Check whether poll() works on special files (like /dev/null) and
   # and ttys (like /dev/tty). On MacOS X 10.4.0, it doesn't.
   AC_TRY_RUN([
#include <fcntl.h>
#include <poll.h>
     int main()
     {
       struct pollfd ufd;
       /* Try /dev/null for reading. */
       ufd.fd = open ("/dev/null", O_RDONLY);
       if (ufd.fd < 0) /* If /dev/null does not exist, it's not MacOS X. */
         return 0;
       ufd.events = POLLIN;
       ufd.revents = 0;
       if (!(poll (&ufd, 1, 0) == 1 && ufd.revents == POLLIN))
         return 1;
       /* Try /dev/null for writing. */
       ufd.fd = open ("/dev/null", O_WRONLY);
       if (ufd.fd < 0) /* If /dev/null does not exist, it's not MacOS X. */
         return 0;
       ufd.events = POLLOUT;
       ufd.revents = 0;
       if (!(poll (&ufd, 1, 0) == 1 && ufd.revents == POLLOUT))
         return 1;
       /* Trying /dev/tty may be too environment dependent. */
       return 0;
     }],
     [cl_cv_func_poll=yes],
     [cl_cv_func_poll=no],
     [# When cross-compiling, assume that poll() works everywhere except on
      # MacOS X, regardless of its version.
      AC_EGREP_CPP([MacOSX], [
#if defined(__APPLE__) && defined(__MACH__)
This is MacOSX
#endif
], [cl_cv_func_poll=no], [cl_cv_func_poll=yes])])])
if test $cl_cv_func_poll = yes; then
  AC_DEFINE([HAVE_POLL], 1,
    [Define to 1 if you have the 'poll' function and it works.])
# Now check whether poll() works reliably on regular files, i.e. signals
# immediate readability and writability, both before EOF and at EOF.
# On FreeBSD 4.0, it doesn't.
AC_CACHE_CHECK([for reliable poll()], cl_cv_func_poll_reliable, [
AC_TRY_RUN([
/* Declare poll(). */
#include <poll.h>
/* Declare open(). */
#include <fcntl.h>
#ifdef OPEN_NEEDS_SYS_FILE_H
#include <sys/file.h>
#endif
/* Declare lseek(). */
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
int main ()
{ int fd = open("conftest.c",O_RDWR,0644);
  int correct_readability_nonempty, correct_readability_empty;
  int correct_writability_nonempty, correct_writability_empty;
  struct pollfd pollfd_bag[1];
  {
    pollfd_bag[0].fd = fd;
    pollfd_bag[0].events = POLLIN;
    pollfd_bag[0].revents = 0;
    correct_readability_nonempty =
      (poll(&pollfd_bag[0],1,0) >= 0 && pollfd_bag[0].revents != 0);
  }
  {
    pollfd_bag[0].fd = fd;
    pollfd_bag[0].events = POLLOUT;
    pollfd_bag[0].revents = 0;
    correct_writability_nonempty =
      (poll(&pollfd_bag[0],1,0) >= 0 && pollfd_bag[0].revents != 0);
  }
  lseek(fd,0,SEEK_END);
  {
    pollfd_bag[0].fd = fd;
    pollfd_bag[0].events = POLLIN;
    pollfd_bag[0].revents = 0;
    correct_readability_empty =
      (poll(&pollfd_bag[0],1,0) >= 0 && pollfd_bag[0].revents != 0);
  }
  {
    pollfd_bag[0].fd = fd;
    pollfd_bag[0].events = POLLOUT;
    pollfd_bag[0].revents = 0;
    correct_writability_empty =
      (poll(&pollfd_bag[0],1,0) >= 0 && pollfd_bag[0].revents != 0);
  }
  exit(!(correct_readability_nonempty && correct_readability_empty
         && correct_writability_nonempty && correct_writability_empty));
}],
cl_cv_func_poll_reliable=yes, cl_cv_func_poll_reliable=no,
dnl When cross-compiling, don't assume anything.
cl_cv_func_poll_reliable="guessing no")
])
case "$cl_cv_func_poll_reliable" in
  *yes) AC_DEFINE(HAVE_RELIABLE_POLL,,[have poll() and it works reliably on files]) ;;
  *no) ;;
esac
fi
])
