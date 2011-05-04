/* sockets.h - wrappers for Windows socket functions

   Copyright (C) 2008-2011 Free Software Foundation, Inc.

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

/* Written by Simon Josefsson */

#ifndef SOCKETS_H
# define SOCKETS_H 1

#define SOCKETS_1_0 0x100  /* don't use - does not work on Windows XP */
#define SOCKETS_1_1 0x101
#define SOCKETS_2_0 0x200  /* don't use - does not work on Windows XP */
#define SOCKETS_2_1 0x201
#define SOCKETS_2_2 0x202

int gl_sockets_startup (int version);
int gl_sockets_cleanup (void);

/* This function is useful it you create a socket using gnulib's
   Winsock wrappers but needs to pass on the socket handle to some
   other library that only accepts sockets. */
#if WINDOWS_SOCKETS

#include <sys/socket.h>

static inline SOCKET
gl_fd_to_handle (int fd)
{
  return _get_osfhandle (fd);
}

#else

#define gl_fd_to_handle(x) (x)

#endif /* WINDOWS_SOCKETS */

#endif /* SOCKETS_H */
