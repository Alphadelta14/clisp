;;; File DEFMACRO.LISP
;;; DEFMACRO macro and a few utility functions for complex macros.
;;; 1988-01-09
;;; Adapted from DEFTYPE on 1989-10-06
;;; German comments translated by Mirian Lennox <mirian@cosmic.com> 2003-19-01

(in-package "SYSTEM")

;; Import from CONTROL.Q:

#| (SYSTEM::PARSE-BODY body &optional docstring-allowed env)
   expands the first forms in the form list body (in the macro-expansion
   environment env), detects occurring declarations (and if
   docstring-allowed=T, also a docstring) and returns three values:
   1. body-rest, the remaining forms
   2. declspec-list, a list of declspecs that appeared
   3. docstring, a docstring that appeared, or NIL
|#
#| (SYSTEM::KEYWORD-TEST arglist kwlist)
   tests if arglist (a pair of keyword/value lists) contains only
   keywords which come from the list kwlist, or else contains a
   keyword/value pair :ALLOW-OTHER-KEYS with value other than NIL.
   If not, an error is raised.
|#
#| (keyword-test arglist kwlist) determines whether only keywords from
kwlist (a list of keyword/value pairs), or else a keyword/value pair
with keyword = :ALLOW-OTHER-KEYS and value other than NIL, appears
in arglist.  If this is not the case, an error message is returned.

 (defun keyword-test (arglist kwlist)
  (let ((unallowed-arglistr nil)
        (allow-other-keys-flag nil))
    (do ((arglistr arglist (cddr arglistr)))
        ((null arglistr))
      (if (eq (first arglistr) ':ALLOW-OTHER-KEYS)
          (if (second arglistr) (setq allow-other-keys-flag t))
          (do ((kw (first arglistr))
               (kwlistr kwlist (cdr kwlistr)))
              ((or (null kwlistr) (eq kw (first kwlistr)))
               (if (and (null kwlistr) (null unallowed-arglistr))
                   (setq unallowed-arglistr arglistr))))))
    (unless allow-other-keys-flag
      (if unallowed-arglistr
        (cerror (TEXT "Both will be ignored.")
                (TEXT "Invalid keyword-value-pair: ~S ~S")
                (first unallowed-arglistr) (second unallowed-arglistr))))))
;; Definition in assembler (see CONTROL.Q)
|#

(defun macro-call-error (macro-form)
  (error-of-type 'source-program-error
    (TEXT "The macro ~S may not be called with ~S arguments: ~S")
    (car macro-form) (1- (length macro-form)) macro-form))

(proclaim '(special
        %restp ;; indicates whether &REST/&BODY/&KEY was given,
               ;; and therefore the number of arguments is unbound.

        %min-args ;; indicates the mininum number of arguments

        %arg-count ;; indicates the number of individual arguments
                   ;; (required and optional arguments combined)

        %let-list ;; reversed list of bindings that have to be done with LET*

        %keyword-tests ;; list of KEYWORD-TEST calls that have to be included

        %default-form ;; default form for optional and keyword arguments,
                      ;; for which no default form is supplied
                      ;; NIL normally, or (QUOTE *) for DEFTYPE.
))
#|
 (ANALYZE1 lambdalist accessexp name wholevar)
analyses a macro lambda list (without &ENVIRONMENT).  accessexp is the
expression which supplies the arguments to be matched with this
lambda list.

 (ANALYZE-REST lambdalistr restexp name)
analyses the part of a macro lambda list that appears after the &REST/&BODY
expression. restexp is the expression that returns the arguments to be matched with this rest of the list.

 (ANALYZE-KEY lambdalistr restvar name)
analyses the part of a macro lambda list which comes after &KEY.
restvar is the symbol that will contain the remaining arguments.

 (ANALYZE-AUX lambdalistr name)
analyses the part of a macro lambda list that comes after &AUX.

 (REMOVE-ENV-ARG lambdalist name)
