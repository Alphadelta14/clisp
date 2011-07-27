# DO NOT EDIT! GENERATED AUTOMATICALLY!
# Copyright (C) 2002-2011 Free Software Foundation, Inc.
#
# This file is free software, distributed under the terms of the GNU
# General Public License.  As a special exception to the GNU General
# Public License, this file may be distributed as part of a program
# that contains a configuration script generated by Autoconf, under
# the same distribution terms as the rest of that program.
#
# Generated by gnulib-tool.
#
# This file represents the compiled summary of the specification in
# gnulib-cache.m4. It lists the computed macro invocations that need
# to be invoked from configure.ac.
# In projects that use version control, this file can be treated like
# other built files.


# This macro should be invoked from ./configure.ac, in the section
# "Checks for programs", right after AC_PROG_CC, and certainly before
# any checks for libraries, header files, types and library functions.
AC_DEFUN([gl_EARLY],
[
  m4_pattern_forbid([^gl_[A-Z]])dnl the gnulib macro namespace
  m4_pattern_allow([^gl_ES$])dnl a valid locale name
  m4_pattern_allow([^gl_LIBOBJS$])dnl a variable
  m4_pattern_allow([^gl_LTLIBOBJS$])dnl a variable
  AC_REQUIRE([AC_PROG_RANLIB])
  AC_REQUIRE([AM_PROG_CC_C_O])
  # Code from module accept:
  # Code from module alignof:
  # Code from module alloca:
  # Code from module alloca-opt:
  # Code from module arpa_inet:
  # Code from module bind:
  # Code from module btowc:
  # Code from module c-ctype:
  # Code from module close:
  # Code from module configmake:
  # Code from module connect:
  # Code from module dosname:
  # Code from module environ:
  # Code from module errno:
  # Code from module extensions:
  AC_REQUIRE([gl_USE_SYSTEM_EXTENSIONS])
  # Code from module fd-hook:
  # Code from module fnmatch:
  # Code from module fnmatch-gnu:
  # Code from module gethostname:
  # Code from module getloadavg:
  # Code from module getpagesize:
  # Code from module getpeername:
  # Code from module getsockname:
  # Code from module getsockopt:
  # Code from module gettext:
  # Code from module gettext-h:
  # Code from module gettimeofday:
  # Code from module gnu-make:
  # Code from module havelib:
  # Code from module host-cpu-c-abi:
  # Code from module include_next:
  # Code from module inet_ntop:
  # Code from module inet_pton:
  # Code from module intprops:
  # Code from module ioctl:
  # Code from module langinfo:
  # Code from module largefile:
  # Code from module libsigsegv:
  # Code from module link-follow:
  # Code from module listen:
  # Code from module localcharset:
  # Code from module lock:
  # Code from module lstat:
  # Code from module malloc-gnu:
  # Code from module malloc-posix:
  # Code from module malloca:
  # Code from module mbrtowc:
  # Code from module mbsinit:
  # Code from module mbsrtowcs:
  # Code from module mbtowc:
  # Code from module memchr:
  # Code from module mkdtemp:
  # Code from module mkfifo:
  # Code from module mknod:
  # Code from module mkstemp:
  # Code from module mktime:
  # Code from module multiarch:
  # Code from module netinet_in:
  # Code from module nl_langinfo:
  # Code from module no-c++:
  # Code from module nocrash:
  # Code from module readlink:
  # Code from module recv:
  # Code from module recvfrom:
  # Code from module regex:
  # Code from module select:
  # Code from module send:
  # Code from module sendto:
  # Code from module setenv:
  # Code from module setsockopt:
  # Code from module shutdown:
  # Code from module signal:
  # Code from module snippet/_Noreturn:
  # Code from module snippet/arg-nonnull:
  # Code from module snippet/c++defs:
  # Code from module snippet/warn-on-use:
  # Code from module socket:
  # Code from module socketlib:
  # Code from module sockets:
  # Code from module socklen:
  # Code from module ssize_t:
  # Code from module stat:
  # Code from module stdbool:
  # Code from module stddef:
  # Code from module stdint:
  # Code from module stdlib:
  # Code from module streq:
  # Code from module strerror-override:
  # Code from module strerror_r-posix:
  # Code from module strftime:
  # Code from module string:
  # Code from module strnlen1:
  # Code from module strptime:
  # Code from module strverscmp:
  # Code from module sys_ioctl:
  # Code from module sys_select:
  # Code from module sys_socket:
  # Code from module sys_stat:
  # Code from module sys_time:
  # Code from module sys_uio:
  # Code from module sys_utsname:
  # Code from module sys_wait:
  # Code from module tempname:
  # Code from module threadlib:
  gl_THREADLIB_EARLY
  # Code from module time:
  # Code from module time_r:
  # Code from module uname:
  # Code from module uniname/base:
  # Code from module uniname/uniname:
  # Code from module unistd:
  # Code from module unitypes:
  # Code from module uniwidth/base:
  # Code from module uniwidth/width:
  # Code from module unsetenv:
  # Code from module verify:
  # Code from module wchar:
  # Code from module wcrtomb:
  # Code from module wctype-h:
])

