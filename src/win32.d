# Include file for WIN32_NATIVE version of CLISP
# Bruno Haible 1997-1999


# Konstanten f�r Steuerzeichen:

#define BEL  7              # Ton ausgeben
# define NL  10             # New line, siehe LISPBIBL.D
#define RUBOUT 127          # Rubout = Delete
#define CRLFstring  "\r\n"  # C-String, der BS-Newline enth�lt

# Declaration of operating system functions
  #define WIN32_LEAN_AND_MEAN  # avoid including junk
  #ifdef __MINGW32__
    # `unused' is used in function declarations.
    #undef unused
    #define ULONG OS_ULONG
    #include <windows.h>
    #undef ULONG
    #define unused (void)
  #else
    #include <windows.h>
  #endif

# Table of system error messages
  #include <winerror.h>
  # extern DWORD GetLastError (void);
  # extern void SetLastError (DWORD ErrCode);
  # extern DWORD FormatMessage (DWORD Flags, LPCVOID Source, DWORD MessageId, DWORD LanguageId, LPTSTR Buffer, DWORD Size, va_list* Arguments);
  # extern int WSAGetLastError (void);
  #define OS_errno GetLastError()
# used by error.d, spvw.d, stream.d, pathname.d

# Getting memory.
  #include <stdlib.h>
  #include <malloc.h>
  extern void* malloc (size_t size);
  extern void free (void* memblock);
# used by spvw.d

# Normal program exit
  nonreturning_function(extern, _exit, (int status));
# used by spvw.d

# Abrupt program termination
  #include <stdlib.h>
  extern void abort (void);
# used by spvw.d, debug.d, eval.d, io.d

# Type of a file handle
  #define Handle  HANDLE
  #define FOREIGN_HANDLE  # box them

# File handles of standard input and standard output
  extern Handle stdin_handle;  # see win32aux.d
  extern Handle stdout_handle; # see win32aux.d
  extern void init_win32 (void);
# used by spvw.d, stream.d

# Signal handling
  # extern BOOL SetConsoleCtrlHandler (BOOL (*) (DWORD CtrlType), BOOL add);
  # extern HANDLE CreateEvent (SECURITY_ATTRIBUTES* EventAttributes, BOOL ManualReset, BOOL InitialState, LPCTSTR Name);
  # extern BOOL PulseEvent (HANDLE Event);
  # extern HANDLE CreateThread (SECURITY_ATTRIBUTES* ThreadAttributes, DWORD StackSize, THREAD_START_ROUTINE* StartAddress, void* Parameter, DWORD CreationFlags, DWORD* ThreadId);
  # extern DWORD WaitForSingleObject (HANDLE Handle, DWORD Milliseconds);
  # extern DWORD WaitForMultipleObjects (DWORD Count, CONST HANDLE * Handles, BOOL WaitAll, DWORD Milliseconds);
  # extern BOOL TerminateThread (HANDLE Thread, DWORD ExitCode);
  # extern BOOL GetExitCodeThread (HANDLE Thread, DWORD* ExitCode);
  # extern DWORD SuspendThread (HANDLE Thread);
  # extern DWORD ResumeThread (HANDLE Thread);
  # extern BOOL GetThreadContext (HANDLE Thread, LPCONTEXT Context);
  # extern BOOL SetThreadContext (HANDLE Thread, CONST CONTEXT * Context);
  # extern HANDLE GetCurrentProcess (void);
  # extern HANDLE GetCurrentThread (void);
  # extern BOOL DuplicateHandle (HANDLE SourceProcessHandle, HANDLE SourceHandle, HANDLE TargetProcessHandle, LPHANDLE TargetHandle, DWORD DesiredAccess, BOOL InheritHandle, DWORD Options);
# used by win32aux.d
  # This is the Ctrl-C handler. It is executed in the main thread and must
  # not return!
  extern void interrupt_handler (void);
  # Install our intelligent Ctrl-C handler.
  # This should be called only once, and only from the main thread.
  extern void install_sigint_handler (void);
# used by spvw.d

# Environment variables
  #include <stdlib.h>
  extern char* getenv (const char* name);
# used by pathname.d, misc.d

