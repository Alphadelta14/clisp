/* Provide a sys/socket header file for systems lacking it (read: MinGW)
   and for systems where it is incomplete.
   Copyright (C) 2005-2010 Free Software Foundation, Inc.
   Written by Simon Josefsson.

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

/* This file is supposed to be used on platforms that lack <sys/socket.h>,
   on platforms where <sys/socket.h> cannot be included standalone, and on
   platforms where <sys/socket.h> does not provide all necessary definitions.
   It is intended to provide definitions and prototypes needed by an
   application.  */

#if defined _sc_gl_GL_ALREADY_INCLUDING_SYS_SOCKET_H
/* Special invocation convention:
   - On Cygwin 1.5.x we have a sequence of nested includes
     <sys/socket.h> -> <cygwin/socket.h> -> <asm/socket.h> -> <cygwin/if.h>,
     and the latter includes <sys/socket.h>.  In this situation, the functions
     are not yet declared, therefore we cannot provide the C++ aliases.  */

#@INCLUDE_NEXT@ @NEXT_SYS_SOCKET_H@

#else
/* Normal invocation convention.  */

#ifndef _sc_gl_GL_SYS_SOCKET_H

#if @HAVE_SYS_SOCKET_H@

# define _sc_gl_GL_ALREADY_INCLUDING_SYS_SOCKET_H

# if __GNUC__ >= 3
@PRAGMA_SYSTEM_HEADER@
# endif

/* On many platforms, <sys/socket.h> assumes prior inclusion of
   <sys/types.h>.  */
# include <sys/types.h>

/* The include_next requires a split double-inclusion guard.  */
# @INCLUDE_NEXT@ @NEXT_SYS_SOCKET_H@

# undef _sc_gl_GL_ALREADY_INCLUDING_SYS_SOCKET_H

#endif

#ifndef _sc_gl_GL_SYS_SOCKET_H
#define _sc_gl_GL_SYS_SOCKET_H

/* The definitions of _sc_gl_GL_FUNCDECL_RPL etc. are copied here.  */

/* The definition of _sc_gl_GL_ARG_NONNULL is copied here.  */

/* The definition of _sc_gl_GL_WARN_ON_USE is copied here.  */

#if !@HAVE_SA_FAMILY_T@
typedef unsigned short  sa_family_t;
#endif

#if !@HAVE_STRUCT_SOCKADDR_STORAGE@
# include <alignof.h>
/* Code taken from glibc sysdeps/unix/sysv/linux/bits/socket.h on
   2009-05-08, licensed under LGPLv2.1+, plus portability fixes. */
# define __ss_aligntype unsigned long int
# define _SS_SIZE 256
# define _SS_PADSIZE \
    (_SS_SIZE - ((sizeof (sa_family_t) >= alignof (__ss_aligntype)      \
                  ? sizeof (sa_family_t)                                \
                  : alignof (__ss_aligntype))                           \
                 + sizeof (__ss_aligntype)))

struct sockaddr_storage
{
  sa_family_t ss_family;      /* Address family, etc.  */
  __ss_aligntype __ss_align;  /* Force desired alignment.  */
  char __ss_padding[_SS_PADSIZE];
};
#endif

#if @HAVE_SYS_SOCKET_H@

/* A platform that has <sys/socket.h>.  */

/* For shutdown().  */
# if !defined SHUT_RD
#  define SHUT_RD 0
# endif
# if !defined SHUT_WR
#  define SHUT_WR 1
# endif
# if !defined SHUT_RDWR
#  define SHUT_RDWR 2
# endif

#else

# ifdef __CYGWIN__
#  error "Cygwin does have a sys/socket.h, doesn't it?!?"
# endif