# This macro should be invoked from ./configure.ac, in the section
# "Check for header files, types and library functions".
AC_DEFUN([gl_INIT],
[
  AM_CONDITIONAL([GL_COND_LIBTOOL], [false])
  gl_cond_libtool=false
  gl_libdeps=
  gl_ltlibdeps=
  gl_m4_base='src/glm4'
  m4_pushdef([AC_LIBOBJ], m4_defn([gl_LIBOBJ]))
  m4_pushdef([AC_REPLACE_FUNCS], m4_defn([gl_REPLACE_FUNCS]))
  m4_pushdef([AC_LIBSOURCES], m4_defn([gl_LIBSOURCES]))
  m4_pushdef([gl_LIBSOURCES_LIST], [])
  m4_pushdef([gl_LIBSOURCES_DIR], [])
  gl_COMMON
  gl_source_base='src/gllib'
AC_REQUIRE([gl_HEADER_SYS_SOCKET])
if test "$ac_cv_header_winsock2_h" = yes; then
  AC_LIBOBJ([accept])
fi
gl_SYS_SOCKET_MODULE_INDICATOR([accept])
gl_FUNC_ALLOCA
gl_HEADER_ARPA_INET
AC_PROG_MKDIR_P
AC_REQUIRE([gl_HEADER_SYS_SOCKET])
if test "$ac_cv_header_winsock2_h" = yes; then
  AC_LIBOBJ([bind])
fi
gl_SYS_SOCKET_MODULE_INDICATOR([bind])
gl_FUNC_BTOWC
if test $HAVE_BTOWC = 0 || test $REPLACE_BTOWC = 1; then
  AC_LIBOBJ([btowc])
  gl_PREREQ_BTOWC
fi
gl_WCHAR_MODULE_INDICATOR([btowc])
gl_FUNC_CLOSE
if test $REPLACE_CLOSE = 1; then
  AC_LIBOBJ([close])
fi
gl_UNISTD_MODULE_INDICATOR([close])
gl_CONFIGMAKE_PREP
AC_REQUIRE([gl_HEADER_SYS_SOCKET])
if test "$ac_cv_header_winsock2_h" = yes; then
  AC_LIBOBJ([connect])
fi
gl_SYS_SOCKET_MODULE_INDICATOR([connect])
gl_ENVIRON
gl_UNISTD_MODULE_INDICATOR([environ])
gl_HEADER_ERRNO_H
gl_FUNC_FNMATCH_POSIX
if test -n "$FNMATCH_H"; then
  AC_LIBOBJ([fnmatch])
  gl_PREREQ_FNMATCH
fi
gl_FUNC_FNMATCH_GNU
if test -n "$FNMATCH_H"; then
  AC_LIBOBJ([fnmatch])
  gl_PREREQ_FNMATCH
fi
gl_FUNC_GETHOSTNAME
if test $HAVE_GETHOSTNAME = 0; then
  AC_LIBOBJ([gethostname])
  gl_PREREQ_GETHOSTNAME
fi
gl_UNISTD_MODULE_INDICATOR([gethostname])
gl_GETLOADAVG
if test $HAVE_GETLOADAVG = 0; then
  AC_LIBOBJ([getloadavg])
  gl_PREREQ_GETLOADAVG
fi
gl_STDLIB_MODULE_INDICATOR([getloadavg])
gl_FUNC_GETPAGESIZE
if test $REPLACE_GETPAGESIZE = 1; then
  AC_LIBOBJ([getpagesize])
fi
gl_UNISTD_MODULE_INDICATOR([getpagesize])
AC_REQUIRE([gl_HEADER_SYS_SOCKET])
if test "$ac_cv_header_winsock2_h" = yes; then
  AC_LIBOBJ([getpeername])
fi
gl_SYS_SOCKET_MODULE_INDICATOR([getpeername])
AC_REQUIRE([gl_HEADER_SYS_SOCKET])
if test "$ac_cv_header_winsock2_h" = yes; then
  AC_LIBOBJ([getsockname])
fi
gl_SYS_SOCKET_MODULE_INDICATOR([getsockname])
AC_REQUIRE([gl_HEADER_SYS_SOCKET])
if test "$ac_cv_header_winsock2_h" = yes; then
  AC_LIBOBJ([getsockopt])
fi
gl_SYS_SOCKET_MODULE_INDICATOR([getsockopt])
dnl you must add AM_GNU_GETTEXT([external]) or similar to configure.ac.
AM_GNU_GETTEXT_VERSION([0.18.1])
AC_SUBST([LIBINTL])
AC_SUBST([LTLIBINTL])
gl_FUNC_GETTIMEOFDAY
if test $HAVE_GETTIMEOFDAY = 0 || test $REPLACE_GETTIMEOFDAY = 1; then
  AC_LIBOBJ([gettimeofday])
  gl_PREREQ_GETTIMEOFDAY
fi
gl_SYS_TIME_MODULE_INDICATOR([gettimeofday])
gl_GNU_MAKE
gl_HOST_CPU_C_ABI
gl_FUNC_INET_NTOP
if test $HAVE_INET_NTOP = 0; then
  AC_LIBOBJ([inet_ntop])
  gl_PREREQ_INET_NTOP
fi
gl_ARPA_INET_MODULE_INDICATOR([inet_ntop])
gl_FUNC_INET_PTON
if test $HAVE_INET_PTON = 0; then
  AC_LIBOBJ([inet_pton])
  gl_PREREQ_INET_PTON
fi
gl_ARPA_INET_MODULE_INDICATOR([inet_pton])
gl_FUNC_IOCTL
if test $HAVE_IOCTL = 0 || test $REPLACE_IOCTL = 1; then
  AC_LIBOBJ([ioctl])
fi
gl_SYS_IOCTL_MODULE_INDICATOR([ioctl])
gl_LANGINFO_H
gl_LIBSIGSEGV
gl_FUNC_LINK_FOLLOWS_SYMLINK
AC_REQUIRE([gl_HEADER_SYS_SOCKET])
if test "$ac_cv_header_winsock2_h" = yes; then
  AC_LIBOBJ([listen])
fi
gl_SYS_SOCKET_MODULE_INDICATOR([listen])
gl_LOCALCHARSET
LOCALCHARSET_TESTS_ENVIRONMENT="CHARSETALIASDIR=\"\$(top_builddir)/$gl_source_base\""
AC_SUBST([LOCALCHARSET_TESTS_ENVIRONMENT])
gl_LOCK
gl_FUNC_LSTAT
if test $REPLACE_LSTAT = 1; then
  AC_LIBOBJ([lstat])
  gl_PREREQ_LSTAT
fi
gl_SYS_STAT_MODULE_INDICATOR([lstat])
gl_FUNC_MALLOC_GNU
if test $REPLACE_MALLOC = 1; then
  AC_LIBOBJ([malloc])
fi
gl_MODULE_INDICATOR([malloc-gnu])
gl_FUNC_MALLOC_POSIX
if test $REPLACE_MALLOC = 1; then
  AC_LIBOBJ([malloc])
fi
gl_STDLIB_MODULE_INDICATOR([malloc-posix])
gl_MALLOCA
gl_FUNC_MBRTOWC
if test $HAVE_MBRTOWC = 0 || test $REPLACE_MBRTOWC = 1; then
  AC_LIBOBJ([mbrtowc])
  gl_PREREQ_MBRTOWC
fi
gl_WCHAR_MODULE_INDICATOR([mbrtowc])
gl_FUNC_MBSINIT
if test $HAVE_MBSINIT = 0 || test $REPLACE_MBSINIT = 1; then
  AC_LIBOBJ([mbsinit])
  gl_PREREQ_MBSINIT
fi
gl_WCHAR_MODULE_INDICATOR([mbsinit])
gl_FUNC_MBSRTOWCS
if test $HAVE_MBSRTOWCS = 0 || test $REPLACE_MBSRTOWCS = 1; then
  AC_LIBOBJ([mbsrtowcs])
  AC_LIBOBJ([mbsrtowcs-state])
  gl_PREREQ_MBSRTOWCS
fi
gl_WCHAR_MODULE_INDICATOR([mbsrtowcs])
gl_FUNC_MBTOWC
if test $REPLACE_MBTOWC = 1; then
  AC_LIBOBJ([mbtowc])
  gl_PREREQ_MBTOWC
fi
gl_STDLIB_MODULE_INDICATOR([mbtowc])
gl_FUNC_MEMCHR
if test $HAVE_MEMCHR = 0 || test $REPLACE_MEMCHR = 1; then
  AC_LIBOBJ([memchr])
  gl_PREREQ_MEMCHR
fi
gl_STRING_MODULE_INDICATOR([memchr])
gl_FUNC_MKDTEMP
if test $HAVE_MKDTEMP = 0; then
  AC_LIBOBJ([mkdtemp])
  gl_PREREQ_MKDTEMP
fi
gl_STDLIB_MODULE_INDICATOR([mkdtemp])
gl_FUNC_MKFIFO
if test $HAVE_MKFIFO = 0 || test $REPLACE_MKFIFO = 1; then
  AC_LIBOBJ([mkfifo])
fi
gl_UNISTD_MODULE_INDICATOR([mkfifo])
gl_FUNC_MKNOD
if test $HAVE_MKNOD = 0 || test $REPLACE_MKNOD = 1; then
  AC_LIBOBJ([mknod])
fi
gl_UNISTD_MODULE_INDICATOR([mknod])
gl_FUNC_MKSTEMP
if test $HAVE_MKSTEMP = 0 || test $REPLACE_MKSTEMP = 1; then
  AC_LIBOBJ([mkstemp])
  gl_PREREQ_MKSTEMP
fi
gl_STDLIB_MODULE_INDICATOR([mkstemp])
gl_FUNC_MKTIME
if test $REPLACE_MKTIME = 1; then
  AC_LIBOBJ([mktime])
  gl_PREREQ_MKTIME
fi
gl_TIME_MODULE_INDICATOR([mktime])
gl_MULTIARCH
gl_HEADER_NETINET_IN
AC_PROG_MKDIR_P
gl_FUNC_NL_LANGINFO
if test $HAVE_NL_LANGINFO = 0 || test $REPLACE_NL_LANGINFO = 1; then
  AC_LIBOBJ([nl_langinfo])
fi
gl_LANGINFO_MODULE_INDICATOR([nl_langinfo])
gt_NO_CXX
gl_FUNC_READLINK
if test $HAVE_READLINK = 0 || test $REPLACE_READLINK = 1; then
  AC_LIBOBJ([readlink])
  gl_PREREQ_READLINK
fi
gl_UNISTD_MODULE_INDICATOR([readlink])
AC_REQUIRE([gl_HEADER_SYS_SOCKET])
if test "$ac_cv_header_winsock2_h" = yes; then
  AC_LIBOBJ([recv])
fi
gl_SYS_SOCKET_MODULE_INDICATOR([recv])
AC_REQUIRE([gl_HEADER_SYS_SOCKET])
if test "$ac_cv_header_winsock2_h" = yes; then
  AC_LIBOBJ([recvfrom])
fi
gl_SYS_SOCKET_MODULE_INDICATOR([recvfrom])
gl_REGEX
if test $ac_use_included_regex = yes; then
  AC_LIBOBJ([regex])
  gl_PREREQ_REGEX
fi
gl_FUNC_SELECT
if test $REPLACE_SELECT = 1; then
  AC_LIBOBJ([select])
fi
gl_SYS_SELECT_MODULE_INDICATOR([select])
AC_REQUIRE([gl_HEADER_SYS_SOCKET])
if test "$ac_cv_header_winsock2_h" = yes; then
  AC_LIBOBJ([send])
fi
gl_SYS_SOCKET_MODULE_INDICATOR([send])
AC_REQUIRE([gl_HEADER_SYS_SOCKET])
if test "$ac_cv_header_winsock2_h" = yes; then
  AC_LIBOBJ([sendto])
fi
gl_SYS_SOCKET_MODULE_INDICATOR([sendto])
gl_FUNC_SETENV
if test $HAVE_SETENV = 0 || test $REPLACE_SETENV = 1; then
  AC_LIBOBJ([setenv])
fi
gl_STDLIB_MODULE_INDICATOR([setenv])
AC_REQUIRE([gl_HEADER_SYS_SOCKET])
if test "$ac_cv_header_winsock2_h" = yes; then
  AC_LIBOBJ([setsockopt])
fi
gl_SYS_SOCKET_MODULE_INDICATOR([setsockopt])
AC_REQUIRE([gl_HEADER_SYS_SOCKET])
if test "$ac_cv_header_winsock2_h" = yes; then
  AC_LIBOBJ([shutdown])
fi
gl_SYS_SOCKET_MODULE_INDICATOR([shutdown])
gl_SIGNAL_H
AC_REQUIRE([gl_HEADER_SYS_SOCKET])
if test "$ac_cv_header_winsock2_h" = yes; then
  AC_LIBOBJ([socket])
fi
# When this module is used, sockets may actually occur as file descriptors,
# hence it is worth warning if the modules 'close' and 'ioctl' are not used.
m4_ifdef([gl_UNISTD_H_DEFAULTS], [AC_REQUIRE([gl_UNISTD_H_DEFAULTS])])
m4_ifdef([gl_SYS_IOCTL_H_DEFAULTS], [AC_REQUIRE([gl_SYS_IOCTL_H_DEFAULTS])])
AC_REQUIRE([gl_PREREQ_SYS_H_WINSOCK2])
if test "$ac_cv_header_winsock2_h" = yes; then
  UNISTD_H_HAVE_WINSOCK2_H_AND_USE_SOCKETS=1
  SYS_IOCTL_H_HAVE_WINSOCK2_H_AND_USE_SOCKETS=1
fi
gl_SYS_SOCKET_MODULE_INDICATOR([socket])
gl_SOCKETLIB
gl_SOCKETS
gl_TYPE_SOCKLEN_T
gt_TYPE_SSIZE_T
gl_FUNC_STAT
if test $REPLACE_STAT = 1; then
  AC_LIBOBJ([stat])
  gl_PREREQ_STAT
fi
gl_SYS_STAT_MODULE_INDICATOR([stat])
AM_STDBOOL_H
gl_STDDEF_H
gl_STDINT_H
gl_STDLIB_H
AC_REQUIRE([gl_HEADER_ERRNO_H])
AC_REQUIRE([gl_FUNC_STRERROR_0])
if test -n "$ERRNO_H" || test $REPLACE_STRERROR_0 = 1; then
  AC_LIBOBJ([strerror-override])
  gl_PREREQ_SYS_H_WINSOCK2
fi
gl_FUNC_STRERROR_R
if test $HAVE_DECL_STRERROR_R = 0 || test $REPLACE_STRERROR_R = 1; then
  AC_LIBOBJ([strerror_r])
  gl_PREREQ_STRERROR_R
fi
gl_STRING_MODULE_INDICATOR([strerror_r])
gl_FUNC_GNU_STRFTIME
gl_HEADER_STRING_H
gl_FUNC_STRPTIME
if test $HAVE_STRPTIME = 0; then
  AC_LIBOBJ([strptime])
  gl_PREREQ_STRPTIME
fi
gl_TIME_MODULE_INDICATOR([strptime])
gl_FUNC_STRVERSCMP
if test $HAVE_STRVERSCMP = 0; then
  AC_LIBOBJ([strverscmp])
  gl_PREREQ_STRVERSCMP
fi
gl_STRING_MODULE_INDICATOR([strverscmp])
gl_SYS_IOCTL_H
AC_PROG_MKDIR_P
gl_HEADER_SYS_SELECT
AC_PROG_MKDIR_P
gl_HEADER_SYS_SOCKET
AC_PROG_MKDIR_P
gl_HEADER_SYS_STAT_H
AC_PROG_MKDIR_P
gl_HEADER_SYS_TIME_H
AC_PROG_MKDIR_P
gl_HEADER_SYS_UIO
AC_PROG_MKDIR_P
gl_SYS_UTSNAME_H
AC_PROG_MKDIR_P
gl_SYS_WAIT_H
AC_PROG_MKDIR_P
gl_FUNC_GEN_TEMPNAME
gl_THREADLIB
gl_HEADER_TIME_H
gl_TIME_R
if test $HAVE_LOCALTIME_R = 0 || test $REPLACE_LOCALTIME_R = 1; then
  AC_LIBOBJ([time_r])
  gl_PREREQ_TIME_R
fi
gl_TIME_MODULE_INDICATOR([time_r])
gl_FUNC_UNAME
if test $HAVE_UNAME = 0; then
  AC_LIBOBJ([uname])
  gl_PREREQ_UNAME
fi
gl_SYS_UTSNAME_MODULE_INDICATOR([uname])
gl_LIBUNISTRING_LIBHEADER([0.9], [uniname.h])
gl_LIBUNISTRING_MODULE([0.9], [uniname/uniname])
gl_UNISTD_H
gl_LIBUNISTRING_LIBHEADER([0.9], [unitypes.h])
gl_LIBUNISTRING_LIBHEADER([0.9], [uniwidth.h])
gl_LIBUNISTRING_MODULE([0.9.4], [uniwidth/width])
gl_FUNC_UNSETENV
if test $HAVE_UNSETENV = 0 || test $REPLACE_UNSETENV = 1; then
  AC_LIBOBJ([unsetenv])
  gl_PREREQ_UNSETENV
fi
gl_STDLIB_MODULE_INDICATOR([unsetenv])
gl_WCHAR_H
gl_FUNC_WCRTOMB
if test $HAVE_WCRTOMB = 0 || test $REPLACE_WCRTOMB = 1; then
  AC_LIBOBJ([wcrtomb])
  gl_PREREQ_WCRTOMB
fi
gl_WCHAR_MODULE_INDICATOR([wcrtomb])
gl_WCTYPE_H
  # End of code from modules
  m4_ifval(gl_LIBSOURCES_LIST, [
    m4_syscmd([test ! -d ]m4_defn([gl_LIBSOURCES_DIR])[ ||
      for gl_file in ]gl_LIBSOURCES_LIST[ ; do
        if test ! -r ]m4_defn([gl_LIBSOURCES_DIR])[/$gl_file ; then
          echo "missing file ]m4_defn([gl_LIBSOURCES_DIR])[/$gl_file" >&2
          exit 1
        fi
      done])dnl
      m4_if(m4_sysval, [0], [],
        [AC_FATAL([expected source file, required through AC_LIBSOURCES, not found])])
  ])
  m4_popdef([gl_LIBSOURCES_DIR])
  m4_popdef([gl_LIBSOURCES_LIST])
  m4_popdef([AC_LIBSOURCES])
  m4_popdef([AC_REPLACE_FUNCS])
  m4_popdef([AC_LIBOBJ])
  AC_CONFIG_COMMANDS_PRE([
    gl_libobjs=
    gl_ltlibobjs=
    if test -n "$gl_LIBOBJS"; then
      # Remove the extension.
      sed_drop_objext='s/\.o$//;s/\.obj$//'
      for i in `for i in $gl_LIBOBJS; do echo "$i"; done | sed -e "$sed_drop_objext" | sort | uniq`; do
        gl_libobjs="$gl_libobjs $i.$ac_objext"
        gl_ltlibobjs="$gl_ltlibobjs $i.lo"
      done
    fi
    AC_SUBST([gl_LIBOBJS], [$gl_libobjs])
    AC_SUBST([gl_LTLIBOBJS], [$gl_ltlibobjs])
  ])
  gltests_libdeps=
  gltests_ltlibdeps=
  m4_pushdef([AC_LIBOBJ], m4_defn([gltests_LIBOBJ]))
  m4_pushdef([AC_REPLACE_FUNCS], m4_defn([gltests_REPLACE_FUNCS]))
  m4_pushdef([AC_LIBSOURCES], m4_defn([gltests_LIBSOURCES]))
  m4_pushdef([gltests_LIBSOURCES_LIST], [])
  m4_pushdef([gltests_LIBSOURCES_DIR], [])
  gl_COMMON
  gl_source_base='tests'
changequote(,)dnl
  gltests_WITNESS=IN_`echo "${PACKAGE-$PACKAGE_TARNAME}" | LC_ALL=C tr abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ | LC_ALL=C sed -e 's/[^A-Z0-9_]/_/g'`_GNULIB_TESTS
changequote([, ])dnl
  AC_SUBST([gltests_WITNESS])
  gl_module_indicator_condition=$gltests_WITNESS
  m4_pushdef([gl_MODULE_INDICATOR_CONDITION], [$gl_module_indicator_condition])
  m4_popdef([gl_MODULE_INDICATOR_CONDITION])
  m4_ifval(gltests_LIBSOURCES_LIST, [
    m4_syscmd([test ! -d ]m4_defn([gltests_LIBSOURCES_DIR])[ ||
      for gl_file in ]gltests_LIBSOURCES_LIST[ ; do
        if test ! -r ]m4_defn([gltests_LIBSOURCES_DIR])[/$gl_file ; then
          echo "missing file ]m4_defn([gltests_LIBSOURCES_DIR])[/$gl_file" >&2
          exit 1
        fi
      done])dnl
      m4_if(m4_sysval, [0], [],
        [AC_FATAL([expected source file, required through AC_LIBSOURCES, not found])])
  ])
  m4_popdef([gltests_LIBSOURCES_DIR])
  m4_popdef([gltests_LIBSOURCES_LIST])
  m4_popdef([AC_LIBSOURCES])
  m4_popdef([AC_REPLACE_FUNCS])
  m4_popdef([AC_LIBOBJ])
  AC_CONFIG_COMMANDS_PRE([
    gltests_libobjs=
    gltests_ltlibobjs=
    if test -n "$gltests_LIBOBJS"; then
      # Remove the extension.
      sed_drop_objext='s/\.o$//;s/\.obj$//'
      for i in `for i in $gltests_LIBOBJS; do echo "$i"; done | sed -e "$sed_drop_objext" | sort | uniq`; do
        gltests_libobjs="$gltests_libobjs $i.$ac_objext"
        gltests_ltlibobjs="$gltests_ltlibobjs $i.lo"
      done
    fi
    AC_SUBST([gltests_LIBOBJS], [$gltests_libobjs])
    AC_SUBST([gltests_LTLIBOBJS], [$gltests_ltlibobjs])
  ])
  LIBGNU_LIBDEPS="$gl_libdeps"
  AC_SUBST([LIBGNU_LIBDEPS])
  LIBGNU_LTLIBDEPS="$gl_ltlibdeps"
  AC_SUBST([LIBGNU_LTLIBDEPS])
])

