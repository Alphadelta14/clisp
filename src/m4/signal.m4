dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2008, 2015, 2017 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ([2.57])

AC_DEFUN([CL_SIGNAL_REINSTALL],
[
  AC_BEFORE([$0], [CL_SIGNAL_UNBLOCK])
  AC_BEFORE([$0], [CL_SIGNAL_BLOCK_OTHERS])
  AC_CACHE_CHECK([whether signal handlers need to be reinstalled],
    [cl_cv_func_signal_reinstall],
    [AC_TRY_RUN([
       #include <stdlib.h>
       #ifdef HAVE_UNISTD_H
        #include <unistd.h>
       #endif
       #include <signal.h>
       volatile int gotsig = 0;
       void sigalrm_handler()
       {
         gotsig = 1;
       }
       int got_sig () { return gotsig; }
       typedef void (*signal_handler_t) (int);
       int main() /* returns 0 if they need not to be reinstalled */
       {
         signal(SIGALRM,(signal_handler_t)sigalrm_handler);
         alarm(1);
         while (!got_sig())
           ;
         exit(!( (signal_handler_t)signal(SIGALRM,(signal_handler_t)sigalrm_handler)
                 == (signal_handler_t)sigalrm_handler
             ) );
       }
       ],
       [cl_cv_func_signal_reinstall=no],
       [cl_cv_func_signal_reinstall=yes],
       [dnl When cross-compiling, don't assume anything.
        cl_cv_func_signal_reinstall="guessing yes"
       ])
    ])
  case "$cl_cv_func_signal_reinstall" in
    *yes)
      AC_DEFINE([SIGNAL_NEED_REINSTALL],,
        [signal handlers need to be reinstalled when they are activated])
      ;;
    *no) ;;
  esac
])

AC_DEFUN([CL_SIGNAL_UNBLOCK],
[
  AC_REQUIRE([CL_SIGNAL_REINSTALL])
  case "$signalblocks" in
    *POSIX* | *BSD*)
      AC_CACHE_CHECK([whether signals are blocked when signal handlers are entered],
        [cl_cv_func_signal_blocked],
        [AC_TRY_RUN([
           #include <stdlib.h>
           #ifdef HAVE_UNISTD_H
            #include <unistd.h>
           #endif
           #include <signal.h>
           volatile int gotsig = 0;
           volatile int wasblocked = 0;
           typedef void (*signal_handler_t) (int);
           void sigalrm_handler()
           {
             gotsig = 1;
             #ifdef SIGNAL_NEED_REINSTALL
               signal(SIGALRM,(signal_handler_t)sigalrm_handler);
             #endif
             {
               sigset_t blocked;
               sigprocmask(SIG_BLOCK, (sigset_t *) 0, &blocked);
               wasblocked = sigismember(&blocked,SIGALRM) ? 1 : 0;
             }
           }
           int got_sig () { return gotsig; }
           int main() /* returns 0 if they need not to be unblocked */
           {
             signal(SIGALRM,(signal_handler_t)sigalrm_handler);
             alarm(1);
             while (!got_sig())
               ;
             exit(wasblocked);
           }
           ],
           [cl_cv_func_signal_blocked=no], [cl_cv_func_signal_blocked=yes],
           [dnl When cross-compiling, assume the worst case.
            cl_cv_func_signal_blocked="guessing yes"
           ])
        ])
      case "$cl_cv_func_signal_blocked" in
        *yes)
          AC_DEFINE([SIGNAL_NEED_UNBLOCK],,
            [SIGNALBLOCK_BSD is defined above and signals need to be unblocked when signal handlers are left])
          ;;
        *no) ;;
      esac
      ;;
    *) ;;
  esac
])

AC_DEFUN([CL_SIGNAL_BLOCK_OTHERS],
[
  AC_REQUIRE([CL_SIGNAL_REINSTALL])
  case "$signalblocks" in
    *POSIX* | *BSD*)
      AC_CACHE_CHECK([whether other signals are blocked when signal handlers are entered],
        [cl_cv_func_signal_blocked_others],
        [AC_TRY_RUN([
           #include <stdlib.h>
           #ifdef HAVE_UNISTD_H
            #include <unistd.h>
           #endif
           #include <signal.h>
           volatile int gotsig = 0;
           volatile int somewereblocked = 0;
           typedef void (*signal_handler_t) (int);
           void sigalrm_handler()
           {
             gotsig = 1;
             #ifdef SIGNAL_NEED_REINSTALL
               signal(SIGALRM,(signal_handler_t)sigalrm_handler);
             #endif
             {
               sigset_t blocked;
               int i;
               sigprocmask(SIG_BLOCK, (sigset_t *) 0, &blocked);
               for (i=1; i<32; i++)
                 if (i!=SIGALRM && sigismember(&blocked,i))
                   somewereblocked = 1;
             }
           }
           int got_sig () { return gotsig; }
           int main() /* returns 0 if they need not to be unblocked */
           {
             signal(SIGALRM,(signal_handler_t)sigalrm_handler);
             alarm(1);
             while (!got_sig())
               ;
             exit(somewereblocked);
           }
           ],
           [cl_cv_func_signal_blocked_others=no],
           [cl_cv_func_signal_blocked_others=yes],
           [dnl When cross-compiling, assume the worst case.
            cl_cv_func_signal_blocked_others="guessing yes"
           ])
        ])
      case "$cl_cv_func_signal_blocked_others" in
        *yes)
          AC_DEFINE([SIGNAL_NEED_UNBLOCK_OTHERS],,
            [SIGNALBLOCK_BSD is defined above and other signals need to be unblocked when signal handlers are left])
          ;;
        *no) ;;
      esac
      ;;
    *) ;;
  esac
])