/* A platform that lacks <sys/socket.h>.

   Currently only MinGW is supported.  See the gnulib manual regarding
   Windows sockets.  MinGW has the header files winsock2.h and
   ws2tcpip.h that declare the sys/socket.h definitions we need.  Note
   that you can influence which definitions you get by setting the
   WINVER symbol before including these two files.  For example,
   getaddrinfo is only available if _WIN32_WINNT >= 0x0501 (that
   symbol is set indiriectly through WINVER).  You can set this by
   adding AC_DEFINE(WINVER, 0x0501) to configure.ac.  Note that your
   code may not run on older Windows releases then.  My Windows 2000
   box was not able to run the code, for example.  The situation is
   slightly confusing because:
   http://msdn.microsoft.com/library/default.asp?url=/library/en-us/winsock/winsock/getaddrinfo_2.asp
   suggests that getaddrinfo should be available on all Windows
   releases. */


# if @HAVE_WINSOCK2_H@
#  include <winsock2.h>
# endif
# if @HAVE_WS2TCPIP_H@
#  include <ws2tcpip.h>
# endif

/* For shutdown(). */
# if !defined SHUT_RD && defined SD_RECEIVE
#  define SHUT_RD SD_RECEIVE
# endif
# if !defined SHUT_WR && defined SD_SEND
#  define SHUT_WR SD_SEND
# endif
# if !defined SHUT_RDWR && defined SD_BOTH
#  define SHUT_RDWR SD_BOTH
# endif

# if @HAVE_WINSOCK2_H@
/* Include headers needed by the emulation code.  */
#  include <sys/types.h>
#  include <io.h>

typedef int socklen_t;

# endif

#endif

#if @HAVE_WINSOCK2_H@

/* Re-define FD_ISSET to avoid a WSA call while we are not using
   network sockets.  */
static inline int
rpl_fd_isset (SOCKET fd, fd_set * set)
{
  u_int i;
  if (set == NULL)
    return 0;

  for (i = 0; i < set->fd_count; i++)
    if (set->fd_array[i] == fd)
      return 1;

  return 0;
}

# undef FD_ISSET
# define FD_ISSET(fd, set) rpl_fd_isset(fd, set)

#endif

/* Wrap everything else to use libc file descriptors for sockets.  */

#if @HAVE_WINSOCK2_H@ && !defined _sc_gl_GL_UNISTD_H
# undef close
# define close close_used_without_including_unistd_h
#endif

#if @HAVE_WINSOCK2_H@ && !defined _sc_gl_GL_UNISTD_H
# undef gethostname
# define gethostname gethostname_used_without_including_unistd_h
#endif

#if @GNULIB_SOCKET@
# if @HAVE_WINSOCK2_H@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef socket
#   define socket rpl_socket
#  endif
_sc_gl_GL_FUNCDECL_RPL (socket, int, (int domain, int type, int protocol));
_sc_gl_GL_CXXALIAS_RPL (socket, int, (int domain, int type, int protocol));
# else
_sc_gl_GL_CXXALIAS_SYS (socket, int, (int domain, int type, int protocol));
# endif
_sc_gl_GL_CXXALIASWARN (socket);
#elif @HAVE_WINSOCK2_H@
# undef socket
# define socket socket_used_without_requesting_gnulib_module_socket
#elif defined GNULIB_POSIXCHECK
# undef socket
# if HAVE_RAW_DECL_SOCKET
_sc_gl_GL_WARN_ON_USE (socket, "socket is not always POSIX compliant - "
                 "use gnulib module socket for portability");
# endif
#endif

#if @GNULIB_CONNECT@
# if @HAVE_WINSOCK2_H@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef connect
#   define connect rpl_connect
#  endif
_sc_gl_GL_FUNCDECL_RPL (connect, int,
                  (int fd, const struct sockaddr *addr, socklen_t addrlen)
                  _sc_gl_GL_ARG_NONNULL ((2)));
_sc_gl_GL_CXXALIAS_RPL (connect, int,
                  (int fd, const struct sockaddr *addr, socklen_t addrlen));
# else
_sc_gl_GL_CXXALIAS_SYS (connect, int,
                  (int fd, const struct sockaddr *addr, socklen_t addrlen));
# endif
_sc_gl_GL_CXXALIASWARN (connect);
#elif @HAVE_WINSOCK2_H@
# undef connect
# define connect socket_used_without_requesting_gnulib_module_connect
#elif defined GNULIB_POSIXCHECK
# undef connect
# if HAVE_RAW_DECL_CONNECT
_sc_gl_GL_WARN_ON_USE (connect, "connect is not always POSIX compliant - "
                 "use gnulib module connect for portability");
