dnl Copyright (C) 1993-2002 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels.

AC_PREREQ(2.13)

AC_DEFUN([CL_IREG_FLOAT_RETURN],
[AC_CACHE_CHECK([whether floats are returned in integer registers], cl_cv_c_float_return_ireg, [
AC_TRY_RUN([float x = (float)1.2;
float y = (float)1.3;
float fun () { return x*y; }
int main()
{ int val = (* (int (*) ()) fun) ();
  exit (!(val == 0x3FC7AE15 || val == 0x15AEC73F));
}], cl_cv_c_float_return_ireg=yes, rm -f core
cl_cv_c_float_return_ireg=no,
dnl When cross-compiling, assume no, because that's how it comes out on
dnl most platforms with floating-point unit, including m68k-linux.
cl_cv_c_float_return_ireg="guessing no")
])
case "$cl_cv_c_float_return_ireg" in
  *yes) AC_DEFINE(__IREG_FLOAT_RETURN__) ;;
  *no) ;;
esac
])
