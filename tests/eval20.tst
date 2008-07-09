;; -*- Lisp -*- vim:filetype=lisp
;; CLtL2 20; ANSI CL 3.1

;; eval

(eval (list 'cdr (car '((quote (a . b)) c))))
b

(makunbound 'x)
x

(eval 'x)
ERROR

(setf x 3)
3

(eval 'x)
3

;; eval-when
(let ((ff "eval-when-test.lisp"))
  (with-open-file (foo ff :direction :output #+(or CMU SBCL) :if-exists #+(or CMU SBCL) :supersede)
    (format foo "~%(eval-when (compile eval)
  ;; note that LAMBDA is not externalizable
  (defvar *junk* #.(lambda (x) (+ 15 x))))~%"))
  (unwind-protect (compile-file ff)
    (post-compile-file-cleanup ff))
  nil)
nil

(defvar *collector*)
*collector*

(let ((forms nil) all (ff "eval-when-test.lisp"))
  (dolist (c '(nil (:compile-toplevel)))
    (dolist (l '(nil (:load-toplevel)))
      (dolist (x '(nil (:execute)))
        (push `(eval-when (,@c ,@l ,@x)
                 (push '(,@c ,@l ,@x) *collector*))
              forms))))
  (dolist (c '(nil (:compile-toplevel)))
    (dolist (l '(nil (:load-toplevel)))
      (dolist (x '(nil (:execute)))
        (push `(let () (eval-when (,@c ,@l ,@x)
                         (push '(let ,@c ,@l ,@x) *collector*)))
              forms))))
  (with-open-file (o ff :direction :output #+(or CMU SBCL) :if-exists #+(or CMU SBCL) :supersede)
    (dolist (f forms)
      (prin1 f o)
      (terpri o)))
  (let ((*collector* nil))
    (load ff)
    (push (cons "load source" *collector*) all))
  (let ((*collector* nil))
    (compile-file ff)
    (push (cons "compile source" *collector*) all))
  (let ((*collector* nil))
    (load (compile-file-pathname ff))
    (push (cons "load compiled" *collector*) all))
  (post-compile-file-cleanup ff)
  (nreverse all))
(("load source"
  (:EXECUTE) (:LOAD-TOPLEVEL :EXECUTE) (:COMPILE-TOPLEVEL :EXECUTE)
  (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL :EXECUTE)
  (LET :EXECUTE) (LET :LOAD-TOPLEVEL :EXECUTE)
  (LET :COMPILE-TOPLEVEL :EXECUTE)
  (LET :COMPILE-TOPLEVEL :LOAD-TOPLEVEL :EXECUTE))
 ("compile source"
  (:COMPILE-TOPLEVEL) (:COMPILE-TOPLEVEL :EXECUTE)
  (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL)
  (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL :EXECUTE))
 ("load compiled"
  (:LOAD-TOPLEVEL) (:LOAD-TOPLEVEL :EXECUTE)
  (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL)
  (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL :EXECUTE)
  (LET :EXECUTE) (LET :LOAD-TOPLEVEL :EXECUTE)
  (LET :COMPILE-TOPLEVEL :EXECUTE)
  (LET :COMPILE-TOPLEVEL :LOAD-TOPLEVEL :EXECUTE)))

;; constantp

(constantp 2)
T

(constantp #\r)
T

(constantp "max")
T

(constantp '#(110))
T

(constantp :max)
T

(constantp T)
T

(constantp NIL)
T

(constantp 'PI)
#-CLISP T #+CLISP NIL

(constantp '(quote foo))
T

(constantp '(+ 3 4))
#+CLISP T #-CLISP NIL

(constantp '((setf cons) 3 4))
NIL

;; <http://www.lisp.org/HyperSpec/Issues/iss146-writeup.html>
(let ((src "foo.lisp") (zz (cons 1 2)))
  (defun setf-foo (u v) (setf (car u) v))
  (with-open-file (s src :direction :output #+(or CMU SBCL) :if-exists #+(or CMU SBCL) :supersede)
    (format s "(progn~%  (defsetf foo setf-foo)
  (defun bar (u v) (setf (foo u) v)))~%"))
  (load src #+CLISP :compiling #+CLISP t)
  (delete-file src)
  (bar zz 12)
  zz)
(12 . 2)

;; globally special
(defparameter x 1) x
(handler-bind ((unbound-variable
                (lambda (c) (princ-error c) (store-value 10))))
  (list (let (x) (makunbound 'x) x) x))
(10 1)

(handler-bind ((unbound-variable
                (lambda (c) (princ-error c) (store-value 11))))
  (list (let (x) (makunbound 'x) (symbol-value 'x)) x))
(11 1)

(handler-bind ((unbound-variable
                (lambda (c) (princ-error c) (store-value 12))))
  (list (let (x) (makunbound 'x) (list x (symbol-value 'x))) x))
((12 12) 1)

(handler-bind ((unbound-variable
                (lambda (c) (princ-error c) (store-value 13))))
  (list (let (x) (makunbound 'x) (list (symbol-value 'x) x)) x))
((13 13) 1)

(let ((count 140))
  (handler-bind ((unbound-variable
                  (lambda (c) (princ-error c) (use-value (incf count)))))
    (list (let (x) (makunbound 'x) (list x (symbol-value 'x))) x)))
((141 142) 1)

(let ((count 150))
  (handler-bind ((unbound-variable
                  (lambda (c) (princ-error c) (use-value (incf count)))))
    (list (let (x) (makunbound 'x) (list (symbol-value 'x) x)) x)))
((151 152) 1)

;; lexical: makunbound does not affect the lexical binding
(let ((y 1))
  (list (let ((y 20)) (makunbound 'y) y) y))
(20 1)

(let ((y 1))
  (handler-bind ((unbound-variable
                  (lambda (c) (princ-error c) (store-value 21))))
    (list (let (y) (makunbound 'y) (symbol-value 'y)) y)))
(21 1)

(let ((y 1))
  (handler-bind ((unbound-variable
                  (lambda (c) (princ-error c) (store-value 220))))
    (list (let ((y 22)) (makunbound 'y) (list y (symbol-value 'y))) y)))
((22 220) 1)

(let ((y 1))
  (handler-bind ((unbound-variable
                  (lambda (c) (princ-error c) (store-value 230))))
    (list (let ((y 23)) (makunbound 'y) (list (symbol-value 'y) y)) y)))
((230 23) 1)

(let ((y 1) (count 240))
  (handler-bind ((unbound-variable
                  (lambda (c) (princ-error c) (use-value (incf count)))))
    (list (let ((y 24)) (makunbound 'y) (list y (symbol-value 'y))) y)))
((24 241) 1)

(let ((y 1) (count 250))
  (handler-bind ((unbound-variable
                  (lambda (c) (princ-error c) (use-value (incf count)))))
    (list (let ((y 25)) (makunbound 'y) (list (symbol-value 'y) y)) y)))
((251 25) 1)


;; Clean up.
(progn (symbol-cleanup 'setf-foo) (symbol-cleanup 'bar) (symbol-cleanup 'x)) T