# endif
#endif

#if @GNULIB_ACCEPT@
# if @HAVE_WINSOCK2_H@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef accept
#   define accept rpl_accept
#  endif
_sc_gl_GL_FUNCDECL_RPL (accept, int,
                  (int fd, struct sockaddr *addr, socklen_t *addrlen));
_sc_gl_GL_CXXALIAS_RPL (accept, int,
                  (int fd, struct sockaddr *addr, socklen_t *addrlen));
# else
/* Need to cast, because on Solaris 10 systems, the third parameter is
                                                       void *addrlen.  */
_sc_gl_GL_CXXALIAS_SYS_CAST (accept, int,
                       (int fd, struct sockaddr *addr, socklen_t *addrlen));
# endif
_sc_gl_GL_CXXALIASWARN (accept);
#elif @HAVE_WINSOCK2_H@
# undef accept
# define accept accept_used_without_requesting_gnulib_module_accept
#elif defined GNULIB_POSIXCHECK
# undef accept
# if HAVE_RAW_DECL_ACCEPT
_sc_gl_GL_WARN_ON_USE (accept, "accept is not always POSIX compliant - "
                 "use gnulib module accept for portability");
# endif
#endif

#if @GNULIB_BIND@
# if @HAVE_WINSOCK2_H@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef bind
#   define bind rpl_bind
#  endif
_sc_gl_GL_FUNCDECL_RPL (bind, int,
                  (int fd, const struct sockaddr *addr, socklen_t addrlen)
                  _sc_gl_GL_ARG_NONNULL ((2)));
_sc_gl_GL_CXXALIAS_RPL (bind, int,
                  (int fd, const struct sockaddr *addr, socklen_t addrlen));
# else
_sc_gl_GL_CXXALIAS_SYS (bind, int,
                  (int fd, const struct sockaddr *addr, socklen_t addrlen));
# endif
_sc_gl_GL_CXXALIASWARN (bind);
#elif @HAVE_WINSOCK2_H@
# undef bind
# define bind bind_used_without_requesting_gnulib_module_bind
#elif defined GNULIB_POSIXCHECK
# undef bind
# if HAVE_RAW_DECL_BIND
_sc_gl_GL_WARN_ON_USE (bind, "bind is not always POSIX compliant - "
                 "use gnulib module bind for portability");
# endif
#endif

#if @GNULIB_GETPEERNAME@
# if @HAVE_WINSOCK2_H@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef getpeername
#   define getpeername rpl_getpeername
#  endif
_sc_gl_GL_FUNCDECL_RPL (getpeername, int,
                  (int fd, struct sockaddr *addr, socklen_t *addrlen)
                  _sc_gl_GL_ARG_NONNULL ((2, 3)));
_sc_gl_GL_CXXALIAS_RPL (getpeername, int,
                  (int fd, struct sockaddr *addr, socklen_t *addrlen));
# else
/* Need to cast, because on Solaris 10 systems, the third parameter is
                                                       void *addrlen.  */
_sc_gl_GL_CXXALIAS_SYS_CAST (getpeername, int,
                       (int fd, struct sockaddr *addr, socklen_t *addrlen));
# endif
_sc_gl_GL_CXXALIASWARN (getpeername);
#elif @HAVE_WINSOCK2_H@
# undef getpeername
# define getpeername getpeername_used_without_requesting_gnulib_module_getpeername
#elif defined GNULIB_POSIXCHECK
# undef getpeername
# if HAVE_RAW_DECL_GETPEERNAME
_sc_gl_GL_WARN_ON_USE (getpeername, "getpeername is not always POSIX compliant - "
                 "use gnulib module getpeername for portability");
# endif
#endif

#if @GNULIB_GETSOCKNAME@
# if @HAVE_WINSOCK2_H@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef getsockname
#   define getsockname rpl_getsockname
#  endif
_sc_gl_GL_FUNCDECL_RPL (getsockname, int,
                  (int fd, struct sockaddr *addr, socklen_t *addrlen)
                  _sc_gl_GL_ARG_NONNULL ((2, 3)));
