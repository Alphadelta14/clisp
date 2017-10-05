dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2003, 2017 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ([2.57])

AC_DEFUN([CL_AS_UNDERSCORE],
[
  AC_BEFORE([$0], [CL_GLOBAL_CONSTRUCTORS])
  m4_pattern_allow([^AS_UNDERSCORE$])
  AC_CACHE_CHECK([for underscore in external names], [cl_cv_prog_as_underscore],
    [cat > conftest.c <<EOF
#ifdef __cplusplus
extern "C"
#endif
int foo (void) { return 0; }
EOF
     # look for the assembly language name in the .s file
     AC_TRY_COMMAND([${CC-cc} -S conftest.c]) >/dev/null 2>&1
     if grep _foo conftest.s >/dev/null; then
       cl_cv_prog_as_underscore=yes
     else
       cl_cv_prog_as_underscore=no
     fi
     rm -f conftest*
    ])
  if test $cl_cv_prog_as_underscore = yes; then
    AS_UNDERSCORE=true
    AC_DEFINE([ASM_UNDERSCORE],,
      [symbols are prefixed by an underscore in assembly language])
  else
    AS_UNDERSCORE=false
  fi
  AC_SUBST([AS_UNDERSCORE])
])
