;; -*- Lisp -*-
;; some tests for SYSCALLS
;; clisp -E utf-8 -q -norc -i ../tests/tests -x '(run-test "syscalls/test")'

(os:hostent-p (show (os:resolve-host-ipaddr "localhost")))
T

(defparameter *tmp1* (os:mkstemp "syscalls-tests-")) *tmp1*
(defparameter *tmp2* (os:mkstemp "syscalls-tests-")) *tmp2*

(let ((*standard-output* (make-broadcast-stream
                          *standard-output* *tmp1* *tmp2*)))
  (show (write *tmp1* :stream *tmp1*)) (terpri *tmp1*)
  (show (write *tmp2* :stream *tmp2*)) (terpri *tmp2*)
  T)
T

#+unix (find :rdwr (show (os:stream-options *tmp1* :fl))) #+unix :RDWR
#+unix (with-open-file (s *tmp1*) (find :rdonly (show (os:stream-options s :fl)))) #+unix :RDONLY
#+unix (os:stream-options *tmp1* :fd) NIL
#+unix (os:stream-options *tmp1* :fd '(:cloexec)) NIL
#+unix (os:stream-options *tmp1* :fd) #+unix (:cloexec)
#+unix (os:stream-options *tmp1* :fd nil) NIL
#+unix (os:stream-options *tmp1* :fd) NIL

(os:stream-lock *tmp1* t) T
(os:stream-lock *tmp1* nil) NIL

(os:priority (os:process-id))
:NORMAL

