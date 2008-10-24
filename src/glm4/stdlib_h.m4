# stdlib_h.m4 serial 11
dnl Copyright (C) 2007, 2008 Free Software Foundation, Inc.
dnl This file is free software; the Free Software Foundation
dnl gives unlimited permission to copy and/or distribute it,
dnl with or without modifications, as long as this notice is preserved.

AC_DEFUN([gl_STDLIB_H],
[
  AC_REQUIRE([gl_STDLIB_H_DEFAULTS])
  gl_CHECK_NEXT_HEADERS([stdlib.h])
])

AC_DEFUN([gl_STDLIB_MODULE_INDICATOR],
[
  dnl Use AC_REQUIRE here, so that the default settings are expanded once only.
  AC_REQUIRE([gl_STDLIB_H_DEFAULTS])
  GNULIB_[]m4_translit([$1],[abcdefghijklmnopqrstuvwxyz./-],[ABCDEFGHIJKLMNOPQRSTUVWXYZ___])=1
])

AC_DEFUN([gl_STDLIB_H_DEFAULTS],
[
  GNULIB_MALLOC_POSIX=0;  AC_SUBST([GNULIB_MALLOC_POSIX])
  GNULIB_REALLOC_POSIX=0; AC_SUBST([GNULIB_REALLOC_POSIX])
  GNULIB_CALLOC_POSIX=0;  AC_SUBST([GNULIB_CALLOC_POSIX])
  GNULIB_ATOLL=0;         AC_SUBST([GNULIB_ATOLL])
  GNULIB_GETLOADAVG=0;    AC_SUBST([GNULIB_GETLOADAVG])
  GNULIB_GETSUBOPT=0;     AC_SUBST([GNULIB_GETSUBOPT])
  GNULIB_MKDTEMP=0;       AC_SUBST([GNULIB_MKDTEMP])
  GNULIB_MKSTEMP=0;       AC_SUBST([GNULIB_MKSTEMP])
  GNULIB_PUTENV=0;        AC_SUBST([GNULIB_PUTENV])
  GNULIB_RANDOM_R=0;      AC_SUBST([GNULIB_RANDOM_R])
  GNULIB_RPMATCH=0;       AC_SUBST([GNULIB_RPMATCH])
  GNULIB_SETENV=0;        AC_SUBST([GNULIB_SETENV])
  GNULIB_STRTOD=0;        AC_SUBST([GNULIB_STRTOD])
  GNULIB_STRTOLL=0;       AC_SUBST([GNULIB_STRTOLL])
  GNULIB_STRTOULL=0;      AC_SUBST([GNULIB_STRTOULL])
  GNULIB_UNSETENV=0;      AC_SUBST([GNULIB_UNSETENV])
  dnl Assume proper GNU behavior unless another module says otherwise.
  HAVE_ATOLL=1;           AC_SUBST([HAVE_ATOLL])
  HAVE_CALLOC_POSIX=1;    AC_SUBST([HAVE_CALLOC_POSIX])
  HAVE_GETSUBOPT=1;       AC_SUBST([HAVE_GETSUBOPT])
  HAVE_MALLOC_POSIX=1;    AC_SUBST([HAVE_MALLOC_POSIX])
  HAVE_MKDTEMP=1;         AC_SUBST([HAVE_MKDTEMP])
  HAVE_REALLOC_POSIX=1;   AC_SUBST([HAVE_REALLOC_POSIX])
  HAVE_RANDOM_R=1;        AC_SUBST([HAVE_RANDOM_R])
  HAVE_RPMATCH=1;         AC_SUBST([HAVE_RPMATCH])
  HAVE_SETENV=1;          AC_SUBST([HAVE_SETENV])
  HAVE_STRTOD=1;          AC_SUBST([HAVE_STRTOD])
  HAVE_STRTOLL=1;         AC_SUBST([HAVE_STRTOLL])
  HAVE_STRTOULL=1;        AC_SUBST([HAVE_STRTOULL])
  HAVE_SYS_LOADAVG_H=0;   AC_SUBST([HAVE_SYS_LOADAVG_H])
  HAVE_UNSETENV=1;        AC_SUBST([HAVE_UNSETENV])
  HAVE_DECL_GETLOADAVG=1; AC_SUBST([HAVE_DECL_GETLOADAVG])
  REPLACE_MKSTEMP=0;      AC_SUBST([REPLACE_MKSTEMP])
  REPLACE_PUTENV=0;       AC_SUBST([REPLACE_PUTENV])
  REPLACE_STRTOD=0;       AC_SUBST([REPLACE_STRTOD])
  VOID_UNSETENV=0;        AC_SUBST([VOID_UNSETENV])
])