removes the pair &ENVIRONMENT/Symbol from a macro lambda list; returns
two values: the shortened lambda list and the symbol to be used
as environment (or the original lambda list and NIL, if &ENVIRONMENT
is not found).

 (MAKE-LENGTH-TEST symbol)
creates a testform from %restp, %min-args, %arg-count, which indicates
during evaluation whether the variable value of the symbol can be a
function call for the macro.

 (MAKE-MACRO-EXPANSION macrodef)
returns, for a macro definition macrodef = (name lambdalist . body),
1. the macro-expander as the program text (FUNCTION ... (LAMBDA ..)),
2. name, a symbol
3. lambda list
4. docstring (or NIL, if not there)

 (MAKE-MACRO-EXPANDER macrodef)
returns, for a macro definition macrodef = (name lambdalist . body),
the actual object #<MACRO expander> for the FENV.
|#

(defun analyze-aux (lambdalistr name)
  (do ((listr lambdalistr (cdr listr)))
      ((atom listr)
       (if listr
         (cerror (TEXT "The rest of the lambda list will be ignored.")
                 (TEXT "The lambda list of macro ~S contains a dot after &AUX.")
                 name)))
    (cond ((symbolp (car listr)) (setq %let-list (cons `(,(car listr) nil) %let-list)))
          ((atom (car listr))
           (error-of-type 'source-program-error
             (TEXT "in macro ~S: ~S may not be used as &AUX variable.")
             name (car listr)))
          (t (setq %let-list
                   (cons `(,(caar listr) ,(cadar listr)) %let-list))))))

(defun get-supplied-p (name item)
  (when (and (consp (cdr item)) (consp (cddr item)))
    (unless (symbolp (caddr item))
      (error-of-type 'source-program-error
        (TEXT "~S: invalid supplied-p variable ~S")
        name (caddr item)))
    (third item)))

