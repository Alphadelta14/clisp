;*******************************************************************************
;*      Test der I/O-Funktionen                                                *
;*******************************************************************************

(PROGN (IN-PACKAGE "SYS") T)
T

;--- let test ------------------------------------------------------------------
; ewiger compiler-fehler
;

(progn (setq bs (make-broadcast-stream)) t)
T

#+XCL *cur-broadcast-stream*
#+XCL NIL

(print 123. bs)
123.

#+XCL *cur-broadcast-stream*
#+XCL NIL

;-------------------------------------------------------------------------------
; Unread test mit structure-stream
;

(SETQ STR1 "test 123456")   "test 123456"

(PROGN (SETQ S1 (make-two-way-stream (MAKE-STRING-INPUT-STREAM STR1)
                                     *standard-output*)) T)
T

(READ S1)   TEST

(READ-CHAR S1)   #\1

(READ-CHAR S1)   #\2

(UNREAD-CHAR #\2 S1)   NIL

(READ-CHAR S1)   #\2

(READ-CHAR S1)   #\3

(READ-CHAR S1)   #\4

(UNREAD-CHAR #\A S1)   ERROR

(READ-CHAR S1)   #\5

(READ-CHAR S1)   #\6

(CLOSE S1)   T

STR1   "test 123456"


;-------------------------------------------------------------------------------

(MULTIPLE-VALUE-LIST (PARSE-INTEGER "abc"))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER "  abc  "))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER "123"))
(123 3)

(MULTIPLE-VALUE-LIST (PARSE-INTEGER "  123  "))
(123 7)

(MULTIPLE-VALUE-LIST (PARSE-INTEGER "123 t"))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER "  123   t  "))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER " ( 12 ) 43   t  "))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER "  abc  " :JUNK-ALLOWED T))
(NIL 2)

(MULTIPLE-VALUE-LIST (PARSE-INTEGER "123" :JUNK-ALLOWED T))
(123 3)

(MULTIPLE-VALUE-LIST (PARSE-INTEGER "  123  " :JUNK-ALLOWED T))
(123 #+XCL 7 #+(or CLISP AKCL ECL ALLEGRO CMU) 5 #-(or XCL CLISP AKCL ECL ALLEGRO CMU) UNKNOWN)

(MULTIPLE-VALUE-LIST (PARSE-INTEGER "123 t" :JUNK-ALLOWED T))
(123 #+XCL 4 #+(or CLISP AKCL ECL ALLEGRO CMU) 3 #-(or XCL CLISP AKCL ECL ALLEGRO CMU) UNKNOWN)

(MULTIPLE-VALUE-LIST (PARSE-INTEGER "  123   t  " :JUNK-ALLOWED T))
(123 #+XCL 8 #+(or CLISP AKCL ECL ALLEGRO CMU) 5 #-(or XCL CLISP AKCL ECL ALLEGRO CMU) UNKNOWN)

(MULTIPLE-VALUE-LIST (PARSE-INTEGER " ( 12 ) 43   t  " :JUNK-ALLOWED
T))
(NIL 1)

(SETQ A "q w e 1 2 r 4 d : :;;;")
"q w e 1 2 r 4 d : :;;;"

(SETQ B "1 2 3 4 5 6 7")
"1 2 3 4 5 6 7"

(SETQ C "1.3 4.223")
"1.3 4.223"

(SETQ D "q w e r t z")
"q w e r t z"

(MULTIPLE-VALUE-LIST (PARSE-INTEGER A))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER B))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER C))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER D))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER A :START 4 :END 6))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER B :START 2 :END 3))
(2 3)

(MULTIPLE-VALUE-LIST (PARSE-INTEGER C :START 1))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER D :START 6))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER A :END 4))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER B :END 3))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER C :END 3))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER D :END 1))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER A :RADIX 1))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER B :RADIX 10))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER C :RADIX 20))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER D :RADIX 40))
ERROR

(MULTIPLE-VALUE-LIST (PARSE-INTEGER A :JUNK-ALLOWED T))
(NIL 0)

