# Auxiliary functions for CLISP on Win32
# Bruno Haible 1997-1999

#include "lispbibl.c"

# File handles of standard input and standard output
  global Handle stdin_handle = INVALID_HANDLE_VALUE;
  global Handle stdout_handle = INVALID_HANDLE_VALUE;

# Auxiliary event for full_read and full_write.
  local HANDLE aux_event;

# Character conversion table for OEM->ANSI.
  local char OEM2ANSI_table[256+1];

# Character conversion table for ANSI->OEM.
  local char ANSI2OEM_table[256+1];

# Auxiliary event for interrupt handling.
  local HANDLE sigint_event;
  local HANDLE sigbreak_event;

# Initialization.
  global void init_win32 (void);
  global void init_win32()
    {
      # Standard input/output handles.
      stdin_handle = GetStdHandle(STD_INPUT_HANDLE);
      stdout_handle = GetStdHandle(STD_OUTPUT_HANDLE);
      # What to do if one of these is == INVALID_HANDLE_VALUE ??
      # Auxiliary events.
      aux_event = CreateEvent(NULL, TRUE, FALSE, NULL);
      sigint_event = CreateEvent(NULL, TRUE, FALSE, NULL);
      sigbreak_event = CreateEvent(NULL, TRUE, FALSE, NULL);
      # Translation table for console input.
      {
        var int i;
        for (i = 0; i < 256; i++)
          OEM2ANSI_table[i] = i;
        OEM2ANSI_table[i] = '\0';
        OemToChar(&OEM2ANSI_table[1],&OEM2ANSI_table[1]);
      }
      # Translation table for console output.
      {
        var int i;
        for (i = 0; i < 256; i++)
          ANSI2OEM_table[i] = i;
        ANSI2OEM_table[i] = '\0';
        CharToOem(&ANSI2OEM_table[1],&ANSI2OEM_table[1]);
      }
      # Winsock.
      {
        var WSADATA data;
        if (WSAStartup(MAKEWORD(1,1),&data)) {
          SOCK_error();
        }
      }
    }


# Ctrl-C-interruptibility.
# We treat Ctrl-C as under Unix: Enter a break loop, continuable if possible.
# We treat Ctrl-Break as usual under Windows: abort the application, as if
# (exit t) was called, with exit code 130.
  # Call fn(arg), being able to abort it if Ctrl-C is pressed.
  # Not reentrant, hence fn() should be very simple and not invoke callbacks.
  # fn() should return 0 once it terminated successfully.
  # Returns TRUE if successful, FALSE if interrupted.
  local BOOL DoInterruptible (LPTHREAD_START_ROUTINE fn, LPVOID arg, BOOL socketp);
  local BOOL interruptible_active;
  local HANDLE interruptible_thread;
  local BOOL interruptible_socketp;

  local BOOL temp_interrupt_handler (DWORD CtrlType);
  local BOOL temp_interrupt_handler(CtrlType)
    var DWORD CtrlType;
    {
      if (CtrlType == CTRL_C_EVENT || CtrlType == CTRL_BREAK_EVENT) {
        # Could invoke a signal handler at this point.??
        if (interruptible_active) {
          # Set interruptible_active to false, so we won't get here a
          # second time and try to terminate the same thread twice.
          interruptible_active = FALSE;
          # Terminate the interruptible operation, set the exitcode to 1.
          if (interruptible_socketp) {
            WSACancelBlockingCall();
          }
          if (!TerminateThread(interruptible_thread,1+CtrlType)) {
            OS_error();
          }
        }
        # Don't invoke the other handlers (in particular, the default handler)
        return TRUE;
      } else {
        # Do invoke the other handlers.
        return FALSE;
      }
    }

  local BOOL DoInterruptible(fn,arg,socketp)
    var LPTHREAD_START_ROUTINE fn;
    var LPVOID arg;
    var BOOL socketp;
    {
      var HANDLE thread;
      var DWORD thread_id;
      var DWORD thread_exitcode;
      thread = CreateThread(NULL,10000,fn,arg,0,&thread_id);
      if (thread==NULL) {
        OS_error();
      }
      interruptible_active = FALSE;
      interruptible_thread = thread;
      interruptible_socketp = socketp;
      SetConsoleCtrlHandler((PHANDLER_ROUTINE)temp_interrupt_handler,TRUE);
      interruptible_active = TRUE;
      WaitForSingleObject(interruptible_thread,INFINITE);
      interruptible_active = FALSE;
      SetConsoleCtrlHandler((PHANDLER_ROUTINE)temp_interrupt_handler,FALSE);
      GetExitCodeThread(interruptible_thread,&thread_exitcode);
      CloseHandle(interruptible_thread);
      if (thread_exitcode==0) {
        return TRUE; # successful termination
      } else {
        if (thread_exitcode == 1+CTRL_BREAK_EVENT) {
          final_exitcode = 130; quit(); # aborted by Ctrl-Break
        }
        return FALSE; # aborted by Ctrl-C
      }
    }