_sc_gl_GL_CXXALIAS_RPL (getsockname, int,
                  (int fd, struct sockaddr *addr, socklen_t *addrlen));
# else
/* Need to cast, because on Solaris 10 systems, the third parameter is
                                                       void *addrlen.  */
_sc_gl_GL_CXXALIAS_SYS_CAST (getsockname, int,
                       (int fd, struct sockaddr *addr, socklen_t *addrlen));
# endif
_sc_gl_GL_CXXALIASWARN (getsockname);
#elif @HAVE_WINSOCK2_H@
# undef getsockname
# define getsockname getsockname_used_without_requesting_gnulib_module_getsockname
#elif defined GNULIB_POSIXCHECK
# undef getsockname
# if HAVE_RAW_DECL_GETSOCKNAME
_sc_gl_GL_WARN_ON_USE (getsockname, "getsockname is not always POSIX compliant - "
                 "use gnulib module getsockname for portability");
# endif
#endif

#if @GNULIB_GETSOCKOPT@
# if @HAVE_WINSOCK2_H@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef getsockopt
#   define getsockopt rpl_getsockopt
#  endif
_sc_gl_GL_FUNCDECL_RPL (getsockopt, int, (int fd, int level, int optname,
                                    void *optval, socklen_t *optlen)
                                   _sc_gl_GL_ARG_NONNULL ((4, 5)));
_sc_gl_GL_CXXALIAS_RPL (getsockopt, int, (int fd, int level, int optname,
                                    void *optval, socklen_t *optlen));
# else
/* Need to cast, because on Solaris 10 systems, the fifth parameter is
                                                       void *optlen.  */
_sc_gl_GL_CXXALIAS_SYS_CAST (getsockopt, int, (int fd, int level, int optname,
                                         void *optval, socklen_t *optlen));
# endif
_sc_gl_GL_CXXALIASWARN (getsockopt);
#elif @HAVE_WINSOCK2_H@
# undef getsockopt
# define getsockopt getsockopt_used_without_requesting_gnulib_module_getsockopt
#elif defined GNULIB_POSIXCHECK
# undef getsockopt
# if HAVE_RAW_DECL_GETSOCKOPT
_sc_gl_GL_WARN_ON_USE (getsockopt, "getsockopt is not always POSIX compliant - "
                 "use gnulib module getsockopt for portability");
# endif
#endif

#if @GNULIB_LISTEN@
# if @HAVE_WINSOCK2_H@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef listen
#   define listen rpl_listen
#  endif
_sc_gl_GL_FUNCDECL_RPL (listen, int, (int fd, int backlog));
_sc_gl_GL_CXXALIAS_RPL (listen, int, (int fd, int backlog));
# else
_sc_gl_GL_CXXALIAS_SYS (listen, int, (int fd, int backlog));
# endif
_sc_gl_GL_CXXALIASWARN (listen);
#elif @HAVE_WINSOCK2_H@
# undef listen
# define listen listen_used_without_requesting_gnulib_module_listen
#elif defined GNULIB_POSIXCHECK
# undef listen
# if HAVE_RAW_DECL_LISTEN
_sc_gl_GL_WARN_ON_USE (listen, "listen is not always POSIX compliant - "
                 "use gnulib module listen for portability");
# endif
#endif

#if @GNULIB_RECV@
# if @HAVE_WINSOCK2_H@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef recv
#   define recv rpl_recv
#  endif
_sc_gl_GL_FUNCDECL_RPL (recv, ssize_t, (int fd, void *buf, size_t len, int flags)
                                 _sc_gl_GL_ARG_NONNULL ((2)));
_sc_gl_GL_CXXALIAS_RPL (recv, ssize_t, (int fd, void *buf, size_t len, int flags));
# else
_sc_gl_GL_CXXALIAS_SYS (recv, ssize_t, (int fd, void *buf, size_t len, int flags));
# endif
_sc_gl_GL_CXXALIASWARN (recv);
#elif @HAVE_WINSOCK2_H@
# undef recv
# define recv recv_used_without_requesting_gnulib_module_recv
#elif defined GNULIB_POSIXCHECK
# undef recv
# if HAVE_RAW_DECL_RECV
_sc_gl_GL_WARN_ON_USE (recv, "recv is not always POSIX compliant - "
                 "use gnulib module recv for portability");
