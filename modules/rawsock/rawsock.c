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
#if defined(HAVE_NETDB_H)
# include <netdb.h>
#endif
#if defined(HAVE_SYS_UIO_H)
# include <sys/uio.h>
#endif
typedef SOCKET rawsock_t;
#if SIZEOF_SIZE_T == 8
# define size_to_I  uint64_to_I
#else
# define size_to_I  uint32_to_I
#endif
#if SIZEOF_SSIZE_T == 8
# define ssize_to_I  sint64_to_I
#else
# define ssize_to_I  sint32_to_I
#endif

DEFMODULE(rawsock,"RAWSOCK")

/* ================== helpers ================== */
/* can trigger GC */
static object my_check_argument (object name, object datum) {
  pushSTACK(NIL);               /* no PLACE */
  pushSTACK(name); pushSTACK(datum); pushSTACK(TheSubr(subr_self)->name);
  check_value(error,GETTEXT("~S: ~S is not a valid ~S argument"));
  return value1;
}
/* DANGER: the return value is invalidated by GC!
 > *arg_: vector
 > STACK_0, STACK_1: START & END
 > prot: PROT_READ or PROT_READ_WRITE
 < size: how many bytes to use
 < pointer to the buffer start
 can trigger GC */
static void* parse_buffer_arg (gcv_object_t *arg_, size_t *size, int prot) {
  uintV start = 0;
  object data;
  *arg_ = check_byte_vector(*arg_);
  if (!missingp(STACK_1)) start = posfixnum_to_V(check_posfixnum(STACK_1));
  *size = missingp(STACK_0) ? vector_length(*arg_)
    : posfixnum_to_V(check_posfixnum(STACK_0));
  data = array_displace_check(*arg_,*size,&start);
  { void *start_address = (void*)(TheSbvector(data)->data + start);
    handle_fault_range(prot,(aint)start_address,(aint)(start_address + *size));
    return start_address;
  }
}
/* DANGER: the return value is invalidated by GC!
 > type: the expected type
 > arg: the argument
 < size: the data size
 > prot: PROT_READ or PROT_READ_WRITE
 < returns the address of the data area
 can trigger GC */
static void* check_struct_data (object type, object arg, SOCKLEN_T *size,
                                int prot) {
  object vec = TheStructure(check_classname(arg,type))->recdata[1];
  *size = Sbvector_length(vec);
  { void *start_address = (void*)(TheSbvector(vec)->data);
    handle_fault_range(prot,(aint)start_address,(aint)(start_address + *size));
    return start_address;
  }
}

#if defined(HAVE_SYS_UIO_H)
/* check the arg is a vector of byte vectors
 > *arg_: vector
 > STACK_0, STACK_1: START & END
 < *arg_: may be modified (bad vector elements replaced with byte vectors)
 < return: how many byte vectors arg contains
 can trigger GC */
static int check_iovec_arg (gcv_object_t *arg_, uintL *offset) {
  int size, ii;
  *arg_ = check_vector(*arg_);
  if (array_atype(*arg_) != Atype_T) return -1; /* cannot contain vectors */
  *offset = (missingp(STACK_1) ? 0 : posfixnum_to_V(check_posfixnum(STACK_1)));
  size = (missingp(STACK_0) ? vector_length(*arg_)
          : posfixnum_to_V(check_posfixnum(STACK_0)));
  *arg_ = array_displace_check(*arg_,size,offset);
  for (ii=*offset; ii<size; ii++)
    TheSvector(*arg_)->data[ii] =
      check_byte_vector(TheSvector(*arg_)->data[ii]);
  return size;
}
/* DANGER: the return value is invalidated by GC!
 this must be called _after_ check_iovec_arg()
 fill the iovec array from the vector of byte vectors
 < vect: (vector (byte-vector))
 < offset: starting offset into vect
 < veclen: number of vect elements to put into buffer
 < buffer: array of struct iovec of length veclen
 < prot: PROT_READ or PROT_READ_WRITE
 > buffer: filled in with data pointers of elements of vect */
static void fill_iovec (object vect, size_t offset, ssize_t veclen,
                        struct iovec *buffer, int prot) {
  gcv_object_t *vec = TheSvector(vect)->data + offset;
  ssize_t pos = veclen;
  for (;pos--; buffer++, vec++) {
    size_t len = vector_length(*vec);
    uintL index = 0;
    object data_vec = array_displace_check(*vec,len,&index);
    buffer->iov_len = len;
    buffer->iov_base= TheSbvector(data_vec)->data + index;
    handle_fault_range(prot,(aint)buffer->iov_base,
                       (aint)(buffer->iov_base + len));
  }
}
#endif  /* HAVE_SYS_UIO_H */

