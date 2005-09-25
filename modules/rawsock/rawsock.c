/*
 * Module for Raw Sockets / CLISP
 * Fred Cohen, 2003-2004
 * Don Cohen, 2003-2004
 * Sam Steingold 2004-2005
 * Bruno Haible 2004-2005
 * <http://www.opengroup.org/onlinepubs/007908799/xns/syssocket.h.html>
 */

#include "clisp.h"

#include "config.h"

#if defined(TIME_WITH_SYS_TIME)
# include <sys/time.h>
# include <time.h>
#else
# if defined(HAVE_SYS_TIME_H)
#  include <sys/time.h>
# elif defined(HAVE_TIME_H)
#  include <time.h>
# endif
#endif
#if defined(HAVE_SYS_TYPES_H)
# include <sys/types.h>
#endif
#if defined(STDC_HEADERS)
# include <stdio.h>
# include <unistd.h>
# include <string.h>            /* for memcpy(3) */
# include <stddef.h>            /* for offsetof */
#endif
#if defined(HAVE_SYS_SOCKET_H)
# include <sys/socket.h>
#endif
#if defined(HAVE_NETINET_IN_H)
# include <netinet/in.h>
#endif
#if defined(HAVE_ARPA_INET_H)
# include <arpa/inet.h>
#endif
#if defined(HAVE_LINUX_IF_PACKET_H)
# include <linux/if_packet.h>
#endif
#if defined(HAVE_NET_IF_H)
# include <net/if.h>
#endif
#if defined(HAVE_NETINET_IF_ETHER_H)
# include <netinet/if_ether.h>
#endif
#if defined(HAVE_SYS_IOCTL_H)
# include <sys/ioctl.h>
#endif
#if defined(HAVE_SYS_UN_H)
# include <sys/un.h>
#endif
#if defined(HAVE_ERRNO_H)
# include <errno.h>
#endif
#if defined(HAVE_STROPS_H)
# include <stropts.h>
#endif
#if defined(HAVE_POLL_H)
# include <poll.h>
#endif
#if defined(HAVE_WINSOCK2_H)
# include <winsock2.h>
#endif
#if defined(HAVE_WS2TCPIP_H)
# include <ws2tcpip.h>
#endif
typedef SOCKET rawsock_t;

DEFMODULE(rawsock,"RAWSOCK")

/* ================== helpers ================== */
/* can trigger GC */
static object my_check_argument (object name, object datum) {
  pushSTACK(NIL);               /* no PLACE */
  pushSTACK(name); pushSTACK(datum); pushSTACK(TheSubr(subr_self)->name);
  check_value(error,GETTEXT("~S: ~S is not a valid ~S argument"));
  return value1;
}
/* can trigger GC */
static object check_buffer_arg (object arg) {
  while (1) {
    if (missingp(arg)) return O(buffer);
    if (simple_bit_vector_p(Atype_8Bit,arg)) return arg;
    arg = check_classname(arg,S(simple_bit_vector));
  }
}
/* DANGER: the return value is invalidated by GC!
 can trigger GC */
static void* parse_buffer_arg (gcv_object_t *arg_, size_t *size) {
  *arg_ = check_buffer_arg(*arg_);
  *size = Sbvector_length(*arg_);
  return (void*)TheSbvector(*arg_)->data;
}
/* DANGER: the return value is invalidated by GC!
 can trigger GC */
static void* check_struct_data (object type, object arg, SOCKLEN_T *size) {
  object vec = TheStructure(check_classname(arg,type))->recdata[1];
  *size = Sbvector_length(vec);
  return (void*)TheSbvector(vec)->data;
}

DEFVAR(buffer,`#.(MAKE-ARRAY 1518 :ELEMENT-TYPE (QUOTE (UNSIGNED-BYTE 8)))`);
DEFUN(RAWSOCK:BUFFER,) { VALUES1(O(buffer)); }
DEFUN(RAWSOCK:RESIZE-BUFFER,new-size) {
  /* new-size is already STACK_0 */
  pushSTACK(S(Kelement_type)); pushSTACK(`(UNSIGNED-BYTE 8)`);
  funcall(L(make_array),3);
  O(buffer)=value1;
}

DEFUN(RAWSOCK:SOCKADDR-FAMILY, sa) {
  SOCKLEN_T size;
  struct sockaddr *sa =
    (struct sockaddr*)check_struct_data(`RAWSOCK::SOCKADDR`,popSTACK(),&size);
  VALUES2(fixnum(sa->sa_family),fixnum(size));
}
DEFUN(RAWSOCK:SOCKADDR-SLOT,&optional slot) {
  /* return offset & size of the slo in SOCKADDR */
 restart_sockaddr_slot:
  if (missingp(STACK_0)) {
    VALUES1(fixnum(sizeof(struct sockaddr)));
  } else if (eq(STACK_0,`:FAMILY`)) {
    struct sockaddr sa;
    VALUES2(fixnum(offsetof(struct sockaddr,sa_family)),
            fixnum(sizeof(sa.sa_family)));
  } else if (eq(STACK_0,`:DATA`)) {
    struct sockaddr sa;
    VALUES2(fixnum(offsetof(struct sockaddr,sa_data)),
            fixnum(sizeof(sa.sa_data)));
  } else {
    pushSTACK(NIL);             /* no PLACE */
    pushSTACK(STACK_1);         /* TYPE-ERROR slot DATUM */
    pushSTACK(`(MEMBER :FAMILY :DATA)`); /* TYPE-ERROR slot EXPECTED-TYPE */
    pushSTACK(`SOCKADDR`); pushSTACK(STACK_2);
    pushSTACK(TheSubr(subr_self)->name);
    check_value(type_error,GETTEXT("~S: unknown slot ~S for ~S"));
    STACK_0 = value1;
    goto restart_sockaddr_slot;
  }
  skipSTACK(1);
}

