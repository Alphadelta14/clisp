/*
 * check-translit 
 *
 *      Simple check of transliteration facilities.
 *      Usage: check-translit SRCDIR FILE FROMCODE TOCODE
 */

IF RxFuncQuery('SysLoadFuncs') THEN DO
   CALL RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
   CALL SysLoadFuncs
END

'@echo off'

PARSE ARG srcdir file fromcode tocode

'.\iconv -f 'fromcode' -t 'tocode' < 'srcdir'\'file'.'fromcode' > tmp'
'cmp 'srcdir'\'file'.'tocode' tmp'
'rm -f tmp'
EXIT