# Character set conversion
  # extern BOOL CharToOem (LPCTSTR Str, LPSTR Dst);
  # extern BOOL OemToChar (LPCTSTR Str, LPSTR Dst);
# used by win32aux.d

# Set working directory
  # extern BOOL SetCurrentDirectory (LPCTSTR PathName);
# used by pathname.d

# Retrieve working directory
  # extern DWORD GetCurrentDirectory (DWORD BufferLength, LPTSTR Buffer);
  # extern DWORD GetFullPathName (LPCTSTR FileName, DWORD BufferLength, LPTSTR Buffer, LPTSTR* FilePart);
  # The actual value of _MAX_PATH is irrelevant, because we retry the calls to
  # GetCurrentDirectory() and GetFullPathName() if the buffer is too small.
  #ifndef _MAX_PATH
    #define _MAX_PATH 1024
  #endif
# used by pathname.d

# Retrieve information about a file
  # //extern DWORD GetLogicalDrives (void); // broken!
  # extern UINT GetDriveType (LPCTSTR RootPathName);
  # extern DWORD GetFileAttributes (LPCTSTR FileName);
  # extern DWORD GetFileType (HANDLE File);
  # //extern DWORD GetFileSize (HANDLE File, LPDWORD FileSizeHigh);
  # extern BOOL GetFileInformationByHandle (HANDLE File, BY_HANDLE_FILE_INFORMATION* FileInformation);
# used by pathname.d, stream.d

# Delete a file
  # extern BOOL DeleteFile (LPCTSTR FileName);
# used by pathname.d

# Rename a file
  # extern BOOL MoveFile (LPCTSTR ExistingFileName, LPCTSTR NewFileName);
# used by pathname.d

# Directory search
  # extern HANDLE FindFirstFile (LPCTSTR FileName, LPWIN32_FIND_DATA FindFileData);
  # extern BOOL FindNextFile (HANDLE FindFile, LPWIN32_FIND_DATA FindFileData);
  # extern BOOL FindClose (HANDLE FindFile);
# used by pathname.d

# Create a directory
  # extern BOOL CreateDirectory (LPCTSTR PathName, SECURITY_ATTRIBUTES* SecurityAttributes);
# used by pathname.d

# Delete a directory
  # extern BOOL RemoveDirectory (LPCTSTR PathName);
# used by pathname.d

# Working with open files
  # extern HANDLE CreateFile (LPCTSTR FileName, DWORD DesiredAccess, DWORD ShareMode, SECURITY_ATTRIBUTES* SecurityAttributes, DWORD CreationDistribution, DWORD FlagsAndAttributes, HANDLE TemplateFile);
  # extern HANDLE GetStdHandle (DWORD StdHandle);
  # extern DWORD GetFileSize (HANDLE File, LPDWORD FileSizeHigh);
  # extern DWORD SetFilePointer (HANDLE File, LONG DistanceToMove, LONG* DistanceToMoveHigh, DWORD MoveMethod);
  # extern BOOL ReadFile (HANDLE File, void* Buffer, DWORD BytesToRead, DWORD* BytesRead, OVERLAPPED* Overlapped);
  # extern BOOL WriteFile (HANDLE File, const void* Buffer, DWORD BytesToWrite, DWORD* BytesWritten, OVERLAPPED* Overlapped);
  # extern BOOL GetConsoleMode (HANDLE ConsoleHandle, LPDWORD Mode);
  # extern BOOL ReadConsole (HANDLE ConsoleInput, void* Buffer, DWORD BytesToRead, DWORD* BytesRead, void* Reserved);
  # extern BOOL GetNumberOfConsoleInputEvents (HANDLE ConsoleInput, LPDWORD NumberOfEvents);
  # extern BOOL PeekConsoleInput (HANDLE ConsoleInput, PINPUT_RECORD Buffer, DWORD Length, LPDWORD NumberOfEventsRead);
  # extern BOOL ReadConsoleInput (HANDLE ConsoleInput, PINPUT_RECORD Buffer, DWORD Length, LPDWORD NumberOfEventsRead);
  # extern BOOL WriteConsoleInput (HANDLE ConsoleInput, CONST INPUT_RECORD * Buffer, DWORD Length, LPDWORD NumberOfEventsWritten);
  # extern BOOL WriteConsole (HANDLE ConsoleOutput, const void* Buffer, DWORD BytesToWrite, DWORD* BytesWritten, void* Reserved);
  # extern HANDLE CreateEvent (SECURITY_ATTRIBUTES* EventAttributes, BOOL ManualReset, BOOL InitialState, LPCTSTR Name);
  # extern BOOL ResetEvent (HANDLE Event);
  # extern BOOL GetOverlappedResult (HANDLE File, OVERLAPPED* Overlapped, DWORD* NumberOfBytesTransferred, BOOL Wait);
  # extern BOOL CloseHandle (HANDLE Object);
  # //extern BOOL DuplicateHandle (HANDLE SourceProcessHandle, HANDLE SourceHandle, HANDLE TargetProcessHandle, HANDLE* TargetHandle, DWORD DesiredAccess, BOOL InheritHandle, DWORD Options);
  # //extern BOOL FlushFileBuffers (HANDLE File);
  # extern BOOL PeekNamedPipe (HANDLE NamedPipe, void* Buffer, DWORD BufferSize, DWORD* BytesRead, DWORD* TotalBytesAvail, DWORD* BytesLeftThisMessage);
  # extern BOOL PurgeComm (HANDLE File, DWORD Flags);
  # extern BOOL FlushConsoleInputBuffer (HANDLE ConsoleInput);
  #if defined(__MINGW32__)
    #define uAsciiChar AsciiChar
  #else # defined(MICROSOFT) || defined(BORLAND)
    #define uAsciiChar uChar.AsciiChar
  #endif