# Sleep a certain time.
# Return TRUE after normal termination, FALSE if interrupted by Ctrl-C.
  global BOOL msleep (DWORD milliseconds);
  local DWORD WINAPI do_sleep (LPVOID arg);
  local DWORD WINAPI do_sleep(arg)
    var LPVOID arg;
    {
      Sleep((DWORD)arg);
      return 0;
    }
  global BOOL msleep(milliseconds)
    var DWORD milliseconds;
    {
      return DoInterruptible(&do_sleep,(void*)milliseconds,FALSE);
    }

# Sleep a certain time.
  global unsigned int sleep (unsigned int seconds);
  global unsigned int sleep(seconds)
    var unsigned int seconds;
    {
      msleep(seconds*1000);
      return 0; # the return value is wrong
    }


# To catch Ctrl-C events, we use a separate thread which waits for an event,
# and install (using SetConsoleCtrlHandler()) a Ctrl-C handler which sends
# an event to this thread. The thread then waits for an appropriate moment
# to let the main thread hyperjump to the desired signal handler.
# We choose this approach because:
# - we don't know in which thread the handler installed via
#   SetConsoleCtrlHandler() will be executed (main thread? separate thread?
#   any other thread?),
# - the desired signal handler may longjmp(), hence we don't want it to
#   be executed in any other thread than the main thread,
# - letting another thread hyperjump is feasible (through GetThreadContext()/
#   SetThreadContext()), but a thread cannot hyperjump itself.

  local HANDLE main_thread = INVALID_HANDLE_VALUE;
  local HANDLE sigint_thread = INVALID_HANDLE_VALUE;

  # Destination for hyperjump. Normally &interrupt_handler, but set to &quit
  # when a Ctrl-Break was seen.
  local DWORD hyperjump_dest = (DWORD)&interrupt_handler;

  local BOOL normal_interrupt_handler (DWORD CtrlType);
  local BOOL normal_interrupt_handler(CtrlType)
    var DWORD CtrlType;
    {
      if (CtrlType == CTRL_C_EVENT || CtrlType == CTRL_BREAK_EVENT) {
        # Send an event to the sigint_thread.
        interrupt_pending = TRUE;
        if (CtrlType == CTRL_C_EVENT) {
          if (!PulseEvent(sigint_event)) {
            OS_error();
          }
        } elif (CtrlType == CTRL_BREAK_EVENT) {
          if (!PulseEvent(sigbreak_event)) {
            OS_error();
          }
        }
        # Don't invoke the other handlers (in particular, the default handler)
        return TRUE;
      } else {
        # Do invoke the other handlers.
        return FALSE;
      }
    }

  local DWORD WINAPI do_sigintwait (LPVOID arg);
  local DWORD WINAPI do_sigintwait(arg)
    var LPVOID arg;
    {
      var int waitstate = 0; // 0: infinite, 1: 0.5 sec, 2: 0.05 sec.
      var local DWORD wait_duration[3] = { INFINITE, 500, 50 };
      var HANDLE waitfor[2];
      waitfor[0] = sigint_event;
      waitfor[1] = sigbreak_event;
      for (;;)
        switch (WaitForMultipleObjects(2,&waitfor[0],FALSE,wait_duration[waitstate])) {
          case WAIT_OBJECT_0+0:
            # Got a sigint_event!
            if (!interrupt_pending) { # already being handled?
              waitstate = 0; break;
            }
            if (waitstate==0) {
              # Do not hyperjump right now. Wait a while - maybe
              # interrupt_pending=TRUE causes a continuable interruption.
              waitstate = 1; break;
            }
            goto try_hyperjump;
          case WAIT_OBJECT_0+1:
            # Got a sigbreak_event!
            final_exitcode = 130; hyperjump_dest = (DWORD)&quit;
            goto try_hyperjump;
          case WAIT_TIMEOUT:
            if (!interrupt_pending) { # already being handled?
              waitstate = 0; break;
            }
            goto try_hyperjump;
          try_hyperjump:
            waitstate = 2;
            # Stop the main thread so that it can't run while we hyperjump it.
            SuspendThread(main_thread);
            if (break_sems_cleared()) {
              # OK, the moment has come to hyperjump the main thread.
              # asciz_out_2("\nHyperjumping! interrupt_pending = %d, waitstate = %d\n",interrupt_pending,waitstate);
              var CONTEXT context;
              context.ContextFlags = CONTEXT_CONTROL | CONTEXT_INTEGER;
              GetThreadContext(main_thread,&context);
              context.Eip = hyperjump_dest;
              SetThreadContext(main_thread,&context);
              # Now it's ok to release the main thread.
              waitstate = 0;
            }
            ResumeThread(main_thread);
            break;
          default: NOTREACHED
        }
    }

  global void install_sigint_handler (void);
  global void install_sigint_handler()
    {
      ASSERT(main_thread==INVALID_HANDLE_VALUE && sigint_thread==INVALID_HANDLE_VALUE);
      # Get main_thread, assuming we are in the main thread.
      if (!DuplicateHandle(GetCurrentProcess(),GetCurrentThread(),
                           GetCurrentProcess(),&main_thread,
                           0, FALSE, DUPLICATE_SAME_ACCESS)) {
        OS_error();
      }
      # Start sigint_thread.
      {
        var DWORD thread_id;
        var HANDLE thread = CreateThread(NULL,10000,(LPTHREAD_START_ROUTINE)do_sigintwait,(LPVOID)0,0,&thread_id);
        if (thread==NULL) {
          OS_error();
        }
        sigint_thread = thread;
      }
      # Install normal_interrupt_handler.
      if (!SetConsoleCtrlHandler((PHANDLER_ROUTINE)normal_interrupt_handler,TRUE)) {
        OS_error();
      }
    }


