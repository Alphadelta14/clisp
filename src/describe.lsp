;;;; Apropos, Describe

(in-package "SYSTEM")

;;-----------------------------------------------------------------------------
;; DESCRIBE

(defvar *describe-nesting* 0)
(defvar *describe-done* nil)

(defun describe-slotted-object (object s)
  (let ((slotnames (mapcar #'clos::slotdef-name (clos::class-slots (clos:class-of object)))))
    (if slotnames
      (let* ((slotstrings (mapcar #'write-to-string slotnames)) more
             (tabpos (+ 4 (reduce #'max (mapcar #'length slotstrings)))))
        (format s (DEUTSCH "~%~v,vtSlots:"
                   ENGLISH "~%~v,vtSlots:"
                   FRANCAIS "~%~v,vtComposants:")
                *describe-nesting* *print-indent-lists*)
        (mapc #'(lambda (slotname slotstring)
                  (format s "~%~v,vt  ~A~VT" (1+ *describe-nesting*)
                          *print-indent-lists* slotstring tabpos)
                  (cond ((clos:slot-boundp object slotname)
                         (format s "=  ~S" (clos:slot-value object slotname))
                         (pushnew (clos:slot-value object slotname) more))
                        ((format s (DEUTSCH "ohne Wert"
                                    ENGLISH "unbound"
                                    FRANCAIS "aucune valeur")))))
              slotnames slotstrings)
        (dolist (vv (nreverse more)) (describe vv)))
      (format s (DEUTSCH "~%~v,vtKeine Slots."
                 ENGLISH "~%~v,vtNo slots."
                 FRANCAIS "~%~v,vtAucun composant.")
              *describe-nesting* *print-indent-lists*))))

(clos:defgeneric describe-object (obj stream)
  (:method ((obj t) (stream stream))
    (ecase (sys::type-of obj)
      #+(or AMIGA FFI)
      (FOREIGN-POINTER
       (format stream (DEUTSCH "ein Foreign-Pointer."
                       ENGLISH "a foreign pointer"
                       FRANCAIS "un pointeur �tranger.")))
      #+FFI
      (FOREIGN-ADDRESS
       (format stream (DEUTSCH "eine Foreign-Adresse."
                       ENGLISH "a foreign address"
                       FRANCAIS "une addresse �trang�re.")))
      #+FFI
      (FOREIGN-VARIABLE
       (format stream
               (DEUTSCH "eine Foreign-Variable vom Foreign-Typ ~S."
                ENGLISH "a foreign variable of foreign type ~S."
                FRANCAIS "une variable �trang�re de type �tranger ~S.")
               (deparse-c-type (sys::%record-ref obj 3))))
      (BYTE
       (format stream (DEUTSCH "ein Byte-Specifier, bezeichnet die ~S Bits ab Bitposition ~S eines Integers."
                       ENGLISH "a byte specifier, denoting the ~S bits starting at bit position ~S of an integer."
                       FRANCAIS "un intervalle de bits, comportant ~S bits � partir de la position ~S d'un entier.")
               (byte-size obj) (byte-position obj)))
      (SPECIAL-OPERATOR
       (format stream (DEUTSCH "ein Special-Form-Handler."
                       ENGLISH "a special form handler."
                       FRANCAIS "un interpr�teur de forme sp�ciale.")))
      (LOAD-TIME-EVAL
       (format stream
               (DEUTSCH "eine Absicht der Evaluierung zur Ladezeit." ; ??
                ENGLISH "a load-time evaluation promise." ; ??
                FRANCAIS "une promesse d'�valuation au moment du chargement.")))
      (WEAK-POINTER
       (multiple-value-bind (value validp) (weak-pointer-value obj)
         (if validp
           (progn
             (format stream (DEUTSCH "ein f�r die GC unsichtbarer Pointer auf ~S."
                             ENGLISH "a GC-invisible pointer to ~S."
                             FRANCAIS "un pointeur, invisible pour le GC, sur ~S.")
                     value)
             (describe value))
           (format stream (DEUTSCH "ein f�r die GC unsichtbarer Pointer auf ein nicht mehr existierendes Objekt."
                           ENGLISH "a GC-invisible pointer to a now defunct object."
                           FRANCAIS "un pointeur, invisible pour le GC, sur un objet qui n'existe plus.")))))
      (READ-LABEL
       (format stream (DEUTSCH "eine Markierung zur Aufl�sung von #~D#-Verweisen bei READ."
                       ENGLISH "a label used for resolving #~D# references during READ."
                       FRANCAIS "une marque destin�e � r�soudre #~D# au cours de READ.")
               (logand (sys::address-of obj)
                       (load-time-value (ash most-positive-fixnum -1)))))
      (FRAME-POINTER
       (format stream (DEUTSCH "ein Pointer in den Stack. Er zeigt auf:"
                       ENGLISH "a pointer into the stack. It points to:"
                       FRANCAIS "un pointeur dans la pile. Il pointe vers :"))
       (sys::describe-frame stream obj))
      (SYSTEM-INTERNAL
       (format stream (DEUTSCH "ein Objekt mit besonderen Eigenschaften."
                       ENGLISH "a special-purpose object."
                       FRANCAIS "un objet distingu�.")))
      (ADDRESS
       (format stream (DEUTSCH "eine Maschinen-Adresse."
                       ENGLISH "a machine address."
                       FRANCAIS "une addresse au niveau de la machine.")))))
  (:method ((obj clos:standard-object) (stream stream))
      (format stream (DEUTSCH "eine Instanz der CLOS-Klasse ~S."
                      ENGLISH "an instance of the CLOS class ~S."
                      FRANCAIS "un objet appartenant � la classe ~S de CLOS.")
              (clos:class-of obj))
   (describe-slotted-object obj stream))
  (:method ((obj structure-object) (stream stream)) ; CLISP specific
    (format stream (DEUTSCH "eine Structure vom Typ ~S."
                    ENGLISH "a structure of type ~S."
                    FRANCAIS "une structure de type ~S.")
            (type-of obj))
    (let ((types (butlast (cdr (sys::%record-ref obj 0)))))
      (when types
        (format stream (DEUTSCH "~%Als solche ist sie auch eine Structure vom Typ ~{~S~^, ~}."
                        ENGLISH "~%As such, it is also a structure of type ~{~S~^, ~}."
                        FRANCAIS "~%En tant que telle, c'est aussi une structure de type ~{~S~^, ~}.")
                types)))
    (describe-slotted-object obj stream))
  (:method ((obj cons) (stream stream))
    (let ((len ; cf. function list-length in CLtL p. 265
           (do ((n 0 (+ n 2))
                (fast obj (cddr fast))
                (slow obj (cdr slow)))
               (nil)
             (when (atom fast) (return n))
             (when (atom (cdr fast)) (return (1+ n)))
             (when (eq (cdr fast) slow) (return nil)))))
      (if len
        (if (null (nthcdr len obj))
          (format stream (DEUTSCH "eine Liste der L�nge ~S."
                          ENGLISH "a list of length ~S."
                          FRANCAIS "une liste de longueur ~S.")
                  len)
          (if (> len 1)
            (format stream
                    (DEUTSCH "eine punktierte Liste der L�nge ~S."
                     ENGLISH "a dotted list of length ~S."
                     FRANCAIS "une liste point�e de longueur ~S.")
                    len)
            (format stream (DEUTSCH "ein Cons."
                            ENGLISH "a cons."
                            FRANCAIS "un �cons�."))))
        (format stream (DEUTSCH "eine zyklische Liste."
                        ENGLISH "a cyclic list."
                        FRANCAIS "une liste circulaire.")))))
  (:method ((obj null) (stream stream))
    (format stream (DEUTSCH "die leere Liste, "
                    ENGLISH "the empty list, "
                    FRANCAIS "la liste vide, "))
    (clos:call-next-method))
  (:method ((obj symbol) (stream stream))
    (format stream (DEUTSCH "das Symbol ~S, "
                    ENGLISH "the symbol ~S, "
                    FRANCAIS "le symbole ~S, ")
            obj)
    (let ((home (symbol-package obj)) mored moree)
      (cond (home
             (format stream (DEUTSCH "liegt in ~S"
                             ENGLISH "lies in ~S"
                             FRANCAIS "est situ� dans ~S")
                     home)
             (pushnew home mored))
            (t (format stream
                       (DEUTSCH "ist uninterniert"
                        ENGLISH "is uninterned"
                        FRANCAIS "n'appartient � aucun paquetage"))))
      (let ((accessible-packs nil))
        (let ((*print-escape* t) (*print-readably* nil))
          (let ((normal-printout
                 (if home
                   (let ((*package* home)) (prin1-to-string obj))
                   (let ((*print-gensym* nil)) (prin1-to-string obj)))))
            (dolist (pack (list-all-packages))
              (when ; obj in pack accessible?
                  (string=
                   (let ((*package* pack)) (prin1-to-string obj))
                   normal-printout)
                (push pack accessible-packs)))))
        (when accessible-packs
          (format stream (DEUTSCH ", ist in ~:[der Package~;den Packages~] ~{~A~^, ~} accessible"
                          ENGLISH ", is accessible in the package~:[~;s~] ~{~A~^, ~}"
                          FRANCAIS ", est visible dans le~:[ paquetage~;s paquetages~] ~{~A~^, ~}")
                  (cdr accessible-packs)
                  (sort (mapcar #'package-name accessible-packs)
                        #'string<))))
      (when (keywordp obj)
        (format stream (DEUTSCH ", ist ein Keyword"
                        ENGLISH ", is a keyword"
                        FRANCAIS ", est un mot-cl�")))
      (when (boundp obj)
        (if (constantp obj)
          (format stream (DEUTSCH ", eine Konstante"
                          ENGLISH ", a constant"
                          FRANCAIS ", une constante"))
          (if (sys::special-variable-p obj)
            (format stream
                    (DEUTSCH ", eine SPECIAL-deklarierte Variable"
                     ENGLISH ", a variable declared SPECIAL"
                     FRANCAIS ", une variable declar�e SPECIAL"))
            (format stream (DEUTSCH ", eine Variable"
                            ENGLISH ", a variable"
                            FRANCAIS ", une variable"))))
        (when (symbol-macro-expand obj)
          (format stream (DEUTSCH " (Macro: ~s)"
                          ENGLISH " (macro: ~s)"
                          FRANCAIS " (macro: ~s)")
                  (macroexpand-1 obj))
          (push `(macroexpand-1 ',obj) moree))
        (format stream (DEUTSCH ", Wert: ~s"
                        ENGLISH ", value: ~s"
                        FRANCAIS ", valeur : ~s")
                (symbol-value obj))
        (pushnew (symbol-value obj) mored))
      (when (fboundp obj)
        (format stream (DEUTSCH ", benennt "
                        ENGLISH ", names "
                        FRANCAIS ", le nom "))
        (cond ((special-operator-p obj)
               (format stream (DEUTSCH "einen Special-Operator"
                               ENGLISH "a special operator"
                               FRANCAIS "d'un operateur sp�cial"))
               (when (macro-function obj)
                 (format stream (DEUTSCH " mit Macro-Definition"
                                 ENGLISH " with macro definition"
                                 FRANCAIS ", aussi d'un macro"))))
              ((functionp (symbol-function obj))
               (format stream (DEUTSCH "eine~:[~; abgeratene~] Funktion"
                               ENGLISH "a~:[~; deprecated~] function"
                               FRANCAIS "d'une fonction~:[~; d�courag�e~]")
                       (member obj *deprecated-functions-list* :test #'eq)))
              (t ; (macro-function obj)
               (format stream (DEUTSCH "einen Macro"
                               ENGLISH "a macro"
                               FRANCAIS "d'un macro"))))
        (pushnew (symbol-function obj) mored))
      (when (or (get obj 'system::type-symbol)
                (get obj 'system::defstruct-description)
                (get obj 'system::deftype-expander))
        (format stream (DEUTSCH ", benennt einen Typ"
                        ENGLISH ", names a type"
                        FRANCAIS ", le nom d'un type"))
        (when (get obj 'system::deftype-expander)
          (push `(type-expand-1 ',obj) moree)))
      (when (get obj 'clos::closclass)
        (format stream (DEUTSCH ", benennt eine Klasse"
                        ENGLISH ", names a class"
                        FRANCAIS ", le nom d'une classe")))
      (when (symbol-plist obj)
        (let ((properties
               (do ((l nil) (pl (symbol-plist obj) (cddr pl)))
                   ((null pl) (nreverse l))
                 (push (car pl) l))))
          (format stream (DEUTSCH ", hat die Propert~@P ~{~S~^, ~}"
                          ENGLISH ", has the propert~@P ~{~S~^, ~}"
                          FRANCAIS ", a ~[~;la propri�t�~:;les propri�t�s~] ~{~S~^, ~}")
                  (length properties) properties))
        (push `(symbol-plist ',obj) moree))
      (format stream (DEUTSCH "."
                      ENGLISH "."
                      FRANCAIS "."))
      (when moree
        (format stream (DEUTSCH "~%~v,vtMehr Information durch Auswerten von ~{~S~^ oder ~}."
                        ENGLISH "~%~v,vtFor more information, evaluate ~{~S~^ or ~}."
                        FRANCAIS "~%~v,vtPour obtenir davantage d'information, �valuez ~{~S~^ ou ~}.")
                *describe-nesting* *print-indent-lists* moree))
      (dolist (zz (nreverse mored)) (describe zz stream))))
  (:method ((obj integer) (stream stream))
    (format stream (DEUTSCH "eine ganze Zahl, belegt ~S Bit~:p, ist als ~:(~A~) repr�sentiert."
                    ENGLISH "an integer, uses ~S bit~:p, is represented as a ~(~A~)."
                    FRANCAIS "un nombre entier, occupant ~S bit~:p, est repr�sent� comme ~(~A~).")
            (integer-length obj) (type-of obj)))
  (:method ((obj ratio) (stream stream))
    (format stream (DEUTSCH "eine rationale, nicht ganze Zahl."
                    ENGLISH "a rational, not integral number."
                    FRANCAIS "un nombre rationnel mais pas entier.")))
  (:method ((obj float) (stream stream))
    (format stream (DEUTSCH "eine Flie�kommazahl mit ~S Mantissenbits (~:(~A~))."
                    ENGLISH "a float with ~S bits of mantissa (~(~A~))."
                    FRANCAIS "un nombre � virgule flottante avec une pr�cision de ~S bits (un ~(~A~)).")
            (float-digits obj) (type-of obj)))
  (:method ((obj complex) (stream stream))
    (format stream (DEUTSCH "eine komplexe Zahl "
                    ENGLISH "a complex number "
                    FRANCAIS "un nombre complexe "))
    (let ((x (realpart obj))
          (y (imagpart obj)))
      (if (zerop y)
        (if (zerop x)
          (format stream (DEUTSCH "im Ursprung"
                          ENGLISH "at the origin"
                          FRANCAIS "� l'origine"))
          (format stream
                  (DEUTSCH "auf der ~:[posi~;nega~]tiven reellen Achse"
                   ENGLISH "on the ~:[posi~;nega~]tive real axis"
                   FRANCAIS "sur la partie ~:[posi~;nega~]tive de l'axe r�elle")
                  (minusp x)))
        (if (zerop x)
          (format stream (DEUTSCH "auf der ~:[posi~;nega~]tiven imagin�ren Achse"
                          ENGLISH "on the ~:[posi~;nega~]tive imaginary axis"
                          FRANCAIS "sur la partie ~:[posi~;nega~]tive de l'axe imaginaire")
                  (minusp y))
          (format stream (DEUTSCH "im ~:[~:[ers~;vier~]~;~:[zwei~;drit~]~]ten Quadranten"
                          ENGLISH "in ~:[~:[first~;fourth~]~;~:[second~;third~]~] the quadrant"
                          FRANCAIS "dans le ~:[~:[premier~;quatri�me~]~;~:[deuxi�me~;troisi�me~]~] quartier")
                  (minusp x) (minusp y)))))
    (format stream (DEUTSCH " der Gau�schen Zahlenebene."
                    ENGLISH " of the Gaussian number plane."
                    FRANCAIS " du plan Gaussien.")))
  (:method ((obj character) (stream stream))
    (format stream (DEUTSCH "ein Zeichen"
                    ENGLISH "a character"
                    FRANCAIS "un caract�re"))
    (format stream (DEUTSCH "."
                    ENGLISH "."
                    FRANCAIS "."))
    (format stream
            (DEUTSCH "~%Es ist ein ~:[nicht ~;~]druckbares Zeichen."
             ENGLISH "~%It is a ~:[non-~;~]printable character."
             FRANCAIS "~%C'est un caract�re ~:[non ~;~]imprimable.")
            (graphic-char-p obj))
    (unless (standard-char-p obj)
      (format stream
              (DEUTSCH "~%Seine Verwendung ist nicht portabel."
               ENGLISH "~%Its use is non-portable."
               FRANCAIS "~%Il n'est pas portable de l'utiliser."))))
  (:method ((obj stream) (stream stream))
    (format stream (DEUTSCH "ein ~:[~:[geschlossener ~;Output-~]~;~:[Input-~;bidirektionaler ~]~]Stream."
                    ENGLISH "a~:[~:[ closed ~;n output-~]~;~:[n input-~;n input/output-~]~]stream."
                    FRANCAIS "un �stream� ~:[~:[ferm�~;de sortie~]~;~:[d'entr�e~;d'entr�e/sortie~]~].")
            (input-stream-p obj) (output-stream-p obj)))
  (:method ((obj package) (stream stream))
    (if (package-name obj)
      (progn
        (format stream (DEUTSCH "die Package mit Namen ~A"
                        ENGLISH "the package named ~A"
                        FRANCAIS "le paquetage de nom ~A")
                (package-name obj))
        (let ((nicknames (package-nicknames obj)))
          (when nicknames
            (format stream
                    (DEUTSCH " und zus�tzlichen Namen ~{~A~^, ~}"
                     ENGLISH ". It has the nicknames ~{~A~^, ~}"
                     FRANCAIS ". Il porte aussi les noms ~{~A~^, ~}")
                    nicknames)))
        (format stream (DEUTSCH "."
                        ENGLISH "."
                        FRANCAIS "."))
        (let ((use-list (package-use-list obj))
              (used-by-list (package-used-by-list obj)))
          (format stream (DEUTSCH "~%~v,vtSie "
                          ENGLISH "~%~v,vtIt "
                          FRANCAIS "~%~v,vtIl ")
                  *describe-nesting* *print-indent-lists*)
          (when use-list
            (format stream (DEUTSCH "importiert die externen Symbole der Package~:[~;s~] ~{~A~^, ~} und "
                            ENGLISH "imports the external symbols of the package~:[~;s~] ~{~A~^, ~} and "
                            FRANCAIS "importe les symboles externes d~:[u paquetage~;es paquetages~] ~{~A~^, ~} et ")
                    (cdr use-list) (mapcar #'package-name use-list)))
          (let ((L nil)) ; maybe list all exported symbols
            (do-external-symbols (s obj) (push s L))
            (if (= 1 *describe-nesting*)
              (format stream (DEUTSCH "exportiert ~:[keine Symbole~;die Symbole~:*~{~<~%~:; ~S~>~^~}~%~]"
                              ENGLISH "exports ~:[no symbols~;the symbols~:*~{~<~%~:; ~S~>~^~}~%~]"
                              FRANCAIS "~:[n'exporte pas de symboles~;exporte les symboles~:*~{~<~%~:; ~S~>~^~}~%~]")
                      (sort L #'string< :key #'symbol-name))
              (format stream (DEUTSCH "exportiert ~:[keine Symbole~:;~:*~d Symbole ~]"
                              ENGLISH "exports ~[no symbols~:;~:*~:d symbols ~]"
                              FRANCAIS "~[n'exporte pas de symboles~:;exporte~:* ~d symboles ~]")
                      (length L))))
          (if used-by-list
            (format stream
                    (DEUTSCH "an die Package~:[~;s~] ~{~A~^, ~}"
                     ENGLISH "to the package~:[~;s~] ~{~A~^, ~}"
                     FRANCAIS "vers le~:[ paquetage~;s paquetages~] ~{~A~^, ~}")
                    (cdr used-by-list)
                    (mapcar #'package-name used-by-list))
            (format stream
                    (DEUTSCH ", aber keine andere Package benutzt diese Exportierungen"
                     ENGLISH ", but no package uses these exports"
                     FRANCAIS ", mais aucun autre paquetage n'utilise ces exportations")))
          (format stream (DEUTSCH "."
                          ENGLISH "."
                          FRANCAIS "."))))
      (format stream (DEUTSCH "eine gel�schte Package."
                      ENGLISH "a deleted package."
                      FRANCAIS "un paquetage �limin�."))))
  (:method ((obj hash-table) (stream stream))
    (format stream (DEUTSCH "eine Hash-Tabelle mit ~S Eintr~:*~[�gen~;ag~:;�gen~]."
                    ENGLISH "a hash table with ~S entr~:@P."
                    FRANCAIS "un tableau de hachage avec ~S entr�e~:*~[s~;~:;s~].")
            (hash-table-count obj)))
  (:method ((obj readtable) (stream stream))
    (format stream (DEUTSCH "~:[eine ~;die Common-Lisp-~]Readtable."
                    ENGLISH "~:[a~;the Common Lisp~] readtable."
                    FRANCAIS "~:[un~;le~] tableau de lecture~:*~:[~; de Common Lisp~].")
            (equalp obj (copy-readtable))))
  (:method ((obj pathname) (stream stream))
    (format stream (DEUTSCH "ein ~:[~;portabler ~]Pathname~:[.~;~:*, aufgebaut aus:~{~A~}~]"
                    ENGLISH "a ~:[~;portable ~]pathname~:[.~;~:*, with the following components:~{~A~}~]"
                    FRANCAIS "un �pathname�~:[~; portable~]~:[.~;~:*, compos� de:~{~A~}~]")
            (sys::logical-pathname-p obj)
            (mapcan #'(lambda (kw component)
                        (when component
                          (list (format nil "~%~A = ~A"
                                        (symbol-name kw)
                                        (make-pathname kw component)))))
                    '(:host :device :directory :name :type :version)
                    (list (pathname-host obj)
                          (pathname-device obj)
                          (pathname-directory obj)
                          (pathname-name obj)
                          (pathname-type obj)
                          (pathname-version obj)))))
  (:method ((obj random-state) (stream stream))
    (format stream (DEUTSCH "ein Random-State."
                    ENGLISH "a random-state."
                    FRANCAIS "un �random-state�.")))
  (:method ((obj array) (stream stream))
    (let ((rank (array-rank obj))
          (eltype (array-element-type obj)))
      (format stream
              (DEUTSCH "ein~:[~; einfacher~] ~A-dimensionaler Array"
               ENGLISH "a~:[~; simple~] ~A dimensional array"
               FRANCAIS "une matrice~:[~; simple~] � ~A dimension~:P")
              (simple-array-p obj) rank)
      (when (eql rank 1)
        (format stream (DEUTSCH " (Vektor)"
                        ENGLISH " (vector)"
                        FRANCAIS " (vecteur)")))
      (unless (eq eltype 'T)
        (format stream (DEUTSCH " von ~:(~A~)s"
                        ENGLISH " of ~(~A~)s"
                        FRANCAIS " de ~(~A~)s")
                eltype))
      (when (adjustable-array-p obj)
        (format stream (DEUTSCH ", adjustierbar"
                        ENGLISH ", adjustable"
                        FRANCAIS ", ajustable")))
      (when (plusp rank)
        (format stream (DEUTSCH ", der Gr��e ~{~S~^ x ~}"
                        ENGLISH ", of size ~{~S~^ x ~}"
                        FRANCAIS ", de grandeur ~{~S~^ x ~}")
                (array-dimensions obj))
        (when (array-has-fill-pointer-p obj)
          (format stream
                  (DEUTSCH " und der momentanen L�nge (Fill-Pointer) ~S"
                   ENGLISH " and current length (fill-pointer) ~S"
                   FRANCAIS " et longueur courante (fill-pointer) ~S")
                  (fill-pointer obj))))
      (format stream (DEUTSCH "."
                      ENGLISH "."
                      FRANCAIS "."))))
  (:method ((obj function) (stream stream))
    (ecase (type-of obj)
      #+FFI
      (FOREIGN-FUNCTION
       (format stream (DEUTSCH "eine Foreign-Funktion."
                       ENGLISH "a foreign function."
                       FRANCAIS "une fonction �trang�re."))
       (multiple-value-bind (req opt rest-p key-p keywords other-keys-p)
           (sys::function-signature obj)
         (sys::describe-signature stream req opt rest-p key-p keywords
                                  other-keys-p)))
      (COMPILED-FUNCTION ; SUBR
       (format stream (DEUTSCH "eine eingebaute System-Funktion."
                       ENGLISH "a built-in system function."
                       FRANCAIS "une fonction pr�d�finie du syst�me."))
       (multiple-value-bind (name req opt rest-p keywords other-keys)
           (sys::subr-info obj)
         (when name
           (sys::describe-signature stream req opt rest-p
                                    keywords keywords other-keys))))
      (FUNCTION
       (format stream
               (DEUTSCH "eine ~:[interpret~;compil~]ierte Funktion."
                ENGLISH "a~:[n interpret~; compil~]ed function."
                FRANCAIS "une fonction ~:[interpr�t~;compil~]�e.")
               (compiled-function-p obj))
       (if (compiled-function-p obj)
         (multiple-value-bind (req opt rest-p key-p keywords other-keys-p)
             (sys::signature obj)
           (sys::describe-signature stream req opt rest-p key-p keywords
                                    other-keys-p)
           (format stream (DEUTSCH "~%~v,vtMehr Information durch Auswerten von ~{~S~^ oder ~}."
                           ENGLISH "~%~v,vtFor more information, evaluate ~{~S~^ or ~}."
                           FRANCAIS "~%~v,vtPour obtenir davantage d'information, �valuez ~{~S~^ ou ~}.")
                   *describe-nesting* *print-indent-lists*
                   `((DISASSEMBLE #',(sys::closure-name obj)))))
         (let ((doc (sys::%record-ref obj 2)))
           (format stream (DEUTSCH "~%~v,vtArgumentliste: ~S"
                           ENGLISH "~%~v,vtargument list: ~S"
                           FRANCAIS "~%~v,vtListe des arguments: ~S")
                   *describe-nesting* *print-indent-lists*
                   (car (sys::%record-ref obj 1)))
           (when doc
             (format stream (DEUTSCH "~%~v,vtDokumentation: ~A"
                             ENGLISH "~%~v,vtdocumentation: ~A"
                             FRANCAIS "~%~v,vtDocumentation: ~A")
                     *describe-nesting* *print-indent-lists*
                     doc))))))))

(defun describe (obj &optional stream)
  (cond ((eq stream 'nil) (setq stream *standard-output*))
        ((eq stream 't) (setq stream *terminal-io*)))
  (if (member obj *describe-done* :test #'eq)
    (format stream (DEUTSCH "~%~v,vt~S [siehe oben]"
                    ENGLISH "~%~v,vt~S [see above]"
                    FRANCAIS "~%~v,vt~S [voir en haut]")
            (1+ *describe-nesting*) *print-indent-lists* obj)
    (let ((*describe-nesting* (1+ *describe-nesting*))
          (*describe-done* (cons obj *describe-done*))
          (*print-circle* t))
      (format stream
              (DEUTSCH "~%~v,vt~a ist "
               ENGLISH "~%~v,vt~a is "
               FRANCAIS "~%~v,vt~a est ")
              *describe-nesting* *print-indent-lists*
              (sys::write-to-short-string obj sys::*prin-linelength*))
      (describe-object obj stream)))
  (values))

;;-----------------------------------------------------------------------------
;; APROPOS

(defun apropos-list (string &optional (package nil))
  (let* ((L nil)
         (fun #'(lambda (sym)
                  (when
                      #| (search string (symbol-name sym) :test #'char-equal) |#
                      (sys::search-string-equal string sym) ; 15 mal schneller!
                    (push sym L)
                ) )
        ))
    (if package
      (system::map-symbols fun package)
      (system::map-all-symbols fun)
    )
    (stable-sort (delete-duplicates L :test #'eq :from-end t)
                 #'string< :key #'symbol-name
    )
) )

(defun apropos (string &optional (package nil))
  (dolist (sym (apropos-list string package))
    (print sym)
    (when (fboundp sym)
      (write-string "   ")
      (write-string (fbound-string sym))
    )
    (when (boundp sym)
      (write-string "   ")
      (if (constantp sym)
        (write-string (DEUTSCH "Konstante"
                       ENGLISH "constant"
                       FRANCAIS "constante")
        )
        (write-string (DEUTSCH "Variable"
                       ENGLISH "variable"
                       FRANCAIS "variable")
    ) ) )
    (when (or (get sym 'system::type-symbol)
              (get sym 'system::defstruct-description)
          )
      (write-string "   ")
      (write-string (DEUTSCH "Typ"
                     ENGLISH "type"
                     FRANCAIS "type")
    ) )
    (when (get sym 'clos::closclass)
      (write-string "   ")
      (write-string (DEUTSCH "Klasse"
                     ENGLISH "class"
                     FRANCAIS "classe")
    ) )
  )
  (values)
)

; Liefert die Signatur eines funktionalen Objekts, als Werte:
; 1. req-anz
; 2. opt-anz
; 3. rest-p
; 4. key-p
; 5. keyword-list
; 6. allow-other-keys-p
(defun function-signature (obj)
  (if (sys::closurep obj)
    (if (compiled-function-p obj)
      ; compilierte Closure
      (multiple-value-bind (req-anz opt-anz rest-p key-p keyword-list allow-other-keys-p)
          (sys::signature obj) ; siehe compiler.lsp
        (values req-anz opt-anz rest-p key-p keyword-list allow-other-keys-p)
      )
      ; interpretierte Closure
      (let ((clos_keywords (sys::%record-ref obj 16)))
        (values (sys::%record-ref obj 12) ; req_anz
                (sys::%record-ref obj 13) ; opt_anz
                (sys::%record-ref obj 19) ; rest_flag
                (not (numberp clos_keywords))
                (if (not (numberp clos_keywords)) (copy-list clos_keywords))
                (sys::%record-ref obj 18) ; allow_flag
      ) )
    )
    (cond #+FFI
          ((eq (type-of obj) 'FOREIGN-FUNCTION)
           (values (sys::foreign-function-signature obj) 0 nil nil nil nil)
          )
          (t
           (multiple-value-bind (name req-anz opt-anz rest-p keywords allow-other-keys)
               (sys::subr-info obj)
             (if name
               (values req-anz opt-anz rest-p keywords keywords allow-other-keys)
               (error (DEUTSCH "~S: ~S ist keine Funktion."
                       ENGLISH "~S: ~S is not a function."
                       FRANCAIS "~S : ~S n'est pas une fonction.")
                      'function-signature obj
               )
) ) )     )) )

(defun signature-to-list (req-anz opt-anz rest-p keyword-p keywords
                          allow-other-keys)
  (let ((args '()) (count -1))
      (dotimes (i req-anz)
      (push (intern (format nil "ARG~D" (incf count)) :sys) args))
      (when (plusp opt-anz)
        (push '&OPTIONAL args)
        (dotimes (i opt-anz)
        (push (intern (format nil "ARG~D" (incf count)) :sys) args)))
      (when rest-p
        (push '&REST args)
      (push 'other-args args))
      (when keyword-p
        (push '&KEY args)
      (dolist (kw keywords) (push kw args))
      (when allow-other-keys (push '&ALLOW-OTHER-KEYS args)))
    (nreverse args)))

(defun arglist (func)
  (multiple-value-call #'signature-to-list (function-signature func)))

(defun describe-signature (s req-anz opt-anz rest-p keyword-p keywords
                           allow-other-keys)
  (when s
    (format s (DEUTSCH "~%~v,vtArgumentliste: "
               ENGLISH "~%~v,vtArgument list: "
               FRANCAIS "~%~v,vtListe des arguments : ")
            *describe-nesting* *print-indent-lists*))
  (format s "(~{~A~^ ~})"
          (signature-to-list req-anz opt-anz rest-p keyword-p keywords
                             allow-other-keys)))

;; DOCUMENTATION mit abfragen und ausgeben??
;; function, variable, type, structure, setf

; Gibt object in einen String aus, der nach M�glichkeit h�chstens max Zeichen
; lang sein soll.
(defun write-to-short-string (object max)
  ; Methode: probiere
  ; level = 0: length = 0,1,2
  ; level = 1: length = 1,2,3,4
  ; level = 2: length = 2,...,6
  ; usw. bis maximal level = 16.
  ; Dabei level m�glichst gro�, und bei festem level length m�glichst gro�.
  (if (or (numberp object) (symbolp object)) ; von length und level unbeeinflusst?
    (write-to-string object)
    (macrolet ((minlength (level) `,level)
               (maxlength (level) `(* 2 (+ ,level 1))))
      ; Um level m�glist gro� zu bekommen, dabei length = minlength w�hlen.
      (let* ((level ; Bin�rsuche nach dem richtigen level
               (let ((level1 0) (level2 16))
                 (loop
                   (when (= (- level2 level1) 1) (return))
                   (let ((levelm (floor (+ level1 level2) 2)))
                     (if (<= (length (write-to-string object :level levelm :length (minlength levelm))) max)
                       (setq level1 levelm) ; levelm passt, probiere gr��ere
                       (setq level2 levelm) ; levelm passt nicht, probiere kleinere
                 ) ) )
                 level1
             ) )
             (length ; Bin�rsuche nach dem richtigen length
               (let ((length1 (minlength level)) (length2 (maxlength level)))
                 (loop
                   (when (= (- length2 length1) 1) (return))
                   (let ((lengthm (floor (+ length1 length2) 2)))
                     (if (<= (length (write-to-string object :level level :length lengthm)) max)
                       (setq length1 lengthm) ; lengthm passt, probiere gr��ere
                       (setq length2 lengthm) ; lengthm passt nicht, probiere kleinere
                 ) ) )
                 length1
            )) )
        (write-to-string object :level level :length length)
) ) ) )
