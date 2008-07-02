dnl Copyright (C) 1993-2008 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ(2.61)

dnl without AC_MSG_...:   with AC_MSG_... and caching:
dnl   AC_COMPILE_IFELSE      CL_COMPILE_CHECK
dnl   AC_LINK_IFELSE         CL_LINK_CHECK
dnl Usage:
dnl AC_xxx_IFELSE(PROGRAM, ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND])
dnl CL_xxx_CHECK(ECHO-TEXT, CACHE-ID, PROGRAM,
dnl              ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND])

dnl 3 next macros avoid aclocal warnings about wrong macro order
AC_DEFUN([CL_MODULE_COMMON_CHECKS],
[AC_REQUIRE([AC_PROG_CC])dnl
AC_REQUIRE([AC_PROG_CPP])dnl
AC_REQUIRE([AC_GNU_SOURCE])dnl
AC_REQUIRE([AC_USE_SYSTEM_EXTENSIONS])dnl
AC_CHECK_HEADERS(time.h sys/time.h)
])

AC_DEFUN([CL_CHECK],[dnl
  AC_CACHE_CHECK([for $2],[$3],
    [$1([AC_LANG_PROGRAM([$4],[$5])],[$3=yes],[$3=no])])
  AS_IF([test $$3 = yes], [$6], [$7])
])

AC_DEFUN([CL_COMPILE_CHECK], [CL_CHECK([AC_COMPILE_IFELSE],$@)])
AC_DEFUN([CL_LINK_CHECK], [CL_CHECK([AC_LINK_IFELSE],$@)])

dnl Expands to the "extern ..." prefix used for system declarations.
dnl AC_LANG_EXTERN()
AC_DEFUN([AC_LANG_EXTERN],
[extern
#ifdef __cplusplus
"C"
#endif
])

AC_DEFUN([CL_CC_WORKS],
[AC_CACHE_CHECK(whether CC works at all, cl_cv_prog_cc_works, [
AC_LANG_PUSH(C)
AC_RUN_IFELSE(AC_LANG_PROGRAM([],[]),
[cl_cv_prog_cc_works=yes], [cl_cv_prog_cc_works=no],
AC_LINK_IFELSE(AC_LANG_PROGRAM([],[]),
[cl_cv_prog_cc_works=yes], [cl_cv_prog_cc_works=no]))
AC_LANG_POP(C)
])
if test "$cl_cv_prog_cc_works" = no; then
AC_MSG_FAILURE([Installation or configuration problem: C compiler cannot create executables.])
fi
])

AC_DEFUN([CL_CONFIG_SUBDIRS],
[dnl No AC_CONFIG_AUX_DIR_DEFAULT, so we don't need install.sh.
AC_PROVIDE([AC_CONFIG_AUX_DIR_DEFAULT])
AC_CONFIG_SUBDIRS([$1])dnl
])

AC_DEFUN([CL_CANONICAL_HOST_CPU],
[AC_REQUIRE([AC_CANONICAL_HOST])AC_REQUIRE([AC_PROG_CC])
case "$host_cpu" in
changequote(,)dnl
  i[4567]86 )
    host_cpu_instructionset=i386
    ;;
  alphaev[4-8] | alphaev56 | alphapca5[67] | alphaev6[78] )
    host_cpu_instructionset=alpha
    ;;
  hppa1.0 | hppa1.1 | hppa2.0* | hppa64 )
    host_cpu_instructionset=hppa
    ;;
  rs6000 )
    host_cpu_instructionset=powerpc
    ;;
  c1 | c2 | c32 | c34 | c38 | c4 )
    host_cpu_instructionset=convex
    ;;
  arm* )
    host_cpu_instructionset=arm
    ;;
changequote([,])dnl
  mips )
    AC_CACHE_CHECK([for 64-bit MIPS], cl_cv_host_mips64, [
AC_EGREP_CPP(yes,
[#if defined(_MIPS_SZLONG)
#if (_MIPS_SZLONG == 64)
/* We should also check for (_MIPS_SZPTR == 64), but gcc keeps this at 32. */
  yes
#endif
#endif
], cl_cv_host_mips64=yes, cl_cv_host_mips64=no)
])
if test $cl_cv_host_mips64 = yes; then
  host_cpu_instructionset=mips64
fi
    ;;
dnl On powerpc64 systems, the C compiler may still be generating 32-bit code.
  powerpc64 )
    AC_CACHE_CHECK([for 64-bit PowerPC], cl_cv_host_powerpc64, [
AC_EGREP_CPP(yes,
[#if defined(__powerpc64__) || defined(_ARCH_PPC64)
  yes
#endif
], cl_cv_host_powerpc64=yes, cl_cv_host_powerpc64=no)
])
if test $cl_cv_host_powerpc64 = yes; then
  host_cpu_instructionset=powerpc64
else
  host_cpu_instructionset=powerpc
fi
    ;;
dnl UltraSPARCs running Linux have `uname -m` = "sparc64", but the C compiler
dnl still generates 32-bit code.
  sparc | sparc64 )
    AC_CACHE_CHECK([for 64-bit SPARC], cl_cv_host_sparc64, [
AC_EGREP_CPP(yes,
[#if defined(__sparcv9) || defined(__arch64__)
  yes
#endif
], cl_cv_host_sparc64=yes, cl_cv_host_sparc64=no)
])
if test $cl_cv_host_sparc64 = yes; then
  host_cpu_instructionset=sparc64
else
  host_cpu_instructionset=sparc
fi
    ;;
dnl On x86_64 systems, the C compiler may still be generating 32-bit code.
  x86_64 )
    AC_CACHE_CHECK([for 64-bit x86_64], cl_cv_host_x86_64, [
AC_EGREP_CPP(yes,
[#if defined(__LP64__) || defined(__x86_64__) || defined(__amd64__)
  yes
#endif
], cl_cv_host_x86_64=yes, cl_cv_host_x86_64=no)
])
if test $cl_cv_host_x86_64 = yes; then
  host_cpu_instructionset=x86_64
else
  host_cpu_instructionset=i386
fi
    ;;
  *)
    host_cpu_instructionset=$host_cpu
    ;;
esac
dnl was AC_DEFINE_UNQUOTED(__${host_cpu}__) but KAI C++ 3.2d doesn't like this
cat >> confdefs.h <<EOF
#ifndef __${host_cpu_instructionset}__
#define __${host_cpu_instructionset}__ 1
#endif
EOF
])
