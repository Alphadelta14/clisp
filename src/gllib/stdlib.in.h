/* A GNU-like <stdlib.h>.

   Copyright (C) 1995, 2001-2004, 2006-2011 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

#if __GNUC__ >= 3
@PRAGMA_SYSTEM_HEADER@
#endif
@PRAGMA_COLUMNS@

#if defined __need_malloc_and_calloc
/* Special invocation convention inside glibc header files.  */

#@INCLUDE_NEXT@ @NEXT_STDLIB_H@

#else
/* Normal invocation convention.  */

#ifndef _gl_GL_STDLIB_H

/* The include_next requires a split double-inclusion guard.  */
#@INCLUDE_NEXT@ @NEXT_STDLIB_H@

#ifndef _gl_GL_STDLIB_H
#define _gl_GL_STDLIB_H

/* NetBSD 5.0 mis-defines NULL.  */
#include <stddef.h>

/* MirBSD 10 defines WEXITSTATUS in <sys/wait.h>, not in <stdlib.h>.  */
#if @GNULIB_SYSTEM_POSIX@ && !defined WEXITSTATUS
# include <sys/wait.h>
#endif

/* Solaris declares getloadavg() in <sys/loadavg.h>.  */
#if (@GNULIB_GETLOADAVG@ || defined GNULIB_POSIXCHECK) && @HAVE_SYS_LOADAVG_H@
# include <sys/loadavg.h>
#endif

#if @GNULIB_RANDOM_R@

/* OSF/1 5.1 declares 'struct random_data' in <random.h>, which is included
   from <stdlib.h> if _REENTRANT is defined.  Include it whenever we need
   'struct random_data'.  */
# if @HAVE_RANDOM_H@
#  include <random.h>
# endif

# if !@HAVE_STRUCT_RANDOM_DATA@ || !@HAVE_RANDOM_R@
#  include <stdint.h>
# endif

# if !@HAVE_STRUCT_RANDOM_DATA@
/* Define 'struct random_data'.
   But allow multiple gnulib generated <stdlib.h> replacements to coexist.  */
#  if !GNULIB_defined_struct_random_data
struct random_data
{
  int32_t *fptr;                /* Front pointer.  */
  int32_t *rptr;                /* Rear pointer.  */
  int32_t *state;               /* Array of state values.  */
  int rand_type;                /* Type of random number generator.  */
  int rand_deg;                 /* Degree of random number generator.  */
  int rand_sep;                 /* Distance between front and rear.  */
  int32_t *end_ptr;             /* Pointer behind state table.  */
};
#   define GNULIB_defined_struct_random_data 1
#  endif
# endif
#endif

#if (@GNULIB_MKSTEMP@ || @GNULIB_MKSTEMPS@ || @GNULIB_GETSUBOPT@ || defined GNULIB_POSIXCHECK) && ! defined __GLIBC__ && !((defined _WIN32 || defined __WIN32__) && ! defined __CYGWIN__)
/* On MacOS X 10.3, only <unistd.h> declares mkstemp.  */
/* On MacOS X 10.5, only <unistd.h> declares mkstemps.  */
/* On Cygwin 1.7.1, only <unistd.h> declares getsubopt.  */
/* But avoid namespace pollution on glibc systems and native Windows.  */
# include <unistd.h>
#endif

#if 3 <= __GNUC__ || __GNUC__ == 2 && 8 <= __GNUC_MINOR__
# define _gl_GL_ATTRIBUTE_NORETURN __attribute__ ((__noreturn__))
#else
# define _gl_GL_ATTRIBUTE_NORETURN
#endif

/* The definitions of _gl_GL_FUNCDECL_RPL etc. are copied here.  */

/* The definition of _gl_GL_ARG_NONNULL is copied here.  */

/* The definition of _gl_GL_WARN_ON_USE is copied here.  */


/* Some systems do not define EXIT_*, despite otherwise supporting C89.  */
#ifndef EXIT_SUCCESS
# define EXIT_SUCCESS 0
#endif
/* Tandem/NSK and other platforms that define EXIT_FAILURE as -1 interfere
   with proper operation of xargs.  */
#ifndef EXIT_FAILURE
# define EXIT_FAILURE 1
#elif EXIT_FAILURE != 1
# undef EXIT_FAILURE
# define EXIT_FAILURE 1
#endif


