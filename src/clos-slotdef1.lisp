;;;; Common Lisp Object System for CLISP
;;;; Slot Definition metaobjects
;;;; Part 1: Class definitions, preliminary accessors, utility functions.
;;;; Bruno Haible 2004-04-18

(in-package "CLOS")

;;; ===========================================================================

;;; The parts of a slot-definition that can be inherited to subclasses, in
;;; such a way that a modification of these values in a superclass can be
;;; adopted by the subclasses without any notification.
;;; We are allowed to do this trick because the functions
;;;   (setf slot-definition-initform)
;;;   (setf slot-definition-initfunction)
;;;   (setf slot-definition-documentation)
;;; are not part of the MOP, i.e. the user is not allowed to modify a
;;; slot-definition after it has been created and initialized.
(defvar *<inheritable-slot-definition-initer>-defclass*
  '(defclass inheritable-slot-definition-initer ()
     ((initform      :type t                  :initarg :initform)
      (initfunction  :type (or null function) :initarg :initfunction))
     (:metaclass structure-class)
     ; (:type cons)
   )
)
(defvar *<inheritable-slot-definition-doc>-defclass*
  '(defclass inheritable-slot-definition-doc ()
     ((documentation :type (or null string)   :initarg :documentation))
     (:metaclass structure-class)
     ; (:type cons)
   )
)

(defmacro inheritable-slot-definition-initform (inheritable)
  `(car ,inheritable))
(defmacro inheritable-slot-definition-initfunction (inheritable)
  `(cdr ,inheritable))
(defun make-inheritable-slot-definition-initer (initform initfunction)
  (cons initform initfunction))