DEFUN(RAWSOCK:SOCKADDR-FAMILY, sa) {
  SOCKLEN_T size;
  struct sockaddr *sa =
    (struct sockaddr*)check_struct_data(`RAWSOCK::SOCKADDR`,popSTACK(),&size,
                                        PROT_READ);
  VALUES2(fixnum(sa->sa_family),fixnum(size));
}
DEFUN(RAWSOCK::SOCKADDR-SLOT,&optional slot) {
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
    pushSTACK(STACK_1/*slot*/); /* TYPE-ERROR slot DATUM */
    pushSTACK(`(MEMBER :FAMILY :DATA)`); /* TYPE-ERROR slot EXPECTED-TYPE */
    pushSTACK(`SOCKADDR`); pushSTACK(STACK_2/*slot*/);
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

struct pos {
  gcv_object_t *vector;
  unsigned int position;
};
void coerce_into_bytes (void *arg, object element);
void coerce_into_bytes (void *arg, object element) {
  struct pos * pos = (struct pos *)arg;
  uint8 value = I_to_uint8(check_uint8(element));
  TheSbvector(*(pos->vector))->data[pos->position++] = value;
}

DEFUN(RAWSOCK:MAKE-SOCKADDR,family &optional data) {
  int family = check_socket_domain(STACK_1);
  struct sockaddr sa;
  unsigned char *buffer, *data;
  size_t buffer_len, data_start = offsetof(struct sockaddr,sa_data);
  struct pos arg;
  if (missingp(STACK_0)) {      /* standard size */
    buffer_len = sizeof(struct sockaddr) - data_start;
  } else if (posfixnump(STACK_0)) { /* integer data => as if sequence of 0 */
    buffer_len = posfixnum_to_V(STACK_0);
  } else {                      /* data should be a sequence */
    pushSTACK(STACK_0); funcall(L(length),1);
    buffer_len = I_to_uint32(value1);
  }
  pushSTACK(allocate_bit_vector(Atype_8Bit,data_start + buffer_len));
  buffer = (unsigned char *)TheSbvector(STACK_0)->data;
  begin_system_call();
  memset(buffer,0,data_start + buffer_len);
  end_system_call();
  ((struct sockaddr*)buffer)->sa_family = family;
  arg.vector = &(STACK_0); arg.position = data_start;
  if (!missingp(STACK_1) && !posfixnump(STACK_1))
    map_sequence(STACK_1/*data*/,coerce_into_bytes,(void*)&arg);
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

/* ================== netdb.h interface ================== */
#if defined(HAVE_NETDB_H)
/* return RAWSOCK:PROTOCOL object in value1 */
static Values protoent_to_protocol (struct protoent *pe) {
  pushSTACK(asciz_to_string(pe->p_name,GLO(misc_encoding)));
  { int count = 0;
    char **alias = pe->p_aliases;
    for (; *alias; count++, alias++)
      pushSTACK(asciz_to_string(*alias,GLO(misc_encoding)));
    value1 = listof(count); pushSTACK(value1);
  }
  pushSTACK(sint_to_I(pe->p_proto));
  funcall(`RAWSOCK::MAKE-PROTOCOL`,3);
}
DEFUN(RAWSOCK:PROTOCOL, &optional protocol)
{ /* interface to getprotobyname() et al
     http://www.opengroup.org/onlinepubs/009695399/functions/getprotoent.html */
  object proto = popSTACK();
  struct protoent *pe = NULL;
  if (missingp(proto)) {        /* get all protocols */
    int count = 0;
#  if defined(HAVE_SETPROTOENT) && defined(HAVE_GETPROTOENT) && defined(HAVE_ENDPROTOENT)
    begin_system_call();
    setprotoent(1);
    while ((pe = getprotoent())) {
      end_system_call();
      protoent_to_protocol(pe); pushSTACK(value1); count++;
      begin_system_call();
    }
    endprotoent();
    end_system_call();
#  endif
    VALUES1(listof(count));
    return;
  } else if (sint_p(proto)) {
#  if defined(HAVE_GETPROTOBYNUMBER)
    begin_system_call();
    pe = getprotobynumber(I_to_sint(proto));
    end_system_call();
#  endif
  } else if (stringp(proto)) {
#  if defined(HAVE_GETPROTOBYNAME)
    with_string_0(proto,GLO(misc_encoding),protoz, {
        begin_system_call();
        pe = getprotobyname(protoz);
        end_system_call();
      });
#  endif
  } else fehler_string_integer(proto);
  if (pe) protoent_to_protocol(pe);
  else VALUES1(NIL);
}
/* --------------- */
/* return RAWSOCK:NETWORK object in value1 */
static Values netent_to_network (struct netent *ne) {
  pushSTACK(asciz_to_string(ne->n_name,GLO(misc_encoding)));
  { int count = 0;
    char **alias = ne->n_aliases;
    for (; *alias; count++, alias++)
      pushSTACK(asciz_to_string(*alias,GLO(misc_encoding)));
    value1 = listof(count); pushSTACK(value1);
  }
  pushSTACK(sint_to_I(ne->n_addrtype));
  pushSTACK(sint_to_I(ne->n_net));
  funcall(`RAWSOCK::MAKE-NETWORK`,4);
}
DEFUN(RAWSOCK:NETWORK, &optional network type)
{ /* interface to getnetbyname() et al
     http://www.opengroup.org/onlinepubs/009695399/functions/getnetent.html */
  unsigned int type = check_uint_defaulted(popSTACK(),-1);
  object net = popSTACK();
  struct netent *ne = NULL;
  if (missingp(net)) {          /* get all networks */
    int count = 0;
#  if defined(HAVE_SETNETENT) && defined(HAVE_GETNETENT) && defined(HAVE_ENDNETENT)
    begin_system_call();
    setnetent(1);
    while ((ne = getnetent())) {
      end_system_call();
      if (type==-1 || type==ne->n_addrtype) {
        netent_to_network(ne); pushSTACK(value1); count++;
      }
      begin_system_call();
    }
    endnetent();
    end_system_call();
#  endif
    VALUES1(listof(count));
    return;
  } else if (uint_p(net)) {
#  if defined(HAVE_GETNETBYNUMBER)
    begin_system_call();
    ne = getnetbynumber(I_to_uint(net),type);
    end_system_call();
#  endif
  } else if (stringp(net)) {
#  if defined(HAVE_GETNETBYNAME)
    with_string_0(net,GLO(misc_encoding),netz, {
        begin_system_call();
        ne = getnetbyname(netz);
        end_system_call();
      });
#  endif
  } else fehler_string_integer(net);
  if (ne) netent_to_network(ne);
  else VALUES1(NIL);
}
#endif  /* HAVE_NETDB_H */
/* ================== sys/socket.h interface ================== */
DEFCHECKER(check_socket_domain,prefix=AF,default=AF_UNSPEC,             \
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
    *sa = (struct sockaddr*)check_struct_data(`RAWSOCK::SOCKADDR`,*arg,size,
                                              PROT_READ_WRITE);
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
    (struct sockaddr*)check_struct_data(`RAWSOCK::SOCKADDR`,STACK_0,&size,
                                        PROT_READ);
  /* no GC after this point! */
  SYSCALL(retval,sock,bind(sock,sa,size));
  VALUES0; skipSTACK(2);
}

DEFUN(RAWSOCK:CONNECT,socket sockaddr) {
  rawsock_t sock = I_to_uint(check_uint(STACK_1));
  int retval;
  SOCKLEN_T size;
  struct sockaddr *sa =
    (struct sockaddr*)check_struct_data(`RAWSOCK::SOCKADDR`,STACK_0,&size,
                                        PROT_READ);
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

DEFUN(RAWSOCK:SOCK-LISTEN,socket backlog) {
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
DEFUN(RAWSOCK:RECV,socket buffer &key START END PEEK OOB WAITALL) {
  int flags = recv_flags();
  rawsock_t sock = I_to_uint(check_uint(STACK_3));
  int retval;
  size_t buffer_len;
  void *buffer = parse_buffer_arg(&STACK_2,&buffer_len,PROT_READ_WRITE);
  SYSCALL(retval,sock,recv(sock,(BUF_TYPE_T)buffer,buffer_len,flags));
  VALUES1(fixnum(retval)); skipSTACK(4);
}

DEFUN(RAWSOCK:RECVFROM, socket buffer address &key START END PEEK OOB WAITALL) {
  int flags = recv_flags();
  rawsock_t sock = I_to_uint(check_uint(STACK_4));
  int retval;
  struct sockaddr *sa = NULL;
  void *buffer;
  size_t buffer_len;
  SOCKLEN_T sa_size;
  if (!missingp(STACK_0)) STACK_0 = check_posfixnum(STACK_0);
  if (!missingp(STACK_1)) STACK_1 = check_posfixnum(STACK_1);
  STACK_3 = check_byte_vector(STACK_3);
  optional_sockaddr_argument(&STACK_2,&sa,&sa_size);
  /* no GC after this point! - buffer, start, end have been checked already */
  buffer = parse_buffer_arg(&STACK_3,&buffer_len,PROT_READ_WRITE);
  SYSCALL(retval,sock,recvfrom(sock,(BUF_TYPE_T)buffer,
                               buffer_len,flags,sa,&sa_size));
  VALUES3(fixnum(retval),fixnum(sa_size),STACK_2); skipSTACK(5);
}

#if defined(HAVE_RECVMSG)       /* not on win32 */
DEFUN(RAWSOCK:RECVMSG,socket message &key PEEK OOB WAITALL) {
  int flags = recv_flags();
  rawsock_t sock = I_to_uint(check_uint(STACK_1));
  int retval;
  SOCKLEN_T size;
  struct msghdr *message =
    (struct msghdr*)check_struct_data(`RAWSOCK::MSGHDR`,STACK_0,&size,
                                      PROT_READ_WRITE);
  SYSCALL(retval,sock,recvmsg(sock,message,flags));
  VALUES1(fixnum(retval)); skipSTACK(2);
}
#endif

DEFUN(RAWSOCK:SOCK-READ,socket buffer &key START END)
{ /* http://www.opengroup.org/onlinepubs/009695399/functions/read.html
     http://www.opengroup.org/onlinepubs/009695399/functions/readv.html */
  rawsock_t sock = I_to_uint(check_uint(STACK_3));
  ssize_t retval;
  size_t len;
  uintL offset;
#if defined(HAVE_SYS_UIO_H) && defined(HAVE_READV)
  if ((retval = check_iovec_arg(&STACK_2,&offset)) >= 0) { /* READV */
    struct iovec *buffer = alloca(sizeof(struct iovec)*retval);
    fill_iovec(STACK_2,offset,retval,buffer,PROT_READ_WRITE);
    SYSCALL(retval,sock,readv(sock,buffer,retval));
  } else
#endif
    {                      /* READ */
      void *buffer = parse_buffer_arg(&STACK_2,&len,PROT_READ_WRITE);
      SYSCALL(retval,sock,read(sock,buffer,len));
    }
  VALUES1(ssize_to_I(retval)); skipSTACK(4);
}

/* ================== SENDING ================== */

/* remove 2 objects from the STACK and return the SEND flag
   based on MSG_OOB MSG_EOR */
DEFFLAGSET(send_flags, MSG_OOB MSG_EOR)
DEFUN(RAWSOCK:SEND,socket buffer &key START END OOB EOR) {
  int flags = send_flags();
  rawsock_t sock = I_to_uint(check_uint(STACK_3));
  int retval;
  size_t buffer_len;
  void *buffer = parse_buffer_arg(&STACK_2,&buffer_len,PROT_READ);
  SYSCALL(retval,sock,send(sock,(const BUF_TYPE_T)buffer,buffer_len,flags));
  VALUES1(fixnum(retval)); skipSTACK(4);
}

#if defined(HAVE_SENDMSG)       /* not on win32 */
DEFUN(RAWSOCK:SENDMSG,socket message &key OOB EOR) {
  int flags = send_flags();
  rawsock_t sock = I_to_uint(check_uint(STACK_1));
  int retval;
  SOCKLEN_T size;
  struct msghdr *message =
    (struct msghdr*)check_struct_data(`RAWSOCK::MSGHDR`,STACK_0,&size,
                                      PROT_READ);
  SYSCALL(retval,sock,sendmsg(sock,message,flags));
  VALUES1(fixnum(retval)); skipSTACK(2);
}
#endif

DEFUN(RAWSOCK:SENDTO, socket buffer address &key START END OOB EOR) {
  int flags = send_flags();
  rawsock_t sock = I_to_uint(check_uint(STACK_4));
  int retval;
  struct sockaddr *sa;
  void *buffer;
  size_t buffer_len;
  SOCKLEN_T size;
  if (!missingp(STACK_0)) STACK_0 = check_posfixnum(STACK_0);
  if (!missingp(STACK_1)) STACK_1 = check_posfixnum(STACK_1);
  STACK_3 = check_byte_vector(STACK_3);
  sa = (struct sockaddr*)check_struct_data(`RAWSOCK::SOCKADDR`,STACK_2,&size,
                                           PROT_READ);
  /* no GC after this point! - buffer, start, end have been checked already */
  buffer = parse_buffer_arg(&STACK_3,&buffer_len,PROT_READ);
  SYSCALL(retval,sock,sendto(sock,(const BUF_TYPE_T)buffer,
                             buffer_len,flags,sa,size));
  VALUES1(fixnum(retval)); skipSTACK(5);
}

DEFUN(RAWSOCK:SOCK-WRITE,socket buffer &key START END)
{ /* http://www.opengroup.org/onlinepubs/009695399/functions/write.html
     http://www.opengroup.org/onlinepubs/009695399/functions/writev.html */
  rawsock_t sock = I_to_uint(check_uint(STACK_3));
  ssize_t retval;
  size_t len;
  uintL offset;
#if defined(HAVE_SYS_UIO_H) && defined(HAVE_READV)
  if ((retval = check_iovec_arg(&STACK_2,&offset)) >= 0) { /* WRITEW */
    struct iovec *buffer = alloca(sizeof(struct iovec)*retval);
    fill_iovec(STACK_2,offset,retval,buffer,PROT_READ);
    SYSCALL(retval,sock,writev(sock,buffer,retval));
  } else
#endif
    {                           /* WRITE */
      void *buffer = parse_buffer_arg(&STACK_2,&len,PROT_READ);
      SYSCALL(retval,sock,write(sock,buffer,len));
    }
  VALUES1(ssize_to_I(retval)); skipSTACK(4);
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
DEFUN(RAWSOCK:IPCSUM, buffer &key START END) { /* IP CHECKSUM */
  size_t length;
  unsigned char* buffer =
    (unsigned char*)parse_buffer_arg(&STACK_2,&length,PROT_READ_WRITE);
  register long sum=0;           /* assumes long == 32 bits */
  unsigned short result;
  unsigned char *ptr=&(buffer[14]);
  unsigned int nbytes;
  /* FIXME: check length > ??? */
  buffer[24]=0;buffer[25]=0;nbytes=(buffer[14] & 0xF) << 2; /* checksum=0, headerlen */
  while(nbytes>1){sum += *ptr; ptr++; sum += *ptr <<8; ptr++; nbytes -= 2;}
  if(nbytes==1){sum += *ptr;}     /* mop up an odd byte,  if necessary */
  sum = (sum >> 16) + (sum & 0xFFFF);
  result=~(sum  + (sum >> 16)) & 0xFFFF;
  buffer[24]=(result & 0xFF);
  buffer[25]=((result >> 8) & 0xFF);
  VALUES1(fixnum(result));
  skipSTACK(3);
}

DEFUN(RAWSOCK:ICMPCSUM, buffer &key START END) { /* ICMP CHECKSUM */
  size_t length;
  unsigned char* buffer =
    (unsigned char*)parse_buffer_arg(&STACK_2,&length,PROT_READ);
  register long sum=0;           /* assumes long == 32 bits */
  unsigned short result;
  unsigned char *ptr;
  unsigned int nbytes, off, offset;
  /* FIXME: check length > ??? */
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
  skipSTACK(3);
}

DEFUN(RAWSOCK:TCPCSUM, buffer &key START END) { /* TCP checksum */
  size_t length;
  unsigned char* buffer =
    (unsigned char*)parse_buffer_arg(&STACK_2,&length,PROT_READ_WRITE);
  register unsigned long sum;  /* assumes long == 32 bits */
  unsigned short result;
  unsigned char *ptr;
  unsigned int nbytes, packsize, offset;
  /* FIXME: check length > ??? */
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
  skipSTACK(3);
}

DEFUN(RAWSOCK:UDPCSUM, buffer &key START END) { /* UDP checksum */
  size_t length;
  unsigned char* buffer =
    (unsigned char*)parse_buffer_arg(&STACK_2,&length,PROT_READ_WRITE);
  register unsigned long sum = 0;  /* assumes long == 32 bits */
  unsigned short result;
  unsigned char *ptr;
  unsigned int nbytes, packsize, offset;
  /* FIXME: check length > ??? */
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
  skipSTACK(3);
}