# endif
#endif

#if @GNULIB_SEND@
# if @HAVE_WINSOCK2_H@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef send
#   define send rpl_send
#  endif
_sc_gl_GL_FUNCDECL_RPL (send, ssize_t,
                  (int fd, const void *buf, size_t len, int flags)
                  _sc_gl_GL_ARG_NONNULL ((2)));
_sc_gl_GL_CXXALIAS_RPL (send, ssize_t,
                  (int fd, const void *buf, size_t len, int flags));
# else
_sc_gl_GL_CXXALIAS_SYS (send, ssize_t,
                  (int fd, const void *buf, size_t len, int flags));
# endif
_sc_gl_GL_CXXALIASWARN (send);
#elif @HAVE_WINSOCK2_H@
# undef send
# define send send_used_without_requesting_gnulib_module_send
#elif defined GNULIB_POSIXCHECK
# undef send
# if HAVE_RAW_DECL_SEND
_sc_gl_GL_WARN_ON_USE (send, "send is not always POSIX compliant - "
                 "use gnulib module send for portability");
# endif
#endif

#if @GNULIB_RECVFROM@
# if @HAVE_WINSOCK2_H@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef recvfrom
#   define recvfrom rpl_recvfrom
#  endif
_sc_gl_GL_FUNCDECL_RPL (recvfrom, ssize_t,
                  (int fd, void *buf, size_t len, int flags,
                   struct sockaddr *from, socklen_t *fromlen)
                  _sc_gl_GL_ARG_NONNULL ((2)));
_sc_gl_GL_CXXALIAS_RPL (recvfrom, ssize_t,
                  (int fd, void *buf, size_t len, int flags,
                   struct sockaddr *from, socklen_t *fromlen));
# else
/* Need to cast, because on Solaris 10 systems, the sixth parameter is
                                               void *fromlen.  */
_sc_gl_GL_CXXALIAS_SYS_CAST (recvfrom, ssize_t,
                       (int fd, void *buf, size_t len, int flags,
                        struct sockaddr *from, socklen_t *fromlen));
# endif
_sc_gl_GL_CXXALIASWARN (recvfrom);
#elif @HAVE_WINSOCK2_H@
# undef recvfrom
# define recvfrom recvfrom_used_without_requesting_gnulib_module_recvfrom
#elif defined GNULIB_POSIXCHECK
# undef recvfrom
# if HAVE_RAW_DECL_RECVFROM
_sc_gl_GL_WARN_ON_USE (recvfrom, "recvfrom is not always POSIX compliant - "
                 "use gnulib module recvfrom for portability");
# endif
#endif

#if @GNULIB_SENDTO@
# if @HAVE_WINSOCK2_H@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef sendto
#   define sendto rpl_sendto
#  endif
_sc_gl_GL_FUNCDECL_RPL (sendto, ssize_t,
                  (int fd, const void *buf, size_t len, int flags,
                   const struct sockaddr *to, socklen_t tolen)
                  _sc_gl_GL_ARG_NONNULL ((2)));
_sc_gl_GL_CXXALIAS_RPL (sendto, ssize_t,
                  (int fd, const void *buf, size_t len, int flags,
                   const struct sockaddr *to, socklen_t tolen));
# else
_sc_gl_GL_CXXALIAS_SYS (sendto, ssize_t,
                  (int fd, const void *buf, size_t len, int flags,
                   const struct sockaddr *to, socklen_t tolen));
# endif
_sc_gl_GL_CXXALIASWARN (sendto);
#elif @HAVE_WINSOCK2_H@
# undef sendto
# define sendto sendto_used_without_requesting_gnulib_module_sendto
#elif defined GNULIB_POSIXCHECK
# undef sendto
# if HAVE_RAW_DECL_SENDTO
_sc_gl_GL_WARN_ON_USE (sendto, "sendto is not always POSIX compliant - "
                 "use gnulib module sendto for portability");
