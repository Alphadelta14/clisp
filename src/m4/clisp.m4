dnl -*- Autoconf -*-
dnl Copyright (C) 2008-2009 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Sam Steingold.

AC_PREREQ(2.13)

dnl set variable $1 to the result of evaluating in clisp of $2
AC_DEFUN([CLISP_SET],[$1=`$cl_cv_clisp -q -norc -x '$2' 2>/dev/null | sed -e 's/^"//' -e 's/"$//'`])

dnl check for a clisp installation
dnl use --with-clisp=path if your clisp is not in the PATH
dnl if you want to link with the full linking set,
dnl use --with-clisp='clisp -K full'
AC_DEFUN([CL_CLISP],[dnl
AC_ARG_WITH([clisp],
AC_HELP_STRING([--with-clisp],[use a specific CLISP installation]),
[cl_cv_use_clisp="$withval"], [cl_cv_use_clisp=default])
if test "$cl_cv_use_clisp" != "no"; then
  if test "$cl_cv_use_clisp" = default -o "$cl_cv_use_clisp" = yes;
  then AC_PATH_PROG(cl_cv_clisp, clisp)
  else cl_cv_clisp="$cl_cv_use_clisp"
  fi
  if test "X$cl_cv_clisp" != "X"; then
    AC_CACHE_CHECK([for CLISP version], [cl_cv_clisp_version], [
     if `$cl_cv_clisp --version | head -n 1 | grep "GNU CLISP" >/dev/null 2>&1`;
     then CLISP_SET(cl_cv_clisp_version,[(lisp-implementation-version)])
     else cl_cv_clisp_version='not a CLISP'
     fi])
    AC_CACHE_CHECK([for CLISP libdir], [cl_cv_clisp_libdir], [
     CLISP_SET(cl_cv_clisp_libdir,[(namestring *lib-directory*)])
     if test ! -r "${cl_cv_clisp_libdir}linkkit/clisp.h"; then
       cl_cv_clisp_libdir="missing ${cl_cv_clisp_libdir}linkkit/clisp.h"
     fi])
    AC_CACHE_CHECK([for CLISP modset], [cl_cv_clisp_modset], [
     CLISP_SET(cl_cv_clisp_modset,[(sys::program-name)])
     cl_cv_clisp_modset=`dirname ${cl_cv_clisp_modset}`
     missing=''
     # cf. check_linkset in clisp-link
     for f in lisp.a lispinit.mem modules.h modules.o makevars; do
       test -r "${cl_cv_clisp_modset}/$f" || missing=${missing}' '$f
     done
     if test -n "${missing}"; then
       cl_cv_clisp_modset="missing${missing}"
     fi])
    AC_CACHE_CHECK([for FFI in CLISP], [cl_cv_clisp_ffi], [
     CLISP_SET(cl_cv_clisp_ffi,[[#+ffi "yes" #-ffi "no"]])])
    CLISP=$cl_cv_clisp; AC_SUBST(CLISP)dnl
    CLISP_INCLUDE="-I${clisp_libdir}linkkit"; AC_SUBST(CLISP_INCLUDE)dnl
    sed 's/^/CLISP_/' ${cl_cv_clisp_modset}/makevars > conftestvars
    source conftestvars
    rm -f conftestvars
    AC_SUBST(CLISP_FILES)dnl
    AC_SUBST(CLISP_LIBS)dnl
    AC_SUBST(CLISP_CFLAGS)dnl
    AC_SUBST(CLISP_CPPFLAGS)dnl
    AC_CACHE_CHECK([for CLISP], [cl_cv_have_clisp], [
     if test -d $cl_cv_clisp_libdir -a -d $cl_cv_clisp_modset; then
       cl_cv_have_clisp=yes
     else cl_cv_have_clisp=no
     fi])
  fi
fi])

AC_DEFUN([CL_CLISP_NEED_FFI],
[test $cl_cv_clisp_ffi = no && AC_MSG_ERROR([FFI is missing])])