#if @GNULIB__EXIT@
/* Terminate the current process with the given return code, without running
   the 'atexit' handlers.  */
# if !@HAVE__EXIT@
_gl_GL_FUNCDECL_SYS (_Exit, void, (int status) _gl_GL_ATTRIBUTE_NORETURN);
# endif
_gl_GL_CXXALIAS_SYS (_Exit, void, (int status));
_gl_GL_CXXALIASWARN (_Exit);
#elif defined GNULIB_POSIXCHECK
# undef _Exit
# if HAVE_RAW_DECL__EXIT
_gl_GL_WARN_ON_USE (_Exit, "_Exit is unportable - "
                 "use gnulib module _Exit for portability");
# endif
#endif


#if @GNULIB_ATOLL@
/* Parse a signed decimal integer.
   Returns the value of the integer.  Errors are not detected.  */
# if !@HAVE_ATOLL@
_gl_GL_FUNCDECL_SYS (atoll, long long, (const char *string) _gl_GL_ARG_NONNULL ((1)));
# endif
_gl_GL_CXXALIAS_SYS (atoll, long long, (const char *string));
_gl_GL_CXXALIASWARN (atoll);
#elif defined GNULIB_POSIXCHECK
# undef atoll
# if HAVE_RAW_DECL_ATOLL
_gl_GL_WARN_ON_USE (atoll, "atoll is unportable - "
                 "use gnulib module atoll for portability");
# endif
#endif

#if @GNULIB_CALLOC_POSIX@
# if @REPLACE_CALLOC@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef calloc
#   define calloc rpl_calloc
#  endif
_gl_GL_FUNCDECL_RPL (calloc, void *, (size_t nmemb, size_t size));
_gl_GL_CXXALIAS_RPL (calloc, void *, (size_t nmemb, size_t size));
# else
_gl_GL_CXXALIAS_SYS (calloc, void *, (size_t nmemb, size_t size));
# endif
_gl_GL_CXXALIASWARN (calloc);
#elif defined GNULIB_POSIXCHECK
# undef calloc
/* Assume calloc is always declared.  */
_gl_GL_WARN_ON_USE (calloc, "calloc is not POSIX compliant everywhere - "
                 "use gnulib module calloc-posix for portability");
#endif

#if @GNULIB_CANONICALIZE_FILE_NAME@
# if @REPLACE_CANONICALIZE_FILE_NAME@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define canonicalize_file_name rpl_canonicalize_file_name
#  endif
_gl_GL_FUNCDECL_RPL (canonicalize_file_name, char *, (const char *name)
                                                  _gl_GL_ARG_NONNULL ((1)));
_gl_GL_CXXALIAS_RPL (canonicalize_file_name, char *, (const char *name));
# else
#  if !@HAVE_CANONICALIZE_FILE_NAME@
_gl_GL_FUNCDECL_SYS (canonicalize_file_name, char *, (const char *name)
                                                  _gl_GL_ARG_NONNULL ((1)));
#  endif
_gl_GL_CXXALIAS_SYS (canonicalize_file_name, char *, (const char *name));
# endif
_gl_GL_CXXALIASWARN (canonicalize_file_name);
#elif defined GNULIB_POSIXCHECK
# undef canonicalize_file_name
# if HAVE_RAW_DECL_CANONICALIZE_FILE_NAME
_gl_GL_WARN_ON_USE (canonicalize_file_name,
                 "canonicalize_file_name is unportable - "
                 "use gnulib module canonicalize-lgpl for portability");
# endif
#endif

#if @GNULIB_GETLOADAVG@
/* Store max(NELEM,3) load average numbers in LOADAVG[].
   The three numbers are the load average of the last 1 minute, the last 5
   minutes, and the last 15 minutes, respectively.
   LOADAVG is an array of NELEM numbers.  */
# if !@HAVE_DECL_GETLOADAVG@
_gl_GL_FUNCDECL_SYS (getloadavg, int, (double loadavg[], int nelem)
                                   _gl_GL_ARG_NONNULL ((1)));
# endif
_gl_GL_CXXALIAS_SYS (getloadavg, int, (double loadavg[], int nelem));
_gl_GL_CXXALIASWARN (getloadavg);
#elif defined GNULIB_POSIXCHECK
# undef getloadavg
# if HAVE_RAW_DECL_GETLOADAVG
_gl_GL_WARN_ON_USE (getloadavg, "getloadavg is not portable - "
                 "use gnulib module getloadavg for portability");