(defmacro inheritable-slot-definition-documentation (inheritable)
  `(car ,inheritable))
(defun make-inheritable-slot-definition-doc (documentation)
  (list documentation))


;;; ===========================================================================

;;; The slot-definition abstract class.

;; Note that the C code can use constant offsets to access the components
;; of <slot-definition> and its subclasses, because
;;   1) The user is not allowed to override methods of the slot-definition-xxx
;;      accessors. (MOP p. 10, 85-86)
;;   2) The user is not allowed to use multiple inheritance between different
;;      categories of metaobjects (MOP p. 3) This allows us to use the
;;      :fixed-slot-locations class option.
;; If this were not possible, we would have to wrap every
;; effective-slot-definition instance in a simple-vector that caches its
;; components. (This is possible because the (setf slot-definition-xxx)
;; functions are not part of the MOP.)

;; Information about a slot, as specified in a DEFCLASS form and kept
;; at runtime.
(defvar *<slot-definition>-defclass*
  '(defclass slot-definition ()
     ((name          :type symbol             :initarg :name)
      (initargs      :type list               :initarg :initargs)
      (type          :type t                  :initarg :type)
      (allocation    :type (or symbol class)  :initarg :allocation)
      (inheritable-initer :type #| inheritable-slot-definition-initer |# cons
                                              :initarg inheritable-initer)
      (inheritable-doc :type #| inheritable-slot-definition-doc |# cons
                                              :initarg inheritable-doc))
     (:fixed-slot-locations)))

;; Information about a slot, as specified in a DEFCLASS form.
(defvar *<direct-slot-definition>-defclass*
  '(defclass direct-slot-definition (slot-definition)
     ((readers       :type list               :initarg :readers)
      (writers       :type list               :initarg :writers))
     (:fixed-slot-locations)))

;; Information about a slot that is still significant at runtime.
(defvar *<effective-slot-definition>-defclass*
  '(defclass effective-slot-definition (slot-definition)
     ((location      :type (or null integer cons)
                                              :initarg location))
     (:fixed-slot-locations)))

;; Fixed slot locations.
(defconstant *<slot-definition>-name-location* 1)
(defconstant *<slot-definition>-initargs-location* 2)
(defconstant *<slot-definition>-type-location* 3)
(defconstant *<slot-definition>-allocation-location* 4)
(defconstant *<slot-definition>-inheritable-initer-location* 5)
(defconstant *<slot-definition>-inheritable-doc-location* 6)
(defconstant *<direct-slot-definition>-readers-location* 7)
(defconstant *<direct-slot-definition>-writers-location* 8)
(defconstant *<effective-slot-definition>-location-location* 7)

;; Preliminary accessors.
(defun slot-definition-name (object)
  (sys::%record-ref object *<slot-definition>-name-location*))
(defun (setf slot-definition-name) (new-value object)
  (setf (sys::%record-ref object *<slot-definition>-name-location*) new-value))
(defun slot-definition-inheritable-initer (object)
  (sys::%record-ref object *<slot-definition>-inheritable-initer-location*))
(defun (setf slot-definition-inheritable-initer) (new-value object)
  (setf (sys::%record-ref object *<slot-definition>-inheritable-initer-location*) new-value))
(defun slot-definition-initform (object)
  (inheritable-slot-definition-initform (sys::%record-ref object *<slot-definition>-inheritable-initer-location*)))
(defun (setf slot-definition-initform) (new-value object)
  (setf (inheritable-slot-definition-initform (sys::%record-ref object *<slot-definition>-inheritable-initer-location*)) new-value))
(defun slot-definition-initfunction (object)
  (inheritable-slot-definition-initfunction (sys::%record-ref object *<slot-definition>-inheritable-initer-location*)))
(defun (setf slot-definition-initfunction) (new-value object)
  (setf (inheritable-slot-definition-initfunction (sys::%record-ref object *<slot-definition>-inheritable-initer-location*)) new-value))
(defun slot-definition-initargs (object)
  (sys::%record-ref object *<slot-definition>-initargs-location*))
(defun (setf slot-definition-initargs) (new-value object)
  (setf (sys::%record-ref object *<slot-definition>-initargs-location*) new-value))
(defun slot-definition-type (object)
  (sys::%record-ref object *<slot-definition>-type-location*))
(defun (setf slot-definition-type) (new-value object)
  (setf (sys::%record-ref object *<slot-definition>-type-location*) new-value))
(defun slot-definition-allocation (object)
  (sys::%record-ref object *<slot-definition>-allocation-location*))
(defun (setf slot-definition-allocation) (new-value object)
  (setf (sys::%record-ref object *<slot-definition>-allocation-location*) new-value))
(defun slot-definition-inheritable-doc (object)
  (sys::%record-ref object *<slot-definition>-inheritable-doc-location*))
(defun (setf slot-definition-inheritable-doc) (new-value object)
  (setf (sys::%record-ref object *<slot-definition>-inheritable-doc-location*) new-value))
(defun slot-definition-documentation (object)
  (inheritable-slot-definition-documentation (sys::%record-ref object *<slot-definition>-inheritable-doc-location*)))
(defun (setf slot-definition-documentation) (new-value object)
  (setf (inheritable-slot-definition-documentation (sys::%record-ref object *<slot-definition>-inheritable-doc-location*)) new-value))
(defun slot-definition-readers (object)
  (sys::%record-ref object *<direct-slot-definition>-readers-location*))
(defun (setf slot-definition-readers) (new-value object)
  (setf (sys::%record-ref object *<direct-slot-definition>-readers-location*) new-value))
(defun slot-definition-writers (object)
  (sys::%record-ref object *<direct-slot-definition>-writers-location*))
(defun (setf slot-definition-writers) (new-value object)
  (setf (sys::%record-ref object *<direct-slot-definition>-writers-location*) new-value))
(defun slot-definition-location (object)
  (sys::%record-ref object *<effective-slot-definition>-location-location*))
(defun (setf slot-definition-location) (new-value object)
  (setf (sys::%record-ref object *<effective-slot-definition>-location-location*) new-value))

;; Initialization of a <slot-definition> instance.
(defun initialize-instance-<slot-definition> (slotdef
                                              &key (name nil name-p)
                                                   (initform nil initform-p)
                                                   (initfunction nil initfunction-p)
                                                   (initargs '())
                                                   (type 'T)
                                                   (allocation ':instance)
                                                   (documentation nil)
                                                   ((inheritable-initer inheritable-initer) nil)
                                                   ((inheritable-doc inheritable-doc) nil)
                                              &allow-other-keys)
  (unless name-p
    (error (TEXT "(~S ~S): The slot name is not specified.")
           'initialize-instance 'slot-definition))
  (unless (symbolp name)
    (error (TEXT "(~S ~S): The slot name should be a symbol, not ~S")
           'initialize-instance 'slot-definition name))
  (unless (eq initform-p initfunction-p)
    (error (TEXT "(~S ~S): The ~S and ~S arguments can only be specified together.")
           'initialize-instance 'slot-definition ':initform ':initfunction))
  (when initfunction-p
    (when initfunction ; FIXME: defstruct.lisp passes :initfunction nil
      (unless (functionp initfunction)
        (error (TEXT "(~S ~S): The ~S argument should be a function, not ~S")
               'initialize-instance 'slot-definition ':initfunction initfunction))))
  (unless (and (listp initargs) (every #'symbolp initargs))
    (error (TEXT "(~S ~S): The ~S argument should be a list of symbols, not ~S")
           'initialize-instance 'slot-definition ':initargs initargs))
  (unless (or (null documentation) (stringp documentation))
    (error (TEXT "(~S ~S): The ~S argument should be a string or NIL, not ~S")
           'initialize-instance 'slot-definition :documentation documentation))
  (unless inheritable-initer
    (setq inheritable-initer
          (make-inheritable-slot-definition-initer initform initfunction)))
  (unless inheritable-doc
    (setq inheritable-doc
          (make-inheritable-slot-definition-doc documentation)))
  (setf (slot-definition-name slotdef)               name)
  (setf (slot-definition-initargs slotdef)           initargs)
  (setf (slot-definition-type slotdef)               type)
  (setf (slot-definition-allocation slotdef)         allocation)
  (setf (slot-definition-inheritable-initer slotdef) inheritable-initer)
  (setf (slot-definition-inheritable-doc slotdef)    inheritable-doc)
  slotdef)

;; Initialization of a <direct-slot-definition> instance.
(defun initialize-instance-<direct-slot-definition> (slotdef &rest args
                                                     &key (allocation ':instance)
                                                          (readers '())
                                                          (writers '())
                                                     &allow-other-keys)
  (apply #'initialize-instance-<slot-definition> slotdef args)
  (unless (symbolp allocation)
    (error (TEXT "(~S ~S): The ~S argument should be a symbol, not ~S")
           'initialize-instance 'slot-definition ':allocation allocation))
  (unless (and (listp readers) (every #'sys::function-name-p readers))
    (error (TEXT "(~S ~S): The ~S argument should be a list of function names, not ~S")
           'initialize-instance 'slot-definition ':readers readers))
  (unless (and (listp writers) (every #'sys::function-name-p writers))
    (error (TEXT "(~S ~S): The ~S argument should be a list of function names, not ~S")
           'initialize-instance 'slot-definition ':writers writers))
  (setf (slot-definition-readers slotdef) readers)
  (setf (slot-definition-writers slotdef) writers)
  slotdef)

;; Initialization of a <effective-slot-definition> instance.
(defun initialize-instance-<effective-slot-definition> (slotdef &rest args
                                                        &key (allocation ':instance)
                                                             ((location location) nil)
                                                        &allow-other-keys)
  (apply #'initialize-instance-<slot-definition> slotdef args)
  (unless (or (eq allocation ':instance) (class-p allocation))
    (error (TEXT "(~S ~S): The ~S argument should be ~S or a class, not ~S")
           'initialize-instance 'slot-definition ':allocation ':instance allocation))
  (setf (slot-definition-location slotdef) location)
  slotdef)


;;; ===========================================================================

;;; Now the concrete classes for <standard-class> and <structure-class> slots.


;;; ---------------------------------------------------------------------------

;; Information about a slot of <standard-class> in DEFCLASS.
(defvar <standard-direct-slot-definition> 'standard-direct-slot-definition)
(defvar *<standard-direct-slot-definition>-defclass*
  '(defclass standard-direct-slot-definition (direct-slot-definition)
     ()
     (:fixed-slot-locations)))
(defvar *<standard-direct-slot-definition>-class-version* (make-class-version))

;; Initialization of a <standard-direct-slot-definition> instance.
(defun initialize-instance-<standard-direct-slot-definition> (slotdef &rest args
                                                              &key
                                                              &allow-other-keys)
  (apply #'initialize-instance-<direct-slot-definition> slotdef args)
  slotdef)

(defun make-instance-<standard-direct-slot-definition> (class &rest args
                                                        &key &allow-other-keys)
  ;; class = <standard-direct-slot-definition>
  ;; Don't add functionality here! This is a preliminary definition that is
  ;; replaced with #'make-instance later.
  (declare (ignore class))
  (let ((slotdef (allocate-metaobject-instance *<standard-direct-slot-definition>-class-version* 9)))
    (apply #'initialize-instance-<standard-direct-slot-definition> slotdef args)))


;;; ---------------------------------------------------------------------------

;; Information about a slot of <standard-class> at runtime.
(defvar <standard-effective-slot-definition> 'standard-effective-slot-definition)
(defvar *<standard-effective-slot-definition>-defclass*
  '(defclass standard-effective-slot-definition (effective-slot-definition)
     ()
     (:fixed-slot-locations)))
(defvar *<standard-effective-slot-definition>-class-version* (make-class-version))

;; Initialization of a <standard-effective-slot-definition> instance.
(defun initialize-instance-<standard-effective-slot-definition> (slotdef &rest args
                                                                 &key
                                                                 &allow-other-keys)
  (apply #'initialize-instance-<effective-slot-definition> slotdef args)
  slotdef)

(defun make-instance-<standard-effective-slot-definition> (class &rest args
                                                           &key &allow-other-keys)
  ;; class = <standard-effective-slot-definition>
  ;; Don't add functionality here! This is a preliminary definition that is
  ;; replaced with #'make-instance later.
  (declare (ignore class))
  (let ((slotdef (allocate-metaobject-instance *<standard-effective-slot-definition>-class-version* 8)))
    (apply #'initialize-instance-<standard-effective-slot-definition> slotdef args)))


;;; ---------------------------------------------------------------------------

;; Information about a slot of <structure-class> in DEFCLASS.
(defvar <structure-direct-slot-definition> 'structure-direct-slot-definition)
(defvar *<structure-direct-slot-definition>-defclass*
  '(defclass structure-direct-slot-definition (direct-slot-definition)
     ((initff   :type t       :initarg initff)) ; init-function-fetcher
     (:fixed-slot-locations)))
(defvar *<structure-direct-slot-definition>-class-version* (make-class-version))

(defun structure-direct-slot-definition-initff (object)
  (sys::%record-ref object 9))
(defun (setf structure-direct-slot-definition-initff) (new-value object)
  (setf (sys::%record-ref object 9) new-value))

;; Initialization of a <structure-direct-slot-definition> instance.
(defun initialize-instance-<structure-direct-slot-definition> (slotdef &rest args
                                                               &key ((initff initff) nil)
                                                               &allow-other-keys)
  (apply #'initialize-instance-<direct-slot-definition> slotdef args)
  (setf (structure-direct-slot-definition-initff slotdef) initff)
  slotdef)

(defun make-instance-<structure-direct-slot-definition> (class &rest args
                                                         &key &allow-other-keys)
  ;; class = <structure-direct-slot-definition>
  ;; Don't add functionality here! This is a preliminary definition that is
  ;; replaced with #'make-instance later.
  (declare (ignore class))
  (let ((slotdef (allocate-metaobject-instance *<structure-direct-slot-definition>-class-version* 10)))
    (apply #'initialize-instance-<structure-direct-slot-definition> slotdef args)))


;;; ---------------------------------------------------------------------------

;; Information about a slot of <structure-class> at runtime.
(defvar <structure-effective-slot-definition> 'structure-effective-slot-definition)
(defvar *<structure-effective-slot-definition>-defclass*
  '(defclass structure-effective-slot-definition (effective-slot-definition)
     ((initff   :type t       :initarg initff) ; init-function-fetcher
      (readonly :type boolean :initarg readonly))
     (:fixed-slot-locations)))
(defvar *<structure-effective-slot-definition>-class-version* (make-class-version))

(defun structure-effective-slot-definition-initff (object)
  (sys::%record-ref object 8))
(defun (setf structure-effective-slot-definition-initff) (new-value object)
  (setf (sys::%record-ref object 8) new-value))
(defun structure-effective-slot-definition-readonly (object)
  (sys::%record-ref object 9))
(defun (setf structure-effective-slot-definition-readonly) (new-value object)
  (setf (sys::%record-ref object 9) new-value))

;; Initialization of a <structure-effective-slot-definition> instance.
(defun initialize-instance-<structure-effective-slot-definition> (slotdef &rest args
                                                                  &key ((initff initff) nil)
                                                                       ((readonly readonly) nil)
                                                                  &allow-other-keys)
  (apply #'initialize-instance-<effective-slot-definition> slotdef args)
  (setf (structure-effective-slot-definition-initff slotdef) initff)
  (setf (structure-effective-slot-definition-readonly slotdef) readonly)
  slotdef)

(defun make-instance-<structure-effective-slot-definition> (class &rest args
                                                            &key &allow-other-keys)
  ;; class = <structure-effective-slot-definition>
  ;; Don't add functionality here! This is a preliminary definition that is
  ;; replaced with #'make-instance later.
  (declare (ignore class))
  (let ((slotdef (allocate-metaobject-instance *<structure-effective-slot-definition>-class-version* 10)))
    (apply #'initialize-instance-<structure-effective-slot-definition> slotdef args)))


;;; ===========================================================================

;; Preliminary.
(defun direct-slot-definition-class (class &rest initargs)
  (declare (ignore class initargs))
  'standard-direct-slot-definition)

;; Converts a list of direct slot specifications (plists) to a list of
;; direct-slot-definition instances.
(defun convert-direct-slots (class direct-slots)
  (mapcar #'(lambda (slot-spec)
              (let ((slot-definition-class
                      (apply #'direct-slot-definition-class class slot-spec)))
                (apply (cond ((eq slot-definition-class 'standard-direct-slot-definition)
                              #'make-instance-<standard-direct-slot-definition>)
                             (t #'make-instance))
                       slot-definition-class slot-spec)))
          direct-slots))

;; Test two direct slots for equality, except for the inheritable slots,
;; where only the presence is compared.
;; Preliminary.
(defun equal-direct-slot (slot1 slot2)
  (and (eq (class-of slot1) (class-of slot2))
       (eq (slot-definition-name slot1) (slot-definition-name slot2))
       (equal (slot-definition-initargs slot1) (slot-definition-initargs slot2))
       (equal (slot-definition-type slot1) (slot-definition-type slot2))
       (equal (slot-definition-allocation slot1) (slot-definition-allocation slot2))
       (eq (null (slot-definition-initfunction slot1)) (null (slot-definition-initfunction slot2)))
       (eq (null (slot-definition-documentation slot1)) (null (slot-definition-documentation slot2)))
       (equal (slot-definition-readers slot1) (slot-definition-readers slot2))
       (equal (slot-definition-writers slot1) (slot-definition-writers slot2))))

;; Preliminary.
(defun effective-slot-definition-class (class &rest initargs)
  (declare (ignore class initargs))
  'standard-effective-slot-definition)

;; To avoid function calls when calling the initfunction of constants, we use
;; a specially tagged function.
(defun make-initfunction-form (form slotname)
  (if (constantp form)
    `(SYS::MAKE-CONSTANT-INITFUNCTION ,form)
    `(FUNCTION ,(sys::concat-pnames "DEFAULT-" slotname)
       (LAMBDA () ,form))))

;; Needed by DEFSTRUCT.
(defun make-load-form-<structure-direct-slot-definition> (object &optional local-initff)
  `(make-instance-<structure-direct-slot-definition>
    <structure-direct-slot-definition>
    :name               ',(slot-definition-name object)
    :initargs           ',(slot-definition-initargs object)
    :type               ',(slot-definition-type object)
    :allocation         ',(slot-definition-allocation object)
    'inheritable-initer ;; The initfunction is serializable only by virtue
                        ;; of the initfunctionform.
                        ;; It's not necessary to preserve the EQ-ness of
                        ;; the initer between the slot in the class and
                        ;; the slot in its subclasses, because structure
                        ;; classes don't support class redefinition.
                        (make-inheritable-slot-definition-initer
                          ',(slot-definition-initform object)
                          ,(or local-initff (structure-direct-slot-definition-initff object)))
    'inheritable-doc    ',(slot-definition-inheritable-doc object)
    :readers            ',(slot-definition-readers object)
    :writers            ',(slot-definition-writers object)
    'initff             ',(structure-direct-slot-definition-initff object)))

;; Needed by DEFSTRUCT.
(defun make-load-form-<structure-effective-slot-definition> (object &optional local-initff)
  `(make-instance-<structure-effective-slot-definition>
    <structure-effective-slot-definition>
    :name               ',(slot-definition-name object)
    :initargs           ',(slot-definition-initargs object)
    :type               ',(slot-definition-type object)
    :allocation         ',(slot-definition-allocation object)
    'inheritable-initer ;; The initfunction is serializable only by virtue
                        ;; of the initfunctionform.
                        ;; It's not necessary to preserve the EQ-ness of
                        ;; the initer between the slot in the class and
                        ;; the slot in its subclasses, because structure
                        ;; classes don't support class redefinition.
                        (make-inheritable-slot-definition-initer
                          ',(slot-definition-initform object)
                          ,(or local-initff (structure-effective-slot-definition-initff object)))
    'inheritable-doc    ',(slot-definition-inheritable-doc object)
    'location           ',(slot-definition-location object)
    'initff             ',(structure-effective-slot-definition-initff object)
    'readonly           ',(structure-effective-slot-definition-readonly object)))
