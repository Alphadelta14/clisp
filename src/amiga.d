# Include-File f�r AMIGA-Version von CLISP
# Bruno Haible, J�rg H�hle 19.12.1994


# Konstanten f�r Steuerzeichen:

#define BEL  7              # Ton ausgeben
#define CSI  (0x9B)         # Control-Sequence-Introducer (Meta-Escape)
#define RUBOUT 127          # Rubout = Delete
#define CRLFstring  "\n"    # C-String, der BS-Newline enth�lt


# Macros, um Longword-aligned Strukturen (z.B. im Stack) zu erzeugen:
# Statt
#   { var struct FileInfoBlock fib;
#     var struct FileInfoBlock * fibptr = &fib;
#     ...
#   }
# schreibe
#   { var LONGALIGNTYPE(struct FileInfoBlock) fib;
#     var struct FileInfoBlock * fibptr = LONGALIGN(&fib);
#     ...
#   }
  #define LONGALIGNTYPE(type)  struct { type dummy1; uintW dummy2; }
  #define LONGALIGN(addr)      ((void*)(floor(((uintL)(addr)+2),4)*4))
# wird verwendet von PATHNAME, STREAM


# Wir definieren dieses selbst, brauchen nur Teile von <exec/types.h>:
#define UBYTE  OS_UBYTE
#define UWORD  OS_UWORD
#define ULONG  OS_ULONG
#include <exec/types.h>
#undef ULONG
#undef UWORD
#undef UBYTE

#include <exec/memory.h>         # f�r Allocate()-Deklaration, MEMF_24BITDMA
#include <exec/execbase.h>       # f�r SysBase, AFF_680x0
#include <dos/dos.h>
#include <dos/dosextens.h>
# #include <dos/dostags.h>       # f�r SystemTags()

#include <stdlib.h>

#ifdef GNU
  # Expandiere alle Betriebssystem-Aufrufe inline, mit Kamil Iskra inlines.h
  #define GNU_INLINES
  # __builtin_strlen() ist inline, __builtin_strcmp() aber nicht.
  #define HAVE_BUILTIN_STRLEN
#endif

#define Class  OS_Class          # Shadowing intuition/classes.h

# das sind die Compiler-spezifischen Prototypen:
# Bei GCC werden dabei inline/...h gelesen, das sind Macros
#define ASTRING  UBYTE*
#include <proto/exec.h>
#include <proto/dos.h>

#undef Class

# BCPL-Pointer (hier BCPL* genannt, Typ BPTR) sind durch 4 teilbare Adressen,
# die durch 4 dividiert wurden.
  #define BPTR_NULL  ((BPTR)0)     # das ist ein spezieller, aber g�ltiger BPTR
  #define BPTR_NONE  ((BPTR)(-1))  # das ist ein ung�ltiger BPTR, Erkennungszeichen


# Typ eines Handle:
  #define Handle  BPTR
  #define Handle_NULL  BPTR_NULL
  #define FOREIGN_HANDLE  # verpacke die Handles sicherheitshalber
# wird verwendet von PATHNAME, SPVW


# F�r asciz_out() und *terminal-io*, initialisiert von SPVW:
  extern Handle stdin_handle;     # low-level stdin Eingabekanal
  extern Handle stdout_handle;    # low-level stdout Ausgabekanal


# Information �ber die eigene Task.
  extern struct ExecBase * const SysBase;
# wird verwendet von SPVW


# Versionsabfragen:
  extern struct DosLibrary * const DOSBase;
# wird verwendet von STREAM


# Deklaration von Typen von Ein-/Ausgabe-Parametern von Betriebssystemfunktionen
  #define CONST


# Programm verlassen und beenden.
# exit(returncode);
# > LONG returncode: R�ckgabewert an den Aufrufer des Programms
#                    (z.B. RETURN_OK, RETURN_WARN, RETURN_ERROR, RETURN_FAIL)
  nonreturning_function(extern, exit, (int returncode));
# wird verwendet von SPVW


# Die Inlines sind jetzt Macros, also k�nnen Funktionen nicht mehr deklariert werden
#if !defined(GNU_INLINES)