(MULTIPLE-VALUE-LIST (PARSE-INTEGER B :JUNK-ALLOWED T))
(1 #+XCL 2 #+(or CLISP AKCL ECL ALLEGRO CMU) 1 #-(or XCL CLISP AKCL ECL ALLEGRO CMU) UNKNOWN)

(MULTIPLE-VALUE-LIST (PARSE-INTEGER C :JUNK-ALLOWED T))
(1 1)

(MULTIPLE-VALUE-LIST (PARSE-INTEGER D :JUNK-ALLOWED T))
(NIL 0)

(STREAM-ELEMENT-TYPE #+XCL STDIN #-XCL *TERMINAL-IO*)
#+(or CLISP ALLEGRO CMU) CHARACTER #-(or CLISP ALLEGRO CMU) STRING-CHAR

(PROGN (SETQ A (MAKE-STRING-INPUT-STREAM "aaa bbb")) T)
T

(READ A)
AAA

#+XCL (B-CLEAR-INPUT A)
#+XCL NIL

(READ A)
#+XCL ERROR
#-XCL BBB

(PROGN (SETQ A (MAKE-STRING-OUTPUT-STREAM))
       (SETQ B (MAKE-STRING-OUTPUT-STREAM))
       (SETQ C (MAKE-BROADCAST-STREAM A B)) T)
T

(PRINT "xxx" C)
"xxx"

(CLEAR-OUTPUT C)
NIL

(FINISH-OUTPUT C)
#+XCL T
#-XCL NIL

(GET-OUTPUT-STREAM-STRING A)
"
\"xxx\" "

(GET-OUTPUT-STREAM-STRING B)
"
\"xxx\" "

(PRINT "yyy" C)
"yyy"

(CLEAR-OUTPUT C)
NIL

(FINISH-OUTPUT C)
#+XCL T
#-XCL NIL

(PRINT "zzz" A)
"zzz"

(CLEAR-OUTPUT A)
NIL

(FINISH-OUTPUT A)
#+XCL T
#-XCL NIL

(GET-OUTPUT-STREAM-STRING A)
#+XCL ""
#-XCL "
\"yyy\" 
\"zzz\" "

(GET-OUTPUT-STREAM-STRING B)
"
\"yyy\" "

(PROGN (SETQ A (MAKE-STRING-INPUT-STREAM "123")) T)
T

(LISTEN A)
T

(READ A)
123

(listen a)
NIL

*PRINT-CASE*
:UPCASE

*PRINT-GENSYM*
T

*PRINT-LEVEL*
NIL

*PRINT-LENGTH*
NIL

*PRINT-ARRAY*
T

*PRINT-ESCAPE*
T

*PRINT-PRETTY*
NIL

*PRINT-CIRCLE*
NIL

*PRINT-BASE*
10

*PRINT-RADIX*
NIL

(SETQ STRING1 "Das ist ein Test mit Print ")
"Das ist ein Test mit Print "

(PRIN1-TO-STRING STRING1)
"\"Das ist ein Test mit Print \""

(PRINC-TO-STRING STRING1)
"Das ist ein Test mit Print "

(PROGN (SETQ A (MAKE-STRING-INPUT-STREAM "123")) T)
T

(READ-CHAR-NO-HANG A)
#\1

(READ A)
23

(read-char-no-hang a)
ERROR

(read-char-no-hang a nil "EOF")
"EOF"

(PROGN (SETQ A (MAKE-STRING-INPUT-STREAM "1   2   ;32  abA"))
(SETQ B (MAKE-STRING-INPUT-STREAM " 1 2 3 A x y z
a b c")) T)
T

(READ-DELIMITED-LIST #\A B)
(1 2 3)

(SETQ C (MULTIPLE-VALUE-LIST (READ-LINE B)))
(" x y z" NIL)

(LENGTH C)
2

(MULTIPLE-VALUE-LIST (READ-LINE B))
("a b c" T)

(MULTIPLE-VALUE-LIST (READ-LINE B))
ERROR

(MULTIPLE-VALUE-LIST (READ-LINE B NIL "EOF"))
("EOF" T)

(PEEK-CHAR NIL A)
#\1

(READ-CHAR A)
#\1

(PEEK-CHAR T A)
#\2

(READ-CHAR A)
#\2

(PEEK-CHAR T A)
#\;

(READ-CHAR A)
#\;

(PEEK-CHAR #\A A)
#\A

(READ-CHAR A)
#\A

(PEEK-CHAR NIL A)
ERROR

(PEEK-CHAR NIL A NIL "EOF")
"EOF"

(SETQ A (QUOTE
((BERLIN (DRESDEN FRANKFURT BONN MUENCHEN)) (MUELLER (KARL LUISE DIETER
ALDO)))))
((BERLIN (DRESDEN FRANKFURT BONN MUENCHEN)) (MUELLER (KARL LUISE DIETER
ALDO)))

(PROGN (SETQ AA (MAKE-STRING-INPUT-STREAM "berlin d mueller :r")) T)
T

(DEFUN ASK (&OPTIONAL (RES NIL))
"  (terpri)(terpri)(terpri)
  (print '(*** Eingabe des  Keywortes ***))
  (print '(- mit :r reset))
  (terpri)" (SETQ X (READ AA)) "  (print x)" (COND
((EQUAL X (QUOTE :R)) (CONS "--- reset ---" RES))
(T (CONS (CADR (ASSOC X A)) (ASK RES)))))
ASK

(ASK)
((DRESDEN FRANKFURT BONN MUENCHEN) NIL (KARL LUISE DIETER ALDO) "--- reset ---")

(SETQ STRING1 "Das ist ein Teststring")
"Das ist ein Teststring"

(SETQ STRING2 "Auch das 1 2 3 ist ein Teststring")
"Auch das 1 2 3 ist ein Teststring"

(MULTIPLE-VALUE-LIST (READ-FROM-STRING STRING1))
(DAS 4)

(MULTIPLE-VALUE-LIST (READ-FROM-STRING STRING2))
(AUCH 5)

(MULTIPLE-VALUE-LIST (READ-FROM-STRING STRING1 T NIL :START 2))
(S 4)

(MULTIPLE-VALUE-LIST
(READ-FROM-STRING STRING1 T NIL :START 2 :PRESERVE-WHITESPACE T))
(S 3)

(MULTIPLE-VALUE-LIST (READ-FROM-STRING STRING2 T NIL :START 5))
(DAS 9)

(MULTIPLE-VALUE-LIST (READ-FROM-STRING STRING2 T NIL :START 5 :END
6))
(D 6)

(MULTIPLE-VALUE-LIST (READ-FROM-STRING STRING1 T NIL :START 4 :END
3))
ERROR

(MULTIPLE-VALUE-LIST (READ-FROM-STRING STRING1 T NIL :END 0))
ERROR

(MULTIPLE-VALUE-LIST (READ-FROM-STRING STRING1 T NIL :START -2 :END
0))
ERROR

(MULTIPLE-VALUE-LIST (READ-FROM-STRING STRING1 T NIL :END 2))
(DA 2)

*READ-SUPPRESS*
NIL

(STANDARD-CHAR-P (QUOTE A))
ERROR

(STANDARD-CHAR-P (QUOTE #\BACKSPACE))
#+XCL T #-XCL NIL

(STANDARD-CHAR-P (QUOTE #\TAB))
#+XCL T #-XCL NIL

(STANDARD-CHAR-P (QUOTE #\NEWLINE))
T

(STANDARD-CHAR-P (QUOTE #\PAGE))
#+XCL T #-XCL NIL

(STANDARD-CHAR-P (QUOTE #\RETURN))
#+XCL T #-XCL NIL

#-CMU
(STRING-CHAR-P (QUOTE A))
#-CMU
ERROR

(#-CMU STRING-CHAR-P #+CMU CHARACTERP (QUOTE #\SPACE))
T

(#-CMU STRING-CHAR-P #+CMU CHARACTERP (QUOTE #\NEWLINE))
T

(#-CMU STRING-CHAR-P #+CMU CHARACTERP (QUOTE #\BACKSPACE))
T

(#-CMU STRING-CHAR-P #+CMU CHARACTERP (QUOTE #\a))
T

(#-CMU STRING-CHAR-P #+CMU CHARACTERP (QUOTE #\8))
T

(#-CMU STRING-CHAR-P #+CMU CHARACTERP (QUOTE #\-))
T

(#-CMU STRING-CHAR-P #+CMU CHARACTERP (QUOTE #\n))
T

(#-CMU STRING-CHAR-P #+CMU CHARACTERP (QUOTE #\())
T

(STRINGP "das ist einer der Teststrings")
T

(STRINGP (QUOTE (DAS IST NATUERLICH FALSCH)))
NIL

(STRINGP "das ist die eine Haelfte" "und das die andere")
ERROR

(SETQ J 0)
0

(WITH-INPUT-FROM-STRING (S "animal crackers" :START 6) (READ S))
CRACKERS

(WITH-INPUT-FROM-STRING (S "animal crackers" :INDEX J :START 6) (READ S))
CRACKERS

J
15

(WITH-INPUT-FROM-STRING (S "animal crackers" :INDEX J :START 7) (READ S))
CRACKERS

J
15

(WITH-INPUT-FROM-STRING (S "animal crackers" :INDEX J :START 2) (READ S))
IMAL

J
7

(WITH-INPUT-FROM-STRING (S "animal crackers" :INDEX J :START 0 :END 6) (READ S))
ANIMAL

J
6

(WITH-INPUT-FROM-STRING (S "animal crackers" :INDEX J :START 0 :END
12) (READ S))
ANIMAL

J
7

(WITH-INPUT-FROM-STRING (S "animal crackers" :INDEX J :START -1) (READ S))
ERROR

J
7

(WITH-INPUT-FROM-STRING (S "animal crackers" :INDEX J :START 6 :END
20) (READ S))
#+XCL CRACKERS #+(or CLISP AKCL ECL ALLEGRO) ERROR #-(or XCL CLISP AKCL ECL ALLEGRO) UNKNOWN

J
#+XCL 20 #+(or CLISP AKCL ECL ALLEGRO) 7 #-(or XCL CLISP AKCL ECL ALLEGRO) UNKNOWN

(SETQ A "Das ist wieder einmal einer der SUUPERTESTstrings.")
"Das ist wieder einmal einer der SUUPERTESTstrings."

(PROGN (SETQ B (MAKE-STRING-OUTPUT-STREAM)) T)
T

(WRITE-STRING A B)
"Das ist wieder einmal einer der SUUPERTESTstrings."

(WRITE-STRING A B :START 10)
"Das ist wieder einmal einer der SUUPERTESTstrings."

(WRITE-STRING A B :START 80)
#+XCL "Das ist wieder einmal einer der SUUPERTESTstrings."
#-XCL ERROR

(WRITE-STRING A B :END 5)
"Das ist wieder einmal einer der SUUPERTESTstrings."

(WRITE-STRING A B :END -2)
ERROR

(WRITE-STRING A B :END 100)
#+XCL "Das ist wieder einmal einer der SUUPERTESTstrings."
#-XCL ERROR

(WRITE-STRING A B :START 5 :END 20)
"Das ist wieder einmal einer der SUUPERTESTstrings."

(WRITE-STRING A B :START 10 :END 5)
#+XCL "Das ist wieder einmal einer der SUUPERTESTstrings."
#-XCL ERROR

(GET-OUTPUT-STREAM-STRING B)
#+XCL
"Das ist wieder einmal einer der SUUPERTESTstrings.eder einmal einer der SUUPERTESTstrings.Das iDas ist wieder einmal einer der SUUPERTESTstrings.st wieder einma"
#+(or CLISP AKCL ECL)
"Das ist wieder einmal einer der SUUPERTESTstrings.eder einmal einer der SUUPERTESTstrings.Das ist wieder einma"
#-(or XCL CLISP AKCL ECL) UNKNOWN

(WRITE-STRING A B)
"Das ist wieder einmal einer der SUUPERTESTstrings."

(LENGTH (GET-OUTPUT-STREAM-STRING B))
50

(WRITE-LINE A B)
"Das ist wieder einmal einer der SUUPERTESTstrings."

(LENGTH (GET-OUTPUT-STREAM-STRING B))
51

(WITH-OUTPUT-TO-STRING (S) (PRINT (QUOTE XXX) S))
"
XXX "

(SETQ A (MAKE-ARRAY 10 :ELEMENT-TYPE (QUOTE #-CMU STRING-CHAR #+CMU CHARACTER) :FILL-POINTER
0))
""

(WITH-OUTPUT-TO-STRING (S A) (PRINC 123 S))
123

A
"123"

(WITH-OUTPUT-TO-STRING (S A) (PRINC 4567 S))
4567

A
"1234567"

(WITH-OUTPUT-TO-STRING (S A) (PRINC 890 S))
890

A
"1234567890"

(WITH-OUTPUT-TO-STRING (S A) (PRINC (QUOTE A) S))
ERROR

A
"1234567890"

(SETQ A
(MAKE-ARRAY 10 :ELEMENT-TYPE (QUOTE #-CMU STRING-CHAR #+CMU CHARACTER) :FILL-POINTER 0 :ADJUSTABLE
T))
""

(WITH-OUTPUT-TO-STRING (S A) (PRINC 123 S))
123

A
"123"

(WITH-OUTPUT-TO-STRING (S A) (PRINC 4567 S))
4567

A
"1234567"

(WITH-OUTPUT-TO-STRING (S A) (PRINC 890 S))
890

A
"1234567890"

(WITH-OUTPUT-TO-STRING (S A) (PRINC (QUOTE ABCDE) S))
ABCDE

A
"1234567890ABCDE"

(WITH-OUTPUT-TO-STRING (S A) (PRINC (QUOTE FGHI) S))
FGHI

A
"1234567890ABCDEFGHI"

(progn
(makunbound 'bs)
(makunbound 'a)
(makunbound 'b)
(makunbound 'c)
(makunbound 'd)
(makunbound 'aa)
(makunbound 'string1)
(makunbound 'string2)
(makunbound 'x)
(makunbound 'j)
(makunbound 's1)
(makunbound 'str1)
t)
T

