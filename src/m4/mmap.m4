dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2010, 2017 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ([2.57])

AC_DEFUN([CL_MMAP],
[
  AC_BEFORE([$0], [CL_MUNMAP])
  AC_BEFORE([$0], [CL_MPROTECT])
  AC_CHECK_HEADER([sys/mman.h], [], [no_mmap=1])
  if test -z "$no_mmap"; then
    AC_CHECK_FUNC([mmap], [], [no_mmap=1])
    if test -z "$no_mmap"; then
      AC_DEFINE([HAVE_MMAP],,[have <sys/mmap.h> and the mmap() function])
      AC_CACHE_CHECK([for working mmap], [cl_cv_func_mmap_works],
        [case "$host" in
           i[34567]86-*-sysv4*)
             # UNIX_SYSV_UHC_1
             avoid=0x08000000 ;;
           mips-sgi-irix* | mips-dec-ultrix*)
             # UNIX_IRIX, UNIX_DEC_ULTRIX
             avoid=0x10000000 ;;
           rs6000-ibm-aix*)
             # UNIX_AIX
             avoid=0x20000000 ;;
           *)
           avoid=0 ;;
         esac
         mmap_prog_1='
           #include <stdlib.h>
           #ifdef HAVE_UNISTD_H
            #include <unistd.h>
           #endif
           #include <fcntl.h>
           #include <sys/types.h>
           #include <sys/mman.h>
           int main ()
           {
           '
         mmap_prog_2="
             #define bits_to_avoid $avoid"'
             #define my_shift 24
             #define my_low   1
             #define my_high  64
             #define my_size  8192 /* hope that 8192 is a multiple of the page size */
             /* i*8 KB for i=1..64 gives a total of 16.25 MB, which is close to what we need */
             #if defined(__APPLE__) && defined(__MACH__) && defined(__x86_64__)
              /* On MacOS X in 64-bit mode, mmapable addresses start at 2^33. */
              #define base_address 0x200000000UL
             #else
              #define base_address 0
             #endif
             {
               long i;
               #define i_ok(i)  ((i) & (bits_to_avoid >> my_shift) == 0)
               for (i=my_low; i<=my_high; i++)
                 if (i_ok(i))
                   {
                     char* addr = (char*)(base_address + (i << my_shift));
                     /* Check for 8 MB, not 16 MB. This is more likely to work on Solaris 2. */
                     #if bits_to_avoid
                       long size = i*my_size;
                     #else
                       long size = ((i+1)/2)*my_size;
                     #endif
                     if (mmap(addr,size,PROT_READ|PROT_WRITE,flags|MAP_FIXED,fd,0) == (void*)-1) exit(1);
                   }
               #define x(i)  *(unsigned char *) (base_address + (i<<my_shift) + (i*i))
               #define y(i)  (unsigned char)((3*i-4)*(7*i+3))
               for (i=my_low; i<=my_high; i++)
                 if (i_ok(i))
                   {
                     x(i) = y(i);
                   }
               for (i=my_high; i>=my_low; i--)
                 if (i_ok(i))
                   {
                     if (x(i) != y(i)) exit(1);
                   }
               exit(0);
             }
           }
           '
         AC_TRY_RUN(GL_NOCRASH[
           $mmap_prog_1
             int flags = MAP_ANON | MAP_PRIVATE;
             int fd = -1;
             nocrash_init();
           $mmap_prog_2
           ],
           [have_mmap_anon=1
            cl_cv_func_mmap_anon=yes
           ],
           [],
           [: # When cross-compiling, don't assume anything.])
         AC_TRY_RUN(GL_NOCRASH[
           $mmap_prog_1
             int flags = MAP_ANONYMOUS | MAP_PRIVATE;
             int fd = -1;
             nocrash_init();
           $mmap_prog_2
           ],
           [have_mmap_anon=1
            cl_cv_func_mmap_anonymous=yes
           ],
           [],
           [: # When cross-compiling, don't assume anything.])
         AC_TRY_RUN(GL_NOCRASH[
           $mmap_prog_1
             #ifndef MAP_FILE
              #define MAP_FILE 0
             #endif
             int flags = MAP_FILE | MAP_PRIVATE;
             int fd = open("/dev/zero",O_RDONLY,0666);
             if (fd<0) exit(1);
             nocrash_init();
           $mmap_prog_2
           ],
           [have_mmap_devzero=1
            cl_cv_func_mmap_devzero=yes
           ],
           [],
           [: # When cross-compiling, don't assume anything.])
         if test -n "$have_mmap_anon" -o -n "$have_mmap_devzero"; then
           cl_cv_func_mmap_works=yes
         else
           cl_cv_func_mmap_works=no
         fi
        ])
      if test "$cl_cv_func_mmap_anon" = yes; then
        AC_DEFINE([HAVE_MMAP_ANON],,[<sys/mman.h> defines MAP_ANON and mmaping with MAP_ANON works])
      fi
      if test "$cl_cv_func_mmap_anonymous" = yes; then
        AC_DEFINE([HAVE_MMAP_ANONYMOUS],,[<sys/mman.h> defines MAP_ANONYMOUS and mmaping with MAP_ANONYMOUS works])
      fi
      if test "$cl_cv_func_mmap_devzero" = yes; then
        AC_DEFINE([HAVE_MMAP_DEVZERO],,[mmaping of the special device /dev/zero works])
      fi
    fi
  fi

  if test "$cl_cv_func_mmap_works" = yes; then
    dnl For SINGLEMAP_MEMORY and the TYPECODES object representation:
    dnl Test which is the highest bit number < 63 (or < 31) at which the kernel
    dnl allows us to mmap memory with MAP_FIXED. That is, try
    dnl   0x4000000000000000 -> 62
    dnl   0x2000000000000000 -> 61
    dnl   0x1000000000000000 -> 60
    dnl   ...
    dnl and return the highest bit number for which mmap succeeds.
    dnl Don't need to test bit 63 (or 31) because we use it as garcol_bit in TYPECODES.
    AC_CACHE_CHECK([for highest bit number which can be included in mmaped addresses],
      [cl_cv_func_mmap_highest_bit],
      [AC_TRY_RUN([
         #include <stdlib.h>
         #ifdef HAVE_UNISTD_H
          #include <unistd.h>
         #endif
         #include <fcntl.h>
         #include <sys/types.h>
         #include <sys/mman.h>
         #ifndef MAP_FILE
          #define MAP_FILE 0
         #endif
         #ifndef MAP_VARIABLE
          #define MAP_VARIABLE 0
         #endif
         int
         main ()
         {
           unsigned int my_size = 32768; /* hope that 32768 is a multiple of the page size */
           int pos;
           for (pos = 8*sizeof(void*)-2; pos > 0; pos--)
             {
               unsigned long address = (unsigned long)1 << pos;
               if (address < 4096)
                 break;
               #ifdef __ia64__
               /* On IA64 in 64-bit mode, the executable sits at 0x4000000000000000.
                  An mmap call to this address would either crash the program (on Linux)
                  or fail (on HP-UX). */
               if (pos == 62)
                 continue;
               #endif
               {
                 char *p;
                 int ret;
                 #if defined HAVE_MMAP_ANON
                   p = (char *) mmap ((void*)address, my_size, PROT_READ | PROT_WRITE, MAP_FIXED | MAP_PRIVATE | MAP_ANON | MAP_VARIABLE, -1, 0);
                 #elif defined HAVE_MMAP_ANONYMOUS
                   p = (char *) mmap ((void*)address, my_size, PROT_READ | PROT_WRITE, MAP_FIXED | MAP_PRIVATE | MAP_ANONYMOUS | MAP_VARIABLE, -1, 0);
                 #elif defined HAVE_MMAP_DEVZERO
                   int zero_fd = open("/dev/zero", O_RDONLY, 0666);
                   if (zero_fd < 0)
                     return 1;
                   p = (char *) mmap ((void*)address, my_size, PROT_READ | PROT_WRITE, MAP_FIXED | MAP_PRIVATE | MAP_FILE | MAP_VARIABLE, zero_fd, 0);
                 #else
                   ??
                 #endif
                 if (p != (char*) -1)
                   /* mmap succeeded. */
                   return pos;
               }
             }
           return 0;
         }
         ],
         [cl_cv_func_mmap_highest_bit=none],
         [cl_cv_func_mmap_highest_bit=$?
          case "$cl_cv_func_mmap_highest_bit" in
            0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 ) dnl Most likely a compiler error code.
              cl_cv_func_mmap_highest_bit=none ;;
          esac
         ],
         [cl_cv_func_mmap_highest_bit="guessing none"])
      ])
    case "$cl_cv_func_mmap_highest_bit" in
      *none) value='-1' ;;
      *) value="$cl_cv_func_mmap_highest_bit" ;;
    esac
  else
    value='-1'
  fi
  AC_DEFINE_UNQUOTED([MMAP_FIXED_ADDRESS_HIGHEST_BIT], [$value],
    [Define to the highest bit number that can be included in mmaped addresses.])
])