# endif
#endif

#if @GNULIB_GETSUBOPT@
/* Assuming *OPTIONP is a comma separated list of elements of the form
   "token" or "token=value", getsubopt parses the first of these elements.
   If the first element refers to a "token" that is member of the given
   NULL-terminated array of tokens:
     - It replaces the comma with a NUL byte, updates *OPTIONP to point past
       the first option and the comma, sets *VALUEP to the value of the
       element (or NULL if it doesn't contain an "=" sign),
     - It returns the index of the "token" in the given array of tokens.
   Otherwise it returns -1, and *OPTIONP and *VALUEP are undefined.
   For more details see the POSIX:2001 specification.
   http://www.opengroup.org/susv3xsh/getsubopt.html */
# if !@HAVE_GETSUBOPT@
_gl_GL_FUNCDECL_SYS (getsubopt, int,
                  (char **optionp, char *const *tokens, char **valuep)
                  _gl_GL_ARG_NONNULL ((1, 2, 3)));
# endif
_gl_GL_CXXALIAS_SYS (getsubopt, int,
                  (char **optionp, char *const *tokens, char **valuep));
_gl_GL_CXXALIASWARN (getsubopt);
#elif defined GNULIB_POSIXCHECK
# undef getsubopt
# if HAVE_RAW_DECL_GETSUBOPT
_gl_GL_WARN_ON_USE (getsubopt, "getsubopt is unportable - "
                 "use gnulib module getsubopt for portability");
# endif
#endif

#if @GNULIB_GRANTPT@
/* Change the ownership and access permission of the slave side of the
   pseudo-terminal whose master side is specified by FD.  */
# if !@HAVE_GRANTPT@
_gl_GL_FUNCDECL_SYS (grantpt, int, (int fd));
# endif
_gl_GL_CXXALIAS_SYS (grantpt, int, (int fd));
_gl_GL_CXXALIASWARN (grantpt);
#elif defined GNULIB_POSIXCHECK
# undef grantpt
# if HAVE_RAW_DECL_GRANTPT
_gl_GL_WARN_ON_USE (ptsname, "grantpt is not portable - "
                 "use gnulib module grantpt for portability");
# endif
#endif

/* If _gl_GL_USE_STDLIB_ALLOC is nonzero, the including module does not
   rely on GNU or POSIX semantics for malloc and realloc (for example,
   by never specifying a zero size), so it does not need malloc or
   realloc to be redefined.  */
#if @GNULIB_MALLOC_POSIX@
# if @REPLACE_MALLOC@
#  if !((defined __cplusplus && defined GNULIB_NAMESPACE) \
        || _gl_GL_USE_STDLIB_ALLOC)
#   undef malloc
#   define malloc rpl_malloc
#  endif
_gl_GL_FUNCDECL_RPL (malloc, void *, (size_t size));
_gl_GL_CXXALIAS_RPL (malloc, void *, (size_t size));
# else
_gl_GL_CXXALIAS_SYS (malloc, void *, (size_t size));
# endif
_gl_GL_CXXALIASWARN (malloc);
#elif defined GNULIB_POSIXCHECK && !_gl_GL_USE_STDLIB_ALLOC
# undef malloc
/* Assume malloc is always declared.  */
_gl_GL_WARN_ON_USE (malloc, "malloc is not POSIX compliant everywhere - "
                 "use gnulib module malloc-posix for portability");
#endif

/* Convert a multibyte character to a wide character.  */
#if @GNULIB_MBTOWC@
# if @REPLACE_MBTOWC@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef mbtowc
#   define mbtowc rpl_mbtowc
#  endif
_gl_GL_FUNCDECL_RPL (mbtowc, int, (wchar_t *pwc, const char *s, size_t n));
_gl_GL_CXXALIAS_RPL (mbtowc, int, (wchar_t *pwc, const char *s, size_t n));
# else
_gl_GL_CXXALIAS_SYS (mbtowc, int, (wchar_t *pwc, const char *s, size_t n));
# endif
_gl_GL_CXXALIASWARN (mbtowc);
#endif

