dnl Copyright (C) 2002 Sam Steingold
dnl -*- Autoconf -*-
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Sam Steingold.

AC_PREREQ(2.57)

AC_DEFUN([CL_LDAP],
[AC_CHECK_HEADERS(lber.h ldap.h,,,
dnl Solaris/cc requires <lber.h> to be included before <ldap.h>
[#if HAVE_LBER_H
# include <lber.h>
#endif
])]
)