AC_DEFUN([CL_SIGACTION],
[
  AC_BEFORE([$0], [CL_SIGACTION_REINSTALL])
  AC_BEFORE([$0], [CL_SIGINTERRUPT])
  AC_CHECK_FUNCS(sigaction)
])

AC_DEFUN([CL_SIGACTION_REINSTALL],
[
  AC_REQUIRE([CL_SIGACTION])
  AC_BEFORE([$0], [CL_SIGACTION_UNBLOCK])
  if test -n "$have_sigaction"; then
    AC_CACHE_CHECK([whether sigaction handlers need to be reinstalled],
      [cl_cv_func_sigaction_reinstall],
      [AC_TRY_RUN([
         #include <stdlib.h>
         #include <string.h>
         #ifdef HAVE_UNISTD_H
          #include <unistd.h>
         #endif
         #include <signal.h>
         typedef void (*signal_handler_t) (int);
         signal_handler_t mysignal (int sig, signal_handler_t handler)
         {
           struct sigaction old_sa;
           struct sigaction new_sa;
           memset(&new_sa,0,sizeof(new_sa));
           new_sa.sa_handler = handler;
           if (sigaction(sig,&new_sa,&old_sa)<0) { return (signal_handler_t)SIG_IGN; }
           return (signal_handler_t)old_sa.sa_handler;
         }
         volatile int gotsig = 0;
         void sigalrm_handler()
         {
           gotsig = 1;
         }
         int got_sig () { return gotsig; }
         int main() /* returns 0 if they need not to be reinstalled */
         {
           mysignal(SIGALRM,(signal_handler_t)sigalrm_handler);
           alarm(1);
           while (!got_sig())
             ;
           exit(!( mysignal(SIGALRM,(signal_handler_t)sigalrm_handler)
                   == (signal_handler_t)sigalrm_handler
               ) );
         }
         ],
         [cl_cv_func_sigaction_reinstall=no],
         [cl_cv_func_sigaction_reinstall=yes],
         [dnl When cross-compiling, don't assume anything.
          cl_cv_func_sigaction_reinstall="guessing yes"
         ])
      ])
    case "$cl_cv_func_sigaction_reinstall" in
      *yes)
        AC_DEFINE([SIGACTION_NEED_REINSTALL],,
          [signal handlers installed via sigaction() need to be reinstalled when they are activated])
        ;;
      *no) ;;
    esac
  fi
])

AC_DEFUN([CL_SIGACTION_UNBLOCK],
[
  AC_REQUIRE([CL_SIGACTION])
  AC_REQUIRE([CL_SIGACTION_REINSTALL])
  if test -n "$have_sigaction"; then
    case "$signalblocks" in
      *POSIX* | *BSD*)
        AC_CACHE_CHECK([whether signals are blocked when sigaction handlers are entered],
          [cl_cv_func_sigaction_blocked],
          [AC_TRY_RUN([
             #include <stdlib.h>
             #ifdef HAVE_UNISTD_H
              #include <unistd.h>
             #endif
             #include <signal.h>
             typedef void (*signal_handler_t) (int);
             signal_handler_t mysignal (int sig, signal_handler_t handler)
             {
               struct sigaction old_sa;
               struct sigaction new_sa;
               memset(&new_sa,0,sizeof(new_sa));
               new_sa.sa_handler = handler;
               if (sigaction(sig,&new_sa,&old_sa)<0) { return (signal_handler_t)SIG_IGN; }
               return (signal_handler_t)old_sa.sa_handler;
             }
             volatile int gotsig = 0;
             volatile int wasblocked = 0;
             void sigalrm_handler()
             {
               gotsig = 1;
               #ifdef SIGNAL_NEED_REINSTALL
                 mysignal(SIGALRM,(signal_handler_t)sigalrm_handler);
               #endif
               {
                 sigset_t blocked;
                 sigprocmask(SIG_BLOCK, (sigset_t *) 0, &blocked);
                 wasblocked = sigismember(&blocked,SIGALRM) ? 1 : 0;
               }
             }
             int got_sig () { return gotsig; }
             int main() /* returns 0 if they need not to be unblocked */
             {
               mysignal(SIGALRM,(signal_handler_t)sigalrm_handler);
               alarm(1);
               while (!got_sig())
                 ;
               exit(wasblocked);
             }
             ],
             [cl_cv_func_sigaction_blocked=no],
             [cl_cv_func_sigaction_blocked=yes],
             [dnl When cross-compiling, assume the worst case.
              cl_cv_func_sigaction_blocked="guessing yes"
             ])
          ])
        case "$cl_cv_func_sigaction_blocked" in
          *yes)
            AC_DEFINE([SIGACTION_NEED_UNBLOCK],,
              [signals need to be unblocked when signal handlers installed via sigaction() are left])
            ;;
          *no) ;;
        esac
        ;;
      *) ;;
    esac
  fi
])