/* can trigger GC */
static object make_sockaddr (void) {
  pushSTACK(allocate_bit_vector(Atype_8Bit,sizeof(struct sockaddr)));
  funcall(`RAWSOCK::MAKE-SA`,1);
  return value1;
}

DEFUN(RAWSOCK:MAKE-SOCKADDR,family data) {
  int family = check_socket_domain(STACK_1);
  struct sockaddr sa;
  unsigned char *buffer;
  size_t buffer_len, data_start = offsetof(struct sockaddr,sa_data);
  STACK_0 = check_buffer_arg(STACK_0);
  buffer_len = Sbvector_length(STACK_0);
  pushSTACK(allocate_bit_vector(Atype_8Bit,data_start + buffer_len));
  buffer = (unsigned char *)TheSbvector(STACK_0)->data;
  begin_system_call();
  memset(buffer,0,data_start + buffer_len);
  memcpy(((struct sockaddr*)buffer)->sa_data,TheSbvector(STACK_1)->data,
         buffer_len);
  end_system_call();
  ((struct sockaddr*)buffer)->sa_family = family;
  funcall(`RAWSOCK::MAKE-SA`,1);
  skipSTACK(2);
}

/* invoke system call C, place return value in R, report error on socket S */
#define SYSCALL(r,s,c)                                  \
  do { begin_system_call(); r = c; end_system_call();   \
    if (r == -1) {                                      \
      if (s<=0) OS_error();                             \
      else OS_file_error(fixnum(s));                    \
    }                                                   \
  } while(0)

/* ================== arpa/inet.h interface ================== */
/* Define even when the OS lacks the C functions; in that case,
   we emulate the C functions. */
DEFUN(RAWSOCK:HTONL, num) {
  uint32 arg = I_to_uint32(check_uint32(popSTACK()));
  uint32 result;
#if defined(HAVE_HTONL)
  begin_system_call(); result = htonl(arg); end_system_call();
#else
  union { struct { uint8 octet3; uint8 octet2; uint8 octet1; uint8 octet0; } o;
          uint32 all;
        }
        word;
  word.all = arg;
  result = ((uint32)word.o.octet3 << 24) | ((uint32)word.o.octet2 << 16)
           | ((uint32)word.o.octet1 << 8) | (uint32)word.o.octet0;
#endif
  VALUES1(uint32_to_I(result));
}
DEFUN(RAWSOCK:NTOHL, num) {
  uint32 arg = I_to_uint32(check_uint32(popSTACK()));
  uint32 result;
#if defined(HAVE_NTOHL)
  begin_system_call(); result = ntohl(arg); end_system_call();
#else
  union { struct { uint8 octet3; uint8 octet2; uint8 octet1; uint8 octet0; } o;
          uint32 all;
        }
        word;
  word.o.octet3 = (arg >> 24) & 0xff;
  word.o.octet2 = (arg >> 16) & 0xff;
  word.o.octet1 = (arg >> 8) & 0xff;
  word.o.octet0 = arg & 0xff;
  result = word.all;
#endif
  VALUES1(uint32_to_I(result));
}
DEFUN(RAWSOCK:HTONS, num) {
  uint16 arg = I_to_uint16(check_uint16(popSTACK()));
  uint16 result;
#if defined(HAVE_HTONS)
  begin_system_call(); result = htons(arg); end_system_call();
#else
  union { struct { uint8 octet1; uint8 octet0; } o;
          uint16 all;
        }
        word;
  word.all = arg;
  result = ((uint16)word.o.octet1 << 8) | (uint16)word.o.octet0;
#endif
  VALUES1(uint16_to_I(result));
}
DEFUN(RAWSOCK:NTOHS, num) {
  uint16 arg = I_to_uint16(check_uint16(popSTACK()));
  uint16 result;
#if defined(HAVE_NTOHS)
  begin_system_call(); result = ntohs(arg); end_system_call();
#else
  union { struct { uint8 octet1; uint8 octet0; } o;
          uint16 all;
        }
        word;
  word.o.octet1 = (arg >> 8) & 0xff;
  word.o.octet0 = arg & 0xff;
  result = word.all;
#endif
  VALUES1(uint16_to_I(result));
}
DEFUN(RAWSOCK:CONVERT-ADDRESS, family address) {
  int family = check_socket_domain(STACK_1);
  if (stringp(STACK_0)) {
    with_string_0(STACK_0,Symbol_value(S(utf_8)),ip_address,
                  { value1 = string_to_addr(ip_address); });
  } else if (integerp(STACK_0)) {
    switch (family) {
     #if defined(AF_INET6)
      case AF_INET6: {
        uint64 ip_address = I_to_uint64(check_uint64(STACK_0));
        value1 = addr_to_string(family,(char*)&ip_address);
      } break;
     #endif
      case AF_INET: {
        uint32 ip_address = I_to_uint32(check_uint32(STACK_0));
        value1 = addr_to_string(family,(char*)&ip_address);
      } break;
      default: value1 = NIL;
    }
  } else fehler_string_integer(STACK_0);
  if (nullp(value1)) {
    pushSTACK(STACK_1);         /* domain */
    pushSTACK(STACK_1);         /* address */
    pushSTACK(TheSubr(subr_self)->name);
    fehler(error,GETTEXT("~S: invalid address ~S for family ~S"));
  }
  skipSTACK(2); mv_count = 1;
}

