/* config.h.in.  Generated automatically from configure.in by autoheader.  */
/* Special definitions, processed by autoheader.
   Copyright (C) 1995, 1996, 1997 Free Software Foundation.
   Ulrich Drepper <drepper@gnu.ai.mit.edu>, 1995.  */

/* Default value for alignment of strings in .mo file.  */
#define DEFAULT_OUTPUT_ALIGNMENT 1

#ifndef PARAMS
# if __STDC__
#  define PARAMS(args) args
# else
#  define PARAMS(args) ()
# endif
#endif


/* Define if using alloca.c.  */
#undef C_ALLOCA

/* Define to empty if the keyword does not work.  */
#undef const

/* Define to one of _getb67, GETB67, getb67 for Cray-2 and Cray-YMP systems.
   This function is required for alloca.c support on those systems.  */
#undef CRAY_STACKSEG_END

/* Define if you have alloca, as a function or macro.  */
#define HAVE_ALLOCA

/* Define if you have <alloca.h> and it should be used (not on Ultrix).  */
#define HAVE_ALLOCA_H

/* Define if you have a working `mmap' system call.  */
#undef HAVE_MMAP

/* Define as __inline if that's what the C compiler calls it.  */
#undef inline

/* Define to `long' if <sys/types.h> doesn't define.  */
#ifndef off_t
#undef off_t
#endif

/* Define if you need to in order for stat and other things to work.  */
#ifndef _POSIX_SOURCE
#undef _POSIX_SOURCE
#endif

/* Define to `unsigned' if <sys/types.h> doesn't define.  */
#ifndef size_t
#undef size_t
#endif

/* If using the C implementation of alloca, define if you know the
   direction of stack growth for your system; otherwise it will be
   automatically deduced at run-time.
 STACK_DIRECTION > 0 => grows toward higher addresses
 STACK_DIRECTION < 0 => grows toward lower addresses
 STACK_DIRECTION = 0 => direction of growth unknown
 */
#define STACK_DIRECTION -1

/* Define if you have the ANSI C header files.  */
#define STDC_HEADERS

/* Define to the name of the distribution.  */
#define PACKAGE clisp

/* Define to the version of the distribution.  */
#define VERSION 1997-12-06

/* Define if your locale.h file contains LC_MESSAGES.  */
#undef HAVE_LC_MESSAGES

/* Define to 1 if NLS is requested.  */
#define ENABLE_NLS

/* Define as 1 if you have catgets and don't want to use GNU gettext.  */
#undef HAVE_CATGETS

/* Define as 1 if you have gettext and don't want to use GNU gettext.  */
#undef HAVE_GETTEXT

/* Define as 1 if you have the stpcpy function.  */
#undef HAVE_STPCPY

/* Define if you have the __argz_count function.  */
#undef HAVE___ARGZ_COUNT

/* Define if you have the __argz_next function.  */
#undef HAVE___ARGZ_NEXT

/* Define if you have the __argz_stringify function.  */
#undef HAVE___ARGZ_STRINGIFY

/* Define if you have the dcgettext function.  */
#undef HAVE_DCGETTEXT

/* Define if you have the getcwd function.  */
#define HAVE_GETCWD

/* Define if you have the getpagesize function.  */
#define HAVE_GETPAGESIZE

/* Define if you have the munmap function.  */
#undef HAVE_MUNMAP

/* Define if you have the putenv function.  */
#define HAVE_PUTENV

/* Define if you have the setenv function.  */
#undef HAVE_SETENV

/* Define if you have the setlocale function.  */
#define HAVE_SETLOCALE

/* Define if you have the stpcpy function.  */
#undef HAVE_STPCPY

/* Define if you have the strcasecmp function.  */
#undef HAVE_STRCASECMP

/* Define if you have the strchr function.  */
#define HAVE_STRCHR

/* Define if you have the strdup function.  */
#define HAVE_STRDUP

/* Define if you have the <argz.h> header file.  */
#undef HAVE_ARGZ_H

/* Define if you have the <limits.h> header file.  */
#define HAVE_LIMITS_H

/* Define if you have the <locale.h> header file.  */
#define HAVE_LOCALE_H

/* Define if you have the <malloc.h> header file.  */
#define HAVE_MALLOC_H

/* Define if you have the <nl_types.h> header file.  */
#undef HAVE_NL_TYPES_H

/* Define if you have the <string.h> header file.  */
#define HAVE_STRING_H

/* Define if you have the <sys/param.h> header file.  */
#define HAVE_SYS_PARAM_H

/* Define if you have the <unistd.h> header file.  */
#define HAVE_UNISTD_H

/* Define if you have the <values.h> header file.  */
#undef HAVE_VALUES_H

/* Define if you have the i library (-li).  */
#undef HAVE_LIBI

/* A file name cannot consist of any character possible.  INVALID_PATH_CHAR
   contains the characters not allowed.  */
#define	INVALID_PATH_CHAR "\1\2\3\4\5\6\7\10\11\12\13\14\15\16\17\20\21\22\23\24\25\26\27\30\31\32\33\34\35\36\37 \177\\:."

/* Length from which starting on warnings about too long strings are given.
   Several systems have limits for strings itself, more have problems with
   strings in their tools (important here: gencat).  1024 bytes is a
   conservative limit.  Because many translation let the message size grow
   (German translations are always bigger) choose a length < 1024.  */
#define WARN_ID_LEN 900

/* This is the page width for the message_print function.  It should
   not be set to more than 79 characters (Emacs users will appreciate
   it).  It is used to wrap the msgid and msgstr strings, and also to
   wrap the file position (#:) comments.  */
#define PAGE_WIDTH 79

