;;; handle the posix functions
;;; Sam Steingold 1999-2008

(defpackage #:posix
  (:use #:common-lisp #:ext)
  (:nicknames #:os)
  (:import-from "SYS" sys::process-id)
  (:shadowing-import-from "EXPORTING" #:defstruct)
  (:export
   #:resolve-host-ipaddr #:bogomips #:loadavg #:mkstemp #:mkdtemp
   #:stream-lock #:with-stream-lock #:duplicate-handle #:copy-file
   #:file-owner #:physical-memory #:stream-options #+unix #:string-time
   #+(or :win32 :cygwin) #:file-properties #+unix #:make-xterm-io-stream
   #:priority #:openlog #:setlogmask #:syslog #:closelog #:process-id #:getppid
   #:getsid #:setsid #:getpgrp #:setpgrp #:setreuid #:setregid #:kill #:sync
   #:errno #:strerror #:gethostid
   #:erf #:erfc #:j0 #:j1 #:jn #:y0 #:y1 #:yn #:tgamma #:lgamma #:ffs))

(pushnew :syscalls *features*)
(provide "syscalls")
(in-package #:posix)

(setf (documentation (find-package '#:posix) 'sys::impnotes) "syscalls")

;;; ============================================================
#+unix (progn
(export '(endutxent getutxent getutxid getutxline pututxline setutxent))
(defstruct (utmpx (:constructor make-utmpx (type user id line pid host tv)))
  type user id line pid host tv)
)
;;; ============================================================
#+unix (progn
(export '(uid gid euid egid pgid groups))
(defsetf uid posix::%setuid)
(defsetf gid posix::%setgid)
(defsetf euid posix::%seteuid)
(defsetf egid posix::%setegid)
(defsetf pgid posix::%setpgid)
(defsetf groups posix::%setgroups)
)
;;; ============================================================
(defmacro with-stream-lock ((stream &rest options) &body body)
  "Lock the stream, execute the body, unlock the stream."
  `(unwind-protect (progn (stream-lock ,stream t ,@options) ,@body)
     (stream-lock ,stream nil ,@options)))
;;; ============================================================
(defun syslog (severity facility format &rest args)
  (%syslog severity facility (apply #'format nil format args)))
;; A compiler macro here is better than a simple (declaim (inline syslog))
;; because when the format string is a string literal, the inliner doesn't
;; produce optimal results.
(define-compiler-macro syslog (severity facility format &rest args)
  `(%syslog ,severity ,facility (format nil ,format ,@args)))
;;; ============================================================
(defsetf priority (pid &optional which) (value)
  `(%set-priority ,value ,pid ,which))
;;; ============================================================
(defstruct (hostent (:constructor
                     make-hostent (name aliases addr-list addrtype)))
  "see gethostbyname(3) for details"
  (name "" :type simple-string :read-only t)
  (aliases nil :type list :read-only t)
  (addr-list nil :type list :read-only t)
  (addrtype 2 :type fixnum :read-only t))

;;; ============================================================
#+unix (export '(crypt encrypt setkey mknod))

#+unix
(defstruct (user-info (:constructor
                       make-user-info (login-id passwd uid gid full-name
                                       home-dir shell)))
  "see <pwd.h> for details"
  (login-id  "" :type simple-string :read-only t)
  (passwd    "" :type simple-string :read-only t)
  (uid        0 :type (unsigned-byte 32) :read-only t)
  (gid        0 :type (unsigned-byte 32) :read-only t)
  (full-name "" :type simple-string :read-only t)
  (home-dir  "" :type simple-string :read-only t)
  (shell     "" :type simple-string :read-only t))

#+unix
(defstruct (group-info (:constructor make-group-info (name gid members)))
  "see <grp.h> for details"
  (name    "" :type simple-string :read-only t)
  (gid      0 :type (unsigned-byte 32) :read-only t)
  (members () :type list :read-only t))
;;; ============================================================
(export '(set-file-stat convert-mode umask))

(defstruct (file-stat
             (:constructor
              make-file-stat (file dev ino mode nlink uid gid rdev size
                              blksize blocks atime mtime ctime)))
  (file    nil :read-only t)
  (dev       0 :type (unsigned-byte 32) :read-only t)
  (ino       0 :type (unsigned-byte 32) :read-only t)
  (mode    nil :type list :read-only t)
  (nlink     1 :type (unsigned-byte 32) :read-only t)
  (uid     nil :type (or null (unsigned-byte 32)) :read-only t)
  (gid     nil :type (or null (unsigned-byte 32)) :read-only t)
  (rdev    nil :type (or null (unsigned-byte 32)) :read-only t)
  (size      0 :type (unsigned-byte 32) :read-only t)
  (blksize nil :type (or null (unsigned-byte 32)) :read-only t)
  (blocks  nil :type (or null (unsigned-byte 32)) :read-only t)
  (atime     0 :type (integer 0) :read-only t)
  (mtime     0 :type (integer 0) :read-only t)
  ;; win32: creation time
  ;; unix: inode change time
  (ctime     0 :type (integer 0) :read-only t))

;;; ============================================================
(defstruct (stat-vfs
             (:constructor
              make-stat-vfs (file bsize frsize blocks bfree bavail files
                             ffree favail fsid flag namemax vol-name fs-type)))
  (file    nil :read-only t)
  (bsize   nil :type (or null (unsigned-byte 32)) :read-only t)
  (frsize  nil :type (or null (unsigned-byte 32)) :read-only t)
  (blocks  nil :type (or null (unsigned-byte 32)) :read-only t)
  (bfree   nil :type (or null (unsigned-byte 32)) :read-only t)
  (bavail  nil :type (or null (unsigned-byte 32)) :read-only t)
  (files   nil :type (or null (unsigned-byte 32)) :read-only t)
  (ffree   nil :type (or null (unsigned-byte 32)) :read-only t)
  (favail  nil :type (or null (unsigned-byte 32)) :read-only t)
  (fsid    nil :type (or null (unsigned-byte 32)) :read-only t)
  (flag    nil :type list :read-only t)
  (namemax nil :type (or null (unsigned-byte 32)) :read-only t)
  (vol-name nil :type (or null string) :read-only t)
  (fs-type nil :type (or null string) :read-only t))
;;; ============================================================
#+unix (export '(sysconf confstr pathconf))
#+unix
(defstruct (uname (:constructor make-uname (sysname nodename release
                                            version machine)))
  "see uname(2) for details"
  (sysname      "" :type simple-string :read-only t)
  (nodename     "" :type simple-string :read-only t)
  (release      "" :type simple-string :read-only t)
  (version      "" :type simple-string :read-only t)
  (machine      "" :type simple-string :read-only t))
;;; ============================================================
#+unix (progn
(defstruct (rlimit (:constructor make-rlimit (cur max)))
  "see getrlimit(2) for details"
  (cur nil :type (or null (unsigned-byte 32)) :read-only t)
  (max nil :type (or null (unsigned-byte 32)) :read-only t))

(defsetf rlimit (what) (cur max) `(set-rlimit ,what ,cur ,max))

(defstruct (usage (:constructor
                   make-usage (user-time system-time max-rss
                               shared-memory data-memory stack-memory
                               minor-page-faults major-page-faults num-swaps
                               blocks-input blocks-output
                               messages-sent messages-received signals
                               context-switches-voluntary
                               context-switches-involuntary)))
  "see getrusage(3) for details"
  (user-time 0.0d0 :type double-float :read-only t)
  (system-time 0.0d0 :type double-float :read-only t)
  (max-rss 0 :type (signed-byte 32) :read-only t)
  (shared-memory 0 :type (signed-byte 32) :read-only t) ; kB-sec
  (data-memory 0 :type (signed-byte 32) :read-only t) ; kB-sec
  (stack-memory 0 :type (signed-byte 32) :read-only t) ; kB-sec
  (minor-page-faults 0 :type (signed-byte 32) :read-only t)
  (major-page-faults 0 :type (signed-byte 32) :read-only t)
  (num-swaps 0 :type (signed-byte 32) :read-only t)
  (blocks-input 0 :type (signed-byte 32) :read-only t)
  (blocks-output 0 :type (signed-byte 32) :read-only t)
  (messages-sent 0 :type (signed-byte 32) :read-only t)
  (messages-received 0 :type (signed-byte 32) :read-only t)
  (signals 0 :type (signed-byte 32) :read-only t)
  (context-switches-voluntary 0 :type (signed-byte 32) :read-only t)
  (context-switches-involuntary 0 :type (signed-byte 32) :read-only t))
)

;;; ============================================================
(export '(convert-attributes))

(defstruct (file-info (:constructor make-file-info
                                    (attributes ctime atime wtime
                                     size name name-short)))
  (attributes nil :read-only t)
  (ctime nil :read-only t) (atime nil :read-only t) (wtime nil :read-only t)
  (size nil :read-only t) (name nil :read-only t) (name-short nil :read-only t))

#-(or win32 cygwin)
(setf (fdefinition 'convert-attributes) #'convert-mode)
#-(or win32 cygwin)
(defun file-info (path)
  (let ((file-stat (file-stat path)))
    (make-file-info (file-stat-mode file-stat) ; attributes
                    (file-stat-ctime file-stat) ; ctime
                    (file-stat-atime file-stat) ; atime
                    (file-stat-mtime file-stat) ; wtime
                    (file-stat-size file-stat)  ; size
                    (file-stat-file file-stat)  ; name
                    (file-stat-file file-stat)))) ; name-short
;;; ============================================================
#+(or win32 cygwin) (progn
(export '(make-shortcut))

(defstruct (shortcut-info
             (:constructor make-shortcut-info
                           (original path stat working-directory arguments
                            show-command icon description hot-key)))
  (original nil :read-only t)
  (path nil :read-only t)
  (working-directory nil :read-only t)
  (arguments nil :read-only t)
  (show-command nil :read-only t)
  (icon nil :read-only t)
  (description nil :read-only t)
  (hot-key nil :read-only t)
  (stat nil :read-only t))

(defstruct (system-info
             (:constructor make-system-info
                           (processor-architecture page-size
                            minimum-application-address
                            maximum-application-address
                            active-processor-mask number-of-processors
                            allocation-granularity
                            processor-level processor-revision)))
  (processor-architecture nil :read-only t)
  (page-size nil :read-only t)
  (minimum-application-address nil :read-only t)
  (maximum-application-address nil :read-only t)
  (active-processor-mask nil :read-only t)
  (number-of-processors nil :read-only t)
  (allocation-granularity nil :read-only t)
  (processor-level nil :read-only t)
  (processor-revision nil :read-only t))

(defstruct (version
             (:constructor make-version
                           (major minor build platform service-pack
                            service-pack-major service-pack-minor
                            suites product-type)))
  (major nil :read-only t)
  (minor nil :read-only t)
  (build nil :read-only t)
  (platform nil :read-only t)
  (service-pack nil :read-only t)
  (service-pack-major nil :read-only t)
  (service-pack-minor nil :read-only t)
  (suites nil :read-only t)
  (product-type nil :read-only t))

(defstruct (memory-status
             (:conc-name memstat-)
             (:constructor mkmemstat
                           (total-physical avail-physical total-page
                            avail-page total-virtual avail-virtual)))
  (total-physical 0 :type (integer 0) :read-only t)
  (avail-physical 0 :type (integer 0) :read-only t)
  (total-page 0 :type (integer 0) :read-only t)
  (avail-page 0 :type (integer 0) :read-only t)
  (total-virtual 0 :type (integer 0) :read-only t)
  (avail-virtual 0 :type (integer 0) :read-only t))

)

(defun physical-memory ()
  "Return 2 values: TOTAL and AVAILABLE physical memory."
  #+unix (let ((page-size (sysconf :PAGESIZE)))
           (values (* page-size (sysconf :PHYS-PAGES))
                   (* page-size (sysconf :AVPHYS-PAGES))))
  #+win32 (let ((mem-stat (memory-status)))
            (values (memstat-total-physical mem-stat)
                    (memstat-avail-physical mem-stat)))
  #-(or unix win32)
  (error "~S: only ~S and ~S are supported" 'physical-memory :unix :win32))

;;;--------------------------------------------------------------------------
;;; service / port map
(defstruct (service (:constructor make-service (name aliases port proto)))
  ;; see getservent(3)
  (name     "" :type string)
  (aliases  () :type list) ; list of strings
  (port      0 :type integer)
  (proto "tcp" :type string))

(unless (fboundp 'service)
(defvar *services*)
(defvar *services-file*
  #+unix "/etc/services"
  #+win32 (string-concat (getenv "WINDIR") "/system32/drivers/etc/services")
  #-(or unix win32)
  (error "~S: only ~S and ~S are supported" '*services-file* :unix :win32))
(defun service (&optional service-name protocol)
  (unless (boundp '*services*)
    (setq *services*
          (with-open-file (in *services-file* :direction :input
                           #+UNICODE :external-format #+UNICODE 'charset:UTF-8)
            (loop :with ret :for line = (read-line in nil nil) :while line :do
              ;; Remove trailing comments.
              (let ((i (position #\# line)))
                (when i (setq line (subseq line 0 i))))
              ;; Split into whitespace separated fields.
              (let ((fields '()))
                (let ((i 0))
                  (loop
                    (let ((i1 (position-if-not #'sys::whitespacep
                                               line :start i)))
                      (unless i1 (return))
                      (let ((i2 (or (position-if #'sys::whitespacep
                                                 line :start i1)
                                    (length line))))
                        (push (subseq line i1 i2) fields)
                        (setq i i2)))))
                (setq fields (nreverse fields))
                (when fields
                  ;; Split second field, of the form "port/proto".
                  (let* ((port+proto (second fields))
                         (i (position #\/ port+proto)))
                    (when i
                      (push
                       (make-service (first fields)
                                     (cddr fields)
                                     (parse-integer (subseq port+proto 0 i))
                                     (subseq port+proto (1+ i)))
                       ret)))))
              :finally (return (nreverse ret))))))
  (etypecase service-name
    (null (mapcar #'copy-service *services*))
    (string
     (or (find-if #'(lambda (se)
                      (and (or (string-equal (service-name se) service-name)
                               (find service-name (service-aliases se)
                                     :test #'string-equal))
                           (or (null protocol)
                               (string-equal (service-proto se) protocol))))
                  *services*)
         (error (SYS::TEXT "service does not exist: ~A/~A")
                service-name protocol)))
    (integer
     (or (find-if #'(lambda (se)
                      (and (= (service-port se) service-name)
                           (or (null protocol)
                               (string-equal (service-proto se) protocol))))
                  *services*)
         (error (SYS::TEXT "service does not exist: ~A/~A")
                service-name protocol)))))
)
(without-package-lock ("SOCKET")
  (sys::deprecate (intern "SOCKET-SERVICE-PORT" "SOCKET") 'service
                  (lambda (&optional sn pr)
                    (let ((ret (service sn pr)))
                      (if (listp ret)
                          (mapcar (lambda (se)
                                    (vector (service-name se)
                                            (service-aliases se)
                                            (service-port se)
                                            (service-proto se)))
                                  ret)
                          (values (service-name ret) (service-aliases ret)
                                  (service-port ret) (service-proto ret)))))))
(without-package-lock ("EXT")
  (export (find-symbol "SOCKET-SERVICE-PORT" "SOCKET") "EXT"))

;;;--------------------------------------------------------------------------
#+unix
(defun make-xterm-io-stream (&key (title "CLISP I/O"))
  (let* ((tmpdir (mkdtemp "/tmp/clisp-x-io-XXXXXX/"))
         (pipe (namestring (merge-pathnames "pipe" tmpdir)))
         xio
         (clos::*enable-clos-warnings* nil))
    (mknod pipe :FIFO :RWXU)
    (setq title (string title))
    ;; - tty tells us what device to use for IO
    ;; - cat holds xterm from quitting and prints the good-bye message
    ;;   (actually, the xterm window disappears before you can read it...)
    (shell (format nil "xterm -n ~s -T ~s -e 'tty >> ~a; cat ~a' &"
                   title title pipe pipe))
    (with-open-file (s pipe :direction :input)
      (setq xio (open (read-line s) :direction :io)))
    ;; GC uses the internal non-generic builtin_stream_close() so
    ;; we cannot rely on GC closing files because we also need to
    ;;  - write something into the pipe to terminate cat and thus xterm and
    ;;  - remove the pipe
    ;; which is done by the :AFTER method below
    (ext:finalize xio #'close)
    (defmethod close :after ((x (eql xio)) &rest junk)
      (declare (ignore x junk))
      (with-open-file (s pipe :direction :output)
        (write-line (SYS::TEXT "Bye.") s))
      (delete-file pipe)
      (delete-directory tmpdir)
      (let ((clos::*enable-clos-warnings* nil))
        (remove-method #'close (find-method #'close '(:after) `((eql ,xio))))))
    xio))

;;;--------------------------------------------------------------------------
#+FFI (progn
(export '(fopen fdopen freopen fclose fflush ; fgetc fputc ungetc
          clearerr feof ferror fileno stdin stdout stderr))
(defconstant stdin (posix::%stdio 0))
(defconstant stdout (posix::%stdio 1))
(defconstant stderr (posix::%stdio 2))
)
;;;--------------------------------------------------------------------------
(defun ffs (n) (integer-length (logand n (- n))))
;; http://www.opengroup.org/onlinepubs/009695399/functions/ffs.html
;; this lisp implementation is about 10% faster than using FFI:
;; (ffi:def-call-out ffs (:name "ffs") (:arguments (i ffi:int))
;;   (:return-type ffi:int) (:language :stdc) (:library :default))
;; and it also supports bignums.
(unless (fboundp 'os:tgamma)
  ;; https://sourceforge.net/tracker/?func=detail&atid=101355&aid=1966375&group_id=1355
  (defun os:tgamma (x)
    (multiple-value-bind (lg sg) (os:lgamma x)
      (* (or sg 1) (exp lg)))))
;;;--------------------------------------------------------------------------
(setf (package-lock "EXT") nil)
(use-package '("POSIX") "EXT")
(without-package-lock ("SYS") (shadow '("VERSION") "SYS"))
(ext:re-export "POSIX" "EXT")
(pushnew "POSIX" custom:*system-package-list* :test #'string=)
(setf (package-lock custom:*system-package-list*) t)