# Limit for the size of a buffer we pass to WriteFile() and similar calls.
# Before introducing this, I have seen mem file corruption: The file produced
# by SAVEINITMEM contained wrong data. More exactly, inside a WriteFile()
# block of size about 75 KB, a block of exactly 8192 bytes, starting at
# an odd address, was shifted to the right by 3 bytes, with zeroes inserted
# at the beginning and three bytes shifted out and lost at the end of this
# 8KB block. This problem sometimes disappeared spontaneously, sometimes by
# rebooting, and was sometimes 100% reproducible (the faulty block being
# always at the same address).
# This could be a bug in WinNT 3.51 or in the NFS client. In any case, it's
# better to work around it: Don't pass areas larger than 64 KB to WriteFile().
# Similarly for ReadFile() and similar calls, since we don't know exactly
# where the bug sits.
# PS: I know that this was necessary in VMS. But this is Win32, not VMS ...
  #define MAX_IO  32768

# Reading from a console.
# Normally, ReadConsoleInput() waits until an keyboard event occurs. Ctrl-C
# is *not* a keyboard event. If the user presses Ctrl-C during a
# ReadConsoleInput() call, hyperjumping takes place, but the main thread
# is not scheduled until a keyboard event occurs. To avoid this, let
# the ReadConsoleInput() call be performed in a separate thread.
# It doesn't make sense to call this with Length > 1 (because some typed
# characters might get lost).
  struct ReadConsoleInput_params {
    HANDLE ConsoleInput; PINPUT_RECORD Buffer; LPDWORD NumberOfEventsRead;
    BOOL retval; DWORD errcode;
  };
  local DWORD WINAPI do_ReadConsoleInput (LPVOID arg);
  local DWORD WINAPI do_ReadConsoleInput(arg)
    var LPVOID arg;
    {
      var struct ReadConsoleInput_params * params = (struct ReadConsoleInput_params *)arg;
      params->retval = ReadConsoleInput(params->ConsoleInput,params->Buffer,1,params->NumberOfEventsRead);
      if (!params->retval)
        params->errcode = GetLastError();
      return 0;
    }
  # Like ReadConsoleInput with Length==1, but is interruptible by Ctrl-C.
  global BOOL ReadConsoleInput1 (HANDLE ConsoleInput, PINPUT_RECORD Buffer, LPDWORD NumberOfEventsRead);
  global BOOL ReadConsoleInput1(ConsoleInput,Buffer,NumberOfEventsRead)
    var HANDLE ConsoleInput;
    var PINPUT_RECORD Buffer;
    var LPDWORD NumberOfEventsRead;
    {
      var struct ReadConsoleInput_params params;
      params.ConsoleInput       = ConsoleInput;
      params.Buffer             = Buffer;
      params.NumberOfEventsRead = NumberOfEventsRead;
      params.retval             = 0;
      params.errcode            = 0;
      if (DoInterruptible(&do_ReadConsoleInput,(void*)&params,FALSE)) {
        if (!params.retval)
          SetLastError(params.errcode);
        return params.retval;
      } else {
        SetLastError(ERROR_SIGINT); return FALSE;
      }
    }