#if @GNULIB_MKDTEMP@
/* Create a unique temporary directory from TEMPLATE.
   The last six characters of TEMPLATE must be "XXXXXX";
   they are replaced with a string that makes the directory name unique.
   Returns TEMPLATE, or a null pointer if it cannot get a unique name.
   The directory is created mode 700.  */
# if !@HAVE_MKDTEMP@
_gl_GL_FUNCDECL_SYS (mkdtemp, char *, (char * /*template*/) _gl_GL_ARG_NONNULL ((1)));
# endif
_gl_GL_CXXALIAS_SYS (mkdtemp, char *, (char * /*template*/));
_gl_GL_CXXALIASWARN (mkdtemp);
#elif defined GNULIB_POSIXCHECK
# undef mkdtemp
# if HAVE_RAW_DECL_MKDTEMP
_gl_GL_WARN_ON_USE (mkdtemp, "mkdtemp is unportable - "
                 "use gnulib module mkdtemp for portability");
# endif
#endif

#if @GNULIB_MKOSTEMP@
/* Create a unique temporary file from TEMPLATE.
   The last six characters of TEMPLATE must be "XXXXXX";
   they are replaced with a string that makes the file name unique.
   The flags are a bitmask, possibly including O_CLOEXEC (defined in <fcntl.h>)
   and O_TEXT, O_BINARY (defined in "binary-io.h").
   The file is then created, with the specified flags, ensuring it didn't exist
   before.
   The file is created read-write (mask at least 0600 & ~umask), but it may be
   world-readable and world-writable (mask 0666 & ~umask), depending on the
   implementation.
   Returns the open file descriptor if successful, otherwise -1 and errno
   set.  */
# if !@HAVE_MKOSTEMP@
_gl_GL_FUNCDECL_SYS (mkostemp, int, (char * /*template*/, int /*flags*/)
                                 _gl_GL_ARG_NONNULL ((1)));
# endif
_gl_GL_CXXALIAS_SYS (mkostemp, int, (char * /*template*/, int /*flags*/));
_gl_GL_CXXALIASWARN (mkostemp);
#elif defined GNULIB_POSIXCHECK
# undef mkostemp
# if HAVE_RAW_DECL_MKOSTEMP
_gl_GL_WARN_ON_USE (mkostemp, "mkostemp is unportable - "
                 "use gnulib module mkostemp for portability");
# endif
#endif

#if @GNULIB_MKOSTEMPS@
/* Create a unique temporary file from TEMPLATE.
   The last six characters of TEMPLATE before a suffix of length
   SUFFIXLEN must be "XXXXXX";
   they are replaced with a string that makes the file name unique.
   The flags are a bitmask, possibly including O_CLOEXEC (defined in <fcntl.h>)
   and O_TEXT, O_BINARY (defined in "binary-io.h").
   The file is then created, with the specified flags, ensuring it didn't exist
   before.
   The file is created read-write (mask at least 0600 & ~umask), but it may be
   world-readable and world-writable (mask 0666 & ~umask), depending on the
   implementation.
   Returns the open file descriptor if successful, otherwise -1 and errno
   set.  */
# if !@HAVE_MKOSTEMPS@
_gl_GL_FUNCDECL_SYS (mkostemps, int,
                  (char * /*template*/, int /*suffixlen*/, int /*flags*/)
                  _gl_GL_ARG_NONNULL ((1)));
# endif
_gl_GL_CXXALIAS_SYS (mkostemps, int,
                  (char * /*template*/, int /*suffixlen*/, int /*flags*/));
_gl_GL_CXXALIASWARN (mkostemps);
#elif defined GNULIB_POSIXCHECK
# undef mkostemps
# if HAVE_RAW_DECL_MKOSTEMPS
_gl_GL_WARN_ON_USE (mkostemps, "mkostemps is unportable - "
                 "use gnulib module mkostemps for portability");
# endif
#endif

#if @GNULIB_MKSTEMP@
/* Create a unique temporary file from TEMPLATE.
   The last six characters of TEMPLATE must be "XXXXXX";
   they are replaced with a string that makes the file name unique.
   The file is then created, ensuring it didn't exist before.
   The file is created read-write (mask at least 0600 & ~umask), but it may be
   world-readable and world-writable (mask 0666 & ~umask), depending on the
   implementation.
   Returns the open file descriptor if successful, otherwise -1 and errno
   set.  */