/* ================== sys/socket.h interface ================== */
DEFCHECKER(check_socket_domain,prefix=AF,default=AF_UNSPEC,            \
           UNSPEC UNIX LOCAL INET AX25                                  \
           IPX APPLETALK NETROM BRIDGE ATMPVC X25 INET6                 \
           ROSE DECnet NETBEUI SECURITY KEY NETLINK                     \
           ROUTE PACKET ASH ECONET ATMSVC SNA IRDA                      \
           PPPOX WANPIPE BLUETOOTH)
DEFCHECKER(check_socket_type,prefix=SOCK,default=SOCK_STREAM,          \
           STREAM DGRAM RAW RDM SEQPACKET PACKET)
DEFCHECKER(check_socket_protocol,prefix=ETH_P, default=0,              \
           LOOP PUP PUPAT IP X25 ARP BPQ                                \
           IEEEPUP IEEEPUPAT DEC DNA-DL DNA-RC DNA-RT LAT DIAG CUST SCA \
           RARP ATALK AARP IPX IPV6 PPP-DISC PPP-SES ATMMPOA ATMFATE 802-3 \
           AX25 ALL 802-2 SNAP DDCMP WAN-PPP PPP-MP LOCALTALK PPPTALK   \
           TR-802-2 MOBITEX CONTROL IRDA ECONET)

DEFUN(RAWSOCK:SOCKET,domain type protocol) {
  rawsock_t sock;
  int protocol = check_socket_protocol(popSTACK());
  int type = check_socket_type(popSTACK());
  int domain = check_socket_domain(popSTACK());
  SYSCALL(sock,-1,socket(domain,type,protocol));
  VALUES1(fixnum(sock));
}

#if defined(HAVE_SOCKETPAIR)    /* not on win32 */
DEFUN(RAWSOCK:SOCKETPAIR,domain type protocol) {
  rawsock_t sock[2];
  int retval;
  int protocol = check_socket_protocol(popSTACK());
  int type = check_socket_type(popSTACK());
  int domain = check_socket_domain(popSTACK());
  SYSCALL(retval,-1,socketpair(domain,type,protocol,sock));
  VALUES2(fixnum(sock[0]),fixnum(sock[1]));
}
#endif

#if defined(HAVE_SOCKATMARK)
DEFUN(RAWSOCK:SOCKATMARK, sock) {
  rawsock_t sock = I_to_uint(check_uint(popSTACK()));
  int retval;
  SYSCALL(retval,sock,sockatmark(sock));
  VALUES_IF(retval);
}
#endif

/* process optional (struct sockaddr*) argument:
   NIL: return NULL
   T: allocate
   SOCKADDR: extract data
 DANGER: the return value is invalidated by GC!
 can trigger GC */
static void optional_sockaddr_argument (gcv_object_t *arg, struct sockaddr**sa,
                                        SOCKLEN_T *size) {
  if (nullp(*arg)) *sa = NULL;
  else {
    if (eq(T,*arg)) *arg = make_sockaddr();
    *sa = (struct sockaddr*)check_struct_data(`RAWSOCK::SOCKADDR`,*arg,size);
  }
}

DEFUN(RAWSOCK:ACCEPT,socket sockaddr) {
  rawsock_t sock = I_to_uint(check_uint(STACK_1));
  int retval;
  struct sockaddr *sa = NULL;
  SOCKLEN_T sa_size;
  optional_sockaddr_argument(&STACK_0,&sa,&sa_size);
  /* no GC after this point! */
  SYSCALL(retval,sock,accept(sock,sa,&sa_size));
  VALUES3(fixnum(retval),fixnum(sa_size),STACK_0); skipSTACK(2);
}

DEFUN(RAWSOCK:BIND,socket sockaddr) {
  rawsock_t sock = I_to_uint(check_uint(STACK_1));
  int retval;
  SOCKLEN_T size;
  struct sockaddr *sa =
    (struct sockaddr*)check_struct_data(`RAWSOCK::SOCKADDR`,STACK_0,&size);
  /* no GC after this point! */
  SYSCALL(retval,sock,bind(sock,sa,size));
  VALUES0; skipSTACK(2);
}

DEFUN(RAWSOCK:CONNECT,socket sockaddr) {
  rawsock_t sock = I_to_uint(check_uint(STACK_1));
  int retval;
  SOCKLEN_T size;
  struct sockaddr *sa =
    (struct sockaddr*)check_struct_data(`RAWSOCK::SOCKADDR`,STACK_0,&size);
  /* no GC after this point! */
  SYSCALL(retval,sock,connect(sock,sa,size));
  VALUES0; skipSTACK(2);
}