# used by spvw.d, stream.d, pathname.d, win32aux.d
  # My private error code when Ctrl-C has been pressed.
  #define ERROR_SIGINT ERROR_SUCCESS
  # Like ReadConsoleInput with Length==1, but is interruptible by Ctrl-C.
  extern BOOL ReadConsoleInput1 (HANDLE ConsoleInput, PINPUT_RECORD Buffer, LPDWORD NumberOfEventsRead);
  # The following functions deal with all kinds of file/pipe/console handles.
  extern int full_read (HANDLE fd, void* buf, int nbyte);
  extern int full_write (HANDLE fd, const void* buf, int nbyte);
  #define RW_BUF_T  void*
  #define read  full_read
  #define write  full_write
  # Changing the position within a file.
  #define lseek(handle,offset,mode)  ((int)SetFilePointer(handle,offset,NULL,mode))
  #define SEEK_SET  FILE_BEGIN
  #define SEEK_CUR  FILE_CURRENT
  #define SEEK_END  FILE_END
# used by spvw.d, stream.d

# Socket connections
  #include <winsock.h>
  # extern int WSAStartup (WORD VersionRequested, WSADATA* WSAData);
  # extern int WSAGetLastError (void);
  # extern void WSASetLastError (int Error);
  # extern int WSACancelBlockingCall (void);
  # extern SOCKET socket (int af, int type, int protocol);
  # extern int bind (SOCKET s, const struct sockaddr * addr, int addrlen);
  # extern int listen (SOCKET s, int backlog);
  # extern SOCKET accept (SOCKET s, struct sockaddr * addr, int * addrlen);
  # extern int connect (SOCKET s, const struct sockaddr * addr, int addrlen);
  # extern int setsockopt (SOCKET s, int level, int optname, const char * optval, int option);
  # extern int recv (SOCKET s, char* buf, int len, int flags);
  # extern int send (SOCKET s, const char* buf, int len, int flags);
  # extern int select (int nfds, fd_set* readfds, fd_set* writefds, fd_set* exceptfds, const struct timeval * timeout);
  # extern int closesocket (SOCKET s);
  # extern int gethostname (char* name, int namelen);
  # extern struct hostent * gethostbyname (const char* name);
  # extern struct hostent * gethostbyaddr (const char* addr, int len, int type);
  # extern struct servent * getservbyname (const char* name, const char* proto);
  # extern struct servent * getservbyport (int port, const char* proto);
  # extern int getpeername (SOCKET s, struct sockaddr * addr, int * addrlen);
  # Type of a socket
  # define SOCKET  unsigned int
  # Error value for functions returning a socket
  # define INVALID_SOCKET  (SOCKET)(-1)
  # Error value for functions returning an `int' status
  # define SOCKET_ERROR  (-1)
  # Accessing the error code
  #define sock_errno  WSAGetLastError()
  #define sock_errno_is(val)  (WSAGetLastError() == WSA##val)
  #define sock_set_errno(val)  WSASetLastError(WSA##val)
  # Signalling a socket related error
  # extern void SOCK_error (void);
  # Reading and writing from a socket
  extern int sock_read (SOCKET fd, void* buf, int nbyte);
  extern int sock_write (SOCKET fd, const void* buf, int nbyte);
  # Wrapping and unwrapping of a socket in a Lisp object
  #define allocate_socket(fd)  allocate_handle((Handle)(fd))
  #define TheSocket(obj)  (SOCKET)TheHandle(obj)
  # Autoconfiguration macros
  #define HAVE_GETHOSTNAME
  #define GETHOSTNAME_SIZE_T int
  #ifndef MAXHOSTNAMELEN
    #define MAXHOSTNAMELEN 64
  #endif
  #define HAVE_GETHOSTBYNAME
  #define GETHOSTBYNAME_CONST const
  #define CONNECT_NAME_T struct sockaddr
  #define CONNECT_CONST const
  #define CONNECT_ADDRLEN_T int
  #define HAVE_IPV4
  #undef HAVE_IPV6
  #undef HAVE_NETINET_IN_H
  #undef HAVE_ARPA_INET_H
  #define RET_INET_ADDR_TYPE unsigned long
  #define INET_ADDR_SUFFIX
  #define INET_ADDR_CONST const
  #undef HAVE_NETINET_TCP_H
  #define SETSOCKOPT_CONST const
  #define SETSOCKOPT_ARG_T char*
  #define SETSOCKOPT_OPTLEN_T int
  #define HAVE_MEMSET
  #define RETMEMSETTYPE void*
  # Do not define HAVE_SELECT because select() works on sockets only.