# if @REPLACE_MKSTEMP@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define mkstemp rpl_mkstemp
#  endif
_gl_GL_FUNCDECL_RPL (mkstemp, int, (char * /*template*/) _gl_GL_ARG_NONNULL ((1)));
_gl_GL_CXXALIAS_RPL (mkstemp, int, (char * /*template*/));
# else
#  if ! @HAVE_MKSTEMP@
_gl_GL_FUNCDECL_SYS (mkstemp, int, (char * /*template*/) _gl_GL_ARG_NONNULL ((1)));
#  endif
_gl_GL_CXXALIAS_SYS (mkstemp, int, (char * /*template*/));
# endif
_gl_GL_CXXALIASWARN (mkstemp);
#elif defined GNULIB_POSIXCHECK
# undef mkstemp
# if HAVE_RAW_DECL_MKSTEMP
_gl_GL_WARN_ON_USE (mkstemp, "mkstemp is unportable - "
                 "use gnulib module mkstemp for portability");
# endif
#endif

#if @GNULIB_MKSTEMPS@
/* Create a unique temporary file from TEMPLATE.
   The last six characters of TEMPLATE prior to a suffix of length
   SUFFIXLEN must be "XXXXXX";
   they are replaced with a string that makes the file name unique.
   The file is then created, ensuring it didn't exist before.
   The file is created read-write (mask at least 0600 & ~umask), but it may be
   world-readable and world-writable (mask 0666 & ~umask), depending on the
   implementation.
   Returns the open file descriptor if successful, otherwise -1 and errno
   set.  */
# if !@HAVE_MKSTEMPS@
_gl_GL_FUNCDECL_SYS (mkstemps, int, (char * /*template*/, int /*suffixlen*/)
                                 _gl_GL_ARG_NONNULL ((1)));
# endif
_gl_GL_CXXALIAS_SYS (mkstemps, int, (char * /*template*/, int /*suffixlen*/));
_gl_GL_CXXALIASWARN (mkstemps);
#elif defined GNULIB_POSIXCHECK
# undef mkstemps
# if HAVE_RAW_DECL_MKSTEMPS
_gl_GL_WARN_ON_USE (mkstemps, "mkstemps is unportable - "
                 "use gnulib module mkstemps for portability");
# endif
#endif

#if @GNULIB_PTSNAME@
/* Return the pathname of the pseudo-terminal slave associated with
   the master FD is open on, or NULL on errors.  */
# if !@HAVE_PTSNAME@
_gl_GL_FUNCDECL_SYS (ptsname, char *, (int fd));
# endif
_gl_GL_CXXALIAS_SYS (ptsname, char *, (int fd));
_gl_GL_CXXALIASWARN (ptsname);
#elif defined GNULIB_POSIXCHECK
# undef ptsname
# if HAVE_RAW_DECL_PTSNAME
_gl_GL_WARN_ON_USE (ptsname, "ptsname is not portable - "
                 "use gnulib module ptsname for portability");
# endif
#endif

#if @GNULIB_PUTENV@
# if @REPLACE_PUTENV@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef putenv
#   define putenv rpl_putenv
#  endif
_gl_GL_FUNCDECL_RPL (putenv, int, (char *string) _gl_GL_ARG_NONNULL ((1)));
_gl_GL_CXXALIAS_RPL (putenv, int, (char *string));
# else
_gl_GL_CXXALIAS_SYS (putenv, int, (char *string));
# endif
_gl_GL_CXXALIASWARN (putenv);
#endif


#if @GNULIB_RANDOM_R@
# if !@HAVE_RANDOM_R@
#  ifndef RAND_MAX
#   define RAND_MAX 2147483647
#  endif
# endif
#endif

#if @GNULIB_RANDOM_R@
# if !@HAVE_RANDOM_R@
_gl_GL_FUNCDECL_SYS (random_r, int, (struct random_data *buf, int32_t *result)
                                 _gl_GL_ARG_NONNULL ((1, 2)));
# endif
_gl_GL_CXXALIAS_SYS (random_r, int, (struct random_data *buf, int32_t *result));
_gl_GL_CXXALIASWARN (random_r);
#elif defined GNULIB_POSIXCHECK
# undef random_r
# if HAVE_RAW_DECL_RANDOM_R
_gl_GL_WARN_ON_USE (random_r, "random_r is unportable - "
                 "use gnulib module random_r for portability");
