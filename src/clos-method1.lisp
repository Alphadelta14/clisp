;;;; Common Lisp Object System for CLISP: Methods
;;;; Bruno Haible 21.8.1993 - 2004
;;;; Sam Steingold 1998 - 2004
;;;; German comments translated into English: Stefan Kain 2002-04-08

(in-package "CLOS")


;;; ---------------------------------------------------------------------------

(defparameter <method>
  (defclass method (metaobject)
    ()))

;;; ---------------------------------------------------------------------------

(defparameter <standard-method>
  (defclass standard-method (method)
    ((function             ; the function
       :type (or null function)
       :accessor std-method-function)
     (wants-next-method-p  ; flag, if the NEXT-METHOD (as function with all
                           ; arguments) resp. NIL is to be passed as first
                           ; argument (= NIL for :BEFORE- and :AFTER-methods)
       :type boolean
       :accessor std-method-wants-next-method-p)
     (parameter-specializers ; list ({class | (EQL object)}*)
       :type list
       :accessor std-method-parameter-specializers)
     (qualifiers           ; list of symbols, e.g. (:before)
       :type list
       :accessor std-method-qualifiers)
     (signature            ; signature struct (see functions.lisp)
       :type (simple-vector 6)
       :accessor std-method-signature)
     (gf                   ; the generic function, which this method belongs to
                           ; (only for the purpose of CALL-NEXT-METHOD and
                           ; NO-NEXT-METHOD)
       :type (or null generic-function)
       :accessor std-method-gf)
     (initfunction         ; returns - if called - the function
                           ; (only for the purpose of ADD-METHOD)
       :type function
       :accessor std-method-initfunction)
     (origin               ; flag, if this method comes from a DEFGENERIC
       :type boolean
       :accessor std-method-origin))
    (:fixed-slot-locations)
    (:generic-accessors nil)))

;; Note about the argument passing convention for methods:
;; 1) The MOP description of COMPUTE-EFFECTIVE-METHOD and MAKE-METHOD-LAMBDA
;;    says that a method function takes 2 arguments: the list of arguments (!)
;;    and the list of next methods. This is awfully inefficient, and useless
;;    (since MAKE-METHOD-LAMBDA is ill-designed anyway). Therefore here we
;;    pass to the function the arguments as-is, and the next methods as
;;    inserted first argument, if needed.
;; 2) Instead of the list of next methods, we pass an effective method that
;;    consists of these next methods. This is more efficient (saves a FUNCALL)
;;    for the simple case of a single applicable method, but is less
;;    efficient (a FUNCALL instead of just a CAR) for longer lists of methods.
;; 3) We don't explicitly pass the generic function to the method during the
;;    invocation. However, for CALL-NEXT-METHOD, NO-NEXT-METHOD and
;;    METHOD-GENERIC-FUNCTION the generic function must be known. So we have
;;    to store a generic function backpointer in the method.
;;    Now, in ANSI CL, methods do not belong to specific generic functions in
;;    principle (because of ADD-METHOD); therefore we must copy the method
;;    during ADD-METHOD. And during REMOVE-METHOD, we determine the identity
;;    of two copies of the same method by looking at std-method-initfunction.

(defun initialize-instance-<standard-method> (method &rest args
                                              &key (qualifiers '())
                                                   ;(lambda-list nil lambda-list-p)
                                                   ;(specializers nil specializers-p)
                                                   (function nil function-p)
                                                   ;(documentation nil)
                                                   initfunction
                                                   wants-next-method-p
                                                   parameter-specializers
                                                   signature
                                                   gf
                                                   origin
                                              &allow-other-keys)
  (when *classes-finished*
    (apply #'%initialize-instance method args)) ; == (call-next-method)
  (setf (std-method-function method) function)
  (setf (std-method-wants-next-method-p method) wants-next-method-p)
  (setf (std-method-parameter-specializers method) parameter-specializers)
  (setf (std-method-qualifiers method) qualifiers)
  (setf (std-method-signature method) signature)
  (setf (std-method-gf method) gf)
  (setf (std-method-initfunction method) initfunction)
  (setf (std-method-origin method) origin)
  method)

(defun make-instance-<standard-method> (class &rest args
                                        &key &allow-other-keys)
  ;; class = <standard-method>
  ;; Don't add functionality here! This is a preliminary definition that is
  ;; replaced with #'make-instance later.
  (declare (ignore class))
  (let ((method (%allocate-instance <standard-method>)))
    (apply #'initialize-instance-<standard-method> method args)))

(defun print-object-<standard-method> (method stream)
  (print-unreadable-object (method stream :type t)
    (dolist (q (std-method-qualifiers method))
      (write q :stream stream)
      (write-char #\Space stream))
    (write (std-method-parameter-specializers method) :stream stream)))

;;; ---------------------------------------------------------------------------

(defparameter <standard-accessor-method>
  (defclass standard-accessor-method (standard-method)
    ((slot-definition      ; direct slot definition responsible for this method
       :type direct-slot-definition
       :accessor %accessor-method-slot-definition))
    (:fixed-slot-locations)
    (:generic-accessors nil)))

(defun initialize-instance-<standard-accessor-method> (method &rest args
                                                       &key slot-definition
                                                       &allow-other-keys)
  (apply #'initialize-instance-<standard-method> method args) ; == (call-next-method)
  (setf (%accessor-method-slot-definition method) slot-definition)
  method)

;;; ---------------------------------------------------------------------------

(defparameter <standard-reader-method>
  (defclass standard-reader-method (standard-accessor-method)
    ()
    (:fixed-slot-locations)))

(defun make-instance-<standard-reader-method> (class &rest args
                                               &key &allow-other-keys)
  ;; class = <standard-reader-method>
  ;; Don't add functionality here! This is a preliminary definition that is
  ;; replaced with #'make-instance later.
  (declare (ignore class))
  (let ((method (%allocate-instance <standard-reader-method>)))
    (apply #'initialize-instance-<standard-accessor-method> method args)))

;;; ---------------------------------------------------------------------------

(defparameter <standard-writer-method>
  (defclass standard-writer-method (standard-accessor-method)
    ()
    (:fixed-slot-locations)))

(defun make-instance-<standard-writer-method> (class &rest args
                                               &key &allow-other-keys)
  ;; class = <standard-writer-method>
  ;; Don't add functionality here! This is a preliminary definition that is
  ;; replaced with #'make-instance later.
  (declare (ignore class))
  (let ((method (%allocate-instance <standard-writer-method>)))
    (apply #'initialize-instance-<standard-accessor-method> method args)))

;;; ---------------------------------------------------------------------------
