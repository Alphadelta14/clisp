dnl Copyright (C) 1993-2002 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ(2.13)

dnl without AC_MSG_...:   with AC_MSG_... and caching:
dnl   AC_TRY_CPP          CL_CPP_CHECK
dnl   AC_TRY_COMPILE      CL_COMPILE_CHECK
dnl   AC_TRY_LINK         CL_LINK_CHECK
dnl   AC_TRY_RUN          CL_RUN_CHECK - would require cross-compiling support
dnl Usage:
dnl AC_TRY_CPP(INCLUDES,
dnl            ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND])
dnl CL_CPP_CHECK(ECHO-TEXT, CACHE-ID,
dnl              INCLUDES,
dnl              ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND])
dnl AC_TRY_xxx(INCLUDES, FUNCTION-BODY,
dnl            ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND])
dnl CL_xxx_CHECK(ECHO-TEXT, CACHE-ID,
dnl              INCLUDES, FUNCTION-BODY,
dnl              ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND])

AC_DEFUN([CL_CPP_CHECK],
[AC_MSG_CHECKING(for $1)
AC_CACHE_VAL($2,[
AC_TRY_CPP([$3], $2=yes, $2=no)
])
AC_MSG_RESULT([$]$2)
if test [$]$2 = yes; then
  ifelse([$4], , :, [$4])
ifelse([$5], , , [else
  $5
])dnl
fi
])

AC_DEFUN([CL_COMPILE_CHECK],
[AC_MSG_CHECKING(for $1)
AC_CACHE_VAL($2,[
AC_TRY_COMPILE([$3],[$4], $2=yes, $2=no)
])
AC_MSG_RESULT([$]$2)
if test [$]$2 = yes; then
  ifelse([$5], , :, [$5])
ifelse([$6], , , [else
  $6
])dnl
fi
])

AC_DEFUN([CL_LINK_CHECK],
[AC_MSG_CHECKING(for $1)
AC_CACHE_VAL($2,[
AC_TRY_LINK([$3],[$4], $2=yes, $2=no)
])
AC_MSG_RESULT([$]$2)
if test [$]$2 = yes; then
  ifelse([$5], , :, [$5])
ifelse([$6], , , [else
  $6
])dnl
fi
])

dnl CL_SILENT(ACTION)
dnl performs ACTION, with AC_MSG_CHECKING and AC_MSG_RESULT being defined away.
AC_DEFUN([CL_SILENT],
[pushdef([AC_MSG_CHECKING],[:])dnl
pushdef([AC_CHECKING],[:])dnl
pushdef([AC_MSG_RESULT],[:])dnl
$1[]dnl
popdef([AC_MSG_RESULT])dnl
popdef([AC_CHECKING])dnl
popdef([AC_MSG_CHECKING])dnl
])

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
AC_LANG_SAVE()
AC_LANG_C()
AC_TRY_RUN([int main() { exit(0); }],
cl_cv_prog_cc_works=yes, cl_cv_prog_cc_works=no,
AC_TRY_LINK([], [], cl_cv_prog_cc_works=yes, cl_cv_prog_cc_works=no))
AC_LANG_RESTORE()
])
case "$cl_cv_prog_cc_works" in
  *no) echo "Installation or configuration problem: C compiler cannot create executables."; exit 1;;
  *yes) ;;
esac
])

AC_DEFUN([CL_CONFIG_SUBDIRS],
[dnl No AC_CONFIG_AUX_DIR_DEFAULT, so we don't need install.sh.
AC_PROVIDE([AC_CONFIG_AUX_DIR_DEFAULT])
AC_CONFIG_SUBDIRS([$1])dnl
])

AC_DEFUN([CL_CANONICAL_HOST],
[AC_REQUIRE([AC_PROG_CC]) dnl Actually: AC_REQUIRE([CL_CC_WORKS])
dnl Set ac_aux_dir before the cache check, because AM_PROG_LIBTOOL needs it.
ac_aux_dir=${srcdir}/$1
dnl A substitute for AC_CONFIG_AUX_DIR_DEFAULT, so we don't need install.sh.
ac_config_guess="$SHELL $ac_aux_dir/config.guess"
ac_config_sub="$SHELL $ac_aux_dir/config.sub"
dnl We have defined $ac_aux_dir.
AC_PROVIDE([AC_CONFIG_AUX_DIR_DEFAULT])dnl
dnl In autoconf-2.52, a single AC_CANONICAL_HOST has the effect of inserting
dnl the code of AC_CANONICAL_BUILD *before* CL_CANONICAL_HOST, i.e. before
dnl ac_aux_dir has been set. To work around this, we list AC_CANONICAL_BUILD
dnl explicitly.
AC_CANONICAL_BUILD
AC_CANONICAL_HOST
])

AC_DEFUN([CL_CANONICAL_HOST_CPU],
[AC_REQUIRE([CL_CANONICAL_HOST])AC_REQUIRE([AC_PROG_CC])
case "$host_cpu" in
changequote(,)dnl
  i[4567]86 )
    host_cpu=i386
    ;;
  alphaev[4-7] | alphaev56 | alphapca5[67] | alphaev6[78] )
    host_cpu=alpha
    ;;
  hppa1.0 | hppa1.1 | hppa2.0* | hppa64 )
    host_cpu=hppa
    ;;
  powerpc )
    host_cpu=rs6000
    ;;
  c1 | c2 | c32 | c34 | c38 | c4 )
    host_cpu=convex
    ;;
  arm* )
    host_cpu=arm
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
  host_cpu=mips64
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
  host_cpu=sparc64
else
  host_cpu=sparc
fi
    ;;
esac
dnl was AC_DEFINE_UNQUOTED(__${host_cpu}__) but KAI C++ 3.2d doesn't like this
cat >> confdefs.h <<EOF
#ifndef __${host_cpu}__
#define __${host_cpu}__ 1
#endif
EOF
])

AC_DEFUN([CL_CANONICAL_HOST_CPU_FOR_FFCALL],
[AC_REQUIRE([CL_CANONICAL_HOST])AC_REQUIRE([AC_PROG_CC])
case "$host_cpu" in
changequote(,)dnl
  i[4567]86 )
    host_cpu=i386
    ;;
  alphaev[4-7] | alphaev56 | alphapca5[67] | alphaev6[78] )
    host_cpu=alpha
    ;;
  hppa1.0 | hppa1.1 | hppa2.0* | hppa64 )
    host_cpu=hppa
    ;;
  powerpc )
    host_cpu=rs6000
    ;;
  c1 | c2 | c32 | c34 | c38 | c4 )
    host_cpu=convex
    ;;
  arm* )
    host_cpu=arm
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
  host_cpu=mips64
else
  AC_CACHE_CHECK([for MIPS with n32 ABI], cl_cv_host_mipsn32, [
dnl Strictly speaking, the MIPS ABI (-32 or -n32) is independent from the CPU
dnl identification (-mips[12] or -mips[34]). But -n32 is commonly used together
dnl with -mips3, and it's easier to test the CPU identification.
AC_EGREP_CPP(yes,
[#if __mips >= 3
  yes
#endif
], cl_cv_host_mipsn32=yes, cl_cv_host_mipsn32=no)
])
if test $cl_cv_host_mipsn32 = yes; then
  host_cpu=mipsn32
fi
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
  host_cpu=sparc64
else
  host_cpu=sparc
fi
    ;;
esac
dnl was AC_DEFINE_UNQUOTED(__${host_cpu}__) but KAI C++ 3.2d doesn't like this
cat >> confdefs.h <<EOF
#ifndef __${host_cpu}__
#define __${host_cpu}__ 1
#endif
EOF
])
