;; -*- Lisp -*-
;; some tests for ZLIB
;; clisp -K full -E utf-8 -q -norc -i ../tests/tests -x '(run-test "zlib/test")'

(format t "~&zlib version: ~S~%" (zlib:z-version))
NIL

(let ((v (make-array 1024 :element-type '(unsigned-byte 8))) c)
  (dotimes (i 1024) (setf (aref v i) 0))
  (print (zlib:compress-bound 1024))
  (ext:times (setq c (zlib:compress v)))
  (print (length c))
  (equalp v (zlib:uncompress c 1024)))
T

(let ((v (make-array 1024 :element-type '(unsigned-byte 8))) c
      (cb (zlib:compress-bound 1024)))
  (dotimes (i 1024) (setf (aref v i) (random 256)))
  (print cb)
  (ext:times (setq c (zlib:compress v)))
  (print (length c))
  (unless (= cb (length c)) (warn "zlib compresses random vectors!"))
  (equalp v (zlib:uncompress c 1050)))
T

(let ((v (make-array 1024 :element-type '(unsigned-byte 8))))
  (dotimes (i 1024) (setf (aref v i) (ash i -5)))
  (print (zlib:compress-bound 1024))
  (loop :for level :from 0 :to 9
    :for c = (zlib:compress v :level level)
    :do (print (list level (length c)))
    :always (equalp v (zlib:uncompress c 1024))))
T
