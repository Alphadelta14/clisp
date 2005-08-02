;;;; Generic documentation
;;;; Sam Steingold 2002 - 2005
;;;; Bruno Haible 2004

(in-package "CLOS")

(defun function-documentation (x)
  (if (typep-class x <standard-generic-function>)
      (std-gf-documentation x)
      (let ((name (sys::function-name x)))
        (or (and (eq (type-of x) 'FUNCTION) ; interpreted function?
                 (sys::%record-ref x 2))
            (and (sys::function-name-p name)
                 (fboundp name) (eq x (sys::unwrapped-fdefinition name))
                 (getf (get (sys::get-funname-symbol x) 'sys::doc)
                       'function))))))

;;; documentation
(defgeneric documentation (x doc-type)
  (:argument-precedence-order doc-type x)
  (:method ((x function) (doc-type (eql 't)))
    (function-documentation x))
  (:method ((x function) (doc-type (eql 'function)))
    (function-documentation x))
  (:method ((x list) (doc-type (eql 'function)))
    (setq x (check-function-name x 'documentation))
    (if (symbolp x)
      (documentation x 'function)
      (if (and (fboundp x) (typep-class (sys::unwrapped-fdefinition x)
                                        <standard-generic-function>))
        (std-gf-documentation (sys::unwrapped-fdefinition x))
        (documentation (second x) 'function))))
  (:method ((x list) (doc-type (eql 'compiler-macro)))
    (setq x (check-function-name x 'documentation))
    (if (symbolp x)
      (documentation x 'compiler-macro)
      (documentation (second x) 'setf-compiler-macro)))
  (:method ((x symbol) (doc-type (eql 'function)))
    (if (and (fboundp x) (typep-class (sys::unwrapped-fdefinition x) <standard-generic-function>))
      (std-gf-documentation (sys::unwrapped-fdefinition x))
      (or (and (fboundp x)
               (let ((f (sys::unwrapped-fdefinition x)))
                 (and (eq (type-of f) 'FUNCTION) ; interpreted function?
                      (sys::%record-ref f 2))))
          (getf (get x 'sys::doc) doc-type))))
  (:method ((x symbol) (doc-type symbol))
    ;; doc-type = `compiler-macro', `setf', `variable', `type',
    ;; `setf-compiler-macro'
    (getf (get x 'sys::doc) doc-type))
  (:method ((x symbol) (doc-type (eql 'type)))
    (let ((class (find-class x nil)))
      (if class
        (documentation class 't)
        (call-next-method))))
  (:method ((x symbol) (doc-type (eql 'structure))) ; structure --> type
    (documentation x 'type))
  (:method ((x symbol) (doc-type (eql 'class))) ; class --> type
    (documentation x 'type))
  (:method ((x method-combination) (doc-type (eql 't)))
    (method-combination-documentation x))
  (:method ((x method-combination) (doc-type (eql 'method-combination)))
    (method-combination-documentation x))
  (:method ((x symbol) (doc-type (eql 'method-combination)))
    (method-combination-documentation (get-method-combination x 'documentation)))
  (:method ((x standard-method) (doc-type (eql 't)))
    (std-method-documentation x))
  (:method ((x package) (doc-type (eql 't)))
    (sys::package-documentation x))
  (:method ((x standard-class) (doc-type (eql 't)))
    (class-documentation x))
  (:method ((x standard-class) (doc-type (eql 'type)))
    (class-documentation x))
  (:method ((x structure-class) (doc-type (eql 't)))
    (class-documentation x))
  (:method ((x structure-class) (doc-type (eql 'type)))
    (class-documentation x))
  ;;; The following are CLISP extensions.
  (:method ((x standard-object) (doc-type (eql 't)))
    (documentation (class-of x) 'type))
  (:method ((x standard-object) (doc-type (eql 'type)))
    (documentation (class-of x) 'type))
  (:method ((x structure-object) (doc-type (eql 't)))
    (documentation (class-of x) 'type))
  (:method ((x structure-object) (doc-type (eql 'type)))
    (documentation (class-of x) 'type))
  (:method ((x defined-class) (doc-type (eql 't)))
    (class-documentation x))
  (:method ((x defined-class) (doc-type (eql 'type)))
    (class-documentation x))
  (:method ((x slot-definition) (doc-type (eql 't)))
    (slot-definition-documentation x)))

(defun set-function-documentation (x new-value)
  (if (typep-class x <standard-generic-function>)
      (setf (std-gf-documentation x) new-value)
      (let ((name (sys::function-name x)))
        (when (eq (type-of x) 'FUNCTION) ; interpreted function?
          (setf (sys::%record-ref x 2) new-value))
        (when (and (sys::function-name-p name)
                   (fboundp name) (eq x (sys::unwrapped-fdefinition name)))
          (sys::%set-documentation (sys::get-funname-symbol name)
                                   'function new-value))
        new-value)))

(defgeneric (setf documentation) (new-value x doc-type)
  (:argument-precedence-order doc-type x new-value)
  (:method (new-value (x function) (doc-type (eql 't)))
    (set-function-documentation x new-value))
  (:method (new-value (x function) (doc-type (eql 'function)))
    (set-function-documentation x new-value))
  (:method (new-value (x list) (doc-type (eql 'function)))
    (setq x (check-function-name x '(setf documentation)))
    (if (symbolp x)
      (sys::%set-documentation x 'function new-value)
      (if (and (fboundp x) (typep-class (sys::unwrapped-fdefinition x)
                                        <standard-generic-function>))
        (setf (std-gf-documentation (sys::unwrapped-fdefinition x)) new-value)
        (sys::%set-documentation (second x) 'setf new-value))))
  (:method (new-value (x list) (doc-type (eql 'compiler-macro)))
    (setq x (check-function-name x '(setf documentation)))
    (if (symbolp x)
      (sys::%set-documentation x 'compiler-macro new-value)
      (sys::%set-documentation (second x) 'setf-compiler-macro new-value)))
  (:method (new-value (x symbol) (doc-type (eql 'function)))
    (if (and (fboundp x) (typep-class (sys::unwrapped-fdefinition x)
                                      <standard-generic-function>))
      (setf (std-gf-documentation (sys::unwrapped-fdefinition x)) new-value)
      (progn
        (when (fboundp x)
          (let ((f (sys::unwrapped-fdefinition x)))
            (when (eq (type-of f) 'FUNCTION) ; interpreted function?
              (setf (sys::%record-ref f 2) new-value))))
        (sys::%set-documentation x 'function new-value)
        new-value)))
  (:method (new-value (x symbol) (doc-type symbol))
    ;; doc-type = `compiler-macro', `setf', `variable', `type',
    ;; `setf-compiler-macro'
    (sys::%set-documentation x doc-type new-value))
  (:method (new-value (x symbol) (doc-type (eql 'type)))
    (let ((class (find-class x nil)))
      (if class
        (setf (documentation class 't) new-value)
        (call-next-method))))
  (:method (new-value (x symbol) (doc-type (eql 'structure)))
    (sys::%set-documentation x 'type new-value))
  (:method (new-value (x symbol) (doc-type (eql 'class)))
    (sys::%set-documentation x 'type new-value))
  (:method (new-value (x method-combination) (doc-type (eql 't)))
    (setf (method-combination-documentation x) new-value))
  (:method
      (new-value (x method-combination) (doc-type (eql 'method-combination)))
    (setf (method-combination-documentation x) new-value))
  (:method (new-value (x symbol) (doc-type (eql 'method-combination)))
    (setf (method-combination-documentation (get-method-combination x '(setf documentation)))
          new-value))
  (:method (new-value (x standard-method) (doc-type (eql 't)))
    (setf (std-method-documentation x) new-value))
  (:method (new-value (x package) (doc-type (eql 't)))
    (setf (sys::package-documentation x) new-value))
  (:method (new-value (x standard-class) (doc-type (eql 't)))
    (setf (class-documentation x) new-value))
  (:method (new-value (x standard-class) (doc-type (eql 'type)))
    (setf (class-documentation x) new-value))
  (:method (new-value (x structure-class) (doc-type (eql 't)))
    (setf (class-documentation x) new-value))
  (:method (new-value (x structure-class) (doc-type (eql 'type)))
    (setf (class-documentation x) new-value))
  ;;; The following are CLISP extensions.
  (:method (new-value (x standard-object) (doc-type (eql 't)))
    (sys::%set-documentation (class-of x) 'type new-value))
  (:method (new-value (x standard-object) (doc-type (eql 'type)))
    (sys::%set-documentation (class-of x) 'type new-value))
  (:method (new-value (x structure-object) (doc-type (eql 't)))
    (sys::%set-documentation (class-of x) 'type new-value))
  (:method (new-value (x structure-object) (doc-type (eql 'type)))
    (sys::%set-documentation (class-of x) 'type new-value))
  (:method (new-value (x defined-class) (doc-type (eql 't)))
    (setf (class-documentation x) new-value))
  (:method (new-value (x defined-class) (doc-type (eql 'type)))
    (setf (class-documentation x) new-value))
  (:method (new-value (x slot-definition) (doc-type (eql 't)))
    (setf (slot-definition-documentation x) new-value)))
