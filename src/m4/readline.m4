dnl -*- Autoconf -*-
dnl Copyright (C) 2002 Sam Steingold
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

AC_PREREQ(2.13)

AC_DEFUN([CL_READLINE],[dnl
AC_REQUIRE([CL_TERMCAP])dnl
if test $ac_cv_search_tgetent != no ; then
  AC_LIB_LINKFLAGS_BODY(readline)
  AC_CHECK_HEADERS(readline/readline.h)
  if test $ac_cv_header_readline_readline_h = yes ; then
    AC_SEARCH_LIBS(readline, readline)
    # newer versions of readline prepend "rl_"
    AC_CHECK_FUNCS(rl_filename_completion_function)
    if [ test $ac_cv_func_rl_filename_completion_function = no ];
    then RL_FCF=filename_completion_function;
    else RL_FCF=rl_filename_completion_function; fi
    CL_PROTO([rl_filename_completion_function], [
      CL_PROTO_CONST([
#include <stdio.h>
#include <readline/readline.h>
      ],[char* ${RL_FCF} (char *, int);], [char* ${RL_FCF}();],
      cl_cv_proto_readline_const) ],
      [extern char* ${RL_FCF}($cl_cv_proto_readline_const char*, int);])
    AC_DEFINE_UNQUOTED(READLINE_FILE_COMPLETE,${RL_FCF})
    AC_DEFINE_UNQUOTED(READLINE_CONST,$cl_cv_proto_readline_const)
    AC_MSG_CHECKING([for rl_already_prompted])
    AC_TRY_COMPILE([
#include <stdio.h>
#include <readline/readline.h>
    ],[rl_already_prompted = 1;],
    AC_MSG_RESULT([yes])
    AC_DEFINE(HAVE_READLINE),
    AC_MSG_RESULT([no; readline is too old and will not be used]))
  fi
fi
])
