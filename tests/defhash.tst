;; -*- Lisp -*-

(define-hash-table-test string string= sxhash)
string

(let ((h (make-hash-table :test 'string)))
  (list
   (setf (gethash "foo" h) 10)
   (gethash "zot" h)
   (gethash "foo" h)
   (gethash "FOO" h)))
(10 NIL 10 NIL)

(let ((h (make-hash-table :test '(string-equal . sxhash))))
  (list
   (setf (gethash "foo" h) 10)
   (gethash "zot" h)
   (gethash "foo" h)
   (gethash "FOO" h)))
(10 NIL 10 10)

(let ((h (make-hash-table
          :test `(,(lambda (a b) (print (list '= a b)) (= a b)) .
                  ,(lambda (x) (let ((z (sxhash (coerce x 'double-float))))
                                 (print (list x z)) z))))))
  (list
   (setf (gethash 100 h) "foo")
   (gethash 10 h)
   (setf (gethash 10 h) "bar")
   (gethash 100 h)
   (gethash 100d0 h)
   (gethash 10f0 h)))
("foo" NIL "bar" "foo" "foo" "bar")

#+nil
(let ((h (make-hash-table
          :test `(= . ,(lambda (x) (sxhash (coerce x 'short-float)))))))
  (loop :for i :from 0 :to 1000
    :do (setf (gethash i h) (format nil "~r" i)))
  (loop :for i :from 0 :to 1000
    :unless (string= (gethash (float i 1d0)) (gethash (float i 1s0)))
    :collect i))
nil

#+nil
(let ((h (make-hash-table
          :test `(,(lambda (a b) (print (list '= a b)) (= a b)) .
                  ,(lambda (x) (let ((z (sxhash (coerce x 'double-float))))
                                 (print (list x z)) z))))))
  (loop :for i :from 0 :to 1000
    :do (setf (gethash i h) (format nil "~r" i)))
  (loop :for i :from 0 :to 1000
    :unless (string= (gethash (float i 1d0)) (gethash (float i 1s0)))
    :collect i))
nil