# used by error.d, misc.d, socket.d, stream.d
# requires linking with wsock32.lib

# Hacking the terminal
  extern int isatty (HANDLE handle); # see win32aux.d
# used by stream.d

# Date and time
  # Don't use GetSystemTime(), because it's unreliable. (See comment in
  # MSVC4.0 crt/src/time.c.) Better use GetLocalTime().
  # //extern void GetLocalTime (SYSTEMTIME* SystemTime);
  # But GetLocalTime() ignores the TZ environment variable, so use _ftime().
  #include <sys/types.h>
  #include <sys/timeb.h>
  #ifdef MICROSOFT
    #define timeb _timeb
    #define ftime _ftime
  #endif
  # extern void ftime (struct timeb *);
  #include <time.h>
  # extern struct tm * localtime (time_t*);
  # extern struct tm * gmtime (time_t*);
  # extern BOOL FileTimeToLocalFileTime (const FILETIME* FileTime, FILETIME* LocalFileTime);
  # extern BOOL FileTimeToSystemTime (const FILETIME* LocalFileTime, SYSTEMTIME* LocalSystemTime);
# used by time.d

# Pausing
  # extern void Sleep (DWORD Milliseconds);
# used by win32aux.d
  # Sleep a certain time.
  # Return TRUE after normal termination, FALSE if interrupted by Ctrl-C.
  extern BOOL msleep (DWORD milliseconds);
  extern unsigned int sleep (unsigned int seconds);
# used by time.d, socket.d