# Like AC_LIBOBJ, except that the module name goes
# into gl_LIBOBJS instead of into LIBOBJS.
AC_DEFUN([gl_LIBOBJ], [
  AS_LITERAL_IF([$1], [gl_LIBSOURCES([$1.c])])dnl
  gl_LIBOBJS="$gl_LIBOBJS $1.$ac_objext"
])

# Like AC_REPLACE_FUNCS, except that the module name goes
# into gl_LIBOBJS instead of into LIBOBJS.
AC_DEFUN([gl_REPLACE_FUNCS], [
  m4_foreach_w([gl_NAME], [$1], [AC_LIBSOURCES(gl_NAME[.c])])dnl
  AC_CHECK_FUNCS([$1], , [gl_LIBOBJ($ac_func)])
])

# Like AC_LIBSOURCES, except the directory where the source file is
# expected is derived from the gnulib-tool parameterization,
# and alloca is special cased (for the alloca-opt module).
# We could also entirely rely on EXTRA_lib..._SOURCES.
AC_DEFUN([gl_LIBSOURCES], [
  m4_foreach([_gl_NAME], [$1], [
    m4_if(_gl_NAME, [alloca.c], [], [
      m4_define([gl_LIBSOURCES_DIR], [src/gllib])
      m4_append([gl_LIBSOURCES_LIST], _gl_NAME, [ ])
    ])
  ])
])

