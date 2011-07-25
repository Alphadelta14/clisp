# close.m4 serial 6
dnl Copyright (C) 2008-2011 Free Software Foundation, Inc.
dnl This file is free software; the Free Software Foundation
dnl gives unlimited permission to copy and/or distribute it,
dnl with or without modifications, as long as this notice is preserved.

AC_DEFUN([gl_FUNC_CLOSE],
[
  m4_ifdef([gl_PREREQ_SYS_H_WINSOCK2], [
    gl_PREREQ_SYS_H_WINSOCK2
    if test $UNISTD_H_HAVE_WINSOCK2_H = 1; then
      dnl Even if the 'socket' module is not used here, another part of the
      dnl application may use it and pass file descriptors that refer to
      dnl sockets to the close() function. So enable the support for sockets.
      gl_REPLACE_CLOSE
    fi
  ])
])

AC_DEFUN([gl_REPLACE_CLOSE],
[
  AC_REQUIRE([gl_UNISTD_H_DEFAULTS])
  REPLACE_CLOSE=1
  AC_LIBOBJ([close])
  m4_ifdef([gl_REPLACE_FCLOSE], [gl_REPLACE_FCLOSE])
])
