dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2008 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ(2.57)

AC_DEFUN([CL_BUILTIN_STRLEN],
[AC_CACHE_CHECK(for inline __builtin_strlen, cl_cv_builtin_strlen, [
cat > conftest.$ac_ext <<EOF
int foo (char* x)
{ return __builtin_strlen(x); }
EOF
if AC_TRY_COMMAND(${CC-cc} -S $CFLAGS $CPPFLAGS conftest.$ac_ext) >/dev/null 2>&1 ; then
  if grep strlen conftest.s >/dev/null ; then
    cl_cv_builtin_strlen=no
  else
    cl_cv_builtin_strlen=yes
  fi
else
  cl_cv_builtin_strlen=no
fi
rm -f conftest*
])
if test $cl_cv_builtin_strlen = yes; then
  AC_DEFINE(HAVE_BUILTIN_STRLEN,,[__builtin_strlen() is compiled inline (not a call to strlen())])
fi
])