# Like AC_LIBOBJ, except that the module name goes
# into gltests_LIBOBJS instead of into LIBOBJS.
AC_DEFUN([gltests_LIBOBJ], [
  AS_LITERAL_IF([$1], [gltests_LIBSOURCES([$1.c])])dnl
  gltests_LIBOBJS="$gltests_LIBOBJS $1.$ac_objext"
])

# Like AC_REPLACE_FUNCS, except that the module name goes
# into gltests_LIBOBJS instead of into LIBOBJS.
AC_DEFUN([gltests_REPLACE_FUNCS], [
  m4_foreach_w([gl_NAME], [$1], [AC_LIBSOURCES(gl_NAME[.c])])dnl
  AC_CHECK_FUNCS([$1], , [gltests_LIBOBJ($ac_func)])
])

# Like AC_LIBSOURCES, except the directory where the source file is
# expected is derived from the gnulib-tool parameterization,
# and alloca is special cased (for the alloca-opt module).
# We could also entirely rely on EXTRA_lib..._SOURCES.
AC_DEFUN([gltests_LIBSOURCES], [
  m4_foreach([_gl_NAME], [$1], [
    m4_if(_gl_NAME, [alloca.c], [], [
      m4_define([gltests_LIBSOURCES_DIR], [tests])
      m4_append([gltests_LIBSOURCES_LIST], _gl_NAME, [ ])
    ])
  ])
])