# Calling programs
  # extern BOOL CreateProcess (LPCTSTR ApplicationName, LPTSTR CommandLine, LPSECURITY_ATTRIBUTES ProcessAttributes, LPSECURITY_ATTRIBUTES ThreadAttributes, BOOL InheritHandles, DWORD CreationFlags, LPVOID Environment, LPCTSTR CurrentDirectory, LPSTARTUPINFO StartupInfo, LPPROCESS_INFORMATION ProcessInformation);
  # extern BOOL GetExitCodeProcess (HANDLE Process, LPDWORD ExitCode);
  # extern BOOL CreatePipe (PHANDLE ReadPipe, PHANDLE WritePipe, LPSECURITY_ATTRIBUTES PipeAttributes, DWORD Size);
  # extern BOOL DuplicateHandle (HANDLE SourceProcessHandle, HANDLE SourceHandle, HANDLE TargetProcessHandle, LPHANDLE TargetHandle, DWORD DesiredAccess, BOOL InheritHandle, DWORD Options);
# used by win32aux.d, pathname.d, stream.d
  extern BOOL MyCreateProcess (LPTSTR CommandLine, HANDLE StdInput, HANDLE StdOutput, LPPROCESS_INFORMATION ProcessInformation);
# used by pathname.d, stream.d

# Getting "random" numbers
  #if defined(__MINGW32__)
    # Not defined in any header.
    extern STDCALL DWORD CoGetCurrentProcess (void);
  #else
    #define boolean OS_boolean
    #include <objbase.h>
    #undef boolean
    # extern DWORD CoGetCurrentProcess (void);
  #endif
# used by lisparit.d
# requires linking with ole32.lib

# Getting information about the machine.
  # extern void GetSystemInfo (LPSYSTEM_INFO SystemInfo);
  #if defined(BORLAND) || defined(__MINGW32__)
    #define wProcessorArchitecture u.s.wProcessorArchitecture
  #endif
# used by misc.d

# Getting more information about the machine.
  # extern LONG RegOpenKeyEx (HKEY Key, LPCTSTR SubKey, DWORD Options, REGSAM Desired, PHKEY Result);
  # extern LONG RegQueryValueEx (HKEY Key, LPTSTR ValueName, LPDWORD Reserved, LPDWORD Type, LPBYTE Data, LPDWORD cbData);
  # extern LONG RegCloseKey (HKEY Key);
# used by misc.d
# requires linking with advapi32.lib

# Examining the memory map.
  # extern DWORD VirtualQuery (LPCVOID Address, PMEMORY_BASIC_INFORMATION Buffer, DWORD Length);
  extern void DumpProcessMemoryMap (void); # see win32aux.d
# used by spvw.d

# Getting virtual memory
  # //extern void GetSystemInfo (LPSYSTEM_INFO SystemInfo);
  # extern LPVOID VirtualAlloc (LPVOID Address, DWORD Size, DWORD AllocationType, DWORD Protect);
  # extern BOOL VirtualFree (LPVOID Address, DWORD Size, DWORD FreeType);
  # extern BOOL VirtualProtect (LPVOID Address, DWORD Size, DWORD NewProtect, PDWORD OldProtect);
  # //extern HANDLE CreateFileMapping (HANDLE File, LPSECURITY_ATTRIBUTES FileMappingAttributes, DWORD Protect, DWORD MaximumSizeHigh, DWORD MaximumSizeLow, LPCTSTR Name);
  # //extern LPVOID MapViewOfFileEx (HANDLE FileMappingObject, DWORD DesiredAccess, DWORD FileOffsetHigh, DWORD FileOffsetLow, DWORD NumberOfBytesToMap, LPVOID BaseAddress);
  # //extern BOOL UnmapViewOfFile (LPCVOID BaseAddress);
  #define HAVE_WIN32_VM
  # Damit kann man munmap() und mprotect() selber schreiben. mmap() wird
  # emuliert, weil MapViewOfFileEx() zu viele Nachteile hat. Siehe spvw.d.
  /* #define HAVE_MMAP */
  #define HAVE_MUNMAP
  #define HAVE_WORKING_MPROTECT
  #define MPROTECT_CONST
  #define MMAP_ADDR_T  void*
  #define MMAP_SIZE_T  DWORD
  #define off_t  _off_t
  #define RETMMAPTYPE  MMAP_ADDR_T
  #define PROT_NONE  PAGE_NOACCESS
  #define PROT_READ  PAGE_READONLY
  #define PROT_READ_WRITE PAGE_READWRITE
  # PROT_WRITE, PROT_EXEC not used
# used by spvw.d

