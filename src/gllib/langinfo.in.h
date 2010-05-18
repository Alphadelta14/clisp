/* Substitute for and wrapper around <langinfo.h>.
   Copyright (C) 2009, 2010 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software Foundation,
   Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.  */

/*
 * POSIX <langinfo.h> for platforms that lack it or have an incomplete one.
 * <http://www.opengroup.org/onlinepubs/9699919799/basedefs/langinfo.h.html>
 */

#ifndef _gl_GL_LANGINFO_H

#if __GNUC__ >= 3
@PRAGMA_SYSTEM_HEADER@
#endif

/* The include_next requires a split double-inclusion guard.  */
#if @HAVE_LANGINFO_H@
# @INCLUDE_NEXT@ @NEXT_LANGINFO_H@
#endif

#ifndef _gl_GL_LANGINFO_H
#define _gl_GL_LANGINFO_H


#if !@HAVE_LANGINFO_H@

/* A platform that lacks <langinfo.h>.  */

/* Assume that it also lacks <nl_types.h> and the nl_item type.  */
typedef int nl_item;

/* nl_langinfo items of the LC_CTYPE category */
# define CODESET     10000
/* nl_langinfo items of the LC_NUMERIC category */
# define RADIXCHAR   10001
# define THOUSEP     10002
/* nl_langinfo items of the LC_TIME category */
# define D_T_FMT     10003
# define D_FMT       10004
# define T_FMT       10005
# define T_FMT_AMPM  10006
# define AM_STR      10007
# define PM_STR      10008
# define DAY_1       10009
# define DAY_2       (DAY_1 + 1)
# define DAY_3       (DAY_1 + 2)
# define DAY_4       (DAY_1 + 3)
# define DAY_5       (DAY_1 + 4)
# define DAY_6       (DAY_1 + 5)
# define DAY_7       (DAY_1 + 6)
# define ABDAY_1     10016
# define ABDAY_2     (ABDAY_1 + 1)
# define ABDAY_3     (ABDAY_1 + 2)
# define ABDAY_4     (ABDAY_1 + 3)
# define ABDAY_5     (ABDAY_1 + 4)
# define ABDAY_6     (ABDAY_1 + 5)
# define ABDAY_7     (ABDAY_1 + 6)
# define MON_1       10023
# define MON_2       (MON_1 + 1)
# define MON_3       (MON_1 + 2)
# define MON_4       (MON_1 + 3)
# define MON_5       (MON_1 + 4)
# define MON_6       (MON_1 + 5)
# define MON_7       (MON_1 + 6)
# define MON_8       (MON_1 + 7)
# define MON_9       (MON_1 + 8)
# define MON_10      (MON_1 + 9)
# define MON_11      (MON_1 + 10)
# define MON_12      (MON_1 + 11)
# define ABMON_1     10035
# define ABMON_2     (ABMON_1 + 1)
# define ABMON_3     (ABMON_1 + 2)
# define ABMON_4     (ABMON_1 + 3)
# define ABMON_5     (ABMON_1 + 4)
# define ABMON_6     (ABMON_1 + 5)
# define ABMON_7     (ABMON_1 + 6)
# define ABMON_8     (ABMON_1 + 7)
# define ABMON_9     (ABMON_1 + 8)
# define ABMON_10    (ABMON_1 + 9)
# define ABMON_11    (ABMON_1 + 10)
# define ABMON_12    (ABMON_1 + 11)
# define ERA         10047
# define ERA_D_FMT   10048
# define ERA_D_T_FMT 10049
# define ERA_T_FMT   10050
# define ALT_DIGITS  10051
/* nl_langinfo items of the LC_MONETARY category */
# define CRNCYSTR    10052
/* nl_langinfo items of the LC_MESSAGES category */
# define YESEXPR     10053
# define NOEXPR      10054

#else

/* A platform that has <langinfo.h>.  */

# if !@HAVE_LANGINFO_CODESET@
#  define CODESET     10000
#  define GNULIB_defined_CODESET 1
# endif

# if !@HAVE_LANGINFO_ERA@
#  define ERA         10047
#  define ERA_D_FMT   10048
#  define ERA_D_T_FMT 10049
#  define ERA_T_FMT   10050
#  define ALT_DIGITS  10051
#  define GNULIB_defined_ERA 1
# endif

#endif

/* The definitions of _gl_GL_FUNCDECL_RPL etc. are copied here.  */

/* The definition of _gl_GL_WARN_ON_USE is copied here.  */

/* Declare overridden functions.  */


/* Return a piece of locale dependent information.
   Note: The difference between nl_langinfo (CODESET) and locale_charset ()
   is that the latter normalizes the encoding names to GNU conventions.  */

#if @GNULIB_NL_LANGINFO@
# if @REPLACE_NL_LANGINFO@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef nl_langinfo
#   define nl_langinfo rpl_nl_langinfo
#  endif
_gl_GL_FUNCDECL_RPL (nl_langinfo, char *, (nl_item item));
_gl_GL_CXXALIAS_RPL (nl_langinfo, char *, (nl_item item));
# else
#  if !@HAVE_NL_LANGINFO@
_gl_GL_FUNCDECL_SYS (nl_langinfo, char *, (nl_item item));
#  endif
_gl_GL_CXXALIAS_SYS (nl_langinfo, char *, (nl_item item));
# endif
_gl_GL_CXXALIASWARN (nl_langinfo);
#elif defined GNULIB_POSIXCHECK
# undef nl_langinfo
# if HAVE_RAW_DECL_NL_LANGINFO
_gl_GL_WARN_ON_USE (nl_langinfo, "nl_langinfo is not portable - "
                 "use gnulib module nl_langinfo for portability");
# endif
#endif


#endif /* _gl_GL_LANGINFO_H */
#endif /* _gl_GL_LANGINFO_H */
