@echo off

echo this will install CLISP on your system,
echo binding file types FAS, MEM and LISP with CLISP.
echo it will also create a CLISP.BAT file on your desktop.
echo press C-c to abort
pause

lisp.exe -B . -M lispinit.mem -norc -C src/install.lisp

pause
