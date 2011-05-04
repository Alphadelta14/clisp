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
# This file represents the specification of how gnulib-tool is used.
# It acts as a cache: It is written and read by gnulib-tool.
# In projects that use version control, this file is meant to be put under
# version control, like the configure.ac and various Makefile.am files.


# Specification in the form of a command-line invocation:
#   gnulib-tool --import --dir=. --lib=libgnu --source-base=modules/syscalls/gllib --m4-base=modules/syscalls/glm4 --doc-base=doc --tests-base=tests --aux-dir=src/build-aux --avoid=no-c++ --avoid=stdint --avoid=stdbool --avoid=havelib --avoid=gettext --avoid=localcharset --avoid=uniwidth/width --avoid=streq --avoid=uniname/uniname --avoid=unitypes --avoid=link-follow --avoid=host-cpu-c-abi --avoid=socklen --avoid=sockets --avoid=fd-hook --avoid=setenv --avoid=unsetenv --avoid=errno --avoid=arpa_inet --avoid=netinet_in --avoid=inet_ntop --avoid=inet_pton --avoid=nocrash --avoid=libsigsegv --avoid=gnu-make --avoid=gettimeofday --avoid=getpagesize --avoid=sys_time --avoid=sys_wait --avoid=alloca-opt --avoid=alloca --avoid=extensions --avoid=include_next --avoid=verify --avoid=string --avoid=mbsinit --avoid=wchar --avoid=wctype --avoid=mbrtowc --avoid=mbsrtowcs --avoid=memchr --avoid=nl_langinfo --avoid=xalloc-die --no-libtool --macro-prefix=sc_gl --no-vc-files mktime strerror strftime strptime strverscmp uname

# Specification in the form of a few gnulib-tool.m4 macro invocations:
gl_LOCAL_DIR([])
gl_MODULES([
  mktime
  strerror
  strftime
  strptime
  strverscmp
  uname
])
gl_AVOID([ no-c++ stdint stdbool havelib gettext localcharset uniwidth/width streq uniname/uniname unitypes link-follow host-cpu-c-abi socklen sockets fd-hook setenv unsetenv errno arpa_inet netinet_in inet_ntop inet_pton nocrash libsigsegv gnu-make gettimeofday getpagesize sys_time sys_wait alloca-opt alloca extensions include_next verify string mbsinit wchar wctype mbrtowc mbsrtowcs memchr nl_langinfo xalloc-die])
gl_SOURCE_BASE([modules/syscalls/gllib])
gl_M4_BASE([modules/syscalls/glm4])
gl_PO_BASE([])
gl_DOC_BASE([doc])
gl_TESTS_BASE([tests])
gl_LIB([libgnu])
gl_MAKEFILE_NAME([])
gl_MACRO_PREFIX([sc_gl])
gl_PO_DOMAIN([])
gl_VC_FILES([false])