DEFUN(RAWSOCK:GETPEERNAME,socket sockaddr) {
  rawsock_t sock = I_to_uint(check_uint(STACK_1));
  int retval;
  struct sockaddr *sa = NULL;
  SOCKLEN_T sa_size;
  optional_sockaddr_argument(&STACK_0,&sa,&sa_size);
  /* no GC after this point! */
  SYSCALL(retval,sock,getpeername(sock,sa,&sa_size));
  VALUES2(STACK_0,fixnum(sa_size)); skipSTACK(2);
}

DEFUN(RAWSOCK:GETSOCKNAME,socket sockaddr) {
  rawsock_t sock = I_to_uint(check_uint(STACK_1));
  int retval;
  struct sockaddr *sa = NULL;
  SOCKLEN_T sa_size;
  optional_sockaddr_argument(&STACK_0,&sa,&sa_size);
  /* no GC after this point! */
  SYSCALL(retval,sock,getsockname(sock,sa,&sa_size));
  VALUES2(STACK_0,fixnum(sa_size)); skipSTACK(2);
}

DEFUN(RAWSOCK:LISTEN,socket backlog) {
  int backlog = I_to_uint(check_uint(popSTACK()));
  rawsock_t sock = I_to_uint(check_uint(popSTACK()));
  int retval;
  SYSCALL(retval,sock,listen(sock,backlog));
  VALUES0;
}

/* ================== RECEIVING ================== */
/* FIXME: replace this with a complete autoconf check using CL_PROTO() */
#if defined(WIN32_NATIVE)
# define BUF_TYPE_T char*
#else
# define BUF_TYPE_T void*
#endif

/* remove 3 objects from the STACK and return the RECV flag
   based on MSG_PEEK MSG_OOB MSG_WAITALL */
DEFFLAGSET(recv_flags,MSG_PEEK MSG_OOB MSG_WAITALL)
DEFUN(RAWSOCK:RECV,socket buffer &key MSG_PEEK MSG_OOB MSG_WAITALL) {
  int flags = recv_flags();
  rawsock_t sock = I_to_uint(check_uint(STACK_1));
  int retval;
  size_t buffer_len;
  void *buffer = parse_buffer_arg(&STACK_0,&buffer_len);
  SYSCALL(retval,sock,recv(sock,(BUF_TYPE_T)buffer,buffer_len,flags));
  VALUES1(fixnum(retval)); skipSTACK(2);
}

DEFUN(RAWSOCK:RECVFROM, socket buffer address \
      &key MSG_PEEK MSG_OOB MSG_WAITALL) {
  int flags = recv_flags();
  rawsock_t sock = I_to_uint(check_uint(STACK_2));
  int retval;
  struct sockaddr *sa = NULL;
  void *buffer;
  size_t buffer_len;
  SOCKLEN_T sa_size;
  STACK_1 = check_buffer_arg(STACK_1);
  optional_sockaddr_argument(&STACK_0,&sa,&sa_size);
  /* no GC after this point! */
  buffer = (void*)TheSbvector(STACK_1)->data;
  buffer_len = Sbvector_length(STACK_1);
  SYSCALL(retval,sock,recvfrom(sock,(BUF_TYPE_T)buffer,
                               buffer_len,flags,sa,&sa_size));
  VALUES3(fixnum(retval),fixnum(sa_size),STACK_0); skipSTACK(3);
}

#if defined(HAVE_RECVMSG)       /* not on win32 */
DEFUN(RAWSOCK:RECVMSG,socket message &key MSG_PEEK MSG_OOB MSG_WAITALL) {
  int flags = recv_flags();
  rawsock_t sock = I_to_uint(check_uint(STACK_1));
  int retval;
  SOCKLEN_T size;
  struct msghdr *message =
    (struct msghdr*)check_struct_data(`RAWSOCK::MSGHDR`,STACK_0,&size);
  SYSCALL(retval,sock,recvmsg(sock,message,flags));
  VALUES1(fixnum(retval)); skipSTACK(2);
}
#endif

DEFUN(RAWSOCK:SOCK-READ,socket buffer) {
  rawsock_t sock = I_to_uint(check_uint(STACK_1));
  int retval;
  size_t buffer_len;
  void *buffer = parse_buffer_arg(&STACK_0,&buffer_len);
  SYSCALL(retval,sock,read(sock,buffer,buffer_len));
  VALUES1(fixnum(retval)); skipSTACK(2);
}

/* ================== SENDING ================== */

/* remove 2 objects from the STACK and return the SEND flag
   based on MSG_OOB MSG_EOR */
DEFFLAGSET(send_flags, MSG_OOB MSG_EOR)
DEFUN(RAWSOCK:SEND,socket buffer &key MSG_OOB MSG_EOR) {
  int flags = send_flags();
  rawsock_t sock = I_to_uint(check_uint(STACK_1));
  int retval;
  size_t buffer_len;
  void *buffer = parse_buffer_arg(&STACK_0,&buffer_len);
  SYSCALL(retval,sock,send(sock,(const BUF_TYPE_T)buffer,buffer_len,flags));
  VALUES1(fixnum(retval)); skipSTACK(2);
}