# Reading from a file/pipe/console handle.
  # This is the non-interruptible routine.
  local int lowlevel_full_read (HANDLE fd, void* buf, int nbyte);
  local int lowlevel_full_read(fd,bufarea,nbyte)
    var HANDLE fd;
    var void* bufarea;
    var int nbyte;
    {
      #if (defined(GENERATIONAL_GC) && defined(SPVW_MIXED)) || defined(SELFMADE_MMAP)
      handle_fault_range(PROT_READ_WRITE,(aint)bufarea,(aint)bufarea+nbyte);
      #endif
      var char* buf = (char*) bufarea;
      var int done = 0;
      until (nbyte==0) {
        var int limited_nbyte = (nbyte <= MAX_IO ? nbyte : MAX_IO);
        var OVERLAPPED overlap;
        var DWORD nchars;
        var DWORD err;
        overlap.Offset = 0;
        overlap.OffsetHigh = 0;
        overlap.Offset = SetFilePointer(fd, 0, &overlap.OffsetHigh, FILE_CURRENT);
        ResetEvent(aux_event);
        overlap.hEvent = aux_event;
        if (ReadFile(fd, buf, limited_nbyte, &nchars, &overlap))
          goto ok;
        /* Disk files (and maybe other handle types) don't support
           overlapped I/O on Win95. */
        err = GetLastError();
        if (err == ERROR_INVALID_PARAMETER) {
          if (ReadFile(fd, buf, limited_nbyte, &nchars, NULL))
            goto ok;
          err = GetLastError();
          /* On Win95, console handles need special handling. */
          if (err == ERROR_INVALID_PARAMETER) {
            if (ReadConsole(fd, buf, limited_nbyte, &nchars, NULL))
              goto ok;
            err = GetLastError();
          }
        }
        if (err == ERROR_HANDLE_EOF || err == ERROR_BROKEN_PIPE)
          break;
        if (err != ERROR_IO_PENDING)
          return -1;
        if (!GetOverlappedResult(fd, &overlap, &nchars, TRUE)) {
          if (GetLastError() == ERROR_HANDLE_EOF)
            break;
          return -1;
        }
       ok:
        if (nchars == 0)
          break;
        buf += nchars; done += nchars; nbyte -= nchars;
      }
      # Possibly translate characters.
      if (done > 0) {
        var int i;
        for (i = -done; i < 0; i++) {
          var unsigned char c = (unsigned char)buf[i];
          if (!(c == (unsigned char)OEM2ANSI_table[c]))
            goto maybe_translate;
        }
        # No character found for which translation makes a difference,
        # hence no need to translate.
        if (FALSE) {
         maybe_translate:
          var DWORD console_mode;
          if (GetConsoleMode(fd,&console_mode)) {
            # It's a console, must really translate characters!
            for (i = -done; i < 0; i++)
              buf[i] = OEM2ANSI_table[(unsigned char)buf[i]];
          }
        }
      }
      return done;
    }
  # Then we make it interruptible.
  struct full_read_params {
    HANDLE fd; void* buf; int nbyte;
    int retval; DWORD errcode;
  };
  local DWORD WINAPI do_full_read (LPVOID arg);
  local DWORD WINAPI do_full_read(arg)
    var LPVOID arg;
    {
      var struct full_read_params * params = (struct full_read_params *)arg;
      params->retval = lowlevel_full_read(params->fd,params->buf,params->nbyte);
      if (params->retval < 0)
        params->errcode = GetLastError();
      return 0;
    }
  global int full_read (HANDLE fd, void* buf, int nbyte);
  global int full_read(fd,buf,nbyte)
    var HANDLE fd;
    var void* buf;
    var int nbyte;
    {
      var struct full_read_params params;
      params.fd      = fd;
      params.buf     = buf;
      params.nbyte   = nbyte;
      params.retval  = 0;
      params.errcode = 0;
      if (DoInterruptible(&do_full_read,(void*)&params,FALSE)) {
        if (params.retval < 0)
          SetLastError(params.errcode);
        return params.retval;
      } else {
        SetLastError(ERROR_SIGINT); return -1;
      }
    }