# Holt das aktuelle Datum und die aktuelle Uhrzeit.
# DateStamp(&datestamp);
# < struct DateStamp datestamp: aktuelle Zeit
#     LONG datestamp.ds_Days   : Anzahl Tage seit 1.1.1978
#     LONG datestamp.ds_Minute : Anzahl Minuten seit Tagesanfang
#     LONG datestamp.ds_Tick   : Anzahl Ticks (1/50 sec) seit Minutenanfang
  extern struct DateStamp * DateStamp (struct DateStamp * datestamp); # siehe dos.library/DateStamp
# wird verwendet von SPVW

# Wartet eine bestimmte Zeit.
# Delay(ticks);
# > ULONG ticks: Anzahl (>0) von Ticks (1/50 sec), die zu warten ist
  extern void Delay (long ticks); # siehe dos.library/Delay
# wird verwendet von MISC


# Holt die letzte Fehlernummer.
# errno = IoErr();
  extern LONG IoErr (void);
# wird verwendet von ERROR, PATHNAME

# Setzt die n�chste Fehlernummer.
# olderrno = SetIoErr(errno);
  extern LONG SetIoErr (LONG);
# wird verwendet von ERROR


# �ffnet eine Datei.
# handle = Open(filename,mode)
# > filename: Name eines Files oder Device (ASCIZ-String)
# > mode: Zugriffsmodus, z.B. MODE_OLDFILE oder MODE_NEWFILE oder MODE_READWRITE
# < handle: Handle oder NULL bei Fehler.
  extern Handle Open (CONST ASTRING filename, long mode); # siehe dos.library/Open
  #define Open(filename,mode)  (Open)((CONST ASTRING)(filename),mode)
# wird verwendet von SPVW, PATHNAME, STREAM

# Schlie�t eine Datei.
# ergebnis = Close(handle)
# > handle: Handle eines offenen Files
# < ergebnis: NULL bei Fehler.
  extern LONG Close (Handle handle); # siehe dos.library/Close
  # define CLOSE(handle)  (Close(handle),0)
# wird verwendet von SPVW, PATHNAME, STREAM

# Liest von einer Datei.
# ergebnis = Read(handle,bufferaddr,bufferlen);
# > handle: Handle eines offenen Files
# > bufferaddr: Adresse eines Buffers mit bufferlen Bytes
# < ergebnis: Anzahl der gelesenen Bytes (0 bei EOF) oder -1 bei Fehler.
  extern LONG Read (Handle handle, APTR bufferaddr, long bufferlen); # siehe dos.library/Read
# wird verwendet von SPVW, STREAM

# Schreibt auf eine Datei.
# ergebnis = Write(handle,bufferaddr,bufferlen);
# > handle: Handle eines offenen Files
# > bufferaddr: Adresse eines Buffers mit bufferlen Bytes
# < ergebnis: Anzahl der geschriebenen Bytes oder -1 bei Fehler.
  extern LONG Write (Handle handle, CONST APTR bufferaddr, long bufferlen); # siehe dos.library/Write
# wird verwendet von SPVW, STREAM

# Dateizeiger positionieren.
# Seek(handle,pos,mode)
# > Handle handle : Handle eines (offenen) Files.
# > LONG pos : Position in Bytes (mu� >=0 bei Modus OFFSET_BEGINNING
#                                 bzw. <=0 bei Modus OFFSET_END sein)
# > LONG mode : Modus (OFFSET_BEGINNING = ab Fileanfang,
#                      OFFSET_CURRENT = ab momentan, OFFSET_END = ab Fileende)
# < LONG ergebnis : alte(!) Position ab Fileanfang oder -1 bei Fehler.
  extern LONG Seek (Handle handle, long pos, long mode); # siehe dos.library/Seek
# wird verwendet von STREAM


# Holt den Eingabe-Handle
# Input()
# < ergebnis: Eingabe-Handle, NULL bei WorkBench-Aufruf des Programms
  extern Handle Input (void); # siehe dos.library/Input