#if defined(HAVE_SENDMSG)       /* not on win32 */
DEFUN(RAWSOCK:SENDMSG,socket message &key MSG_OOB MSG_EOR) {
  int flags = send_flags();
  rawsock_t sock = I_to_uint(check_uint(STACK_1));
  int retval;
  SOCKLEN_T size;
  struct msghdr *message =
    (struct msghdr*)check_struct_data(`RAWSOCK::MSGHDR`,STACK_0,&size);
  SYSCALL(retval,sock,sendmsg(sock,message,flags));
  VALUES1(fixnum(retval)); skipSTACK(2);
}
#endif

DEFUN(RAWSOCK:SENDTO, socket buffer address &key MSG_OOB MSG_EOR) {
  int flags = send_flags();
  rawsock_t sock = I_to_uint(check_uint(STACK_2));
  int retval;
  struct sockaddr *sa;
  void *buffer;
  size_t buffer_len;
  SOCKLEN_T size;
  STACK_1 = check_buffer_arg(STACK_1);
  sa = (struct sockaddr*)check_struct_data(`RAWSOCK::SOCKADDR`,STACK_0,&size);
  /* no GC after this point! */
  buffer = (void*)TheSbvector(STACK_1)->data;
  buffer_len = Sbvector_length(STACK_1);
  SYSCALL(retval,sock,sendto(sock,(const BUF_TYPE_T)buffer,
                             buffer_len,flags,sa,size));
  VALUES1(fixnum(retval)); skipSTACK(3);
}

DEFUN(RAWSOCK:SOCK-WRITE,socket buffer) {
  rawsock_t sock = I_to_uint(check_uint(STACK_1));
  int retval;
  size_t buffer_len;
  void *buffer = parse_buffer_arg(&STACK_0,&buffer_len);
  SYSCALL(retval,sock,write(sock,buffer,buffer_len));
  VALUES1(fixnum(retval)); skipSTACK(2);
}

DEFUN(RAWSOCK:SOCK-CLOSE, socket) {
  rawsock_t sock = I_to_uint(check_uint(popSTACK()));
  int retval;
#if defined(HAVE_WINSOCK2_H)
  SYSCALL(retval,sock,closesocket(sock));
#else
  SYSCALL(retval,sock,close(sock));
#endif
  VALUES1(fixnum(retval));
}

#if defined(HAVE_NET_IF_H)
/* STACK_1 = name, for error reporting */
static void configdev (rawsock_t sock, char* name, int ipaddress, int flags) {
  struct ifreq ifrequest;
#if defined(SIOCGIFFLAGS) && defined(SIOCSIFFLAGS)
  memset(&ifrequest, 0, sizeof(struct ifreq));
  strcpy(ifrequest.ifr_name, name);
  if (ioctl(sock, SIOCGIFFLAGS, &ifrequest) < 0)
    OS_file_error(STACK_1);
  ifrequest.ifr_flags |= flags;
  if (ioctl(sock, SIOCSIFFLAGS, &ifrequest) < 0)
    OS_file_error(STACK_1);
#endif
#if defined(SIOCGIFADDR) && defined(SIOCSIFADDR)
  memset(&ifrequest, 0, sizeof(struct ifreq));
  strcpy(ifrequest.ifr_name, name);
  if (ioctl(sock, SIOCGIFADDR, &ifrequest) < 0)
    OS_file_error(STACK_1);
  /* address was 0.0.0.0 -> error */
  if (ipaddress != 0) {
    if (ioctl(sock, SIOCGIFADDR, &ifrequest) < 0)
      OS_file_error(STACK_1);
    else {
      register int j;
      for (j=2;j<6;j++) ifrequest.ifr_addr.sa_data[j] = 0;
      if (ioctl(sock, SIOCSIFADDR, &ifrequest) < 0)
        OS_file_error(STACK_1);
    }
  }
#endif
}

DEFFLAGSET(configdev_flags,IFF_PROMISC IFF_NOARP)
DEFUN(RAWSOCK:CONFIGDEV, socket name ipaddress &key PROMISC NOARP) {
  int flags = configdev_flags();
  uint32 ipaddress = I_to_UL(check_uint32(STACK_0));
  rawsock_t sock = I_to_uint(check_uint(STACK_2));
  with_string_0(check_string(STACK_1),Symbol_value(S(utf_8)),name, {
      begin_system_call();
      configdev(sock, name, ipaddress, flags);
      end_system_call();
    });
  VALUES0; skipSTACK(3);
}
#endif  /* HAVE_NET_IF_H */

/* ================== socket options ================== */
#if defined(HAVE_GETSOCKOPT) || defined(HAVE_SETSOCKOPT)
DEFCHECKER(sockopt_level,default=SOL_SOCKET, ALL=-1 SOL-SOCKET          \
           SOL-IP SOL-IPX SOL-AX25 SOL-ATALK SOL-NETROM SOL-TCP SOL-UDP \
           IPPROTO-IP IPPROTO-IPV6 IPPROTO-ICMP IPPROTO-RAW IPPROTO-TCP \
           IPPROTO-UDP IPPROTO-IGMP IPPROTO-IPIP IPPROTO-EGP IPPROTO-PUP \
           IPPROTO-IDP IPPROTO-GGP IPPROTO-ND IPPROTO-HOPOPTS           \
           IPPROTO-ROUTING IPPROTO-FRAGMENT IPPROTO-ESP IPPROTO-AH      \
           IPPROTO-ICMPV6 IPPROTO-DSTOPTS IPPROTO-NONE)