# This macro records the list of files which have been installed by
# gnulib-tool and may be removed by future gnulib-tool invocations.
AC_DEFUN([gl_FILE_LIST], [
  build-aux/config.rpath
  build-aux/snippet/_Noreturn.h
  build-aux/snippet/arg-nonnull.h
  build-aux/snippet/c++defs.h
  build-aux/snippet/warn-on-use.h
  lib/accept.c
  lib/alignof.h
  lib/alloca.c
  lib/alloca.in.h
  lib/arpa_inet.in.h
  lib/bind.c
  lib/btowc.c
  lib/c-ctype.c
  lib/c-ctype.h
  lib/close.c
  lib/config.charset
  lib/connect.c
  lib/dosname.h
  lib/errno.in.h
  lib/fd-hook.c
  lib/fd-hook.h
  lib/fnmatch.c
  lib/fnmatch.in.h
  lib/fnmatch_loop.c
  lib/gethostname.c
  lib/getloadavg.c
  lib/getpagesize.c
  lib/getpeername.c
  lib/getsockname.c
  lib/getsockopt.c
  lib/gettext.h
  lib/gettimeofday.c
  lib/glthread/lock.c
  lib/glthread/lock.h
  lib/glthread/threadlib.c
  lib/inet_ntop.c
  lib/inet_pton.c
  lib/intprops.h
  lib/ioctl.c
  lib/langinfo.in.h
  lib/listen.c
  lib/localcharset.c
  lib/localcharset.h
  lib/lstat.c
  lib/malloc.c
  lib/malloca.c
  lib/malloca.h
  lib/malloca.valgrind
  lib/mbrtowc.c
  lib/mbsinit.c
  lib/mbsrtowcs-impl.h
  lib/mbsrtowcs-state.c
  lib/mbsrtowcs.c
  lib/mbtowc-impl.h
  lib/mbtowc.c
  lib/memchr.c
  lib/memchr.valgrind
  lib/mkdtemp.c
  lib/mkfifo.c
  lib/mknod.c
  lib/mkstemp.c
  lib/mktime-internal.h
  lib/mktime.c
  lib/netinet_in.in.h
  lib/nl_langinfo.c
  lib/readlink.c
  lib/recv.c
  lib/recvfrom.c
  lib/ref-add.sin
  lib/ref-del.sin
  lib/regcomp.c
  lib/regex.c
  lib/regex.h
  lib/regex_internal.c
  lib/regex_internal.h
  lib/regexec.c
  lib/select.c
  lib/send.c
  lib/sendto.c
  lib/setenv.c
  lib/setsockopt.c
  lib/shutdown.c
  lib/signal.in.h
  lib/socket.c
  lib/sockets.c
  lib/sockets.h
  lib/stat.c
  lib/stdbool.in.h
  lib/stddef.in.h
  lib/stdint.in.h
  lib/stdlib.in.h
  lib/streq.h
  lib/strerror-override.c
  lib/strerror-override.h
  lib/strerror_r.c
  lib/strftime.c
  lib/strftime.h
  lib/string.in.h
  lib/strnlen1.c
  lib/strnlen1.h
  lib/strptime.c
  lib/strverscmp.c
  lib/sys_ioctl.in.h
  lib/sys_select.in.h
  lib/sys_socket.in.h
  lib/sys_stat.in.h
  lib/sys_time.in.h
  lib/sys_uio.in.h
  lib/sys_utsname.in.h
  lib/sys_wait.in.h
  lib/tempname.c
  lib/tempname.h
  lib/time.in.h
  lib/time_r.c
  lib/uname.c
  lib/uniname.in.h
  lib/uniname/gen-uninames.lisp
  lib/uniname/uniname.c
  lib/uniname/uninames.h
  lib/unistd.in.h
  lib/unitypes.in.h
  lib/uniwidth.in.h
  lib/uniwidth/cjk.h
  lib/uniwidth/width.c
  lib/unsetenv.c
  lib/verify.h
  lib/w32sock.h
  lib/wchar.in.h
  lib/wcrtomb.c
  lib/wctype.in.h
  m4/00gnulib.m4
  m4/alloca.m4
  m4/arpa_inet_h.m4
  m4/btowc.m4
  m4/close.m4
  m4/codeset.m4
  m4/configmake.m4
  m4/eealloc.m4
  m4/environ.m4
  m4/errno_h.m4
  m4/extensions.m4
  m4/fcntl-o.m4
  m4/fnmatch.m4
  m4/gethostname.m4
  m4/getloadavg.m4
  m4/getpagesize.m4
  m4/gettext.m4
  m4/gettimeofday.m4
  m4/glibc2.m4
  m4/glibc21.m4
  m4/gnu-make.m4
  m4/gnulib-common.m4
  m4/host-cpu-c-abi.m4
  m4/iconv.m4
  m4/include_next.m4
  m4/inet_ntop.m4
  m4/inet_pton.m4
  m4/intdiv0.m4
  m4/intl.m4
  m4/intldir.m4
  m4/intlmacosx.m4
  m4/intmax.m4
  m4/inttypes-pri.m4
  m4/inttypes_h.m4
  m4/ioctl.m4
  m4/langinfo_h.m4
  m4/largefile.m4
  m4/lcmessage.m4
  m4/lib-ld.m4
  m4/lib-link.m4
  m4/lib-prefix.m4
  m4/libsigsegv.m4
  m4/libunistring-base.m4
  m4/link-follow.m4
  m4/localcharset.m4
  m4/locale-fr.m4
  m4/locale-ja.m4
  m4/locale-zh.m4
  m4/lock.m4
  m4/longlong.m4
  m4/lstat.m4
  m4/malloc.m4
  m4/malloca.m4
  m4/mbrtowc.m4
  m4/mbsinit.m4
  m4/mbsrtowcs.m4
  m4/mbstate_t.m4
  m4/mbtowc.m4
  m4/memchr.m4
  m4/mkdtemp.m4
  m4/mkfifo.m4
  m4/mknod.m4
  m4/mkstemp.m4
  m4/mktime.m4
  m4/mmap-anon.m4
  m4/multiarch.m4
  m4/netinet_in_h.m4
  m4/nl_langinfo.m4
  m4/nls.m4
  m4/no-c++.m4
  m4/nocrash.m4
  m4/po.m4
  m4/printf-posix.m4
  m4/progtest.m4
  m4/readlink.m4
  m4/regex.m4
  m4/select.m4
  m4/setenv.m4
  m4/signal_h.m4
  m4/size_max.m4
  m4/socketlib.m4
  m4/sockets.m4
  m4/socklen.m4
  m4/sockpfaf.m4
  m4/ssize_t.m4
  m4/stat.m4
  m4/stdbool.m4
  m4/stddef_h.m4
  m4/stdint.m4
  m4/stdint_h.m4
  m4/stdlib_h.m4
  m4/strerror.m4
  m4/strerror_r.m4
  m4/strftime.m4
  m4/string_h.m4
  m4/strptime.m4
  m4/strverscmp.m4
  m4/sys_ioctl_h.m4
  m4/sys_select_h.m4
  m4/sys_socket_h.m4
  m4/sys_stat_h.m4
  m4/sys_time_h.m4
  m4/sys_uio_h.m4
  m4/sys_utsname_h.m4
  m4/sys_wait_h.m4
  m4/tempname.m4
  m4/threadlib.m4
  m4/time_h.m4
  m4/time_r.m4
  m4/tm_gmtoff.m4
  m4/uintmax_t.m4
  m4/uname.m4
  m4/unistd_h.m4
  m4/visibility.m4
  m4/warn-on-use.m4
  m4/wchar_h.m4
  m4/wchar_t.m4
  m4/wcrtomb.m4
  m4/wctype_h.m4
  m4/wint_t.m4
  m4/xsize.m4
])