# endif
#endif

#if @GNULIB_SETSOCKOPT@
# if @HAVE_WINSOCK2_H@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef setsockopt
#   define setsockopt rpl_setsockopt
#  endif
_sc_gl_GL_FUNCDECL_RPL (setsockopt, int, (int fd, int level, int optname,
                                    const void * optval, socklen_t optlen)
                                   _sc_gl_GL_ARG_NONNULL ((4)));
_sc_gl_GL_CXXALIAS_RPL (setsockopt, int, (int fd, int level, int optname,
                                    const void * optval, socklen_t optlen));
# else
_sc_gl_GL_CXXALIAS_SYS (setsockopt, int, (int fd, int level, int optname,
                                    const void * optval, socklen_t optlen));
# endif
_sc_gl_GL_CXXALIASWARN (setsockopt);
#elif @HAVE_WINSOCK2_H@
# undef setsockopt
# define setsockopt setsockopt_used_without_requesting_gnulib_module_setsockopt
#elif defined GNULIB_POSIXCHECK
# undef setsockopt
# if HAVE_RAW_DECL_SETSOCKOPT
_sc_gl_GL_WARN_ON_USE (setsockopt, "setsockopt is not always POSIX compliant - "
                 "use gnulib module setsockopt for portability");
# endif
#endif

#if @GNULIB_SHUTDOWN@
# if @HAVE_WINSOCK2_H@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef shutdown
#   define shutdown rpl_shutdown
#  endif
_sc_gl_GL_FUNCDECL_RPL (shutdown, int, (int fd, int how));
_sc_gl_GL_CXXALIAS_RPL (shutdown, int, (int fd, int how));
# else
_sc_gl_GL_CXXALIAS_SYS (shutdown, int, (int fd, int how));
# endif
_sc_gl_GL_CXXALIASWARN (shutdown);
#elif @HAVE_WINSOCK2_H@
# undef shutdown
# define shutdown shutdown_used_without_requesting_gnulib_module_shutdown
#elif defined GNULIB_POSIXCHECK
# undef shutdown
# if HAVE_RAW_DECL_SHUTDOWN
_sc_gl_GL_WARN_ON_USE (shutdown, "shutdown is not always POSIX compliant - "
                 "use gnulib module shutdown for portability");
# endif
#endif

#if @HAVE_WINSOCK2_H@
# undef select
# define select                select_used_without_including_sys_select_h
#endif

#if @GNULIB_ACCEPT4@
/* Accept a connection on a socket, with specific opening flags.
   The flags are a bitmask, possibly including O_CLOEXEC (defined in <fcntl.h>)
   and O_TEXT, O_BINARY (defined in "binary-io.h").
   See also the Linux man page at
   <http://www.kernel.org/doc/man-pages/online/pages/man2/accept4.2.html>.  */
# if @HAVE_ACCEPT4@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define accept4 rpl_accept4
#  endif
_sc_gl_GL_FUNCDECL_RPL (accept4, int,
                  (int sockfd, struct sockaddr *addr, socklen_t *addrlen,
                   int flags));
_sc_gl_GL_CXXALIAS_RPL (accept4, int,
                  (int sockfd, struct sockaddr *addr, socklen_t *addrlen,
                   int flags));
# else
_sc_gl_GL_FUNCDECL_SYS (accept4, int,
                  (int sockfd, struct sockaddr *addr, socklen_t *addrlen,
                   int flags));
_sc_gl_GL_CXXALIAS_SYS (accept4, int,
                  (int sockfd, struct sockaddr *addr, socklen_t *addrlen,
                   int flags));
# endif
_sc_gl_GL_CXXALIASWARN (accept4);
#elif defined GNULIB_POSIXCHECK
# undef accept4
# if HAVE_RAW_DECL_ACCEPT4
_sc_gl_GL_WARN_ON_USE (accept4, "accept4 is unportable - "
                 "use gnulib module accept4 for portability");
# endif
#endif

#endif /* _sc_gl_GL_SYS_SOCKET_H */
#endif /* _sc_gl_GL_SYS_SOCKET_H */
#endif