DEFCHECKER(sockopt_name,default=-1,prefix=SO,                            \
           DEBUG ACCEPTCONN BROADCAST USELOOPBACK PEERCRED              \
           REUSEADDR KEEPALIVE LINGER OOBINLINE SNDBUF RCVBUF ERROR TYPE \
           DONTROUTE RCVLOWAT RCVTIMEO SNDLOWAT SNDTIMEO)
#endif
#if defined(HAVE_GETSOCKOPT)
#define GET_SOCK_OPT(opt_type,retform) do {                             \
    opt_type val;                                                       \
    SOCKLEN_T len = sizeof(val);                                        \
    int status;                                                         \
    begin_system_call();                                                \
    status = getsockopt(sock,level,name,(SETSOCKOPT_ARG_T)&val,&len);   \
    end_system_call();                                                  \
    if (status==0) return retform;                                      \
    else return (err_p ? OS_file_error(fixnum(sock)),NIL : S(Kerror));  \
  } while(0)
/* can trigger GC */
static object get_sock_opt (rawsock_t sock, int level, int name, int err_p) {
  switch (name) {
#  if defined(SO_DEBUG)
    case SO_DEBUG:
#  endif
#  if defined(SO_ACCEPTCONN)
    case SO_ACCEPTCONN:
#  endif
#  if defined(SO_BROADCAST)
    case SO_BROADCAST:
#  endif
#  if defined(SO_REUSEADDR)
    case SO_REUSEADDR:
#  endif
#  if defined(SO_KEEPALIVE)
    case SO_KEEPALIVE:
#  endif
#  if defined(SO_OOBINLINE)
    case SO_OOBINLINE:
#  endif
#  if defined(SO_DONTROUTE)
    case SO_DONTROUTE:
#  endif
#  if defined(SO_USELOOPBACK)
    case SO_USELOOPBACK:
#  endif
      GET_SOCK_OPT(int,val ? T : NIL);
#  if defined(SO_PEERCRED)
    case SO_PEERCRED:
#  endif
#  if defined(SO_RCVLOWAT)
    case SO_RCVLOWAT:
#  endif
#  if defined(SO_SNDLOWAT)
    case SO_SNDLOWAT:
#  endif
#  if defined(SO_SNDBUF)
    case SO_SNDBUF:
#  endif
#  if defined(SO_RCVBUF)
    case SO_RCVBUF:
#  endif
#  if defined(SO_ERROR)
    case SO_ERROR:
#  endif
      GET_SOCK_OPT(int,sint_to_I(val));
#  if defined(SO_TYPE)
    case SO_TYPE:
      GET_SOCK_OPT(int,check_socket_type_reverse(val));
#  endif
#  if defined(SO_LINGER)
    case SO_LINGER:
      GET_SOCK_OPT(struct linger,val.l_onoff ? sint_to_I(val.l_linger) : NIL);
#  endif
#  if defined(SO_RCVTIMEO)
    case SO_RCVTIMEO:
#  endif
#  if defined(SO_SNDTIMEO)
    case SO_SNDTIMEO:
#  endif
      GET_SOCK_OPT(struct timeval,sec_usec_number(val.tv_sec,val.tv_usec,0));
    default: NOTREACHED;
  }
}
#undef GET_SOCK_OPT
DEFUN(RAWSOCK:SOCKET-OPTION, sock name &key :LEVEL)
{ /* http://www.opengroup.org/onlinepubs/009695399/functions/getsockopt.html */
  int level = sockopt_level(popSTACK());
  int name = sockopt_name(popSTACK());
  rawsock_t sock;
  stream_handles(popSTACK(),true,NULL,&sock,NULL);
  if (level == -1) {                      /* :ALL */
    int pos1;
    for (pos1=1; pos1 < sockopt_level_map.size; pos1++) {
      const c_lisp_pair_t *level_clp = &(sockopt_level_map.table[pos1]);
      pushSTACK(*(level_clp->l_const));
      if (name == -1) {
        int pos2;
        for (pos2=0; pos2 < sockopt_name_map.size; pos2++) {
          const c_lisp_pair_t *name_clp = &(sockopt_name_map.table[pos2]);
          pushSTACK(*name_clp->l_const);
          pushSTACK(get_sock_opt(sock,level_clp->c_const,name_clp->c_const,0));
        }
        { object tmp = listof(2*sockopt_name_map.size); pushSTACK(tmp); }
      } else
        pushSTACK(get_sock_opt(sock,level_clp->c_const,name,0));
    }
    VALUES1(listof(2*(sockopt_level_map.size-1))); /* skip :ALL */
  } else {
    if (name == -1) {
      int pos2;
      for (pos2=0; pos2 < sockopt_name_map.size; pos2++) {
        const c_lisp_pair_t *name_clp = &(sockopt_name_map.table[pos2]);
        pushSTACK(*(name_clp->l_const));
        pushSTACK(get_sock_opt(sock,level,name_clp->c_const,0));
      }
      VALUES1(listof(2*sockopt_name_map.size));
    } else
      VALUES1(get_sock_opt(sock,level,name,1));
  }
}
#endif
#if defined(HAVE_SETSOCKOPT)
#define SET_SOCK_OPT(opt_type,valform) do {                             \
    int status;                                                         \
    opt_type val; valform;                                              \
    begin_system_call();                                                \
    status = setsockopt(sock,level,name,(SETSOCKOPT_ARG_T)&val,sizeof(val)); \
    end_system_call();                                                  \
    if (status) OS_file_error(fixnum(sock));                            \
    return;                                                             \
  } while(0)