#+unix
(listp (show (if (fboundp 'os:sysconf) (os:sysconf) '(no os:sysconf)))) T
#+unix
(listp (show (if (fboundp 'os:confstr) (os:confstr) '(no os:confstr)))) T

#+unix
(listp (show (if (fboundp 'os:usage)
                  (multiple-value-list (os:usage)) '(no os:usage))))
T
#+unix
(listp (show (if (fboundp 'os:rlimit)
                  (multiple-value-list (os:rlimit)) '(no os:rlimit))))
T

#+unix
(os:uname-p (show (os:uname))) T
#+unix
(os:user-data-p (show (os:user-data (ext:getenv "USER")))) T

(os:file-stat-p (show (os:file-stat *tmp1*))) T
(os:file-stat-p (show (os:file-stat (pathname *tmp1*)))) T
(os:set-file-stat *tmp2* :atime t :mtime t) NIL

(os:convert-mode #o0666)
#+unix (:RUSR :WUSR :RGRP :WGRP :ROTH :WOTH)
#+win32 (:RUSR :WUSR 54)
#-(or unix win32) ERROR

(os:convert-mode '(:RWXU #+unix :RWXG #+unix :RWXO))
#+unix #o0777
#+win32 #o0700
#-(or unix win32) ERROR

(os:stat-vfs-p (show (os:stat-vfs *tmp2*))) T

(string= (show #+win32 (ext:string-concat (ext:getenv "USERDOMAIN") "\\"
                                          (ext:getenv "USERNAME"))
               #+unix (ext:getenv "USER")
               #-(or unix win32) ERROR)
         (show (os:file-owner *tmp1*)))
T

(progn (close *tmp1*) (close *tmp2*) T) T

(listp (show (os:copy-file *tmp1* *tmp2* :if-exists :append))) T
(listp (show (os:copy-file *tmp2* *tmp1* :if-exists :append))) T
(listp (show (os:copy-file *tmp1* *tmp2* :if-exists :append))) T
(listp (show (os:copy-file *tmp2* *tmp1* :if-exists :append))) T
(listp (show (os:copy-file *tmp1* *tmp2* :if-exists :append))) T
(listp (show (os:copy-file *tmp2* *tmp1* :if-exists :append))) T
(listp (show (os:copy-file *tmp1* *tmp2* :if-exists :append))) T
(listp (show (os:copy-file *tmp2* *tmp1* :if-exists :append))) T
(listp (show (os:copy-file *tmp1* *tmp2* :if-exists :append))) T
(listp (show (os:copy-file *tmp2* *tmp1* :if-exists :append))) T

(integerp (show (with-open-file (s *tmp1* :direction :input) (file-length s))))
T

(integerp (show (with-open-file (s *tmp2* :direction :input) (file-length s))))
T

#+win32                      ; win32 functions barf on cygwin pathnames
(os:file-info-p (show (os:file-info *tmp2*)))
#+win32 T

#+(or win32 cygwin)
(os:system-info-p (show (os:system-info)))
#+(or win32 cygwin) T
#+(or win32 cygwin)
(os:version-p (show (os:version)))
T
#+(or win32 cygwin)
(os:memory-status-p (show (os:memory-status)))
T

(let ((sysconf #+unix (show (os:sysconf)) #-unix nil))
  ;; guard against broken unixes, like FreeBSD 4.10-BETA
  (if #+unix (and (get sysconf :PAGESIZE)
                  (get sysconf :PHYS-PAGES)
                  (get sysconf :AVPHYS-PAGES))
      #-unix T
      (listp (show (multiple-value-list (os:physical-memory))))
      T))
T

;; test file locking
(let ((buf (make-array 100 :fill-pointer t :adjustable t
                       :element-type 'character)))
  (defun flush-stream (s)
    (setf (fill-pointer buf) 0)
    (loop :for c = (read-char-no-hang s nil nil) :while c
      :do (vector-push-extend c buf))
    (show buf)))
FLUSH-STREAM

(defun proc-send (proc fmt &rest args)
  (apply #'format proc fmt args)
  (terpri proc) (force-output proc) (sleep 1)
  (flush-stream proc))
PROC-SEND

(let* ((argv (ext:argv)) (run (aref argv 0))
       (args (list "-M" (aref argv (1+ (position "-M" argv :test #'string=)))
                   "-norc" "-q")))
  (defparameter *proc1* (ext:run-program run :arguments args
                                         :input :stream :output :stream))
  (defparameter *proc2* (ext:run-program run :arguments args
                                         :input :stream :output :stream))
  (sleep 1)
  (flush-stream *proc1*)
  (flush-stream *proc2*)
  t)
T

(stringp
 (proc-send *proc1* "(setq s (open ~S :direction :output :if-exists :append))"
            (truename *tmp1*)))
T
(stringp
 (proc-send *proc2* "(setq s (open ~S :direction :output :if-exists :append))"
            (truename *tmp1*)))
T

(read-from-string (proc-send *proc1* "(stream-lock s t)")) T
(proc-send *proc2* "(stream-lock s t)")  "" ; blocked

(read-from-string (proc-send *proc1* "(stream-lock s nil)")) NIL ; released
(read-from-string (flush-stream *proc2*)) T             ; acquired

(read-from-string (proc-send *proc1* "(stream-lock s t :block nil)")) NIL
(read-from-string (proc-send *proc2* "(stream-lock s nil)")) NIL ; released
(read-from-string (proc-send *proc1* "(stream-lock s t :block nil)")) T
(read-from-string (proc-send *proc1* "(stream-lock s nil)")) NIL ; released

;; check :rename-and-delete
;; woe32 signals ERROR_SHARING_VIOLATION
;; when renaming a file opened by a different process
#-win32
(let ((inode (show (posix:file-stat-ino (posix:file-stat *tmp1*)))))
  (with-open-stream (s (ext:run-program
                        "tail" :arguments (list "-f" (namestring *tmp1*)
                                                (format nil "--pid=~D"
                                                        (os:process-id)))
                        :output :stream))
    (sleep 1) (flush-stream s)
    (with-open-file (new *tmp1* :direction :output
                         :if-exists :rename-and-delete)
      (= inode (show (posix:file-stat-ino (posix:file-stat new)))))))
#-win32 NIL

(progn (proc-send *proc1* "(close s)~%(ext:quit)")
       (close (two-way-stream-input-stream *proc1*))
       (close (two-way-stream-output-stream *proc1*))
       (close *proc1*) (makunbound '*proc1*) (unintern '*proc1*)
       (proc-send *proc2* "(close s)~%(ext:quit)" )
       (close (two-way-stream-input-stream *proc2*))
       (close (two-way-stream-output-stream *proc2*))
       (close *proc2*) (makunbound '*proc2*) (unintern '*proc2*)
       (delete-file *tmp1*) (makunbound '*tmp1*) (unintern '*tmp1*)
       (delete-file *tmp2*) (makunbound '*tmp2*) (unintern '*tmp2*)
       (fmakunbound 'flush-stream) (unintern 'flush-stream)
       (fmakunbound 'proc-send) (unintern 'proc-send)
       T)
T