# endif
#endif

#if @GNULIB_RANDOM_R@
# if !@HAVE_RANDOM_R@
_gl_GL_FUNCDECL_SYS (srandom_r, int,
                  (unsigned int seed, struct random_data *rand_state)
                  _gl_GL_ARG_NONNULL ((2)));
# endif
_gl_GL_CXXALIAS_SYS (srandom_r, int,
                  (unsigned int seed, struct random_data *rand_state));
_gl_GL_CXXALIASWARN (srandom_r);
#elif defined GNULIB_POSIXCHECK
# undef srandom_r
# if HAVE_RAW_DECL_SRANDOM_R
_gl_GL_WARN_ON_USE (srandom_r, "srandom_r is unportable - "
                 "use gnulib module random_r for portability");
# endif
#endif

#if @GNULIB_RANDOM_R@
# if !@HAVE_RANDOM_R@
_gl_GL_FUNCDECL_SYS (initstate_r, int,
                  (unsigned int seed, char *buf, size_t buf_size,
                   struct random_data *rand_state)
                  _gl_GL_ARG_NONNULL ((2, 4)));
# endif
_gl_GL_CXXALIAS_SYS (initstate_r, int,
                  (unsigned int seed, char *buf, size_t buf_size,
                   struct random_data *rand_state));
_gl_GL_CXXALIASWARN (initstate_r);
#elif defined GNULIB_POSIXCHECK
# undef initstate_r
# if HAVE_RAW_DECL_INITSTATE_R
_gl_GL_WARN_ON_USE (initstate_r, "initstate_r is unportable - "
                 "use gnulib module random_r for portability");
# endif
#endif

#if @GNULIB_RANDOM_R@
# if !@HAVE_RANDOM_R@
_gl_GL_FUNCDECL_SYS (setstate_r, int,
                  (char *arg_state, struct random_data *rand_state)
                  _gl_GL_ARG_NONNULL ((1, 2)));
# endif
_gl_GL_CXXALIAS_SYS (setstate_r, int,
                  (char *arg_state, struct random_data *rand_state));
_gl_GL_CXXALIASWARN (setstate_r);
#elif defined GNULIB_POSIXCHECK
# undef setstate_r
# if HAVE_RAW_DECL_SETSTATE_R
_gl_GL_WARN_ON_USE (setstate_r, "setstate_r is unportable - "
                 "use gnulib module random_r for portability");
# endif
#endif


#if @GNULIB_REALLOC_POSIX@
# if @REPLACE_REALLOC@
#  if !((defined __cplusplus && defined GNULIB_NAMESPACE) \
        || _gl_GL_USE_STDLIB_ALLOC)
#   undef realloc
#   define realloc rpl_realloc
#  endif
_gl_GL_FUNCDECL_RPL (realloc, void *, (void *ptr, size_t size));
_gl_GL_CXXALIAS_RPL (realloc, void *, (void *ptr, size_t size));
# else
_gl_GL_CXXALIAS_SYS (realloc, void *, (void *ptr, size_t size));
# endif
_gl_GL_CXXALIASWARN (realloc);
#elif defined GNULIB_POSIXCHECK && !_gl_GL_USE_STDLIB_ALLOC
# undef realloc
/* Assume realloc is always declared.  */
_gl_GL_WARN_ON_USE (realloc, "realloc is not POSIX compliant everywhere - "
                 "use gnulib module realloc-posix for portability");
#endif

#if @GNULIB_REALPATH@
# if @REPLACE_REALPATH@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define realpath rpl_realpath
#  endif
_gl_GL_FUNCDECL_RPL (realpath, char *, (const char *name, char *resolved)
                                    _gl_GL_ARG_NONNULL ((1)));
_gl_GL_CXXALIAS_RPL (realpath, char *, (const char *name, char *resolved));
# else
#  if !@HAVE_REALPATH@
_gl_GL_FUNCDECL_SYS (realpath, char *, (const char *name, char *resolved)
                                    _gl_GL_ARG_NONNULL ((1)));