# Writing to a file/pipe/console handle.
  global int full_write (HANDLE fd, const void* buf, int nbyte);
  global int full_write(fd,bufarea,nbyte)
    var HANDLE fd;
    var const void* bufarea;
    var int nbyte;
    {
      #if (defined(GENERATIONAL_GC) && defined(SPVW_MIXED)) || defined(SELFMADE_MMAP)
      handle_fault_range(PROT_READ,(aint)bufarea,(aint)bufarea+nbyte);
      #endif
      var const char* buf = (const char*) bufarea;
      # Possibly translate characters.
      if (nbyte > 0) {
        var int i;
        for (i = 0; i < nbyte; i++) {
          var unsigned char c = (unsigned char)buf[i];
          if (!(c == (unsigned char)ANSI2OEM_table[c]))
            goto maybe_translate;
        }
        # No character found for which translation makes a difference,
        # hence no need to translate.
        if (FALSE) {
         maybe_translate:
          var DWORD console_mode;
          if (GetConsoleMode(fd,&console_mode)) {
            # It's a console, must really translate characters!
            var char* newbuf = alloca(nbyte);
            for (i = 0; i < nbyte; i++)
              newbuf[i] = ANSI2OEM_table[(unsigned char)buf[i]];
            buf = newbuf;
          }
        }
      }
      var int done = 0;
      until (nbyte==0) {
        # Possibly check for Ctrl-C here ??
        var int limited_nbyte = (nbyte <= MAX_IO ? nbyte : MAX_IO);
        var OVERLAPPED overlap;
        var DWORD nchars;
        var DWORD err;
        overlap.Offset = 0;
        overlap.OffsetHigh = 0;
        overlap.Offset = SetFilePointer(fd, 0, &overlap.OffsetHigh, FILE_CURRENT);
        ResetEvent(aux_event);
        overlap.hEvent = aux_event;
        if (WriteFile(fd, buf, limited_nbyte, &nchars, &overlap))
          goto ok;
        /* Disk files (and maybe other handle types) don't support
           overlapped I/O on Win95. */
        err = GetLastError();
        if (err == ERROR_INVALID_PARAMETER) {
          if (WriteFile(fd, buf, limited_nbyte, &nchars, NULL))
            goto ok;
          err = GetLastError();
          /* On Win95, console handles need special handling. */
          if (err == ERROR_INVALID_PARAMETER) {
            if (WriteConsole(fd, buf, limited_nbyte, &nchars, NULL))
              goto ok;
            err = GetLastError();
          }
        }
        if (err != ERROR_IO_PENDING)
          return -1;
        if (!GetOverlappedResult(fd, &overlap, &nchars, TRUE))
          return -1;
       ok:
        buf += nchars; done += nchars; nbyte -= nchars;
      }
      return done;
    }