static void set_sock_opt (rawsock_t sock, int level, int name, object value) {
  if (eq(value,S(Kerror))) return;
  switch (name) {
#  if defined(SO_DEBUG)
    case SO_DEBUG:
#  endif
#  if defined(SO_ACCEPTCONN)
    case SO_ACCEPTCONN:
#  endif
#  if defined(SO_BROADCAST)
    case SO_BROADCAST:
#  endif
#  if defined(SO_REUSEADDR)
    case SO_REUSEADDR:
#  endif
#  if defined(SO_KEEPALIVE)
    case SO_KEEPALIVE:
#  endif
#  if defined(SO_OOBINLINE)
    case SO_OOBINLINE:
#  endif
#  if defined(SO_DONTROUTE)
    case SO_DONTROUTE:
#  endif
#  if defined(SO_USELOOPBACK)
    case SO_USELOOPBACK:
#  endif
      SET_SOCK_OPT(int,val=!nullp(value));
#  if defined(SO_PEERCRED)
    case SO_PEERCRED:
#  endif
#  if defined(SO_RCVLOWAT)
    case SO_RCVLOWAT:
#  endif
#  if defined(SO_SNDLOWAT)
    case SO_SNDLOWAT:
#  endif
#  if defined(SO_SNDBUF)
    case SO_SNDBUF:
#  endif
#  if defined(SO_RCVBUF)
    case SO_RCVBUF:
#  endif
#  if defined(SO_ERROR)
    case SO_ERROR:
#  endif
      SET_SOCK_OPT(int,val=I_to_sint32(check_sint32(value)));
#  if defined(SO_TYPE)
    case SO_TYPE:
      SET_SOCK_OPT(int,val=check_socket_type(value));
#  endif
#  if defined(SO_LINGER)
    case SO_LINGER:
      SET_SOCK_OPT(struct linger,
                   if (nullp(value)) val.l_onoff=0;
                   else { val.l_onoff = 1;
                     val.l_linger = I_to_sint32(check_sint32(value));});
#  endif
#  if defined(SO_RCVTIMEO)
    case SO_RCVTIMEO:
#  endif
#  if defined(SO_SNDTIMEO)
    case SO_SNDTIMEO:
#  endif
      SET_SOCK_OPT(struct timeval,sec_usec(value,NIL,&val));
    default: NOTREACHED;
  }
}
#undef SET_SOCK_OPT
/* name=-1   => set many socket options from the plist
   otherwise => set this option
 can trigger GC */
static void set_sock_opt_many (rawsock_t sock, int level, int name,
                               object opt_or_plist) {
  if (name == -1) {
    pushSTACK(opt_or_plist); pushSTACK(opt_or_plist);
    while (!endp(STACK_0)) {
      int name = sockopt_name(Car(STACK_0));
      STACK_0 = Cdr(STACK_0);
      if (!consp(STACK_0)) fehler_plist_odd(STACK_1);
      set_sock_opt(sock,level,name,Car(STACK_0));
      STACK_0 = Cdr(STACK_0);
    }
    skipSTACK(2);
  } else
    set_sock_opt(sock,level,name,opt_or_plist);
}

DEFUN(RAWSOCK::SET-SOCKET-OPTION, value sock name &key :LEVEL)
{ /* http://www.opengroup.org/onlinepubs/009695399/functions/setsockopt.html */
  int level = sockopt_level(popSTACK());
  int name = sockopt_name(popSTACK());
  rawsock_t sock;
  stream_handles(popSTACK(),true,NULL,&sock,NULL);
  if (level == -1) {                      /* :ALL */
    pushSTACK(STACK_0);
    while (!endp(STACK_0)) {
      int level = sockopt_level(Car(STACK_0));
      STACK_0 = Cdr(STACK_0);
      if (!consp(STACK_0)) fehler_plist_odd(STACK_1);
      set_sock_opt_many(sock,level,name,Car(STACK_0));
      STACK_0 = Cdr(STACK_0);
    }
    skipSTACK(1);
  } else
    set_sock_opt_many(sock,level,name,STACK_0);
  VALUES1(popSTACK());
}
#endif