# verwendet von SPVW

# Holt den Ausgabe-Handle
# Output()
# < ergebnis: Ausgabe-Handle, NULL bei WorkBench-Aufruf des Programms
  extern Handle Output (void); # siehe dos.library/Output
# verwendet von SPVW


# Legt den Finger auf eine Datei oder ein Directory.
# lock = Lock(name,mode);
# > name: Name der Datei bzw. des Directory (ASCIZ-String)
# > mode: Zugriffsmodus, z.B. ACCESS_READ (= SHARED_LOCK) oder ACCESS_WRITE (= EXCLUSIVE_LOCK)
# < struct FileLock BCPL* lock: Lock oder NULL bei Fehler.
  extern BPTR Lock (CONST ASTRING name, long mode); # siehe dos.library/Lock
  #define Lock(name,mode)  (Lock)((CONST ASTRING)(name),mode)
# wird verwendet von PATHNAME

# L��t eine Datei oder ein Directory wieder los.
# UnLock(lock);
# > struct FileLock BCPL* lock: Lock oder NULL.
  extern void UnLock (BPTR lock); # siehe dos.library/UnLock
# wird verwendet von PATHNAME

# Holt Informationen zu einer Datei oder einem Directory.
# ergebnis = Examine(lock,&fib);
# > struct FileLock BCPL* lock: Lock.
# > struct FileInfoBlock fib: Platz f�r die Informationen, LONGALIGNED,
#     LONG fib.fib_DirEntryType     : >=0 bei Directory, <0 bei normaler Datei
#     char fib.fib_Filename []      : Filename, ein ASCIZ-String
#     LONG fib.fib_Size             : Gr��e des Files in Bytes
#     struct DateStamp fib.fib_Date : Datum der letzten Modifikation
#     char fib.fib_Comment []       : Kommentar
# < ergebnis: NULL bei Fehler
  extern LONG Examine (BPTR lock, struct FileInfoBlock * fib); # siehe dos.library/Examine
# wird verwendet von PATHNAME

# Holt Informationen zu einem Directory-Eintrag.
# ergebnis = ExNext(lock,&fib);
# > struct FileLock BCPL* lock: Lock auf ein Directory.
# > struct FileInfoBlock fib: Platz f�r die Informationen, wie bei Examine()
# < ergebnis: NULL bei Fehler, und IoErr()=ERROR_NO_MORE_ENTRIES am Schlu�.
  extern LONG ExNext (BPTR lock, struct FileInfoBlock * fib); # siehe dos.library/ExNext
# wird verwendet von PATHNAME

# Durchsuchen von Directories nach Dateien:
# 1. Lock f�rs Directory besorgen: Lock().
# 2. Examine() dieses Lock in einen FIB.
# 3. ExNext() dieses Lock und denselben FIB solange bis ERROR_NO_MORE_ENTRIES.
# 4. Lock zur�ckgeben: UnLock().

# Besorgt das Parent Directory zu einem Lock auf ein Directory.
# parentlock = ParentDir(lock);
# > struct FileLock BCPL* lock: Lock auf ein Directory
# < struct FileLock BCPL* parentlock: Lock aufs Parent Directory davon,
#     oder NULL bei Fehler oder bei Versuch, Parent vom Root Dir zu nehmen.
  extern BPTR ParentDir (BPTR lock); # siehe dos.library/ParentDir
# wird verwendet von PATHNAME


# Datei l�schen.
# DeleteFile(filename)
# > filename : Filename, ein ASCIZ-String
# < ergebnis : NULL bei Fehler.
  extern LONG DeleteFile (CONST ASTRING filename); # siehe dos.library/DeleteFile
  #define DeleteFile(filename)  (DeleteFile)((CONST ASTRING)(filename))
# wird verwendet von PATHNAME

# Datei umbenennen.
# Rename(oldname,newname)
# > oldname : alter Filename, ein ASCIZ-String
# > newname : neuer Filename, ein ASCIZ-String
# < ergebnis : NULL bei Fehler.
  extern LONG Rename (CONST ASTRING oldname, CONST ASTRING newname); # siehe dos.library/Rename
  #define Rename(oldname,newname)  (Rename)((CONST ASTRING)(oldname),(CONST ASTRING)(newname))
