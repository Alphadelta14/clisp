;; Load the ansi-tests testsuite into CLISP in *ANSI* mode.
;; Usage:
;;   $ cd ansi-tests
;;   $ clisp -q -ansi -i clispload.lsp

;; First the infrastructure.
(load "gclload1.lsp")

;; Set *package*.
(in-package :cl-test)

;; for ENSURE-DIRECTORIES-EXIST.8
(when (ext:probe-directory "scratch/")
  (mapc #'delete-file (directory "scratch/*"))
  (ext:delete-dir "scratch/"))

;; The expected failures.
(setq regression-test::*expected-failures* '(

  ;; ANSI CL 11.1.2. says that the only nickname of the COMMON-LISP package
  ;; is "CL". In CLISP it also has the nickname "LISP", for backward
  ;; compatibility with older programs.
  COMMON-LISP-PACKAGE-NICKNAMES

  ;; ANSI CL 11.1.2. says that the only nickname of the COMMON-LISP-USER
  ;; package is "CL-USER". In CLISP it also has the nickname "USER", for
  ;; backward compatibility with older programs.
  COMMON-LISP-USER-PACKAGE-NICKNAMES

  ;; The symbols
  ;;   LEAST-NEGATIVE-LONG-FLOAT LEAST-NEGATIVE-NORMALIZED-LONG-FLOAT
  ;;   LEAST-POSITIVE-LONG-FLOAT LEAST-POSITIVE-NORMALIZED-LONG-FLOAT
  ;;   LONG-FLOAT-EPSILON LONG-FLOAT-NEGATIVE-EPSILON MOST-NEGATIVE-LONG-FLOAT
  ;;   MOST-POSITIVE-LONG-FLOAT PI
  ;; are variables, not constants, in CLISP, because the long-float precision
  ;; can be changed at run-time, and the values of these symbols change
  ;; accordingly.
  CL-CONSTANT-SYMBOLS.1
  CONSTANTP.10

  ;; Paul Dietz assumes that the qualifiers of methods are checked only
  ;; at run time, when the effective method is determined.
  ;; I argue that the description of DEFMETHOD allows qualifier checking to
  ;; occur already at method definition time.
  DEFGENERIC-METHOD-COMBINATION.+.10
  DEFGENERIC-METHOD-COMBINATION.+.11
  DEFGENERIC-METHOD-COMBINATION.APPEND.10
  DEFGENERIC-METHOD-COMBINATION.APPEND.11
  DEFGENERIC-METHOD-COMBINATION.APPEND.13
  DEFGENERIC-METHOD-COMBINATION.NCONC.10
  DEFGENERIC-METHOD-COMBINATION.NCONC.11
  DEFGENERIC-METHOD-COMBINATION.LIST.10
  DEFGENERIC-METHOD-COMBINATION.LIST.11
  DEFGENERIC-METHOD-COMBINATION.MAX.10
  DEFGENERIC-METHOD-COMBINATION.MAX.11
  DEFGENERIC-METHOD-COMBINATION.MIN.10
  DEFGENERIC-METHOD-COMBINATION.MIN.11
  DEFGENERIC-METHOD-COMBINATION.AND.10
  DEFGENERIC-METHOD-COMBINATION.AND.11
  DEFGENERIC-METHOD-COMBINATION.OR.10
  DEFGENERIC-METHOD-COMBINATION.OR.11
  DEFGENERIC-METHOD-COMBINATION.PROGN.10
  DEFGENERIC-METHOD-COMBINATION.PROGN.11

  ;; Paul Dietz assumes that the HASH-TABLE-TEST function returns the
  ;; EQ/EQL/EQUAL/EQUALP symbol.
  ;; In CLISP, #'EQ has several function designators: EQ, EXT:FASTHASH-EQ,
  ;; EXT:STABLEHASH-EQ, and the HASH-TABLE-TEST function returns one of
  ;; them, arbitrarily.
  HASH-TABLE-TEST.1 HASH-TABLE-TEST.2 HASH-TABLE-TEST.3 HASH-TABLE-TEST.4

  ;; In CLISP (atan 1L0) is more than long-float-epsilon apart from (/ pi 4).
  ATAN.11 ATAN.13

  ;; In CLISP rounding errors cause (let ((c #C(97748.0s0 0.0s0))) (/ c c))
  ;; to be different from #C(1.0s0 0.0s0).
  /.8

  ;; CLISP supports complex numbers with realpart and imagpart of different
  ;; type.
  COMPLEX.2 COMPLEX.4 COMPLEX.5 IMAGPART.4

  ;; Paul Dietz assumes that the classes STREAM and CONDITION are disjoint.
  ;; In CLISP they are not, because the user can create subclasses inheriting
  ;; from FUNDAMENTAL-STREAM and any other class with metaclass STANDARD-CLASS.
  ;; ANSI CL 4.2.2.(1) allows such classes.
  TYPES.7B TYPES.7C

  ;; Paul Dietz assumes that the class STREAM is disjoint from user-defined
  ;; classes with metaclass STANDARD-CLASS.
  ;; In CLISP this is not the case, because the user can create subclasses
  ;; inheriting from FUNDAMENTAL-STREAM and any other class with metaclass
  ;; STANDARD-CLASS. ANSI CL 4.2.2. allows such classes.
  USER-CLASS-DISJOINTNESS

  ;; Paul Dietz assumes that two user-defined classes with metaclass
  ;; STANDARD-CLASS that don't inherit from each other are disjoint.
  ;; In CLISP this is not the case, because the user can create subclasses
  ;; inheriting from both classes. ANSI CL 4.2.2.(3) allows such classes.
  ;; We don't want SUBTYPEP to depend on the existence or absence of
  ;; subclasses.
  USER-CLASS-DISJOINTNESS-2 TAC-3.16

  ;; Paul Dietz assumes that multidimensional arrays of element type CHARACTER
  ;; or BIT are printed like multidimensional arrays of element type T.
  PRINT.ARRAY.2.12 PRINT.ARRAY.2.14 PRINT.ARRAY.2.16 PRINT.ARRAY.2.18
  PRINT.ARRAY.2.19

  ; To be revisited:
  BIGNUM.FLOAT.COMPARE.1A BIGNUM.FLOAT.COMPARE.1B BIGNUM.FLOAT.COMPARE.2A
  BIGNUM.FLOAT.COMPARE.2B BIGNUM.FLOAT.COMPARE.3A BIGNUM.FLOAT.COMPARE.3B
  BIGNUM.FLOAT.COMPARE.4A BIGNUM.FLOAT.COMPARE.4B BIGNUM.FLOAT.COMPARE.5A
  BIGNUM.FLOAT.COMPARE.5B BIGNUM.FLOAT.COMPARE.6A BIGNUM.FLOAT.COMPARE.6B
  BIGNUM.FLOAT.COMPARE.7 BIGNUM.FLOAT.COMPARE.8
  BIGNUM.SHORT-FLOAT.RANDOM.COMPARE.1 RATIONAL.SHORT-FLOAT.RANDOM.COMPARE.1
  RATIONAL.SINGLE-FLOAT.RANDOM.COMPARE.1 COPY-PPRINT-DISPATCH.1
  COPY-PPRINT-DISPATCH.2 COPY-PPRINT-DISPATCH.3 COPY-PPRINT-DISPATCH.4
  PRINT.ARRAY.2.21 PRINT.ARRAY.2.22 PRINT.ARRAY.2.23 PPRINT-TABULAR.6
  PPRINT-TABULAR.7 PPRINT-TABULAR.8 PPRINT-TABULAR.9 PPRINT-TABULAR.10
  PPRINT-TABULAR.11 PPRINT-TABULAR.12 PPRINT-TABULAR.13 PPRINT-TABULAR.14
  PPRINT-TABULAR.15 PPRINT-TABULAR.16 PPRINT-TABULAR.17 PPRINT-TABULAR.18
  PPRINT-TABULAR.19 PPRINT-TABULAR.20 PPRINT-TABULAR.21 PPRINT-TABULAR.22
  PPRINT-TABULAR.24 PPRINT-INDENT.9 PPRINT-INDENT.10 PPRINT-INDENT.19
  PPRINT-INDENT.21 PPRINT-INDENT.22 PPRINT-INDENT.23
  PPRINT-LOGICAL-BLOCK.ERROR.1 PPRINT-LOGICAL-BLOCK.ERROR.2
  PPRINT-LOGICAL-BLOCK.ERROR.3 PPRINT-POP.6 PPRINT-POP.7 PPRINT-POP.8
  PPRINT-NEWLINE.1 PPRINT-NEWLINE.2 PPRINT-NEWLINE.3 PPRINT-NEWLINE.LINEAR.1
  PPRINT-NEWLINE.LINEAR.2 PPRINT-NEWLINE.LINEAR.6 PPRINT-NEWLINE.LINEAR.7
  PPRINT-NEWLINE.LINEAR.8 PPRINT-NEWLINE.MISER.4 PPRINT-NEWLINE.MISER.6
  PPRINT-NEWLINE.MISER.7 PPRINT-NEWLINE.MISER.8 PPRINT-NEWLINE.MISER.9
  PPRINT-NEWLINE.MISER.10 PPRINT-NEWLINE.MISER.11 PPRINT-NEWLINE.FILL.1
  PPRINT-NEWLINE.FILL.2 PPRINT-NEWLINE.FILL.3 PPRINT-NEWLINE.FILL.4
  PPRINT-NEWLINE.FILL.5 PPRINT-NEWLINE.FILL.6 PPRINT-NEWLINE.FILL.7
  PPRINT-NEWLINE.MANDATORY.1 PPRINT-NEWLINE.MANDATORY.2
  PPRINT-NEWLINE.MANDATORY.3 PPRINT-NEWLINE.MANDATORY.5 PPRINT-TAB.NON-PRETTY.1
  PPRINT-TAB.NON-PRETTY.2 PPRINT-TAB.NON-PRETTY.3 PPRINT-TAB.NON-PRETTY.4
  PPRINT-TAB.NON-PRETTY.5 PPRINT-TAB.NON-PRETTY.6 PPRINT-TAB.NON-PRETTY.7
  PPRINT-TAB.NON-PRETTY.8 PPRINT-TAB.SECTION-RELATIVE.1
  PRINT-UNREADABLE-OBJECT.2 PRINT-UNREADABLE-OBJECT.3
))

;; A few tests call DISASSEMBLE. Make it work without user intervention.
(setf (ext:getenv "PAGER") "cat")

;; Avoid floating-point computation warnings that bloat the log file.
(setq custom:*warn-on-floating-point-contagion* nil)
(setq custom:*warn-on-floating-point-rational-contagion* nil)

;; Then the tests.
(load "gclload2.lsp")

;; One test exceeds the memory available in the SPVW_PURE_BLOCKS model.
(when (and (= (logand (sys::address-of nil) #xffffff) 0) ; SPVW_PURE_BLOCKS ?
           (<= (integer-length most-positive-fixnum) 26)) ; 32-bit machine ?
  ;; Inhibit the CHAR-INT.2 test.
  (defun char-int.2.fn () t))