(defun analyze-key (lambdalistr restvar name
                    &aux (otherkeysforbidden t) (kwlist nil))
      (do ((listr lambdalistr (cdr listr))
           (next)
           (kw)
           (svar)
           (g))
          ((atom listr)
           (if listr
             (cerror (TEXT "The rest of the lambda list will be ignored.")
                     (TEXT "The lambda list of macro ~S contains a dot after &KEY.")
                     name)))
        (setq next (car listr))
        (cond ((eq next '&ALLOW-OTHER-KEYS) (setq otherkeysforbidden nil))
              ((eq next '&AUX)
               (return-from nil (analyze-aux (cdr listr) name)))
              ((or (eq next '&ENVIRONMENT) (eq next '&WHOLE) (eq next '&REST)
                   (eq next '&OPTIONAL) (eq next '&BODY) (eq next '&KEY))
               (cerror (TEXT "It will be ignored.")
                       (TEXT "The lambda list of macro ~S contains a badly placed ~S.")
                       name next))
              (t
               (when %default-form
                 (cond ((symbolp next) (setq next (list next %default-form)))
                       ((and (consp next) (eql (length next) 1))
                        (setq next (list (car next) %default-form)))))
               (cond ((symbolp next)  ; foo
                      (setq kw (intern (symbol-name next) *keyword-package*))
                      (setq %let-list
                            (cons `(,next (GETF ,restvar ,kw NIL)) %let-list))
                      (setq kwlist (cons kw kwlist)))
                     ((atom next)
                      (cerror (TEXT "It will be ignored.")
                              (TEXT "The lambda list of macro ~S contains the invalid element ~S")
                              name next))
                     ((symbolp (car next))  ; (foo ...)
                      (setq kw (intern (symbol-name (car next)) *keyword-package*))
                      (when (setq svar (get-supplied-p name next))
                        (setq %let-list (cons `(,svar t) %let-list)))
                      (setq %let-list
                            (cons `(,(car next)
                                     ;; the default value should not be
                                     ;; evaluated unless it is actually used
                                     (or (GETF ,restvar ,kw)
                                         ,@(when svar `((setq ,svar nil)))
                                         ,(cadr next)))
                                  %let-list))
                      (setq kwlist (cons kw kwlist)))
                     ((not (and (consp (car next)) (symbolp (caar next)) (consp (cdar next))))
                      (cerror (TEXT "~0*It will be ignored.")
                              (TEXT "The lambda list of macro ~S contains an invalid keyword specification ~S")
                              name (car next)))
                     ((symbolp (cadar next))  ; ((:foo *foo*) ...)
                      (setq kw (caar next))
                      (when (setq svar (get-supplied-p name next))
                        (setq %let-list (cons `(,svar t) %let-list)))
                      (setq %let-list
                            (cons `(,(cadar next)
                                     (or (GETF ,restvar ,kw)
                                         ,@(when svar `((setq ,svar nil)))
                                         ,(cadr next)))
                                  %let-list))
                      (setq kwlist (cons kw kwlist)))
                     (t ; subform
                      (error-of-type 'source-program-error
                        (TEXT "~S: invalid lambda list element ~S")
                        name next)
                      (setq kw (caar next))
                      (setq g (gensym))
                      (setq svar (and (cddr next) (symbolp (third next))
                                      (third next)))
                      (when svar
                        (setq %let-list (cons `(,svar t) %let-list)))
                      (setq %let-list
                            (cons `(,g (or (GETF ,restvar ,kw)
                                           ,@(when svar `((setq ,svar nil)))
                                           ,(cadr next)))
                                  %let-list))
                      (setq kwlist (cons kw kwlist))
                      (let ((%min-args 0) (%arg-count 0) (%restp nil)
                            (%default-form nil))
                        (analyze1 (cadar next) g name g)))))))
      (if otherkeysforbidden
        (setq %keyword-tests
          (cons `(KEYWORD-TEST ,restvar ',kwlist) %keyword-tests))))

(%putd 'analyze-rest
  (function analyze-rest
    (lambda (lambdalistr restexp name)
      (if (atom lambdalistr)
        (error-of-type 'source-program-error
          (TEXT "The lambda list of macro ~S is missing a variable after &REST/&BODY.")
          name))
      (let ((restvar (car lambdalistr))
            (listr (cdr lambdalistr)))
        (setq %restp t)
        (cond ((symbolp restvar)
               (setq %let-list (cons `(,restvar ,restexp) %let-list)))
              ((atom restvar)
               (error-of-type 'source-program-error
                 (TEXT "The lambda list of macro ~S contains an illegal variable after &REST/&BODY: ~S")
                 name restvar))
              (t
               (let ((%min-args 0) (%arg-count 0) (%restp nil))
                 (analyze1 restvar restexp name restexp))))
        (cond ((null listr))
              ((atom listr)
               (cerror (TEXT "The rest of the lambda list will be ignored.")
                       (TEXT "The lambda list of macro ~S contains a misplaced dot.")
                       name))
              ((eq (car listr) '&KEY) (analyze-key (cdr listr) restvar name))
              ((eq (car listr) '&AUX) (analyze-aux (cdr listr) name))
              (t (cerror (TEXT "They will be ignored.")
                         (TEXT "The lambda list of macro ~S contains superfluous elements: ~S")
                         name listr)))))))

(defun cons-car (exp &aux h)
  (if
   (and
    (consp exp)
    (setq h
          (assoc (car exp)
                 '((car . caar) (cdr . cadr)
                   (caar . caaar) (cadr . caadr) (cdar . cadar) (cddr . caddr)
                   (caaar . caaaar) (caadr . caaadr) (cadar . caadar)
                   (caddr . caaddr) (cdaar . cadaar) (cdadr . cadadr)
                   (cddar . caddar) (cdddr . cadddr)
                   (cddddr . fifth)))))
   (cons (cdr h) (cdr exp))
   (list 'car exp)))

(defun cons-cdr (exp &aux h)
  (if
   (and
    (consp exp)
    (setq h
          (assoc (car exp)
                 '((car . cdar) (cdr . cddr)
                   (caar . cdaar) (cadr . cdadr) (cdar . cddar) (cddr . cdddr)
                   (caaar . cdaaar) (caadr . cdaadr) (cadar . cdadar)
                   (caddr . cdaddr) (cdaar . cddaar) (cdadr . cddadr)
                   (cddar . cdddar) (cdddr . cddddr)))))
   (cons (cdr h) (cdr exp))
   (list 'cdr exp)))

(defun analyze1 (lambdalist accessexp name wholevar)
  (do ((listr lambdalist (cdr listr))
       (withinoptional nil)
       (item)
       (g))
      ((atom listr)
       (when listr
         (unless (symbolp listr)
           (error-of-type 'source-program-error
             (TEXT "The lambda list of macro ~S contains an illegal &REST variable: ~S")
             name listr))
         (setq %let-list (cons `(,listr ,accessexp) %let-list))
         (setq %restp t)))
    (setq item (car listr))
    (cond ((eq item '&WHOLE)
           (if (and wholevar (cdr listr) (symbolp (cadr listr)))
               (setq %let-list (cons `(,(cadr listr) ,wholevar) %let-list)
                     listr (cdr listr))
               (error-of-type 'source-program-error
                 (TEXT "The lambda list of macro ~S contains an invalid &WHOLE: ~S")
                 name listr)))
          ((eq item '&OPTIONAL)
           (if withinoptional
               (cerror (TEXT "It will be ignored.")
                       (TEXT "The lambda list of macro ~S contains a superfluous ~S.")
                       name item))
           (setq withinoptional t))
          ((or (eq item '&REST) (eq item '&BODY))
           (return-from nil (analyze-rest (cdr listr) accessexp name)))
          ((eq item '&KEY)
           (setq g (gensym))
           (setq %restp t)
           (setq %let-list (cons `(,g ,accessexp) %let-list))
           (return-from nil (analyze-key (cdr listr) g name)))
          ((eq item '&ALLOW-OTHER-KEYS)
           (cerror (TEXT "It will be ignored.")
                   (TEXT "The lambda list of macro ~S contains ~S before &KEY.")
                   name item))
          ((eq item '&ENVIRONMENT)
           (cerror (TEXT "It will be ignored.")
                   (TEXT "The lambda list of macro ~S contains ~S which is illegal here.")
                   name item))
          ((eq item '&AUX)
           (return-from nil (analyze-aux (cdr listr) name)))
          (withinoptional
           (setq %arg-count (1+ %arg-count))
           (if %default-form
             (cond ((symbolp item) (setq item (list item %default-form)))
                   ((and (consp item) (eql (length item) 1))
                    (setq item (list (car item) %default-form)))))
           (cond ((symbolp item)
                  (setq %let-list (cons `(,item ,(cons-car accessexp))
                                        %let-list)))
                 ((atom item)
                  #1=
                  (error-of-type 'source-program-error
                    (TEXT "The lambda list of macro ~S contains an invalid element ~S")
                    name item))
                 ((symbolp (car item))
                  (setq %let-list
                        (cons `(,(car item) (IF ,accessexp
                                              ,(cons-car accessexp)
                                              ,(if (consp (cdr item))
                                                 (cadr item) 'NIL)))
                              %let-list))
                  (when (setq g (get-supplied-p name item))
                    (setq %let-list
                          (cons `(,g (NOT (NULL ,accessexp)))
                                %let-list))))
                 (t
                  (setq g (gensym))
                  (setq %let-list
                        (cons `(,g ,(if (consp (cdr item))
                                      `(IF ,accessexp
                                         ,(cons-car accessexp)
                                         ,(cadr item))
                                      (cons-car accessexp)))
                              %let-list))
                  (let ((%min-args 0) (%arg-count 0) (%restp nil))
                    (analyze1 (car item) g name g))
                  (if (consp (cddr item))
                    (setq %let-list
                          (cons `(,(caddr item) (NOT (NULL ,accessexp))) %let-list)))))
           (setq accessexp (cons-cdr accessexp)))
          (t ; required arguments
           (setq %min-args (1+ %min-args))
           (setq %arg-count (1+ %arg-count))
           (cond ((symbolp item)
                  (setq %let-list (cons `(,item ,(cons-car accessexp)) %let-list)))
                 ((atom item)
                  #1#) ; (error-of-type ... name item), s.o.
                 (t
                  (let ((%min-args 0) (%arg-count 0) (%restp nil))
                    (analyze1 item (cons-car accessexp) name
                              (cons-car accessexp)))))
           (setq accessexp (cons-cdr accessexp))))))

(defun remove-env-arg (lambdalist name)
  (do ((listr lambdalist (cdr listr)))
      ((atom listr) (values lambdalist nil))
    (if (eq (car listr) '&ENVIRONMENT)
      (if (and (consp (cdr listr)) (symbolp (cadr listr)) (cadr listr))
        ;; found &ENVIRONMENT
        (return
          (values
           (do ((l1 lambdalist (cdr l1)) ; lambda list without &ENVIRONMENT/symbol
                (l2 nil (cons (car l1) l2)))
               ((eq (car l1) '&ENVIRONMENT)
                (nreconc l2 (cddr l1))))
           (cadr listr)))
        (error-of-type 'source-program-error
          (TEXT "In the lambda list of macro ~S, &ENVIRONMENT must be followed by a non-NIL symbol: ~S")
          name lambdalist)))))

(defun make-length-test (var &optional (header 1))
  (let ((len `(LIST-LENGTH-DOTTED ,var)))
    (cond ((and (zerop %min-args) %restp) NIL)
          ((zerop %min-args) `(> ,len ,(+ header %arg-count)))
          (%restp `(< ,len ,(+ header %min-args)))
          ((= %min-args %arg-count) `(/= ,len ,(+ header %min-args)))
          (t `(NOT (<= ,(+ header %min-args)
                       ,len ,(+ header %arg-count)))))))

(defun make-macro-expansion (macrodef &optional pre-process)
  (when (atom macrodef)
    (error-of-type 'source-program-error
      (TEXT "Cannot define a macro from that: ~S")
      macrodef))
  (unless (symbolp (car macrodef))
    (error-of-type 'source-program-error
      (TEXT "The name of a macro must be a symbol, not ~S")
      (car macrodef)))
  (when (atom (cdr macrodef))
    (error-of-type 'source-program-error
      (TEXT "Macro ~S is missing a lambda list.")
      (car macrodef)))
  (let ((name (car macrodef))
        (lambdalist (cadr macrodef))
        (body (cddr macrodef)))
    (multiple-value-bind (body-rest declarations docstring)
        (parse-body body t) ; global environment!
      (if declarations (setq declarations
                             (list (cons 'DECLARE declarations))))
      (multiple-value-bind (newlambdalist envvar)
          (remove-env-arg lambdalist name)
        (let ((%arg-count 0) (%min-args 0) (%restp nil)
              (%let-list nil) (%keyword-tests nil) (%default-form nil))
          (analyze1 newlambdalist '(CDR <MACRO-FORM>) name '<MACRO-FORM>)
          (let ((lengthtest (make-length-test '<MACRO-FORM>))
                (mainform `(LET* ,(nreverse %let-list)
                             ,@declarations
                             ,@(nreverse %keyword-tests)
                             (BLOCK ,name ,@body-rest))))
            (if lengthtest
              (setq mainform
                    `(IF ,lengthtest
                       (MACRO-CALL-ERROR <MACRO-FORM>)
                       ,mainform)))
            (values
             `(FUNCTION ,name
                (LAMBDA (<MACRO-FORM> &OPTIONAL ,(or envvar '<ENV-ARG>))
                (DECLARE (CONS <MACRO-FORM>))
                ,@(if envvar
                    declarations ;; possibly contains a (declare (ignore envvar))
                    '((DECLARE (IGNORE <ENV-ARG>))))
                ,@(if docstring (list docstring))
                ,@(if pre-process
                    `((setq <MACRO-FORM> (,pre-process <MACRO-FORM>))))
                ,mainform))
             name
             lambdalist
             docstring)))))))

(defun make-macro-expander (macrodef)
  (make-macro (eval (make-macro-expansion macrodef))))
