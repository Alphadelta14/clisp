;; Copyright (C) 2002-2004, Yuji Minejima <ggb01164@nifty.ne.jp>
;; ALL RIGHTS RESERVED.
;;
;; $ Id: should-array.lisp,v 1.12 2004/08/09 02:49:55 yuji Exp $
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;;
;;  * Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;;  * Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in
;;    the documentation and/or other materials provided with the
;;    distribution.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(HANDLER-CASE (PROGN (ADJUST-ARRAY (MAKE-ARRAY '(3 3)) '(1 9) :FILL-POINTER 1))
  (ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))

#-CLISP ;Bruno: Why expect an error? A string _is_ an array.
(progn
  #-(or cmu clispxxx)
  (HANDLER-CASE (PROGN (ADJUSTABLE-ARRAY-P "not-a-symbol"))
    (TYPE-ERROR NIL T)
    (ERROR NIL NIL)
    (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
  #+(or cmu clispxxx) 'skipped)

(progn
  #-cmu
  (HANDLER-CASE (PROGN (ADJUSTABLE-ARRAY-P #\a))
    (TYPE-ERROR NIL T)
    (ERROR NIL NIL)
    (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
  #+cmu 'skipped)

(progn
  #-cmu
  (HANDLER-CASE (PROGN (ADJUSTABLE-ARRAY-P '(NIL)))
    (TYPE-ERROR NIL T)
    (ERROR NIL NIL)
    (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
  #+cmu 'skipped)

(HANDLER-CASE (PROGN (ARRAY-DIMENSIONS 'NOT-AN-ARRAY))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
(HANDLER-CASE (PROGN (ARRAY-DIMENSIONS #\a))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
(HANDLER-CASE (PROGN (ARRAY-DIMENSIONS '(NIL)))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))


(HANDLER-CASE (PROGN (ARRAY-ELEMENT-TYPE 'NOT-AN-ARRAY))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
(HANDLER-CASE (PROGN (ARRAY-ELEMENT-TYPE #\a))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
(HANDLER-CASE (PROGN (ARRAY-ELEMENT-TYPE '(NIL)))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))

(progn
  #-cmu
  (HANDLER-CASE (PROGN (ARRAY-HAS-FILL-POINTER-P 'NOT-AN-ARRAY))
    (TYPE-ERROR NIL T)
    (ERROR NIL NIL)
    (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
  #+cmu 'skipped)

(progn
  #-cmu
  (HANDLER-CASE (PROGN (ARRAY-HAS-FILL-POINTER-P #\a))
    (TYPE-ERROR NIL T)
    (ERROR NIL NIL)
    (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
  #+cmu 'skipped)

(progn
  #-cmu
  (HANDLER-CASE (PROGN (ARRAY-HAS-FILL-POINTER-P '(NIL)))
    (TYPE-ERROR NIL T)
    (ERROR NIL NIL)
    (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
  #+cmu 'skipped)

(progn
  #-cmu
  (HANDLER-CASE (PROGN (ARRAY-DISPLACEMENT 'NOT-AN-ARRAY))
    (TYPE-ERROR NIL T)
    (ERROR NIL NIL)
    (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
  #+cmu 'skipped)

(progn
  #-cmu
  (HANDLER-CASE (PROGN (ARRAY-DISPLACEMENT #\a))
    (TYPE-ERROR NIL T)
    (ERROR NIL NIL)
    (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
  #+cmu 'skipped)

(progn
  #-cmu
  (HANDLER-CASE (PROGN (ARRAY-DISPLACEMENT '(NIL)))
    (TYPE-ERROR NIL T)
    (ERROR NIL NIL)
    (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
  #+cmu 'skipped)

(HANDLER-CASE (PROGN (ARRAY-RANK 'NOT-AN-ARRAY))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
(HANDLER-CASE (PROGN (ARRAY-RANK #\a))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
(HANDLER-CASE (PROGN (ARRAY-RANK '(NIL)))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))

(HANDLER-CASE (PROGN (ARRAY-TOTAL-SIZE 'NOT-AN-ARRAY))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
(HANDLER-CASE (PROGN (ARRAY-TOTAL-SIZE #\a))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
(HANDLER-CASE (PROGN (ARRAY-TOTAL-SIZE '(NIL)))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))

(HANDLER-CASE (PROGN (FILL-POINTER 'NOT-AN-ARRAY))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
(HANDLER-CASE (PROGN (FILL-POINTER #\a))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
(HANDLER-CASE (PROGN (FILL-POINTER '(NIL)))
  (TYPE-ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))

(let ((vector (make-array 10 :fill-pointer nil)))
  (or (not (array-has-fill-pointer-p vector))
      (HANDLER-CASE (PROGN (FILL-POINTER VECTOR))
        (TYPE-ERROR NIL T)
        (ERROR NIL NIL)
        (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))))

(let ((vector (make-array 10 :fill-pointer nil)))
  (or (not (array-has-fill-pointer-p vector))
      (HANDLER-CASE (PROGN (SETF (FILL-POINTER VECTOR) 0))
        (TYPE-ERROR NIL T)
        (ERROR NIL NIL)
        (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))))

(progn
  #-(or cmu clispxxx)
  (HANDLER-CASE (PROGN (VECTOR-POP (MAKE-ARRAY 10 :FILL-POINTER NIL)))
    (TYPE-ERROR NIL T)
    (ERROR NIL NIL)
    (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
  #+(or cmu clispxxx) 'skipped)

(HANDLER-CASE (PROGN (VECTOR-POP (MAKE-ARRAY 10 :FILL-POINTER 0)))
  (ERROR NIL T)
  (ERROR NIL NIL)
  (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))
(let ((vec (make-array 3 :fill-pointer t :initial-contents '(a b c))))
  (and (eq (vector-pop vec) 'c)
       (eq (vector-pop vec) 'b)
       (eq (vector-pop vec) 'a)
       (HANDLER-CASE (PROGN (VECTOR-POP VEC))
              (ERROR NIL T)
              (ERROR NIL NIL)
              (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))))


(let ((vector (make-array 10 :fill-pointer nil)))
  (or (not (array-has-fill-pointer-p vector))
      (HANDLER-CASE (PROGN (VECTOR-PUSH 'A VECTOR))
        (ERROR NIL T)
        (ERROR NIL NIL)
        (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))))

(let ((vector (make-array 10 :fill-pointer nil)))
  (or (not (array-has-fill-pointer-p vector))
      (HANDLER-CASE (PROGN (VECTOR-PUSH-EXTEND 'A VECTOR))
        (ERROR NIL T)
        (ERROR NIL NIL)
        (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))))

(let ((vector (make-array 1 :fill-pointer t :adjustable nil)))
  (or (adjustable-array-p vector)
      (HANDLER-CASE (PROGN (VECTOR-PUSH-EXTEND 'A VECTOR))
        (ERROR NIL T)
        (ERROR NIL NIL)
        (:NO-ERROR (&REST REST) (DECLARE (IGNORE REST)) NIL))))

