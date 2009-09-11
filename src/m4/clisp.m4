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
[cl_use_clisp="$withval"], [cl_use_clisp=default])
cl_cv_have_clisp=no
if test "$cl_use_clisp" != "no"; then
  if test "$cl_use_clisp" = default -o "$cl_use_clisp" = yes;
  then AC_PATH_PROG(cl_cv_clisp, clisp)
  else cl_cv_clisp="$cl_use_clisp"
  fi
  if test "X$cl_cv_clisp" != "X"; then
    AC_CACHE_CHECK([for CLISP version], [cl_cv_clisp_version], [dnl
     if `$cl_cv_clisp --version | head -n 1 | grep "GNU CLISP" >/dev/null 2>&1`;
     then CLISP_SET(cl_cv_clisp_version,[(lisp-implementation-version)])
     else cl_cv_clisp_version='not a CLISP'
     fi])
    AC_CACHE_CHECK([for CLISP libdir], [cl_cv_clisp_libdir], [dnl
     CLISP_SET(cl_cv_clisp_libdir,[(namestring *lib-directory*)])
     # cf src/clisp-link.in:linkkitdir
     missing=''
     for f in modules.c clisp.h; do
       test -r "${cl_cv_clisp_libdir}linkkit/$f" || missing=${missing}' '$f
     done
     test -n "${missing}" && cl_cv_clisp_libdir="missing${missing}"])
    AC_CACHE_CHECK([for CLISP linking set], [cl_cv_clisp_linkset], [dnl
     CLISP_SET(cl_cv_clisp_linkset,[(sys::program-name)])
     cl_cv_clisp_linkset=`dirname ${cl_cv_clisp_linkset}`
     missing=''
     # cf. src/clisp-link.in:check_linkset (we do not need to check for
     # lisp.run because cl_cv_clisp_linkset comes from SYS::PROGRAM-NAME)
     for f in lisp.a lispinit.mem modules.h modules.o makevars; do
       test -r "${cl_cv_clisp_linkset}/$f" || missing=${missing}' '$f
     done
     test -n "${missing}" && cl_cv_clisp_linkset="missing${missing}"])
    CLISP=$cl_cv_clisp; AC_SUBST(CLISP)dnl
    CLISP_LINKKIT="${cl_cv_clisp_libdir}linkkit"; AC_SUBST(CLISP_LINKKIT)dnl
    sed 's/^/CLISP_/' ${cl_cv_clisp_linkset}/makevars > conftestvars
    source conftestvars
    rm -f conftestvars
    AC_SUBST(CLISP_FILES)dnl
    AC_SUBST(CLISP_LIBS)dnl
    AC_SUBST(CLISP_CFLAGS)dnl
    AC_SUBST(CLISP_CPPFLAGS)dnl
    AC_CACHE_CHECK([for CLISP], [cl_cv_have_clisp],
     [test -d $cl_cv_clisp_libdir -a -d $cl_cv_clisp_linkset && \
       cl_cv_have_clisp=yes])
  fi
fi])

AC_DEFUN([CL_CLISP_NEED_FFI],[AC_REQUIRE([CL_CLISP])dnl
AC_CACHE_CHECK([for FFI in CLISP], [cl_cv_clisp_ffi],
 [CLISP_SET(cl_cv_clisp_ffi,[[#+ffi "yes" #-ffi "no"]])])
test $cl_cv_clisp_ffi = no && AC_MSG_ERROR([FFI is missing in CLISP])])