#  endif
_gl_GL_CXXALIAS_SYS (realpath, char *, (const char *name, char *resolved));
# endif
_gl_GL_CXXALIASWARN (realpath);
#elif defined GNULIB_POSIXCHECK
# undef realpath
# if HAVE_RAW_DECL_REALPATH
_gl_GL_WARN_ON_USE (realpath, "realpath is unportable - use gnulib module "
                 "canonicalize or canonicalize-lgpl for portability");
# endif
#endif

#if @GNULIB_RPMATCH@
/* Test a user response to a question.
   Return 1 if it is affirmative, 0 if it is negative, or -1 if not clear.  */
# if !@HAVE_RPMATCH@
_gl_GL_FUNCDECL_SYS (rpmatch, int, (const char *response) _gl_GL_ARG_NONNULL ((1)));
# endif
_gl_GL_CXXALIAS_SYS (rpmatch, int, (const char *response));
_gl_GL_CXXALIASWARN (rpmatch);
#elif defined GNULIB_POSIXCHECK
# undef rpmatch
# if HAVE_RAW_DECL_RPMATCH
_gl_GL_WARN_ON_USE (rpmatch, "rpmatch is unportable - "
                 "use gnulib module rpmatch for portability");
# endif
#endif

#if @GNULIB_SETENV@
/* Set NAME to VALUE in the environment.
   If REPLACE is nonzero, overwrite an existing value.  */
# if @REPLACE_SETENV@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef setenv
#   define setenv rpl_setenv
#  endif
_gl_GL_FUNCDECL_RPL (setenv, int,
                  (const char *name, const char *value, int replace)
                  _gl_GL_ARG_NONNULL ((1)));
_gl_GL_CXXALIAS_RPL (setenv, int,
                  (const char *name, const char *value, int replace));
# else
#  if !@HAVE_DECL_SETENV@
_gl_GL_FUNCDECL_SYS (setenv, int,
                  (const char *name, const char *value, int replace)
                  _gl_GL_ARG_NONNULL ((1)));
#  endif
_gl_GL_CXXALIAS_SYS (setenv, int,
                  (const char *name, const char *value, int replace));
# endif
# if !(@REPLACE_SETENV@ && !@HAVE_DECL_SETENV@)
_gl_GL_CXXALIASWARN (setenv);
# endif
#elif defined GNULIB_POSIXCHECK
# undef setenv
# if HAVE_RAW_DECL_SETENV
_gl_GL_WARN_ON_USE (setenv, "setenv is unportable - "
                 "use gnulib module setenv for portability");
# endif
#endif

#if @GNULIB_STRTOD@
 /* Parse a double from STRING, updating ENDP if appropriate.  */
# if @REPLACE_STRTOD@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define strtod rpl_strtod
#  endif
_gl_GL_FUNCDECL_RPL (strtod, double, (const char *str, char **endp)
                                  _gl_GL_ARG_NONNULL ((1)));
_gl_GL_CXXALIAS_RPL (strtod, double, (const char *str, char **endp));
# else
#  if !@HAVE_STRTOD@
_gl_GL_FUNCDECL_SYS (strtod, double, (const char *str, char **endp)
                                  _gl_GL_ARG_NONNULL ((1)));
#  endif
_gl_GL_CXXALIAS_SYS (strtod, double, (const char *str, char **endp));
# endif
_gl_GL_CXXALIASWARN (strtod);
#elif defined GNULIB_POSIXCHECK
# undef strtod
# if HAVE_RAW_DECL_STRTOD
_gl_GL_WARN_ON_USE (strtod, "strtod is unportable - "
                 "use gnulib module strtod for portability");
# endif
#endif

#if @GNULIB_STRTOLL@
/* Parse a signed integer whose textual representation starts at STRING.
   The integer is expected to be in base BASE (2 <= BASE <= 36); if BASE == 0,
   it may be decimal or octal (with prefix "0") or hexadecimal (with prefix
   "0x").
   If ENDPTR is not NULL, the address of the first byte after the integer is
   stored in *ENDPTR.
   Upon overflow, the return value is LLONG_MAX or LLONG_MIN, and errno is set
   to ERANGE.  */
# if !@HAVE_STRTOLL@
_gl_GL_FUNCDECL_SYS (strtoll, long long,
                  (const char *string, char **endptr, int base)
                  _gl_GL_ARG_NONNULL ((1)));
