;; -*- Lisp -*-
;; Test some MOP-like CLOS features

; Make the MOP symbols accessible from package CLOS.
#-(or CLISP ALLEGRO LISPWORKS)
(let ((packname
         #+SBCL "SB-PCL" ; or "SB-MOP"?
         #+CMU "PCL" ; or "MOP"?
         #+OpenMCL "OPENMCL-MOP" ; or "CCL" ?
         ))
  #+SBCL (unlock-package packname)
  (rename-package packname packname (cons "CLOS" (package-nicknames packname)))
  t)
#-(or CLISP ALLEGRO LISPWORKS)
T

#-(or CMU18 OpenMCL LISPWORKS)
(progn
  (defstruct rectangle1 (x 0.0) (y 0.0))
  (defclass counted1-class (structure-class)
    ((counter :initform 0)))
  (defclass counted1-rectangle (rectangle1) () (:metaclass counted1-class))
  (defmethod make-instance :after ((c counted1-class) &rest args)
    (incf (slot-value c 'counter)))
  (slot-value (find-class 'counted1-rectangle) 'counter)
  (make-instance 'counted1-rectangle)
  (slot-value (find-class 'counted1-rectangle) 'counter))
#-(or CMU18 OpenMCL LISPWORKS)
1

#-CMU18
(progn
  (defclass rectangle2 ()
    ((x :initform 0.0 :initarg x) (y :initform 0.0 :initarg y)))
  (defclass counted2-class (standard-class)
    ((counter :initform 0)))
  #-CLISP
  (defmethod clos:validate-superclass ((c1 counted2-class) (c2 standard-class))
    t)
  (defclass counted2-rectangle (rectangle2) () (:metaclass counted2-class))
  (defmethod make-instance :after ((c counted2-class) &rest args)
    (incf (slot-value c 'counter)))
  (slot-value (find-class 'counted2-rectangle) 'counter)
  (make-instance 'counted2-rectangle)
  (slot-value (find-class 'counted2-rectangle) 'counter))
#-CMU18
1

(progn
  (defclass counter ()
    ((count :allocation :class :initform 0 :reader how-many)))
  (defclass counted-object (counter) ((name :initarg :name)))
  (defmethod initialize-instance :after ((obj counter) &rest args)
    (incf (slot-value obj 'count)))
  (list (how-many (make-instance 'counted-object :name 'foo))
        (how-many (clos:class-prototype (find-class 'counter)))
        (how-many (make-instance 'counted-object :name 'bar))
        (how-many (clos:class-prototype (find-class 'counter)))))
(1 1 2 2)

;; Check that the slot :accessor option works also on structure-class.
#-(or OpenMCL LISPWORKS)
(progn
  (defclass structure01 () ((x :initarg :x :accessor structure01-x))
    (:metaclass structure-class))
  (let ((object (make-instance 'structure01 :x 17)))
    (list (typep #'structure01-x 'generic-function)
          (structure01-x object)
          (progn (incf (structure01-x object)) (structure01-x object)))))
#-(or OpenMCL LISPWORKS)
(t 17 18)


;; Check that print-object can print all kinds of uninitialized metaobjects.
(defun as-string (obj)
  (let ((string (write-to-string obj :escape t :pretty nil)))
    ;; For CLISP: Remove pattern #x[0-9A-F]* from it:
    (let ((i (search "#x" string)))
      (when i
        (let ((j (or (position-if-not #'(lambda (c) (digit-char-p c 16)) string
                                      :start (+ i 2))
                     (length string))))
          (setq string (concatenate 'string (subseq string 0 i) (subseq string j))))))
    ;; For CMUCL, SBCL: Substitute {} for pattern {[0-9A-F]*} :
    (do ((pos 0))
        (nil)
      (let ((i (search "{" string :start2 pos)))
        (unless i (return))
        (let ((j (position-if-not #'(lambda (c) (digit-char-p c 16)) string
                                  :start (+ i 1))))
          (unless (and j (eql (char string j) #\})) (return))
          (setq string (concatenate 'string (subseq string 0 (+ i 1)) (subseq string j)))
          (setq pos (+ i 2)))))
    string))
AS-STRING

(as-string (allocate-instance (find-class 'clos:specializer)))
#+CLISP "#<SPECIALIZER >"
#+CMU "#<PCL:SPECIALIZER {}>"
#+SBCL "#<SB-MOP:SPECIALIZER {}>"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'class)))
#+CLISP "#<CLASS #<UNBOUND>>"
#+CMU "#<CLASS \"unbound\" {}>"
#+SBCL "#<CLASS \"unbound\">"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'standard-class)))
#+CLISP "#<STANDARD-CLASS #<UNBOUND> :UNINITIALIZED>"
#+CMU "#<STANDARD-CLASS \"unbound\" {}>"
#+SBCL "#<STANDARD-CLASS \"unbound\">"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'structure-class)))
#+CLISP "#<STRUCTURE-CLASS #<UNBOUND>>"
#+CMU "#<STRUCTURE-CLASS \"unbound\" {}>"
#+SBCL "#<STRUCTURE-CLASS \"unbound\">"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'clos:eql-specializer)))
#+CLISP "#<EQL-SPECIALIZER #<UNBOUND>>"
#+CMU "#<PCL:EQL-SPECIALIZER {}>"
#+SBCL "#<SB-MOP:EQL-SPECIALIZER {}>"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'clos:slot-definition)))
#+CLISP "#<SLOT-DEFINITION #<UNBOUND> >"
#+CMU "#<SLOT-DEFINITION \"unbound\" {}>"
#+SBCL "#<SB-MOP:SLOT-DEFINITION \"unbound\">"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'clos:direct-slot-definition)))
#+CLISP "#<DIRECT-SLOT-DEFINITION #<UNBOUND> >"
#+CMU "#<DIRECT-SLOT-DEFINITION \"unbound\" {}>"
#+SBCL "#<SB-MOP:DIRECT-SLOT-DEFINITION \"unbound\">"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'clos:effective-slot-definition)))
#+CLISP "#<EFFECTIVE-SLOT-DEFINITION #<UNBOUND> >"
#+CMU "#<EFFECTIVE-SLOT-DEFINITION \"unbound\" {}>"
#+SBCL "#<SB-MOP:EFFECTIVE-SLOT-DEFINITION \"unbound\">"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'clos:standard-direct-slot-definition)))
#+CLISP "#<STANDARD-DIRECT-SLOT-DEFINITION #<UNBOUND> >"
#+CMU "#<STANDARD-DIRECT-SLOT-DEFINITION \"unbound\" {}>"
#+SBCL "#<SB-MOP:STANDARD-DIRECT-SLOT-DEFINITION \"unbound\">"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'clos:standard-effective-slot-definition)))
#+CLISP "#<STANDARD-EFFECTIVE-SLOT-DEFINITION #<UNBOUND> >"
#+CMU "#<STANDARD-EFFECTIVE-SLOT-DEFINITION \"unbound\" {}>"
#+SBCL "#<SB-MOP:STANDARD-EFFECTIVE-SLOT-DEFINITION \"unbound\">"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'method-combination)))
#+CLISP "#<METHOD-COMBINATION #<UNBOUND> >"
#+(or CMU SBCL) "#<METHOD-COMBINATION {}>"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'method)))
#+CLISP "#<METHOD >"
#+(or CMU SBCL) "#<METHOD {}>"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'standard-method)))
#+CLISP "#<STANDARD-METHOD :UNINITIALIZED>"
#+CMU "#<#<STANDARD-METHOD {}> {}>"
#+SBCL "#<STANDARD-METHOD #<STANDARD-METHOD {}> {}>"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'clos:standard-reader-method)))
#+CLISP "#<STANDARD-READER-METHOD :UNINITIALIZED>"
#+CMU "#<#<#<PCL:STANDARD-READER-METHOD {}> {}> {}>"
#+SBCL "#<SB-MOP:STANDARD-READER-METHOD #<SB-MOP:STANDARD-READER-METHOD #<SB-MOP:STANDARD-READER-METHOD {}> {}> {}>"
#-CLISP UNKNOWN

(as-string (allocate-instance (find-class 'clos:standard-writer-method)))
#+CLISP "#<STANDARD-WRITER-METHOD :UNINITIALIZED>"
#+CMU "#<#<#<PCL:STANDARD-WRITER-METHOD {}> {}> {}>"
#+SBCL "#<SB-MOP:STANDARD-WRITER-METHOD #<SB-MOP:STANDARD-WRITER-METHOD #<SB-MOP:STANDARD-WRITER-METHOD {}> {}> {}>"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'clos:funcallable-standard-object)))
#+CLISP "#<FUNCALLABLE-STANDARD-OBJECT #<UNBOUND>>"
#+CMU "#<PCL:FUNCALLABLE-STANDARD-OBJECT {}>"
#+SBCL "#<SB-MOP:FUNCALLABLE-STANDARD-OBJECT {}>"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'generic-function)))
#+CLISP "#<GENERIC-FUNCTION #<UNBOUND>>"
#+(or CMU SBCL) "#<GENERIC-FUNCTION {}>"
#-(or CLISP CMU SBCL) UNKNOWN

(as-string (allocate-instance (find-class 'standard-generic-function)))
#+CLISP "#<STANDARD-GENERIC-FUNCTION #<UNBOUND>>"
#+CMU "#<STANDARD-GENERIC-FUNCTION \"unbound\" \"?\" {}>"
#+SBCL "#<STANDARD-GENERIC-FUNCTION \"unbound\" \"?\">"
#-(or CLISP CMU SBCL) UNKNOWN


;; Check that defclass supports user-defined options.
(progn
  (defclass option-class (standard-class)
    ((option :accessor cl-option :initarg :my-option)))
  #-CLISP
  (defmethod clos:validate-superclass ((c1 option-class) (c2 standard-class))
    t)
  (macrolet ((eval-succeeds (form)
               `(not (nth-value 1 (ignore-errors (eval ',form))))))
    (list (eval-succeeds
            (defclass testclass02a ()
              ()
              (:my-option foo)
              (:metaclass option-class)))
          (cl-option (find-class 'testclass02a))
          (eval-succeeds
            (defclass testclass02b ()
              ()
              (:my-option bar)
              (:my-option baz)
              (:metaclass option-class)))
          (eval-succeeds
            (defclass testclass02c ()
              ()
              (:other-option foo)
              (:metaclass option-class))))))
(T (FOO) NIL NIL)


;; Check that defclass supports user-defined slot options.
(progn
  (defclass option-slot-definition (standard-direct-slot-definition)
    ((option :accessor sl-option :initarg :my-option)))
  (defclass option-slot-class (standard-class)
    ())
  (defmethod clos:direct-slot-definition-class ((c option-slot-class) &rest args)
    (declare (ignore args))
    (find-class 'option-slot-definition))
  #-CLISP
  (defmethod clos:validate-superclass ((c1 option-slot-class) (c2 standard-class))
    t)
  (macrolet ((eval-succeeds (form)
               `(not (nth-value 1 (ignore-errors (eval ',form))))))
    (list (eval-succeeds
            (defclass testclass03a ()
              ((x :my-option foo))
              (:metaclass option-slot-class)))
          (sl-option (first (class-direct-slots (find-class 'testclass03a))))
          (eval-succeeds
            (defclass testclass03b ()
              ((x :my-option bar :my-option baz))
              (:metaclass option-slot-class)))
          (sl-option (first (class-direct-slots (find-class 'testclass03b))))
          (eval-succeeds
            (defclass testclass03c ()
              ((x :other-option foo))
              (:metaclass option-slot-class)))
          (eval-succeeds
            (defclass testclass03d ()
              ((x :my-option foo))
              (:my-option bar)
              (:metaclass option-slot-class))))))
(T FOO T (BAR BAZ) NIL NIL)

;; Check that after a class redefinition, new user-defined direct slots
;; have replaced the old direct slots.
(progn
  (defclass extended-slot-definition (standard-direct-slot-definition)
    ((option1 :initarg :option1)
     (option2 :initarg :option2)))
  (defclass extended-slot-class (standard-class)
    ())
  (defmethod clos:direct-slot-definition-class ((c extended-slot-class) &rest args)
    (declare (ignore args))
    (find-class 'extended-slot-definition))
  #-CLISP
  (defmethod clos:validate-superclass ((c1 extended-slot-class) (c2 standard-class))
    t)
  (defclass testclass03e () ((x :option1 bar)) (:metaclass extended-slot-class))
  (defclass testclass03e () ((x :option2 baz)) (:metaclass extended-slot-class))
  (let ((cl (find-class 'testclass03e)))
    (list (length (class-direct-slots cl))
          (slot-boundp (first (class-direct-slots cl)) 'option1)
          (slot-boundp (first (class-direct-slots cl)) 'option2))))
(1 NIL T)


;; Check that defgeneric supports user-defined options.
(progn
  (defclass option-generic-function (standard-generic-function)
    ((option :accessor gf-option :initarg :my-option))
    (:metaclass clos:funcallable-standard-class))
  (macrolet ((eval-succeeds (form)
               `(not (nth-value 1 (ignore-errors (eval ',form))))))
    (list (eval-succeeds
            (defgeneric testgf04a (x y)
              (:my-option foo)
              (:generic-function-class option-generic-function)))
          (gf-option #'testgf04a)
          (eval-succeeds
            (defgeneric testgf04b (x y)
              (:my-option bar)
              (:my-option baz)
              (:generic-function-class option-generic-function)))
          (eval-succeeds
            (defgeneric testgf04c (x y)
              (:my-option bar)
              (:other-option baz)
              (:generic-function-class option-generic-function))))))
(T (FOO) NIL NIL)


;; Check dependents notification on classes.
(progn
  (defclass dependent05 () ((counter :initform 0)))
  (defclass testclass05 () ())
  (defmethod clos:update-dependent ((c class) (d dependent05) &rest args)
    (incf (slot-value d 'counter)))
  (let ((testclass (find-class 'testclass05))
        (dep1 (make-instance 'dependent05))
        (dep2 (make-instance 'dependent05))
        (dep3 (make-instance 'dependent05)))
    (clos:add-dependent testclass dep1)
    (clos:add-dependent testclass dep2)
    (clos:add-dependent testclass dep3)
    (clos:add-dependent testclass dep1)
    (reinitialize-instance testclass :name 'testclass05-renamed)
    (clos:remove-dependent testclass dep2)
    (reinitialize-instance testclass :name 'testclass05-rerenamed)
    (list (slot-value dep1 'counter)
          (slot-value dep2 'counter)
          (slot-value dep3 'counter))))
(2 1 2)

;; Check dependents notification on generic functions.
(progn
  (defclass dependent06 () ((history :initform '())))
  (defgeneric testgf06 (x))
  (defmethod clos:update-dependent ((gf generic-function) (d dependent06) &rest args)
    (push args (slot-value d 'history)))
  (let ((testgf #'testgf06)
        (dep1 (make-instance 'dependent06))
        (dep2 (make-instance 'dependent06))
        (dep3 (make-instance 'dependent06)))
    (clos:add-dependent testgf dep1)
    (clos:add-dependent testgf dep2)
    (clos:add-dependent testgf dep3)
    (clos:add-dependent testgf dep1)
    (reinitialize-instance testgf :name 'testgf06-renamed)
    (defmethod testgf06 ((x integer)))
    (clos:remove-dependent testgf dep2)
    (defmethod testgf06 ((x real)))
    (remove-method testgf (find-method testgf '() (list (find-class 'integer))))
    (mapcar #'(lambda (history)
                (mapcar #'(lambda (event)
                            (mapcar #'(lambda (x)
                                        (if (typep x 'method)
                                          (list 'method (mapcar #'class-name (method-specializers x)))
                                          x))
                                    event))
                        history))
            (list (reverse (slot-value dep1 'history))
                  (reverse (slot-value dep2 'history))
                  (reverse (slot-value dep3 'history))))))
(((:name testgf06-renamed) (add-method (method (integer))) (add-method (method (real))) (remove-method (method (integer))))
 ((:name testgf06-renamed) (add-method (method (integer))))
 ((:name testgf06-renamed) (add-method (method (integer))) (add-method (method (real))) (remove-method (method (integer)))))


;;; Check the dependent protocol
;;;   add-dependent remove-dependent map-dependents

(progn
  (defparameter *timestamp* 0)
  (defclass prioritized-dependent ()
    ((priority :type real :initform 0 :initarg :priority :reader dependent-priority)))
  (defclass prioritized-dispatcher ()
    ((dependents :type list :initform nil)))
  (defmethod clos:add-dependent ((metaobject prioritized-dispatcher) (dependent prioritized-dependent))
    (unless (member dependent (slot-value metaobject 'dependents))
      (setf (slot-value metaobject 'dependents)
            (sort (cons dependent (slot-value metaobject 'dependents)) #'>
                  :key #'dependent-priority))))
  (defmethod clos:remove-dependent ((metaobject prioritized-dispatcher) (dependent prioritized-dependent))
    (setf (slot-value metaobject 'dependents)
          (delete dependent (slot-value metaobject 'dependents))))
  (defmethod clos:map-dependents ((metaobject prioritized-dispatcher) function)
    ; Process the dependents list in decreasing priority order.
    (dolist (dependent (slot-value metaobject 'dependents))
      (funcall function dependent)
      (incf *timestamp*)))
  t)
T

;; Check that notification on classes can proceed by priorities.
(progn
  (setq *timestamp* 0)
  (defclass prioritized-class (prioritized-dispatcher standard-class)
    ())
  #-CLISP
  (defmethod clos:validate-superclass ((c1 prioritized-class) (c2 standard-class))
    t)
  (defclass testclass07 () () (:metaclass prioritized-class))
  (defclass dependent07 (prioritized-dependent) ((history :initform nil)))
  (defmethod clos:update-dependent ((c class) (d dependent07) &rest args)
    (push (cons *timestamp* args) (slot-value d 'history)))
  (let ((testclass (find-class 'testclass07))
        (dep1 (make-instance 'dependent07 :priority 5))
        (dep2 (make-instance 'dependent07 :priority 10))
        (dep3 (make-instance 'dependent07 :priority 1)))
    (clos:add-dependent testclass dep1)
    (clos:add-dependent testclass dep2)
    (clos:add-dependent testclass dep3)
    (clos:add-dependent testclass dep1)
    (reinitialize-instance testclass :name 'testclass07-renamed)
    (clos:remove-dependent testclass dep2)
    (reinitialize-instance testclass :name 'testclass07-rerenamed)
    (list (reverse (slot-value dep1 'history))
          (reverse (slot-value dep2 'history))
          (reverse (slot-value dep3 'history)))))
(((1 :name testclass07-renamed) (3 :name testclass07-rerenamed))
 ((0 :name testclass07-renamed))
 ((2 :name testclass07-renamed) (4 :name testclass07-rerenamed)))

;; Check that notification on generic-functions can proceed by priorities.
(progn
  (setq *timestamp* 0)
  (defclass prioritized-generic-function (prioritized-dispatcher standard-generic-function)
    ()
    (:metaclass clos:funcallable-standard-class))
  (defgeneric testgf08 (x) (:generic-function-class prioritized-generic-function))
  (defclass dependent08 (prioritized-dependent) ((history :initform '())))
  (defmethod clos:update-dependent ((gf generic-function) (d dependent08) &rest args)
    (push (cons *timestamp* args) (slot-value d 'history)))
  (let ((testgf #'testgf08)
        (dep1 (make-instance 'dependent08 :priority 1))
        (dep2 (make-instance 'dependent08 :priority 10))
        (dep3 (make-instance 'dependent08 :priority 5)))
    (clos:add-dependent testgf dep1)
    (clos:add-dependent testgf dep2)
    (clos:add-dependent testgf dep3)
    (clos:add-dependent testgf dep1)
    (reinitialize-instance testgf :name 'testgf08-renamed)
    (defmethod testgf08 ((x integer)))
    (clos:remove-dependent testgf dep2)
    (defmethod testgf08 ((x real)))
    (remove-method testgf (find-method testgf '() (list (find-class 'integer))))
    (mapcar #'(lambda (history)
                (mapcar #'(lambda (event)
                            (mapcar #'(lambda (x)
                                        (if (typep x 'method)
                                          (list 'method (mapcar #'class-name (method-specializers x)))
                                          x))
                                    event))
                        history))
            (list (reverse (slot-value dep1 'history))
                  (reverse (slot-value dep2 'history))
                  (reverse (slot-value dep3 'history))))))
(((2 :name testgf08-renamed) (5 add-method (method (integer))) (7 add-method (method (real))) (9 remove-method (method (integer))))
 ((0 :name testgf08-renamed) (3 add-method (method (integer))))
 ((1 :name testgf08-renamed) (4 add-method (method (integer))) (6 add-method (method (real))) (8 remove-method (method (integer)))))


;;; Check the direct-methods protocol
;;;   add-direct-method remove-direct-method
;;;   specializer-direct-generic-functions specializer-direct-methods

;; Check that it's possible to avoid storing all trivially specialized methods.
;; We can do this since the class <t> will never change.
(let ((<t> (find-class 't))
      (operation-counter 0))
  (defmethod clos:add-direct-method ((specializer (eql <t>)) (method method))
    (incf operation-counter))
  (defmethod clos:remove-direct-method ((specializer (eql <t>)) (method method))
    (incf operation-counter))
  (defmethod clos:specializer-direct-generic-functions ((class (eql <t>)))
    '())
  (defmethod clos:specializer-direct-methods ((class (eql <t>)))
    '())
  (setq operation-counter 0)
  ;; Note that add-direct-method is called once for each specializer of the
  ;; new method; since it has three times the specializer <t>, add-direct-method
  ;; is called three times.
  (fmakunbound 'testgf09)
  (defmethod testgf09 (x y z) (+ x y z))
  (list (null (clos:specializer-direct-generic-functions (find-class 't)))
        (null (clos:specializer-direct-methods (find-class 't)))
        operation-counter))
(t t 3)


;;; Check the direct-subclasses protocol
;;;   add-direct-subclass remove-direct-subclass class-direct-subclasses

;; Check that it's possible to count only instantiated direct subclasses.
;; (Subclasses that have no instances yet can be treated like garbage-collected
;; subclasses and be ignored.)
(progn
  (defclass volatile-class (standard-class)
    ((instantiated :type boolean :initform nil)))
  (defparameter *volatile-class-hack* nil)
  (defmethod clos:add-direct-subclass :around ((superclass volatile-class) (subclass volatile-class))
    (when *volatile-class-hack* (call-next-method)))
  (defmethod clos:remove-direct-subclass :around ((superclass volatile-class) (subclass volatile-class))
    nil)
  (defun note-volatile-class-instantiated (class)
    (unless (slot-value class 'instantiated)
      (setf (slot-value class 'instantiated) t)
      (dolist (superclass (clos:class-direct-superclasses class))
        (when (typep superclass 'volatile-class)
          (unless (member class (clos:class-direct-subclasses superclass))
            (let ((*volatile-class-hack* t))
              (clos:add-direct-subclass superclass class))
            (note-volatile-class-instantiated superclass))))))
  (defmethod allocate-instance :after ((class volatile-class) &rest initargs)
    (note-volatile-class-instantiated class))
  #-CLISP
  (defmethod clos:validate-superclass ((c1 volatile-class) (c2 standard-class))
    t)
  (defclass testclass10 () () (:metaclass volatile-class))
  (defclass testclass10a (testclass10) () (:metaclass volatile-class))
  (defclass testclass10b (testclass10) () (:metaclass volatile-class))
  (defclass testclass10c (testclass10) () (:metaclass volatile-class))
  (defclass testclass10d (testclass10b) () (:metaclass volatile-class))
  (let ((results '()))
    (push (clos:class-direct-subclasses (find-class 'testclass10)) results)
    (push (clos:class-direct-subclasses (find-class 'testclass10a)) results)
    (push (clos:class-direct-subclasses (find-class 'testclass10b)) results)
    (push (clos:class-direct-subclasses (find-class 'testclass10c)) results)
    (push (clos:class-direct-subclasses (find-class 'testclass10d)) results)
    (make-instance 'testclass10d)
    (push (clos:class-direct-subclasses (find-class 'testclass10)) results)
    (push (clos:class-direct-subclasses (find-class 'testclass10a)) results)
    (push (clos:class-direct-subclasses (find-class 'testclass10b)) results)
    (push (clos:class-direct-subclasses (find-class 'testclass10c)) results)
    (push (clos:class-direct-subclasses (find-class 'testclass10d)) results)
    (mapcar #'(lambda (l) (mapcar #'class-name l)) (nreverse results))))
(() () () () ()
 (testclass10b) () (testclass10d) () ())


;;; Check the compute-applicable-methods protocol
;;;   compute-applicable-methods compute-applicable-methods-using-classes

;; Check that it's possible to change the order of applicable methods from
;; most-specific-first to most-specific-last.
(progn
  (defclass msl-generic-function (standard-generic-function)
    ()
    (:metaclass clos:funcallable-standard-class))
  (defun reverse-method-list (methods)
    (let ((result '()))
      (dolist (method methods)
        (if (and (consp result)
                 (equal (method-qualifiers method) (method-qualifiers (caar result))))
          (push method (car result))
          (push (list method) result)))
      (reduce #'append result)))
  (defmethod clos:compute-applicable-methods ((gf msl-generic-function) arguments)
    (reverse-method-list (call-next-method)))
  (defmethod clos:compute-applicable-methods-using-classes ((gf msl-generic-function) classes)
    (reverse-method-list (call-next-method)))
  (defgeneric testgf11 (x) (:generic-function-class msl-generic-function)
    (:method ((x integer)) (cons 'integer (if (next-method-p) (call-next-method))))
    (:method ((x real)) (cons 'real (if (next-method-p) (call-next-method))))
    (:method ((x number)) (cons 'number (if (next-method-p) (call-next-method))))
    (:method :around ((x integer)) (coerce (call-next-method) 'vector)))
  (list (testgf11 5.0) (testgf11 17)))
((number real) #(number real integer))

;; Check that it's possible to filter-out applicable methods.
(progn
  (defclass nonumber-generic-function (standard-generic-function)
    ()
    (:metaclass clos:funcallable-standard-class))
  (defun nonumber-method-list (methods)
    (remove-if #'(lambda (method)
                   (member (find-class 'number) (clos:method-specializers method)))
               methods))
  (defmethod clos:compute-applicable-methods ((gf nonumber-generic-function) arguments)
    (nonumber-method-list (call-next-method)))
  (defmethod clos:compute-applicable-methods-using-classes ((gf nonumber-generic-function) classes)
    (nonumber-method-list (call-next-method)))
  (defgeneric testgf12 (x) (:generic-function-class nonumber-generic-function)
    (:method ((x integer)) (cons 'integer (if (next-method-p) (call-next-method))))
    (:method ((x real)) (cons 'real (if (next-method-p) (call-next-method))))
    (:method ((x number)) (cons 'number (if (next-method-p) (call-next-method))))
    (:method :around ((x integer)) (coerce (call-next-method) 'vector)))
  (list (testgf12 5.0) (testgf12 17)))
((real) #(integer real))


;;; Check the compute-class-precedence-list protocol
;;;   compute-class-precedence-list

;; Check that it's possible to compute the precedence list using a
;; breadth-first search instead of a depth-first search.
(progn
  (defclass bfs-class (standard-class)
    ())
  (defmethod clos:compute-class-precedence-list ((class bfs-class))
    (let ((queue (list class))
          (next-queue '())
          (cpl '()))
      (loop
        (when (null queue)
          (setq queue (reverse next-queue) next-queue '())
          (when (null queue)
            (return)))
        (let ((c (pop queue)))
          (unless (member c cpl)
            (push c cpl)
            (setq next-queue (revappend (clos:class-direct-superclasses c) next-queue)))))
      (nreverse cpl)))
  #-CLISP
  (defmethod clos:validate-superclass ((c1 bfs-class) (c2 standard-class))
    t)
  ;          a
  ;        /   \
  ;      b       d
  ;      |       |
  ;      c       e
  ;        \   /
  ;          f
  (defclass testclass13a () () (:metaclass bfs-class))
  (defclass testclass13b (testclass13a) () (:metaclass bfs-class))
  (defclass testclass13c (testclass13b) () (:metaclass bfs-class))
  (defclass testclass13d (testclass13a) () (:metaclass bfs-class))
  (defclass testclass13e (testclass13d) () (:metaclass bfs-class))
  (defclass testclass13f (testclass13c testclass13e) () (:metaclass bfs-class))
  (mapcar #'class-name (subseq (clos:class-precedence-list (find-class 'testclass13f)) 0 6)))
;; With the default depth-first / topological-sort search algorithm:
;; (testclass13f testclass13c testclass13b testclass13e testclass13d testclass13a)
(testclass13f testclass13c testclass13e testclass13b testclass13d testclass13a)


;;; Check the compute-default-initargs protocol
;;;   compute-default-initargs

;; Check that it's possible to add additional initargs.
(progn
  (defparameter *extra-value* 'extra)
  (defclass custom-default-initargs-class (standard-class)
    ())
  (defmethod clos:compute-default-initargs ((class custom-default-initargs-class))
    (let ((original-default-initargs
            (remove-duplicates
              (reduce #'append
                      (mapcar #'clos:class-direct-default-initargs
                              (clos:class-precedence-list class)))
              :key #'car
              :from-end t)))
      (cons (list ':extra '*extra-value* #'(lambda () *extra-value*))
            (remove ':extra original-default-initargs :key #'car))))
  #-CLISP
  (defmethod clos:validate-superclass ((c1 custom-default-initargs-class) (c2 standard-class))
    t)
  (defclass testclass14 () ((slot :initarg :extra)) (:metaclass custom-default-initargs-class))
  (slot-value (make-instance 'testclass14) 'slot))
EXTRA


;;; Check the compute-discriminating-function protocol
;;;   compute-discriminating-function

;; Check that it's possible to add tracing to a generic function.
(progn
  (defclass traced-generic-function (standard-generic-function)
    ()
    (:metaclass clos:funcallable-standard-class))
  (defvar *last-traced-arguments* nil)
  (defvar *last-traced-values* nil)
  (defmethod clos:compute-discriminating-function ((gf traced-generic-function))
    (let ((orig-df (call-next-method))
          (name (clos:generic-function-name gf)))
      #'(lambda (&rest arguments)
          (declare (compile))
          (format *trace-output* "~%=> ~S arguments: ~:S" name arguments)
          (setq *last-traced-arguments* arguments)
          (let ((values (multiple-value-list (apply orig-df arguments))))
            (format *trace-output* "~%<= ~S values: ~:S" name values)
            (setq *last-traced-values* values)
            (values-list values)))))
  (defgeneric testgf15 (x) (:generic-function-class traced-generic-function)
     (:method ((x number)) (values x (- x) (* x x) (/ x))))
  (testgf15 5)
  (list *last-traced-arguments* *last-traced-values*))
((5) (5 -5 25 1/5))


;;; Check the compute-effective-method protocol
;;;   compute-effective-method

;; Check that it is possible to modify the effective-method in a way that is
;; orthogonal to the method-combination. In particular, check that it's
;; possible to provide 'redo' and 'return' restarts for each method invocation.
(progn
  (defun add-method-restarts (form method)
    (let ((block (gensym))
          (tag (gensym)))
      `(BLOCK ,block
         (TAGBODY
           ,tag
           (RETURN-FROM ,block
             (RESTART-CASE ,form
               (METHOD-REDO ()
                 :REPORT (LAMBDA (STREAM) (FORMAT STREAM "Try calling ~S again." ,method))
                 (GO ,tag))
               (METHOD-RETURN (L)
                 :REPORT (LAMBDA (STREAM) (FORMAT STREAM "Specify return values for ~S call." ,method))
                 :INTERACTIVE (LAMBDA () (SYS::PROMPT-FOR-NEW-VALUE 'VALUES))
                 (RETURN-FROM ,block (VALUES-LIST L)))))))))
  (defun convert-effective-method (efm)
    (if (consp efm)
      (if (eq (car efm) 'CALL-METHOD)
        (let ((method-list (third efm)))
          (if (or (typep (first method-list) 'method) (rest method-list))
            ; Reduce the case of multiple methods to a single one.
            ; Make the call to the next-method explicit.
            (convert-effective-method
              `(CALL-METHOD ,(second efm)
                 ((MAKE-METHOD
                    (CALL-METHOD ,(first method-list) ,(rest method-list))))))
            ; Now the case of at most one method.
            (if (typep (second efm) 'method)
              ; Wrap the method call in a RESTART-CASE.
              (add-method-restarts
                (cons (convert-effective-method (car efm))
                      (convert-effective-method (cdr efm)))
                (second efm))
              ; Normal recursive processing.
              (cons (convert-effective-method (car efm))
                    (convert-effective-method (cdr efm))))))
        (cons (convert-effective-method (car efm))
              (convert-effective-method (cdr efm))))
      efm))
  (defclass debuggable-generic-function (standard-generic-function)
    ()
    (:metaclass clos:funcallable-standard-class))
  (defmethod clos:compute-effective-method ((gf debuggable-generic-function) method-combination methods)
    (convert-effective-method (call-next-method)))
  (defgeneric testgf16 (x) (:generic-function-class debuggable-generic-function))
  (defclass testclass16a () ())
  (defclass testclass16b (testclass16a) ())
  (defclass testclass16c (testclass16a) ())
  (defclass testclass16d (testclass16b testclass16c) ())
  (defmethod testgf16 ((x testclass16a))
    (list 'a
          (not (null (find-restart 'method-redo)))
          (not (null (find-restart 'method-return)))))
  (defmethod testgf16 ((x testclass16b))
    (cons 'b (call-next-method)))
  (defmethod testgf16 ((x testclass16c))
    (cons 'c (call-next-method)))
  (defmethod testgf16 ((x testclass16d))
    (cons 'd (call-next-method)))
  (testgf16 (make-instance 'testclass16d)))
(D B C A T T)


;;; Check the compute-effective-slot-definition protocol
;;;   compute-effective-slot-definition

;; Check that it's possible to generate initargs automatically and have a
;; default initform of 42.
(progn
  (defclass auto-initargs-class (standard-class)
    ())
  (defmethod clos:compute-effective-slot-definition ((class auto-initargs-class) name direct-slot-definitions)
    (let ((eff-slot (call-next-method)))
      ;; NB: The MOP doesn't specify setters for slot-definition objects, but
      ;; most implementations have it. Without these setters, it is not possible
      ;; to make use of compute-effective-slot-definition, since the MOP p. 43
      ;; says "the value returned by the extending method must be the value
      ;; returned by [the predefined] method".
      (unless (clos:slot-definition-initargs eff-slot)
        (setf (clos:slot-definition-initargs eff-slot)
              (list (intern (symbol-name (clos:slot-definition-name eff-slot))
                            (find-package "KEYWORD")))))
      (unless (clos:slot-definition-initfunction eff-slot)
        (setf (clos:slot-definition-initfunction eff-slot) #'(lambda () 42)
              (clos:slot-definition-initform eff-slot) '42))
      eff-slot))
  #-CLISP
  (defmethod clos:validate-superclass ((c1 auto-initargs-class) (c2 standard-class))
    t)
  (defclass testclass17 () ((x) (y)) (:metaclass auto-initargs-class))
  (let ((inst (make-instance 'testclass17 :x 17)))
    (list (slot-value inst 'x) (slot-value inst 'y))))
(17 42)


;;; Check the compute-slots protocol
;;;   compute-slots

;; Check that it's possible to add additional local slots.
(progn
  (defclass testclass18b (testclass18a) ())
  (defmethod clos:compute-slots ((class (eql (find-class 'testclass18b))))
    (append (call-next-method)
            (list (make-instance 'clos:standard-effective-slot-definition
                    :name 'y
                    :allocation :instance))))
  (defclass testclass18a ()
    ((x :allocation :class)))
  (clos:finalize-inheritance (find-class 'testclass18b))
  ;; testclass18b should now have a shared slot, X, and a local slot, Y.
  (append
    (mapcar #'(lambda (slot)
                (list (clos:slot-definition-name slot)
                      (integerp (clos:slot-definition-location slot))))
            (clos:class-slots (find-class 'testclass18b)))
    (let ((inst1 (make-instance 'testclass18b))
          (inst2 (make-instance 'testclass18b)))
      (setf (slot-value inst1 'y) 'abc)
      (setf (slot-value inst2 'y) 'def)
      (list (slot-value inst1 'y) (slot-value inst2 'y)))))
((X NIL) (Y T) ABC DEF)

;; Check that it's possible to add additional shared slots.
(progn
  (defclass testclass19b (testclass19a) ())
  (defmethod clos:compute-slots ((class (eql (find-class 'testclass19b))))
    (append (call-next-method)
            (list (make-instance 'clos:standard-effective-slot-definition
                    :name 'y
                    :allocation :class))))
  (defclass testclass19a ()
    ((x :allocation :class)))
  (clos:finalize-inheritance (find-class 'testclass19b))
  ;; testclass19b should now have two shared slots, X and Y.
  (append
    (mapcar #'(lambda (slot)
                (list (clos:slot-definition-name slot)
                      (integerp (clos:slot-definition-location slot))))
            (clos:class-slots (find-class 'testclass19b)))
    (let ((inst1 (make-instance 'testclass19b))
          (inst2 (make-instance 'testclass19b)))
      (setf (slot-value inst1 'y) 'abc)
      (setf (slot-value inst2 'y) 'def)
      (list (slot-value inst1 'y) (slot-value inst2 'y)))))
((X NIL) (Y NIL) DEF DEF)


;;; Check the direct-slot-definition-class protocol
;;;   direct-slot-definition-class

;; Check that it's possible to generate accessors automatically.
(progn
  (defclass auto-accessors-direct-slot-definition-class (standard-class)
    ((containing-class-name :initarg :containing-class-name)))
  #-CLISP
  (defmethod clos:validate-superclass ((c1 auto-accessors-direct-slot-definition-class) (c2 standard-class))
    t)
  (defclass auto-accessors-class (standard-class)
    ())
  (defmethod clos:direct-slot-definition-class ((class auto-accessors-class) &rest initargs)
    (let ((dsd-class-name (gensym)))
      (clos:ensure-class dsd-class-name
        :metaclass (find-class 'auto-accessors-direct-slot-definition-class)
        :direct-superclasses (list (find-class 'clos:standard-direct-slot-definition))
        :containing-class-name (class-name class))
      (eval `(defmethod initialize-instance :after ((dsd ,dsd-class-name) &rest args)
               (when (and (null (clos:slot-definition-readers dsd))
                          (null (clos:slot-definition-writers dsd)))
                 (let* ((containing-class-name (slot-value (class-of dsd) 'containing-class-name))
                        (accessor-name
                          (intern (concatenate 'string
                                               (symbol-name containing-class-name)
                                               "-"
                                               (symbol-name (clos:slot-definition-name dsd)))
                                  (symbol-package containing-class-name))))
                   (setf (clos:slot-definition-readers dsd) (list accessor-name))
                   (setf (clos:slot-definition-writers dsd) (list (list 'setf accessor-name)))))))
      (find-class dsd-class-name)))
  #-CLISP
  (defmethod clos:validate-superclass ((c1 auto-accessors-class) (c2 standard-class))
    t)
  (defclass testclass20 ()
    ((x :initarg :x) (y))
    (:metaclass auto-accessors-class))
  (let ((inst (make-instance 'testclass20 :x 12)))
    (list (testclass20-x inst) (setf (testclass20-y inst) 13))))
(12 13)


;;; Check the effective-slot-definition-class protocol
;;;   effective-slot-definition-class

;; See below, with the slot-value-using-class protocol.


;;; Check the slot-value-using-class protocol
;;;   slot-value-using-class (setf slot-value-using-class)
;;;   slot-boundp-using-class slot-makunbound-using-class

;; Check that it's possible to store all slot values in property lists.
(progn
  (defparameter *external-slot-values* '())
  (defclass external-slot-definition (clos:standard-effective-slot-definition)
    ())
  (let ((unbound (gensym "UNBOUND")))
    (defmethod clos:slot-value-using-class ((class standard-class) instance (slot external-slot-definition))
      (let ((value (getf (getf *external-slot-values* instance) (clos:slot-definition-name slot) unbound)))
        (if (eq value unbound)
          (slot-unbound class instance (clos:slot-definition-name slot))
          value)))
    (defmethod (setf clos:slot-value-using-class) (new-value (class standard-class) instance (slot external-slot-definition))
      (setf (getf (getf *external-slot-values* instance) (clos:slot-definition-name slot)) new-value))
    (defmethod clos:slot-boundp-using-class ((class standard-class) instance (slot external-slot-definition))
      (let ((value (getf (getf *external-slot-values* instance) (clos:slot-definition-name slot) unbound)))
        (not (eq value unbound))))
    (defmethod clos:slot-makunbound-using-class ((class standard-class) instance (slot external-slot-definition))
      (remf (getf *external-slot-values* instance) (clos:slot-definition-name slot))
      instance))
  (defclass external-slot-definition-class (standard-class)
    ())
  #-CLISP
  (defmethod clos:validate-superclass ((c1 external-slot-definition-class) (c2 standard-class))
    t)
  (defmethod clos:effective-slot-definition-class ((class external-slot-definition-class) &rest args)
    (find-class 'external-slot-definition))
  (defclass testclass22 ()
    ((x :initarg :x) (y :initarg :y))
    (:metaclass external-slot-definition-class))
  (let ((inst1 (make-instance 'testclass22 :x 3 :y 4))
        (inst2 (make-instance 'testclass22 :x 5 :y 12))
        (results '()))
    (push (slot-value inst1 'x) results)
    (push (slot-value inst2 'x) results)
    (push (slot-value inst1 'y) results)
    (push (slot-value inst2 'y) results)
    (push (or (equal *external-slot-values*
                     (list inst2 (list 'x 5 'y 12) inst1 (list 'x 3 'y 4)))
              (equal *external-slot-values*
                     (list inst2 (list 'y 12 'x 5) inst1 (list 'y 4 'x 3))))
          results)
    (setf (slot-value inst2 'x) -5)
    (push (slot-value inst2 'x) results)
    (slot-makunbound inst1 'y)
    (push (list (slot-boundp inst1 'x) (slot-boundp inst1 'y)) results)
    (slot-makunbound inst1 'x)
    (push (or (equal *external-slot-values*
                     (list inst2 (list 'x -5 'y 12) inst1 nil))
              (equal *external-slot-values*
                     (list inst2 (list 'y 12 'x -5) inst1 nil)))
          results)
    (nreverse results)))
(3 5 4 12 T -5 (T NIL) T)


;;; Check the ensure-class-using-class protocol
;;;   ensure-class-using-class

;; Check that it's possible to take the documentation from elsewhere.
(progn
  (defparameter *doc-database*
    '((testclass23 . "This is a dumb class for testing.")
      (testgf24 . "This is a dumb generic function for testing.")))
  (defclass externally-documented-class (standard-class)
    ())
  #-CLISP
  (defmethod clos:validate-superclass ((c1 externally-documented-class) (c2 standard-class))
    t)
  (dolist (given-name (mapcar #'car *doc-database*))
    (defmethod clos:ensure-class-using-class ((class class) (name (eql given-name)) &rest args &key documentation &allow-other-keys)
      (if (and (null documentation)
               (setq documentation (cdr (assoc name *doc-database*))))
        (apply #'call-next-method class name (list* ':documentation documentation args))
        (call-next-method)))
    (defmethod clos:ensure-class-using-class ((class null) (name (eql given-name)) &rest args &key documentation &allow-other-keys)
      (if (and (null documentation)
               (setq documentation (cdr (assoc name *doc-database*))))
        (apply #'call-next-method class name (list* ':documentation documentation args))
        (call-next-method))))
  (defclass testclass23 ()
    ()
    (:metaclass externally-documented-class))
  (documentation 'testclass23 'class))
"This is a dumb class for testing."


;;; Check the ensure-generic-function-using-class protocol
;;;   ensure-generic-function-using-class

;; Check that it's possible to take the documentation from elsewhere.
(progn
  (defparameter *doc-database*
    '((testclass23 . "This is a dumb class for testing.")
      (testgf24 . "This is a dumb generic function for testing.")))
  (defclass externally-documented-generic-function (standard-generic-function)
    ()
    (:metaclass clos:funcallable-standard-class))
  (dolist (given-name (mapcar #'car *doc-database*))
    (defmethod clos:ensure-generic-function-using-class ((gf generic-function) (name (eql given-name)) &rest args &key documentation &allow-other-keys)
      (if (and (null documentation)
               (setq documentation (cdr (assoc name *doc-database* :test #'equal))))
        (apply #'call-next-method gf name (list* ':documentation documentation args))
        (call-next-method)))
    (defmethod clos:ensure-generic-function-using-class ((gf null) (name (eql given-name)) &rest args &key documentation &allow-other-keys)
      (if (and (null documentation)
               (setq documentation (cdr (assoc name *doc-database* :test #'equal))))
        (apply #'call-next-method gf name (list* ':documentation documentation args))
        (call-next-method))))
  (defgeneric testgf24 (x)
    (:generic-function-class externally-documented-generic-function))
  (documentation 'testgf24 'function))
"This is a dumb generic function for testing."


;;; Check the reader-method-class protocol
;;;   reader-method-class

;; Check that it's possible to define reader methods that do typechecking.
(progn
  (defclass typechecking-reader-method (clos:standard-reader-method)
    ())
  (defmethod initialize-instance ((method typechecking-reader-method) &rest initargs
                                  &key slot-definition)
    (let ((name (clos:slot-definition-name slot-definition))
          (type (clos:slot-definition-type slot-definition)))
      (apply #'call-next-method method
             :function #'(lambda (args next-methods)
                           (declare (ignore next-methods))
                           #+CLISP (declare (compile))
                           (apply #'(lambda (instance)
                                      (let ((value (slot-value instance name)))
                                        (unless (typep value type)
                                          (error "Slot ~S of ~S is not of type ~S: ~S"
                                                 name instance type value))
                                        value))
                                  args))
             initargs)))
  (defclass typechecking-reader-class (standard-class)
    ())
  #-CLISP
  (defmethod clos:validate-superclass ((c1 typechecking-reader-class) (c2 standard-class))
    t)
  (defmethod reader-method-class ((class typechecking-reader-class) direct-slot &rest args)
    (find-class 'typechecking-reader-method))
  (defclass testclass25 ()
    ((pair :type (cons symbol (cons symbol null)) :initarg :pair :accessor testclass25-pair))
    (:metaclass typechecking-reader-class))
  (macrolet ((succeeds (form)
               `(not (nth-value 1 (ignore-errors ,form)))))
    (let ((p (list 'abc 'def))
          (x (make-instance 'testclass25)))
      (list (succeeds (make-instance 'testclass25 :pair '(seventeen 17)))
            (succeeds (setf (testclass25-pair x) p))
            (succeeds (setf (second p) 456))
            (succeeds (testclass25-pair x))
            (succeeds (slot-value x 'pair))))))
(t t t nil t)


;;; Check the writer-method-class protocol
;;;   writer-method-class

;; Check that it's possible to define writer methods that do typechecking.
(progn
  (defclass typechecking-writer-method (clos:standard-writer-method)
    ())
  (defmethod initialize-instance ((method typechecking-writer-method) &rest initargs
                                  &key slot-definition)
    (let ((name (clos:slot-definition-name slot-definition))
          (type (clos:slot-definition-type slot-definition)))
      (apply #'call-next-method method
             :function #'(lambda (args next-methods)
                           (declare (ignore next-methods))
                           #+CLISP (declare (compile))
                           (apply #'(lambda (new-value instance)
                                      (unless (typep new-value type)
                                        (error "Slot ~S of ~S: new value is not of type ~S: ~S"
                                               name instance type new-value))
                                      (setf (slot-value instance name) new-value))
                                  args))
             initargs)))
  (defclass typechecking-writer-class (standard-class)
    ())
  #-CLISP
  (defmethod clos:validate-superclass ((c1 typechecking-writer-class) (c2 standard-class))
    t)
  (defmethod writer-method-class ((class typechecking-writer-class) direct-slot &rest args)
    (find-class 'typechecking-writer-method))
  (defclass testclass26 ()
    ((pair :type (cons symbol (cons symbol null)) :initarg :pair :accessor testclass26-pair))
    (:metaclass typechecking-writer-class))
  (macrolet ((succeeds (form)
               `(not (nth-value 1 (ignore-errors ,form)))))
    (let ((p (list 'abc 'def))
          (x (make-instance 'testclass26)))
      (list (succeeds (make-instance 'testclass26 :pair '(seventeen 17)))
            (succeeds (setf (testclass26-pair x) p))
            (succeeds (setf (second p) 456))
            (succeeds (testclass26-pair x))
            (succeeds (setf (testclass26-pair x) p))
            (succeeds (setf (slot-value x 'pair) p))))))
(t t t t nil t)


;;; Check the validate-superclass protocol
;;;   validate-superclass

;; Check that it's possible to create subclasses of generic-function
;; that are not instances of funcallable-standard-class.
#-CLISP
(progn
  (defmethod clos:validate-superclass ((c1 standard-class) (c2 clos:funcallable-standard-class))
    t)
  (defclass uncallable-generic-function (standard-generic-function)
    ()
    (:metaclass standard-class))
  (let ((inst (make-instance 'uncallable-generic-function
                :name 'testgf27
                :lambda-list '(x y)
                :method-class (find-class 'standard-method)
                :method-combination (find-method-combination #'print-object 'standard nil))))
    (list (typep inst 'standard-object)
          (typep inst 'clos:funcallable-standard-object)
          (typep (class-of inst) 'standard-class)
          (typep (class-of inst) 'clos:funcallable-standard-class))))
#-CLISP
(T T T NIL)

;; Check that it's possible to create uncounted subclasses of counted classes.
(progn
  (defparameter *counter27* 0)
  (defclass counted27-class (standard-class)
    ())
  (defmethod make-instance :after ((c counted27-class) &rest args)
    (incf *counter27*))
  #-CLISP
  (defmethod clos:validate-superclass ((c1 counted27-class) (c2 standard-class))
    t)
  (defclass testclass27a () () (:metaclass counted27-class))
  (make-instance 'testclass27a)
  (defmethod clos:validate-superclass ((c1 standard-class) (c2 counted27-class))
    t)
  (defclass testclass27b (testclass27a) () (:metaclass standard-class))
  (make-instance 'testclass27b)
  (make-instance 'testclass27b)
  *counter27*)
1


;;; Check that extending many MOP generic functions is possible, however
;;; overriding methods of these MOP generic functions is forbidden.

;; Check class-default-initargs.
(let ((*sampclass* (defclass sampclass01 () ())))
  (defmethod clos:class-default-initargs ((c (eql *sampclass*)))
    (call-next-method))
  (clos:class-default-initargs *sampclass*)
  t)
T
(let ((*sampclass* (defclass sampclass02 () ())))
  (let ((badmethod
          (defmethod clos:class-default-initargs ((c (eql *sampclass*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:class-default-initargs *sampclass*))
      (remove-method #'clos:class-default-initargs badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check class-direct-default-initargs.
(let ((*sampclass* (defclass sampclass03 () ())))
  (defmethod clos:class-direct-default-initargs ((c (eql *sampclass*)))
    (call-next-method))
  (clos:class-direct-default-initargs *sampclass*)
  t)
T
(let ((*sampclass* (defclass sampclass04 () ())))
  (let ((badmethod
          (defmethod clos:class-direct-default-initargs ((c (eql *sampclass*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:class-direct-default-initargs *sampclass*))
      (remove-method #'clos:class-direct-default-initargs badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check class-direct-slots.
(let ((*sampclass* (defclass sampclass05 () ())))
  (defmethod clos:class-direct-slots ((c (eql *sampclass*)))
    (call-next-method))
  (clos:class-direct-slots *sampclass*)
  t)
T
(let ((*sampclass* (defclass sampclass06 () ())))
  (let ((badmethod
          (defmethod clos:class-direct-slots ((c (eql *sampclass*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:class-direct-slots *sampclass*))
      (remove-method #'clos:class-direct-slots badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check class-direct-superclasses.
(let ((*sampclass* (defclass sampclass07 () ())))
  (defmethod clos:class-direct-superclasses ((c (eql *sampclass*)))
    (call-next-method))
  (clos:class-direct-superclasses *sampclass*)
  t)
T
(let ((*sampclass* (defclass sampclass08 () ())))
  (let ((badmethod
          (defmethod clos:class-direct-superclasses ((c (eql *sampclass*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:class-direct-superclasses *sampclass*))
      (remove-method #'clos:class-direct-superclasses badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check class-finalized-p.
(let ((*sampclass* (defclass sampclass09 () ())))
  (defmethod clos:class-finalized-p ((c (eql *sampclass*)))
    (call-next-method))
  (clos:class-finalized-p *sampclass*)
  t)
T
(let ((*sampclass* (defclass sampclass10 () ())))
  (let ((badmethod
          (defmethod clos:class-finalized-p ((c (eql *sampclass*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:class-finalized-p *sampclass*))
      (remove-method #'clos:class-finalized-p badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check class-precedence-list.
(let ((*sampclass* (defclass sampclass11 () ())))
  (defmethod clos:class-precedence-list ((c (eql *sampclass*)))
    (call-next-method))
  (clos:class-precedence-list *sampclass*)
  t)
T
(let ((*sampclass* (defclass sampclass12 () ())))
  (let ((badmethod
          (defmethod clos:class-precedence-list ((c (eql *sampclass*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:class-precedence-list *sampclass*))
      (remove-method #'clos:class-precedence-list badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check class-prototype.
(let ((*sampclass* (defclass sampclass13 () ())))
  (defmethod clos:class-prototype ((c (eql *sampclass*)))
    (call-next-method))
  (clos:class-prototype *sampclass*)
  t)
T
(let ((*sampclass* (defclass sampclass14 () ())))
  (let ((badmethod
          (defmethod clos:class-prototype ((c (eql *sampclass*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:class-prototype *sampclass*))
      (remove-method #'clos:class-prototype badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check class-slots.
(let ((*sampclass* (defclass sampclass15 () ())))
  (defmethod clos:class-slots ((c (eql *sampclass*)))
    (call-next-method))
  (clos:class-slots *sampclass*)
  t)
T
(let ((*sampclass* (defclass sampclass16 () ())))
  (let ((badmethod
          (defmethod clos:class-slots ((c (eql *sampclass*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:class-slots *sampclass*))
      (remove-method #'clos:class-slots badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check (setf class-name).
(let ((*sampclass* (defclass sampclass17 () ())))
  (defmethod (setf class-name) (new-value (c (eql *sampclass*)))
    (call-next-method))
  (setf (class-name *sampclass*) 'sampclass17renamed)
  t)
T
(let ((*sampclass* (defclass sampclass18 () ())))
  (let ((badmethod
          (defmethod (setf class-name) (new-value (c (eql *sampclass*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (setf (class-name *sampclass*) 'sampclass18renamed))
      (remove-method #'(setf class-name) badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check finalize-inheritance.
(let ((*sampclass* (defclass sampclass19 () ())))
  (defmethod clos:finalize-inheritance ((c (eql *sampclass*)))
    (call-next-method))
  (clos:finalize-inheritance *sampclass*)
  t)
T
(let ((*sampclass* (defclass sampclass20 () ())))
  (let ((badmethod
          (defmethod clos:finalize-inheritance ((c (eql *sampclass*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:finalize-inheritance *sampclass*))
      (remove-method #'clos:finalize-inheritance badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check find-method-combination.
(let ((*sampgf* (defgeneric sampgf01 (x y))))
  (defmethod clos:find-method-combination ((gf (eql *sampgf*)) name options)
    (call-next-method))
  (clos:find-method-combination *sampgf* 'standard nil)
  t)
T
(let ((*sampgf* (defgeneric sampgf02 (x y))))
  (let ((badmethod
          (defmethod clos:find-method-combination ((gf (eql *sampgf*)) name options)
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:find-method-combination *sampgf* 'standard nil))
      (remove-method #'clos:find-method-combination badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check generic-function-argument-precedence-order.
(let ((*sampgf* (defgeneric sampgf03 (x y))))
  (defmethod clos:generic-function-argument-precedence-order ((gf (eql *sampgf*)))
    (call-next-method))
  (clos:generic-function-argument-precedence-order *sampgf*)
  t)
T
(let ((*sampgf* (defgeneric sampgf04 (x y))))
  (let ((badmethod
          (defmethod clos:generic-function-argument-precedence-order ((gf (eql *sampgf*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:generic-function-argument-precedence-order *sampgf*))
      (remove-method #'clos:generic-function-argument-precedence-order badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check generic-function-declarations.
(let ((*sampgf* (defgeneric sampgf05 (x y))))
  (defmethod clos:generic-function-declarations ((gf (eql *sampgf*)))
    (call-next-method))
  (clos:generic-function-declarations *sampgf*)
  t)
T
(let ((*sampgf* (defgeneric sampgf06 (x y))))
  (let ((badmethod
          (defmethod clos:generic-function-declarations ((gf (eql *sampgf*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:generic-function-declarations *sampgf*))
      (remove-method #'clos:generic-function-declarations badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check generic-function-lambda-list.
(let ((*sampgf* (defgeneric sampgf07 (x y))))
  (defmethod clos:generic-function-lambda-list ((gf (eql *sampgf*)))
    (call-next-method))
  (clos:generic-function-lambda-list *sampgf*)
  t)
T
(let ((*sampgf* (defgeneric sampgf08 (x y))))
  (let ((badmethod
          (defmethod clos:generic-function-lambda-list ((gf (eql *sampgf*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:generic-function-lambda-list *sampgf*))
      (remove-method #'clos:generic-function-lambda-list badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check generic-function-method-class.
(let ((*sampgf* (defgeneric sampgf09 (x y))))
  (defmethod clos:generic-function-method-class ((gf (eql *sampgf*)))
    (call-next-method))
  (clos:generic-function-method-class *sampgf*)
  t)
T
(let ((*sampgf* (defgeneric sampgf10 (x y))))
  (let ((badmethod
          (defmethod clos:generic-function-method-class ((gf (eql *sampgf*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:generic-function-method-class *sampgf*))
      (remove-method #'clos:generic-function-method-class badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check generic-function-method-combination.
(let ((*sampgf* (defgeneric sampgf11 (x y))))
  (defmethod clos:generic-function-method-combination ((gf (eql *sampgf*)))
    (call-next-method))
  (clos:generic-function-method-combination *sampgf*)
  t)
T
(let ((*sampgf* (defgeneric sampgf12 (x y))))
  (let ((badmethod
          (defmethod clos:generic-function-method-combination ((gf (eql *sampgf*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:generic-function-method-combination *sampgf*))
      (remove-method #'clos:generic-function-method-combination badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check generic-function-methods.
(let ((*sampgf* (defgeneric sampgf13 (x y))))
  (defmethod clos:generic-function-methods ((gf (eql *sampgf*)))
    (call-next-method))
  (clos:generic-function-methods *sampgf*)
  t)
T
(let ((*sampgf* (defgeneric sampgf14 (x y))))
  (let ((badmethod
          (defmethod clos:generic-function-methods ((gf (eql *sampgf*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:generic-function-methods *sampgf*))
      (remove-method #'clos:generic-function-methods badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check generic-function-name.
(let ((*sampgf* (defgeneric sampgf15 (x y))))
  (defmethod clos:generic-function-name ((gf (eql *sampgf*)))
    (call-next-method))
  (clos:generic-function-name *sampgf*)
  t)
T
(let ((*sampgf* (defgeneric sampgf16 (x y))))
  (let ((badmethod
          (defmethod clos:generic-function-name ((gf (eql *sampgf*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:generic-function-name *sampgf*))
      (remove-method #'clos:generic-function-name badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check (setf generic-function-name).
(let ((*sampgf* (defgeneric sampgf17 (x y))))
  (defmethod (setf clos:generic-function-name) (new-value (gf (eql *sampgf*)))
    (call-next-method))
  (setf (clos:generic-function-name *sampgf*) 'sampgf17renamed)
  t)
T
(let ((*sampgf* (defgeneric sampgf18 (x y))))
  (let ((badmethod
          (defmethod (setf clos:generic-function-name) (new-value (gf (eql *sampgf*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (setf (clos:generic-function-name *sampgf*) 'sampgf18renamed))
      (remove-method #'(setf clos:generic-function-name) badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check method-function.
(let ((*sampmethod* (defmethod sampgf19 () 'bar)))
  (defmethod clos:method-function ((method (eql *sampmethod*)))
    (call-next-method))
  (clos:method-function *sampmethod*)
  t)
T
(let ((*sampmethod* (defmethod sampgf20 () 'bar)))
  (let ((badmethod
          (defmethod clos:method-function ((method (eql *sampmethod*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:method-function *sampmethod*))
      (remove-method #'clos:method-function badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check method-generic-function.
(let ((*sampmethod* (defmethod sampgf21 () 'bar)))
  (defmethod clos:method-generic-function ((method (eql *sampmethod*)))
    (call-next-method))
  (clos:method-generic-function *sampmethod*)
  t)
T
(let ((*sampmethod* (defmethod sampgf22 () 'bar)))
  (let ((badmethod
          (defmethod clos:method-generic-function ((method (eql *sampmethod*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:method-generic-function *sampmethod*))
      (remove-method #'clos:method-generic-function badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check method-lambda-list.
(let ((*sampmethod* (defmethod sampgf23 () 'bar)))
  (defmethod clos:method-lambda-list ((method (eql *sampmethod*)))
    (call-next-method))
  (clos:method-lambda-list *sampmethod*)
  t)
T
(let ((*sampmethod* (defmethod sampgf24 () 'bar)))
  (let ((badmethod
          (defmethod clos:method-lambda-list ((method (eql *sampmethod*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:method-lambda-list *sampmethod*))
      (remove-method #'clos:method-lambda-list badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check method-specializers.
(let ((*sampmethod* (defmethod sampgf25 () 'bar)))
  (defmethod clos:method-specializers ((method (eql *sampmethod*)))
    (call-next-method))
  (clos:method-specializers *sampmethod*)
  t)
T
(let ((*sampmethod* (defmethod sampgf26 () 'bar)))
  (let ((badmethod
          (defmethod clos:method-specializers ((method (eql *sampmethod*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:method-specializers *sampmethod*))
      (remove-method #'clos:method-specializers badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check accessor-method-slot-definition.
(let ((*sampmethod*
        (progn (defclass sampclass21 () ((x :reader sampclass21x)))
               (first (clos:generic-function-methods #'sampclass21x)))))
  (defmethod clos:accessor-method-slot-definition ((method (eql *sampmethod*)))
    (call-next-method))
  (clos:accessor-method-slot-definition *sampmethod*)
  t)
T
(let ((*sampmethod*
        (progn (defclass sampclass22 () ((x :reader sampclass22x)))
               (first (clos:generic-function-methods #'sampclass22x)))))
  (let ((badmethod
          (defmethod clos:accessor-method-slot-definition ((slotdef (eql *sampmethod*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:accessor-method-slot-definition *sampmethod*))
      (remove-method #'clos:accessor-method-slot-definition badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check slot-definition-allocation.
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass23 () ((x)))))))
  (defmethod clos:slot-definition-allocation ((slotdef (eql *sampslot*)))
    (call-next-method))
  (clos:slot-definition-allocation *sampslot*)
  t)
T
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass24 () ((x)))))))
  (let ((badmethod
          (defmethod clos:slot-definition-allocation ((slotdef (eql *sampslot*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:slot-definition-allocation *sampslot*))
      (remove-method #'clos:slot-definition-allocation badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check slot-definition-initargs.
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass25 () ((x)))))))
  (defmethod clos:slot-definition-initargs ((slotdef (eql *sampslot*)))
    (call-next-method))
  (clos:slot-definition-initargs *sampslot*)
  t)
T
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass26 () ((x)))))))
  (let ((badmethod
          (defmethod clos:slot-definition-initargs ((slotdef (eql *sampslot*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:slot-definition-initargs *sampslot*))
      (remove-method #'clos:slot-definition-initargs badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check slot-definition-initform.
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass27 () ((x)))))))
  (defmethod clos:slot-definition-initform ((slotdef (eql *sampslot*)))
    (call-next-method))
  (clos:slot-definition-initform *sampslot*)
  t)
T
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass28 () ((x)))))))
  (let ((badmethod
          (defmethod clos:slot-definition-initform ((slotdef (eql *sampslot*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:slot-definition-initform *sampslot*))
      (remove-method #'clos:slot-definition-initform badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check slot-definition-initfunction.
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass29 () ((x)))))))
  (defmethod clos:slot-definition-initfunction ((slotdef (eql *sampslot*)))
    (call-next-method))
  (clos:slot-definition-initfunction *sampslot*)
  t)
T
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass30 () ((x)))))))
  (let ((badmethod
          (defmethod clos:slot-definition-initfunction ((slotdef (eql *sampslot*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:slot-definition-initfunction *sampslot*))
      (remove-method #'clos:slot-definition-initfunction badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check slot-definition-name.
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass31 () ((x)))))))
  (defmethod clos:slot-definition-name ((slotdef (eql *sampslot*)))
    (call-next-method))
  (clos:slot-definition-name *sampslot*)
  t)
T
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass32 () ((x)))))))
  (let ((badmethod
          (defmethod clos:slot-definition-name ((slotdef (eql *sampslot*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:slot-definition-name *sampslot*))
      (remove-method #'clos:slot-definition-name badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check slot-definition-type.
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass33 () ((x)))))))
  (defmethod clos:slot-definition-type ((slotdef (eql *sampslot*)))
    (call-next-method))
  (clos:slot-definition-type *sampslot*)
  t)
T
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass34 () ((x)))))))
  (let ((badmethod
          (defmethod clos:slot-definition-type ((slotdef (eql *sampslot*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:slot-definition-type *sampslot*))
      (remove-method #'clos:slot-definition-type badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check slot-definition-readers.
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass35 () ((x)))))))
  (defmethod clos:slot-definition-readers ((slotdef (eql *sampslot*)))
    (call-next-method))
  (clos:slot-definition-readers *sampslot*)
  t)
T
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass36 () ((x)))))))
  (let ((badmethod
          (defmethod clos:slot-definition-readers ((slotdef (eql *sampslot*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:slot-definition-readers *sampslot*))
      (remove-method #'clos:slot-definition-readers badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check slot-definition-writers.
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass37 () ((x)))))))
  (defmethod clos:slot-definition-writers ((slotdef (eql *sampslot*)))
    (call-next-method))
  (clos:slot-definition-writers *sampslot*)
  t)
T
(let ((*sampslot*
        (first (clos:class-direct-slots (defclass sampclass38 () ((x)))))))
  (let ((badmethod
          (defmethod clos:slot-definition-writers ((slotdef (eql *sampslot*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:slot-definition-writers *sampslot*))
      (remove-method #'clos:slot-definition-writers badmethod))))
#+CLISP ERROR
#-CLISP T

;; Check slot-definition-location.
(let ((*sampslot*
        (first (clos:class-slots (defclass sampclass39 () ((x)))))))
  (defmethod clos:slot-definition-location ((slotdef (eql *sampslot*)))
    (call-next-method))
  (clos:slot-definition-location *sampslot*)
  t)
T
(let ((*sampslot*
        (first (clos:class-slots (defclass sampclass40 () ((x)))))))
  (let ((badmethod
          (defmethod clos:slot-definition-location ((slotdef (eql *sampslot*)))
            (values (call-next-method) t))))
    (unwind-protect
      (nth-value 1 (clos:slot-definition-location *sampslot*))
      (remove-method #'clos:slot-definition-location badmethod))))
#+CLISP ERROR
#-CLISP T


;; Check that it's possible to create custom method classes.
(progn
  (defclass custom-method (method)
    ((qualifiers       :reader method-qualifiers
                       :writer (setf custom-method-qualifiers))
     (lambda-list      :reader method-lambda-list
                       :writer (setf custom-method-lambda-list))
     (specializers     :reader method-specializers
                       :writer (setf custom-method-specializers))
     (function         :reader method-function
                       :writer (setf custom-method-function))
     (documentation    :accessor custom-method-documentation)
     (generic-function :reader method-generic-function
                       :writer (setf custom-method-generic-function))))
  (defmethod initialize-instance ((method custom-method) &rest args
                                  &key qualifiers lambda-list specializers
                                       function documentation
                                  &allow-other-keys)
    (call-next-method)
    (setf (custom-method-qualifiers method) qualifiers)
    (setf (custom-method-lambda-list method) lambda-list)
    (setf (custom-method-specializers method) specializers)
    (setf (custom-method-function method) function)
    (setf (custom-method-documentation method) documentation)
    (setf (custom-method-generic-function method) nil)
    method)
  (defmethod documentation ((x custom-method) (doc-type (eql 't)))
    (declare (ignore doc-type))
    (custom-method-documentation x))
  (defmethod (setf documentation) (new-value (x custom-method) (doc-type (eql 't)))
    (declare (ignore doc-type))
    (setf (custom-method-documentation x) new-value))
  ;; (setf method-generic-function) is a CLISP extension.
  (defmethod (setf method-generic-function) (new-gf (method custom-method))
    (setf (custom-method-generic-function method) new-gf))
  #| ; Instead of overriding add-method and remove-method:
  (defmethod add-method ((gf standard-generic-function) (m custom-method))
    (setf (custom-method-generic-function m) gf)
    (call-next-method))
  (defmethod remove-method ((gf standard-generic-function) (m custom-method))
    (setf (custom-method-generic-function m) nil)
    (call-next-method))
  |#
  (let ((result '()))
    (defgeneric testgf30 (a b)
      (:method ((a integer) (b integer)) (- (call-next-method) (floor a b)))
      (:method ((a real) (b real)) (/ (float a) (float b)))
      (:method-class custom-method))
    (push (not (find-method #'testgf30 nil (list (find-class 'integer) (find-class 'integer)) nil))
          result)
    (push (testgf30 17 2) result)
    (defgeneric testgf30 (a b)
      (:method ((a real) (b real)) (/ (float a) (float b)))
      (:method-class custom-method))
    (push (not (find-method #'testgf30 nil (list (find-class 'integer) (find-class 'integer)) nil))
          result)
    (push (testgf30 17 2) result)
    (nreverse result)))
(NIL 0.5 T 8.5)


;;; Application example: Typechecked slots

(progn
  (defclass typechecked-slot-definition (clos:standard-effective-slot-definition)
    ())
  (defmethod clos:slot-value-using-class ((class standard-class) instance (slot typechecked-slot-definition))
    (let ((value (call-next-method)))
      (unless (typep value (clos:slot-definition-type slot))
        (error "Slot ~S of ~S has changed, no longer of type ~S"
               (clos:slot-definition-name slot) instance (clos:slot-definition-type slot)))
      value))
  (defmethod (setf clos:slot-value-using-class) (new-value (class standard-class) instance (slot typechecked-slot-definition))
    (unless (typep new-value (clos:slot-definition-type slot))
      (error "Slot ~S of ~S: new value is not of type ~S: ~S"
             (clos:slot-definition-name slot) instance (clos:slot-definition-type slot) new-value))
    (call-next-method))
  (defclass typechecked-slot-definition-class (standard-class)
    ())
  #-CLISP
  (defmethod clos:validate-superclass ((c1 typechecked-slot-definition-class) (c2 standard-class))
    t)
  (defmethod clos:effective-slot-definition-class ((class typechecked-slot-definition-class) &rest args)
    (find-class 'typechecked-slot-definition))
  (defclass testclass28 ()
    ((pair :type (cons symbol (cons symbol null)) :initarg :pair :accessor testclass28-pair))
    (:metaclass typechecked-slot-definition-class))
  (macrolet ((succeeds (form)
               `(not (nth-value 1 (ignore-errors ,form)))))
    (let ((p (list 'abc 'def))
          (x (make-instance 'testclass28)))
      (list (succeeds (make-instance 'testclass28 :pair '(seventeen 17)))
            (succeeds (setf (testclass28-pair x) p))
            (succeeds (setf (second p) 456))
            (succeeds (testclass28-pair x))
            (succeeds (slot-value x 'pair))))))
(nil t t nil nil)
