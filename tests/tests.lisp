;; run the test suit:

#+OLD-CLISP
;; Binding *ERROR-HANDLER* is a hammer technique for catching errors. It also
;; disables CLCS processing and thus breaks tests that rely on the condition
;; system, such as:
;;   - the compile-file on structure literal test in clos.lisp
;;   - all tests that use IGNORE-ERRORS
(defmacro with-ignored-errors (&rest forms)
  (let ((b (gensym)))
    `(BLOCK ,b
       (LET ((*ERROR-HANDLER*
              #'(LAMBDA (&REST ARGS)
                  (with-standard-io-syntax
                    (let* ((*print-readably* nil)
                           (error-message (apply #'format nil (cdr args))))
                      (terpri) (princ error-message)
                      (return-from ,b (values 'error error-message)))))))
         ,@forms))))

#+(or AKCL ECL)
(defmacro with-ignored-errors (&rest forms)
  (let ((b (gensym))
        (h (gensym)))
    `(BLOCK ,b
       (LET ((,h (SYMBOL-FUNCTION 'SYSTEM:UNIVERSAL-ERROR-HANDLER)))
         (UNWIND-PROTECT
           (PROGN (SETF (SYMBOL-FUNCTION 'SYSTEM:UNIVERSAL-ERROR-HANDLER)
                        #'(LAMBDA (&REST ARGS) (RETURN-FROM ,b 'ERROR)))
                  ,@forms)
           (SETF (SYMBOL-FUNCTION 'SYSTEM:UNIVERSAL-ERROR-HANDLER) ,h))))))

#+ALLEGRO
(defmacro with-ignored-errors (&rest forms)
  (let ((r (gensym)))
    `(LET ((,r (MULTIPLE-VALUE-LIST (EXCL:ERRORSET (PROGN ,@forms)))))
       (IF (CAR ,r) (VALUES-LIST (CDR ,r)) 'ERROR))))

#-(or OLD-CLISP AKCL ECL ALLEGRO)
(defmacro with-ignored-errors (&rest forms)
  (let ((b (gensym)))
    `(BLOCK ,b
       (HANDLER-BIND
         ((ERROR #'(LAMBDA (CONDITION)
                     (TERPRI) (PRINC CONDITION)
                     (RETURN-FROM ,b (values 'ERROR
                                             (princ-to-string condition))))))
         ,@forms))))

(defun merge-extension (type filename)
  (make-pathname :type type :defaults filename))

;; (lisp-implementation-type) may return something quite long, e.g.,
;; on CMUCL it returns "CMU Common Lisp".
(defvar lisp-implementation-type
  #+CLISP "CLISP" #+AKCL "AKCL" #+ECL "ECL" #+ALLEGRO "ALLEGRO" #+CMU "CMUCL"
  #-(or CLISP AKCL ECL ALLEGRO CMU) (lisp-implementation-type))

(defun do-test (stream log &optional (ignore-errors t))
  (let ((eof "EOF") (error-count 0) (total-count 0))
    (loop
      (let ((form (read stream nil eof))
            (result (read stream nil eof)))
        (when (or (eq form eof) (eq result eof)) (return))
        (incf total-count)
        (print form)
        (multiple-value-bind (my-result error-message)
            (if ignore-errors
                (with-ignored-errors (eval form)) ; return ERROR on errors
                (eval form)) ; don't disturb the condition system when testing it!
          (cond ((eql result my-result)
                 (format t "~%EQL-OK: ~S" result))
                ((equal result my-result)
                 (format t "~%EQUAL-OK: ~S" result))
                ((equalp result my-result)
                 (format t "~%EQUALP-OK: ~S" result))
                (t
                 (incf error-count)
                 (format t "~%ERROR!! ~S should be ~S !" my-result result)
                 (format log "~%Form: ~S~%CORRECT: ~S~%~7A: ~S~%~@[~A~%~]"
                             form result lisp-implementation-type
                             my-result error-message))))))
    (values total-count error-count)))

(defun do-errcheck (stream log &optional ignore-errors)
  (declare (ignore ignore-errors))
  (let ((eof "EOF") (error-count 0) (total-count 0))
    (loop
      (let ((form (read stream nil eof))
            (errtype (read stream nil eof)))
        (when (or (eq form eof) (eq errtype eof)) (return))
        (incf total-count)
        (print form)
        (let ((my-result (nth-value 1 (ignore-errors (eval form)))))
          (multiple-value-bind (typep-result typep-error)
              (ignore-errors (typep my-result errtype))
            (cond ((and (not typep-error) typep-result)
                   (format t "~%OK: ~S" errtype))
                  (t
                   (incf error-count)
                   (format t "~%ERROR!! ~S instead of ~S !" my-result errtype)
                   (format log "~%Form: ~S~%CORRECT: ~S~%~7A: ~S~%"
                               form errtype lisp-implementation-type
                               my-result)))))))
    (values total-count error-count)))

(defvar *run-test-tester* #'do-test)
(defvar *run-test-ignore-errors* t)

(defun run-test (testname
                 &optional (tester *run-test-tester*)
                           (ignore-errors *run-test-ignore-errors*)
                 &aux (logname (merge-extension "erg" testname))
                      error-count total-count)
  (with-open-file (s (merge-extension "tst" testname) :direction :input)
    (format t "~&~s: started ~s~%" 'run-test s)
    (with-open-file (log logname :direction :output
                                 #+SBCL :if-exists #+SBCL :supersede
                                 #+ANSI-CL :if-exists #+ANSI-CL :new-version)
      (let ((*package* *package*) (*print-circle* t) (*print-pretty* nil))
        (setf (values total-count error-count)
              (funcall tester s log ignore-errors)))))
  (when (zerop error-count) (delete-file logname))
  (format t "~&~s: finished ~s (~:d error~:p out of ~:d test~:p)~%"
          'run-test testname error-count total-count)
  (values total-count error-count))

(defmacro with-accumulating-errors ((error-count total-count) &body body)
  (let ((err (gensym)) (tot (gensym)))
    `(multiple-value-bind (,tot ,err) (progn ,@body)
       (incf ,error-count ,err)
       (incf ,total-count ,tot))))

(defun run-files (files)
  (let ((error-count 0) (total-count 0))
    (dolist (file files)
      (with-accumulating-errors (error-count total-count)
        (run-test file)))
    (format
     t "~&~s: finished ~:d file~:p (~:d error~:p out of ~:d test~:p)~%~S~%"
     'run-files (length files) error-count total-count files)
    (values error-count total-count)))

(defun run-some-tests (&optional (dirlist '("./")))
  (let ((files (mapcan (lambda (dir)
                         (directory (make-pathname :name :wild :type "tst"
                                                   :defaults dir)))
                       dirlist)))
    (if files (run-files files)
        (warn "no TST files in directories ~S" dirlist))))

(defun run-all-tests (&optional (disable-risky t))
  (let ((error-count 0) (total-count 0)
        #+CLISP (custom:*warn-on-floating-point-contagion* nil)
        #+CLISP (custom:*warn-on-floating-point-rational-contagion* nil)
        (*features* (if disable-risky *features*
                        (cons :enable-risky-tests *features*))))
    (dolist (ff `(#-(or AKCL ECL)   "alltest"
                                    "array"
                                    "backquot"
                  #+CLISP           "bin-io"
                  #-AKCL            "characters"
                  #+(or CLISP ALLEGRO CMU) "clos"
                  #+CLISP ,@(unless disable-risky '("defhash"))
                  #+(and CLISP UNICODE) "encoding"
                                    "eval20"
                  #+(and CLISP FFI) "ffi"
                                    "floeps"
                                    "format"
                  #+CLISP           "genstream"
                  #+XCL             "hash"
                                    "hashlong"
                  #+CLISP           "hashtable"
                                    "iofkts"
                                    "lambda"
                                    "lists151"
                                    "lists152"
                                    "lists153"
                                    "lists154"
                                    "lists155"
                                    "lists156"
                  #+(or CLISP ALLEGRO CMU) "loop"
                                    "macro8"
                                    "map"
                  #+(or CLISP ALLEGRO CMU) "mop"
                                    "number"
                  #+CLISP           "number2"
                  #-(or AKCL ALLEGRO CMU) "pack11"
                  #+(or XCL CLISP)  "path"
                  #+XCL             "readtable"
                  #-CMU             "setf"
                                    "steele7"
                  #-ALLEGRO         "streams"
                                    "streamslong"
                                    "strings"
                  #-(or AKCL ECL)   "symbol10"
                                    "symbols"
                  #+XCL             "tprint"
                  #+XCL             "tread"
                                    "type"
                  #+CLISP           "weak"
                  #+CLISP           "hashweak"))
      (with-accumulating-errors (error-count total-count) (run-test ff)))
    #+CLISP
    (dotimes (i 20)
      (with-accumulating-errors (error-count total-count)
        (run-test "weakptr")))
    #+(or CLISP ALLEGRO CMU)
    (with-accumulating-errors (error-count total-count)
      (run-test "conditions" #'do-test nil))
    (with-accumulating-errors (error-count total-count)
      (run-test "excepsit" #'do-errcheck))
    (format t "~s: grand total: ~:d error~:p out of ~:d test~:p~%"
            'run-all-tests error-count total-count)
    (values total-count error-count)))