# endif
_gl_GL_CXXALIAS_SYS (strtoll, long long,
                  (const char *string, char **endptr, int base));
_gl_GL_CXXALIASWARN (strtoll);
#elif defined GNULIB_POSIXCHECK
# undef strtoll
# if HAVE_RAW_DECL_STRTOLL
_gl_GL_WARN_ON_USE (strtoll, "strtoll is unportable - "
                 "use gnulib module strtoll for portability");
# endif
#endif

#if @GNULIB_STRTOULL@
/* Parse an unsigned integer whose textual representation starts at STRING.
   The integer is expected to be in base BASE (2 <= BASE <= 36); if BASE == 0,
   it may be decimal or octal (with prefix "0") or hexadecimal (with prefix
   "0x").
   If ENDPTR is not NULL, the address of the first byte after the integer is
   stored in *ENDPTR.
   Upon overflow, the return value is ULLONG_MAX, and errno is set to
   ERANGE.  */
# if !@HAVE_STRTOULL@
_gl_GL_FUNCDECL_SYS (strtoull, unsigned long long,
                  (const char *string, char **endptr, int base)
                  _gl_GL_ARG_NONNULL ((1)));
# endif
_gl_GL_CXXALIAS_SYS (strtoull, unsigned long long,
                  (const char *string, char **endptr, int base));
_gl_GL_CXXALIASWARN (strtoull);
#elif defined GNULIB_POSIXCHECK
# undef strtoull
# if HAVE_RAW_DECL_STRTOULL
_gl_GL_WARN_ON_USE (strtoull, "strtoull is unportable - "
                 "use gnulib module strtoull for portability");
# endif
#endif

#if @GNULIB_UNLOCKPT@
/* Unlock the slave side of the pseudo-terminal whose master side is specified
   by FD, so that it can be opened.  */
# if !@HAVE_UNLOCKPT@
_gl_GL_FUNCDECL_SYS (unlockpt, int, (int fd));
# endif
_gl_GL_CXXALIAS_SYS (unlockpt, int, (int fd));
_gl_GL_CXXALIASWARN (unlockpt);
#elif defined GNULIB_POSIXCHECK
# undef unlockpt
# if HAVE_RAW_DECL_UNLOCKPT
_gl_GL_WARN_ON_USE (unlockpt, "unlockpt is not portable - "
                 "use gnulib module unlockpt for portability");
# endif
#endif

#if @GNULIB_UNSETENV@
/* Remove the variable NAME from the environment.  */
# if @REPLACE_UNSETENV@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef unsetenv
#   define unsetenv rpl_unsetenv
#  endif
_gl_GL_FUNCDECL_RPL (unsetenv, int, (const char *name) _gl_GL_ARG_NONNULL ((1)));
_gl_GL_CXXALIAS_RPL (unsetenv, int, (const char *name));
# else
#  if !@HAVE_DECL_UNSETENV@
_gl_GL_FUNCDECL_SYS (unsetenv, int, (const char *name) _gl_GL_ARG_NONNULL ((1)));
#  endif
_gl_GL_CXXALIAS_SYS (unsetenv, int, (const char *name));
# endif
# if !(@REPLACE_UNSETENV@ && !@HAVE_DECL_UNSETENV@)
_gl_GL_CXXALIASWARN (unsetenv);
# endif
#elif defined GNULIB_POSIXCHECK
# undef unsetenv
# if HAVE_RAW_DECL_UNSETENV
_gl_GL_WARN_ON_USE (unsetenv, "unsetenv is unportable - "
                 "use gnulib module unsetenv for portability");
# endif
#endif

/* Convert a wide character to a multibyte character.  */
#if @GNULIB_WCTOMB@
# if @REPLACE_WCTOMB@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef wctomb
#   define wctomb rpl_wctomb
#  endif
_gl_GL_FUNCDECL_RPL (wctomb, int, (char *s, wchar_t wc));
_gl_GL_CXXALIAS_RPL (wctomb, int, (char *s, wchar_t wc));
# else
_gl_GL_CXXALIAS_SYS (wctomb, int, (char *s, wchar_t wc));
# endif
_gl_GL_CXXALIASWARN (wctomb);
#endif


#endif /* _gl_GL_STDLIB_H */
#endif /* _gl_GL_STDLIB_H */
#endif