# Reading from a socket.
  # This is the non-interruptible routine.
  local int lowlevel_sock_read (SOCKET fd, void* buf, int nbyte);
  local int lowlevel_sock_read(fd,bufarea,nbyte)
    var SOCKET fd;
    var void* bufarea;
    var int nbyte;
    {
      #if (defined(GENERATIONAL_GC) && defined(SPVW_MIXED)) || defined(SELFMADE_MMAP)
      handle_fault_range(PROT_READ_WRITE,(aint)bufarea,(aint)bufarea+nbyte);
      #endif
      var char* buf = (char*) bufarea;
      var int done = 0;
      until (nbyte==0) {
        var int limited_nbyte = (nbyte <= MAX_IO ? nbyte : MAX_IO);
        var int retval = recv(fd,buf,limited_nbyte,0);
        if (retval == 0)
          break;
        elif (retval < 0)
          return retval;
        else {
          buf += retval; done += retval; nbyte -= retval;
        }
      }
      return done;
    }
  # Then we make it interruptible.
  struct sock_read_params {
    SOCKET fd; void* buf; int nbyte;
    int retval; int errcode;
  };
  local DWORD WINAPI do_sock_read (LPVOID arg);
  local DWORD WINAPI do_sock_read(arg)
    var LPVOID arg;
    {
      var struct sock_read_params * params = (struct sock_read_params *)arg;
      params->retval = lowlevel_sock_read(params->fd,params->buf,params->nbyte);
      if (params->retval < 0)
        params->errcode = WSAGetLastError();
      return 0;
    }
  global int sock_read (SOCKET fd, void* buf, int nbyte);
  global int sock_read(fd,buf,nbyte)
    var SOCKET fd;
    var void* buf;
    var int nbyte;
    {
      var struct sock_read_params params;
      params.fd      = fd;
      params.buf     = buf;
      params.nbyte   = nbyte;
      params.retval  = 0;
      params.errcode = 0;
      if (DoInterruptible(&do_sock_read,(void*)&params,TRUE)) {
        if (params.retval < 0)
          WSASetLastError(params.errcode);
        return params.retval;
      } else {
        WSASetLastError(WSAEINTR); return -1;
      }
    }

# Writing to a socket.
  # This is the non-interruptible routine.
  local int lowlevel_sock_write (SOCKET fd, const void* buf, int nbyte);
  local int lowlevel_sock_write(fd,bufarea,nbyte)
    var SOCKET fd;
    var const void* bufarea;
    var int nbyte;
    {
      #if (defined(GENERATIONAL_GC) && defined(SPVW_MIXED)) || defined(SELFMADE_MMAP)
      handle_fault_range(PROT_READ,(aint)bufarea,(aint)bufarea+nbyte);
      #endif
      var const char* buf = (const char*) bufarea;
      var int done = 0;
      until (nbyte==0) {
        var int limited_nbyte = (nbyte <= MAX_IO ? nbyte : MAX_IO);
        var int retval = send(fd,buf,limited_nbyte,0);
        if (retval == 0)
          break;
        elif (retval < 0)
          return retval;
        else {
          buf += retval; done += retval; nbyte -= retval;
        }
      }
      return done;
    }
  # Then we make it interruptible.
  struct sock_write_params {
    SOCKET fd; const void* buf; int nbyte;
    int retval; int errcode;
  };
  local DWORD WINAPI do_sock_write (LPVOID arg);
  local DWORD WINAPI do_sock_write(arg)
    var LPVOID arg;
    {
      var struct sock_write_params * params = (struct sock_write_params *)arg;
      params->retval = lowlevel_sock_write(params->fd,params->buf,params->nbyte);
      if (params->retval < 0)
        params->errcode = WSAGetLastError();
      return 0;
    }
  global int sock_write (SOCKET fd, const void* buf, int nbyte);
  global int sock_write(fd,buf,nbyte)
    var SOCKET fd;
    var const void* buf;
    var int nbyte;
    {
      var struct sock_write_params params;
      params.fd      = fd;
      params.buf     = buf;
      params.nbyte   = nbyte;
      params.retval  = 0;
      params.errcode = 0;
      if (DoInterruptible(&do_sock_write,(void*)&params,TRUE)) {
        if (params.retval < 0)
          WSASetLastError(params.errcode);
        return params.retval;
      } else {
        WSASetLastError(WSAEINTR); return -1;
      }
    }

# Testing for possibly interactive handle.
  global int isatty (HANDLE handle);
  global int isatty(handle)
    var HANDLE handle;
    {
      var DWORD ftype = GetFileType(handle);
      return (ftype == FILE_TYPE_CHAR || ftype == FILE_TYPE_PIPE);
    }