# wird verwendet von PATHNAME

# Neues Subdirectory anlegen.
# lock = CreateDir(name);
# > name: Pfadname, ein ASCIZ-String
# < struct FileLock BCPL* lock: Lock auf das neue Subdirectory, NULL bei Fehler.
  extern BPTR CreateDir (CONST ASTRING name); # siehe dos.library/CreateDir
  #define CreateDir(name)  (CreateDir)((CONST ASTRING)(name))
# wird verwendet von PATHNAME

# Subdirectory l�schen.
# DeleteFile(name)
# > name : Pfadname, ein ASCIZ-String
# < ergebnis : NULL bei Fehler.
  # extern LONG DeleteFile (CONST ASTRING filename); # siehe dos.library/DeleteFile, s.o.
# wird verwendet von PATHNAME

# Current Directory (des Prozesses) neu setzen.
# CurrentDir(lock)
# > FileLock BCPL* lock: Lock auf ein Directory, wird zum neuen current directory
# < FileLock BCPL* ergebnis: Lock aufs alte current directory
# Beim Programmende mu� das Current Directory Lock wieder dasselbe wie beim
# Programmstart sein. Alle anderen Locks sind freizugeben.
  extern BPTR CurrentDir (BPTR lock); # siehe dos.library/CurrentDir
# wird verwendet von PATHNAME, SPVW


# Stellt fest, ob ein File interaktiv (ein Terminal o.�.) ist.
# IsInteractive(handle)
# > handle: Handle eines (offenen) Files
# < ergebnis: gibt an, ob das File interaktiv ist
  extern LONG IsInteractive (Handle handle); # siehe dos.library/IsInteractive
# wird verwendet von STREAM, SPVW

# Stellt fest, ob innerhalb einer gewissen Zeit ein Zeichen anliegt.
# WaitForChar(handle,timeout)
# > handle: Handle eines (offenen) interaktiven Files
# > timeout: maximale Wartezeit (>=0), in Mikrosekunden
# < ergebnis: gibt an, ob bis zum Ende der Wartezeit ein Zeichen lesbar ist.
  extern LONG WaitForChar (Handle handle, long timeout);
# wird verwendet von STREAM

# Umschalten CON/RAW (line/single-character mode).
# SetMode(handle,mode)
# > handle: Handle eines (offenen) interaktiven Files
# > mode: 1 f�r RAW, 0 f�r CON
# < ergebnis: 0 falls nicht erfolgreich (Modus lie� sich nicht umsetzen)
  extern LONG SetMode (BPTR handle, long mode); # siehe dos.library/SetMode
# wird verwendet von STREAM


# Fordert ein St�ck Speicher beim Betriebssystem an.
# AllocMem(size,preference)
# > size: angeforderte Gr��e in Bytes
# > preference: MEMF_ANY oder MEMF_24BITDMA
# < ergebnis: Anfangsadresse des allozierten Bereichs, oder NULL
  extern APTR AllocMem (unsigned long size, unsigned long flags); # siehe exec.library/AllocMem
# wird verwendet von SPVW

# Gibt dem Betriebssystem ein St�ck Speicher zur�ck.
# FreeMem(address,size);
# > address: Anfangsadresse des allozierten Bereichs
# > size: Gr��e dieses Bereichs in Bytes
  extern void FreeMem (APTR address, unsigned long size); # siehe exec.library/FreeMem
# wird verwendet von SPVW


# Liefert einen Pointer auf die eigene Task.
# FindTask(NULL)
# < ergebnis: Pointer auf den Deskriptor der eigenen Task
  extern struct Task * FindTask (CONST UBYTE* taskname); # siehe exec.library/FindTask
# wird verwendet von ERROR, LISPARIT

