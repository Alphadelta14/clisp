dnl Copyright (C) 1993-2002 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels.

AC_PREREQ(2.13)

AC_DEFUN([CL_OPENDIR],
[AC_REQUIRE([CL_DIR_HEADER])dnl
AC_BEFORE([$0], [CL_CLOSEDIR])dnl
AC_BEFORE([$0], [CL_FILECHARSET])dnl
CL_PROTO([opendir], [
CL_PROTO_CONST([
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <$ac_header_dirent>
], [DIR* opendir (char* dirname);], [DIR* opendir();], cl_cv_proto_opendir_arg1)
], [extern DIR* opendir ($cl_cv_proto_opendir_arg1 char*);])
AC_DEFINE_UNQUOTED(OPENDIR_CONST,$cl_cv_proto_opendir_arg1)
])
