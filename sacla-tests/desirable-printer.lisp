;; Copyright (C) 2002-2004, Yuji Minejima <ggb01164@nifty.ne.jp>
;; ALL RIGHTS RESERVED.
;;
;; $ Id: desirable-printer.lisp,v 1.4 2004/02/20 07:23:42 yuji Exp $
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

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :upcase)
  (string= (write-to-string '|ZEBRA| :pretty nil :readably t :case :upcase)
           "ZEBRA"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :upcase)
  (string= (write-to-string '|Zebra| :pretty nil :readably t :case :upcase)
           "|Zebra|"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :upcase)
  (string= (write-to-string '|zebra| :pretty nil :readably t :case :upcase)
           "|zebra|"))


(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :upcase)
  (string= (write-to-string '|ZEBRA| :pretty nil :readably t :case :downcase)
           "zebra"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :upcase)
  (string= (write-to-string '|Zebra| :pretty nil :readably t :case :downcase)
           "|Zebra|"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :upcase)
  (string= (write-to-string '|zebra| :pretty nil :readably t :case :downcase)
           "|zebra|"))


(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :upcase)
  (string= (write-to-string '|ZEBRA| :pretty nil :readably t :case :capitalize)
           "Zebra"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :upcase)
  (string= (write-to-string '|Zebra| :pretty nil :readably t :case :capitalize)
           "|Zebra|"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :upcase)
  (string= (write-to-string '|zebra| :pretty nil :readably t :case :capitalize)
           "|zebra|"))

;;

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :downcase)
  (string= (write-to-string '|ZEBRA| :pretty nil :readably t :case :upcase)
           "|ZEBRA|"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :downcase)
  (string= (write-to-string '|Zebra| :pretty nil :readably t :case :upcase)
           "|Zebra|"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :downcase)
  (string= (write-to-string '|zebra| :pretty nil :readably t :case :upcase)
           "ZEBRA"))


(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :downcase)
  (string= (write-to-string '|ZEBRA| :pretty nil :readably t :case :downcase)
           "|ZEBRA|"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :downcase)
  (string= (write-to-string '|Zebra| :pretty nil :readably t :case :downcase)
           "|Zebra|"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :downcase)
  (string= (write-to-string '|zebra| :pretty nil :readably t :case :downcase)
           "zebra"))


(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :downcase)
  (string= (write-to-string '|ZEBRA| :pretty nil :readably t :case :capitalize)
           "|ZEBRA|"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :downcase)
  (string= (write-to-string '|Zebra| :pretty nil :readably t :case :capitalize)
           "|Zebra|"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :downcase)
  (string= (write-to-string '|zebra| :pretty nil :readably t :case :capitalize)
           "Zebra"))


;;
(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :preserve)
  (string= (write-to-string '|ZEBRA| :pretty nil :readably t :case :upcase)
           "ZEBRA"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :preserve)
  (string= (write-to-string '|Zebra| :pretty nil :readably t :case :upcase)
           "Zebra"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :preserve)
  (string= (write-to-string '|zebra| :pretty nil :readably t :case :upcase)
           "zebra"))


(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :preserve)
  (string= (write-to-string '|ZEBRA| :pretty nil :readably t :case :downcase)
           "ZEBRA"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :preserve)
  (string= (write-to-string '|Zebra| :pretty nil :readably t :case :downcase)
           "Zebra"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :preserve)
  (string= (write-to-string '|zebra| :pretty nil :readably t :case :downcase)
           "zebra"))


(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :preserve)
  (string= (write-to-string '|ZEBRA| :pretty nil :readably t :case :capitalize)
           "ZEBRA"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :preserve)
  (string= (write-to-string '|Zebra| :pretty nil :readably t :case :capitalize)
           "Zebra"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :preserve)
  (string= (write-to-string '|zebra| :pretty nil :readably t :case :capitalize)
           "zebra"))


;;
(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :invert)
  (string= (write-to-string '|ZEBRA| :pretty nil :readably t :case :upcase)
           "zebra"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :invert)
  (string= (write-to-string '|Zebra| :pretty nil :readably t :case :upcase)
           "Zebra"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :invert)
  (string= (write-to-string '|zebra| :pretty nil :readably t :case :upcase)
           "ZEBRA"))


(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :invert)
  (string= (write-to-string '|ZEBRA| :pretty nil :readably t :case :downcase)
           "zebra"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :invert)
  (string= (write-to-string '|Zebra| :pretty nil :readably t :case :downcase)
           "Zebra"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :invert)
  (string= (write-to-string '|zebra| :pretty nil :readably t :case :downcase)
           "ZEBRA"))


(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :invert)
  (string= (write-to-string '|ZEBRA| :pretty nil :readably t :case :capitalize)
           "zebra"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :invert)
  (string= (write-to-string '|Zebra| :pretty nil :readably t :case :capitalize)
           "Zebra"))

(let ((*readtable* (copy-readtable nil)))
  (setf (readtable-case *readtable*) :invert)
  (string= (write-to-string '|zebra| :pretty nil :readably t :case :capitalize)
           "ZEBRA"))