# Create a new process, given a command line and two handles for standard
# input and standard output (both must be inheritable).
  global BOOL MyCreateProcess (LPTSTR CommandLine, HANDLE StdInput, HANDLE StdOutput, LPPROCESS_INFORMATION ProcessInformation);
  global BOOL MyCreateProcess(CommandLine,StdInput,StdOutput,ProcessInformation)
    var LPTSTR CommandLine;
    var HANDLE StdInput;
    var HANDLE StdOutput;
    var LPPROCESS_INFORMATION ProcessInformation;
    {
      var STARTUPINFO sinfo;
      sinfo.cb = sizeof(STARTUPINFO);
      sinfo.lpReserved = NULL;
      sinfo.lpDesktop = NULL;
      sinfo.lpTitle = NULL;
      sinfo.cbReserved2 = 0;
      sinfo.lpReserved2 = NULL;
      sinfo.dwFlags = STARTF_USESTDHANDLES;
      sinfo.hStdInput = StdInput;
      sinfo.hStdOutput = StdOutput;
      sinfo.hStdError = GetStdHandle(STD_ERROR_HANDLE);
      if (sinfo.hStdError == INVALID_HANDLE_VALUE)
        return FALSE;
      if (!CreateProcess(NULL, CommandLine, NULL, NULL, TRUE, 0,
                         NULL, NULL, &sinfo, ProcessInformation))
        return FALSE;
      return TRUE;
    }


# I want to see a backtrace!
  int abort_dummy;
  global void abort()
    {
      #ifdef MICROSOFT
        # This hack is necessary because if you write  1/0  the MSVC compiler
        # signals an error at compilation time!!
        var volatile int zero = 0;
        abort_dummy = 1/zero;
      #else
        abort_dummy = 1/0;
      #endif
    }


# Print out the memory map of the process.
  global void DumpProcessMemoryMap (void);
  global void DumpProcessMemoryMap()
    {
      var MEMORY_BASIC_INFORMATION info;
      var aint address = 0;
      asciz_out("Memory dump:" NLstring);
      while (VirtualQuery((void*)address,&info,sizeof(info)) == sizeof(info)) {
        # Always info.BaseAddress = address.
        switch (info.State) {
          case MEM_FREE:    asciz_out("-"); break;
          case MEM_RESERVE: asciz_out("+"); break;
          case MEM_COMMIT:  asciz_out("*"); break;
          default: asciz_out("?"); break;
        }
        asciz_out_2(" 0x%x - 0x%x",(aint)info.BaseAddress,
                                   (aint)info.BaseAddress+info.RegionSize-1);
        if (!(info.State == MEM_FREE)) {
          asciz_out_1(" (0x%x) ",(aint)info.AllocationBase);
          # info.AllocationProtect is apparently irrelevant.
          switch (info.Protect & ~(PAGE_GUARD|PAGE_NOCACHE)) {
            case PAGE_READONLY:          asciz_out(" R  "); break;
            case PAGE_READWRITE:         asciz_out(" RW "); break;
            case PAGE_WRITECOPY:         asciz_out(" RWC"); break;
            case PAGE_EXECUTE:           asciz_out("X   "); break;
            case PAGE_EXECUTE_READ:      asciz_out("XR  "); break;
            case PAGE_EXECUTE_READWRITE: asciz_out("XRW "); break;
            case PAGE_EXECUTE_WRITECOPY: asciz_out("XRWC"); break;
            case PAGE_NOACCESS:          asciz_out("----"); break;
            default: asciz_out("?"); break;
          }
          if (info.Protect & PAGE_GUARD)
            asciz_out(" PAGE_GUARD");
          if (info.Protect & PAGE_NOCACHE)
            asciz_out(" PAGE_NOCACHE");
          asciz_out(" ");
          switch (info.Type) {
            case MEM_IMAGE:   asciz_out("MEM_IMAGE"); break;
            case MEM_MAPPED:  asciz_out("MEM_MAPPED"); break;
            case MEM_PRIVATE: asciz_out("MEM_PRIVATE"); break;
            default:          asciz_out("MEM_?"); break;
          }
        }
        asciz_out(NLstring);
        address = (aint)info.BaseAddress + info.RegionSize;
      }
      asciz_out("End of memory dump." NLstring);
    }