/* ================== CHECKSUM from Fred Cohen ================== */
DEFUN(RAWSOCK:IPCSUM, &optional buffer) { /* IP CHECKSUM */
  unsigned char* buffer = TheSbvector(check_buffer_arg(popSTACK()))->data;
  register long sum=0;           /* assumes long == 32 bits */
  unsigned short result;
  unsigned char *ptr=&(buffer[14]);
  unsigned int nbytes;
  buffer[24]=0;buffer[25]=0;nbytes=(buffer[14] & 0xF) << 2; /* checksum=0, headerlen */
  while(nbytes>1){sum += *ptr; ptr++; sum += *ptr <<8; ptr++; nbytes -= 2;}
  if(nbytes==1){sum += *ptr;}     /* mop up an odd byte,  if necessary */
  sum = (sum >> 16) + (sum & 0xFFFF);
  result=~(sum  + (sum >> 16)) & 0xFFFF;
  buffer[24]=(result & 0xFF);
  buffer[25]=((result >> 8) & 0xFF);
  VALUES1(fixnum(result));
}

DEFUN(RAWSOCK:ICMPCSUM, &optional buffer) { /* ICMP CHECKSUM */
  unsigned char* buffer = TheSbvector(check_buffer_arg(popSTACK()))->data;
  register long sum=0;           /* assumes long == 32 bits */
  unsigned short result;
  unsigned char *ptr;
  unsigned int nbytes, off, offset;
  off=((buffer[14]&0xF)<<2);offset=off+14; /* start of ICMP header */
  buffer[offset+2]=0;buffer[offset+3]=0;
  nbytes=(((buffer[16])<<8)+(buffer[17]))-off; /* bytes in ICMP part */
  ptr=&(buffer[offset]);
  while(nbytes>1){sum += *ptr; ptr++; sum += *ptr <<8; ptr++; nbytes -= 2;}
  if(nbytes==1){sum += *ptr;}     /* mop up an odd byte,  if necessary */
  sum = (sum >> 16) + (sum & 0xFFFF);
  result=~(sum  + (sum >> 16)) & 0xFFFF;
  buffer[offset+2]=(result & 0xFF);
  buffer[offset+3]=((result >> 8) & 0xFF);
  VALUES1(fixnum(result));
}

DEFUN(RAWSOCK:TCPCSUM, &optional buffer) {      /* TCP checksum */
  unsigned char* buffer = TheSbvector(check_buffer_arg(popSTACK()))->data;
  register unsigned long sum;  /* assumes long == 32 bits */
  unsigned short result;
  unsigned char *ptr;
  unsigned int nbytes, packsize, offset;
  sum = (buffer[26]<<8)+ buffer[27]+(buffer[28]<<8)+ buffer[29];  /* Src IP */
  sum +=(buffer[30]<<8)+ buffer[31]+(buffer[32]<<8)+ buffer[33];  /* Dst IP */
  sum +=(buffer[23]);           /* zero followed by protocol */
  packsize=((buffer[16])<<8)+(buffer[17]); /* packet size - not including ARP area */
  offset=((buffer[14]&0xF)<<2); /* start of TCP header (rel to IP header) */
  sum +=(packsize - offset);    /* size of TCP part of the packet */
  ptr=&(buffer[offset+14]);     /* start of TCP header in buffer */
  nbytes=packsize-offset;       /* number of bytes to checksum */
  buffer[offset+16+14]=0;
  buffer[offset+17+14]=0; /* initialize TCP checksum to 0 */
  while(nbytes>1){sum += *ptr<<8; ptr++; sum += *ptr; ptr++; nbytes -= 2;}
  if (nbytes==1) {sum += *ptr<<8;} /* mop up an odd byte,  if necessary */
  sum = (sum >> 16) + (sum & 0xFFFF);
  result=~(sum  + (sum >> 16)) & 0xFFFF;
  buffer[offset+17+14]=(result & 0xFF);
  buffer[offset+16+14]=((result >> 8) & 0xFF);
  VALUES1(fixnum(result));
}

DEFUN(RAWSOCK:UDPCSUM, &optional buffer) { /* UDP checksum */
  unsigned char* buffer = TheSbvector(check_buffer_arg(popSTACK()))->data;
  register unsigned long sum = 0;  /* assumes long == 32 bits */
  unsigned short result;
  unsigned char *ptr;
  unsigned int nbytes, packsize, offset;
  sum = (buffer[26]<<8)+ buffer[27]+(buffer[28]<<8)+ buffer[29];  /* Src IP */
  sum +=(buffer[30]<<8)+ buffer[31]+(buffer[32]<<8)+ buffer[33];  /* Dst IP */
  sum +=(buffer[23]);           /* zero followed by protocol */
  packsize=((buffer[16])<<8)+(buffer[17]); /* packet size */
  offset=((buffer[14]&0xF)<<2);            /* start of UDP header */
  sum +=(((buffer[16])<<8)+(buffer[17])) -offset;
  ptr=&(buffer[offset+14]);     /* start of TCP header */
  nbytes=packsize-offset;
  buffer[offset+6+14]=0;
  buffer[offset+7+14]=0; /* initialize UDP checksum to 0 */
  while(nbytes>1){sum += *ptr <<8; ptr++; sum += *ptr; ptr++; nbytes -= 2;}
  if (nbytes==1) {sum += *ptr<<8;} /* mop up an odd byte, if necessary */
  sum = (sum >> 16) + (sum & 0xFFFF);
  result=~(sum  + (sum >> 16)) & 0xFFFF;
  buffer[offset+7+14]=(result & 0xFF);
  buffer[offset+6+14]=((result >> 8) & 0xFF);
  VALUES1(fixnum(result));
}
