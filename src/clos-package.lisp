;;;; Common Lisp Object System for CLISP
;;;; Bruno Haible 21.8.1993 - 2004
;;;; Sam Steingold 1998 - 2004

;; to use it: (USE-PACKAGE "CLOS").

(in-package "COMMON-LISP")
(pushnew ':clos *features*)

(in-package "SYSTEM") ; necessary despite DEFPACKAGE!

;; Defined later, in functions.lisp.
(import 'make-signature)
(import 'sig-req-num)
(import 'sig-opt-num)
(import 'sig-rest-p)
(import 'sig-keys-p)
(import 'sig-keywords)
(import 'sig-allow-p)
(import 'check-function-name)

;; Defined later, in compiler.lisp.
(import 'compiler::%generic-function-lambda)
(import 'compiler::%optimize-function-lambda)

(defpackage "CLOS"
  (:import-from "EXT" ext:mapcap)
  (:import-from "SYSTEM"
    ;; Import:
    sys::text                   ; for error messages (i18n.d)
    sys::error-of-type          ; defined in error.d
    sys::check-function-name    ; defined in trace.lisp
    sys::function-name-p        ; defined in control.d
    sys::function-block-name    ; defined in eval.d
    sys::memq                   ; defined in list.d
    sys::gensym-list            ; defined in macros2.lisp
    sys::make-signature         ; defined in functions.lisp
    sys::sig-req-num sys::sig-opt-num sys::sig-rest-p ; likewise
    sys::sig-keys-p sys::sig-keywords sys::sig-allow-p ; likewise
    ;; clos::generic-function-p ; defined in predtype.d
    ;; clos::class-p clos:class-of clos:find-class ; defined in predtype.d
    ;; clos::typep-class        ; defined in predtype.d
    ;; clos::structure-object-p ; defined in record.d
    ;; clos::std-instance-p clos::allocate-std-instance ; defined in record.d
    ;; clos::%allocate-instance ; defined in record.d
    ;; clos:slot-value clos::set-slot-value ; defined in record.d
    ;; clos:slot-boundp clos:slot-makunbound ; defined in record.d
    ;; clos:slot-exists-p ; defined in record.d
    ;; clos::class-gethash clos::class-tuple-gethash ; defined in hashtabl.d
    sys::*keyword-package*      ; defined in init.lisp, compiler.lisp
    compiler::%generic-function-lambda ; defined in compiler.lisp
    compiler::%optimize-function-lambda ; defined in compiler.lisp
    compiler::analyze-lambdalist ; FIXME: shouldn't be used
    ;; clos:generic-flet clos:generic-labels ; treated in compiler.lisp
    ;; Export:
    ;; clos::closclass ; property in predtype.d, type.lisp, compiler.lisp
    ;; clos:class      ; used in record.d
    ;; clos:generic-function ; used in type.lisp, compiler.lisp
    ;; clos:standard-generic-function ; used in predtype.d, type.lisp, compiler.lisp
    ;; clos:slot-missing clos:slot-unbound  ; called by record.d
    ;; clos::*make-instance-table*          ; used in record.d
    ;; clos::*reinitialize-instance-table*  ; used in record.d
    ;; clos::initial-reinitialize-instance  ; called by record.d
    ;; clos::initial-initialize-instance    ; called by record.d
    ;; clos::initial-make-instance          ; called by record.d
    ;; clos:print-object                    ; called by io.d
    ;; clos:describe-object                 ; called by user2.lisp
    ;; clos::define-structure-class         ; called by defstruct.lisp
    ;; clos::defstruct-remove-print-object-method ; called by defstruct.lisp
    ;; clos::built-in-class-p               ; called by type.lisp
    ;; clos::subclassp  ; called by type.lisp, used in compiler.lisp
    ;; clos:class-name                      ; used in type.lisp, compiler.lisp
    ;; clos:find-class                      ; used in compiler.lisp
    ;; clos::defgeneric-lambdalist-callinfo ; called by compiler.lisp
    ;; clos::make-generic-function-form     ; called by compiler.lisp
    )) ; defpackage

(in-package "CLOS")

;;; exports: ** also in init.lisp ** !
(export
 '(;; names of functions and macros:
   slot-value slot-boundp slot-makunbound slot-exists-p with-slots
   with-accessors documentation
   find-class class-of defclass defmethod call-next-method next-method-p
   defgeneric generic-function generic-flet generic-labels
   class-name no-applicable-method no-next-method no-primary-method
   find-method add-method remove-method
   compute-applicable-methods method-qualifiers function-keywords
   slot-missing slot-unbound
   print-object describe-object
   make-instance allocate-instance initialize-instance reinitialize-instance
   shared-initialize ensure-generic-function
   make-load-form make-load-form-saving-slots
   change-class update-instance-for-different-class
   update-instance-for-redefined-class make-instances-obsolete
   ;; names of classes:
   class standard-class structure-class built-in-class
   standard-object structure-object
   generic-function standard-generic-function method standard-method
   ;; method combinations
   standard method-combination define-method-combination
   method-combination-error invalid-method-error
   call-method make-method))

;;; MOP exports: ** also in init.lisp ** !
(export
        '(;; MOP for dependents
          ;; MOP for slot definitions
          slot-definition
          direct-slot-definition standard-direct-slot-definition
          effective-slot-definition standard-effective-slot-definition
          slot-definition-name
          slot-definition-initform slot-definition-initfunction
          slot-definition-type slot-definition-allocation
          slot-definition-initargs
          slot-definition-readers slot-definition-writers
          slot-definition-location
          direct-slot-definition-class effective-slot-definition-class
          ;; MOP for slot access
          ;; MOP for classes
          class-prototype class-finalized-p finalize-inheritance
          ;; MOP for specializers
          ;; MOP for methods
          ;; MOP for method combinations
          ;; MOP for generic functions
          ;; CLISP specific symbols
          generic-flet generic-labels no-primary-method
          method-call-error method-call-type-error
          method-call-error-generic-function
          method-call-error-method method-call-error-argument-list
)        )