# Fragt die aktuelle Signal-Maske ab und modifiziert sie.
# (Die Signal-Maske gibt an, welche Signale bei der eigenen Task angekommen
# sind, aber noch nicht verarbeitet wurden. Wird vom Betriebssystem
# asynchron ver�ndert.)
# SetSignal(signals_to_set,signals_to_change)
# < ergebnis: ehemalige Signal-Maske signals
# < neue Signal-Maske
#     signals := (signals & ~signals_to_change) | (signals_to_set & signals_to_change)
#              = signals ^ ((signals ^ signals_to_set) & signals_to_change)
  extern ULONG SetSignal (unsigned long signals_to_set, unsigned long signals_to_change); # siehe exec.library/SetSignal
# wird verwendet von Macro interruptp

# Wartet auf ein oder mehrere Signal(e).
# Wait(signals)
# > signals: Signale, auf die gewartet werden soll
# < ergebnis: Signale, die eingetreten sind
  extern ULONG Wait (unsigned long signals); # siehe exec.library/Wait
# wird verwendet von SPVW, REXX


# Programme aufrufen.
# Execute(command,ihandle,ohandle)
# > command: Kommandozeile, wie man sie im Kommandozeilen-Interpreter eintippt
#            oder "" f�r Subshell (bei interaktivem ihandle).
# > ihandle: Handle f�r weitere Kommandos, nachdem command abgearbeitet ist,
#            bei ihandle = 0 werden keine weiteren Kommandos ausgef�hrt.
# > ohandle: Handle f�r Ausgaben der Kommandos,
#            bei ohandle = 0 gehen Ausgaben ins aktuelle Fenster.
# < ergebnis: Flag, ob erfolgreich aufgerufen.
  extern LONG Execute (CONST ASTRING command, BPTR ihandle, BPTR ohandle); # siehe dos.library/Execute
  #define Execute(command,ihandle,ohandle)  (Execute)((CONST ASTRING)(command),ihandle,ohandle)
# wird verwendet von PATHNAME
#
# SystemTagList(command,tags)
# SystemTags(command,tags...)
# > command: Kommandozeile, wie man sie im Kommandozeilen-Interpreter eintippt
# > tags: Array von ULONG (vgl. dostags.h), am Schlu� TAG_DONE
#         SYS_Input: Handle f�r Eingabestrom, Default Input()
#         SYS_Output: Handle f�r Ausgabestrom, Default Output()
#                     wenn 0 und Input interaktiv ist, wird es geklont
#         SYS_UserShell: g�nstig, wenn command vom Anwender stammt
# < ergebnis: Returncode, -1 bei Fehler
  extern LONG SystemTaglist (CONST ASTRING command, CONST struct TagItem *tags);
  extern LONG SystemTags (CONST ASTRING command, CONST struct TagItem *tags, ...);
# wird verwendet von PATHNAME


# Springt in den Debugger.
# Debug(0);
  extern void Debug (unsigned long flags); # siehe exec.library/Debug
# wird verwendet von DEBUG

#endif # GNU_INLINES


# Letzte Fehlernummer
  #define OS_errno  IoErr()

# Arbeiten mit offenen Files:
  #define read Read
  # Wrapper um die System-Aufrufe, die Teilergebnisse behandeln:
  #define RW_BUF_T  void*
  extern long full_read (Handle handle, RW_BUF_T buf, long nbyte);
  extern long full_write (Handle handle, const RW_BUF_T buf, long nbyte);
# wird verwendet von SPVW, STREAM, AMIGAAUX

# ignoriere Ergebnis, was sollen wir tun k�nnen?
  #define CLOSE(handle)  (Close(handle),0)

# Stellt fest, ob ein File interaktiv (ein Terminal o.�.) ist.
  #define isatty(h)  IsInteractive(h)


# Sofortiger Programmabbruch, Sprung in den Debugger
  nonreturning_function(extern, abort, (void));
# wird verwendet von SPVW, EVAL, IO


# STREAM.D : Terminal-Stream, finish_output_file, Pipe-Streams?
# PATHNAME.D : Wildcards mit regular expressions
# PATHNAME.D : assure_dir_exists mit symlinks
# SPVW.D : SP_bound, SP_ueber & NO_SP_MALLOC

