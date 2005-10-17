;; -*- Lisp -*-
;; some tests for clx/new-clx
;; clisp -K full -E utf-8 -q -norc -i ../tests/tests -x '(run-test "clx/new-clx/test")'

(defparameter *dpy* (show (xlib:open-display ""))) *dpy*

(xlib:closed-display-p *dpy*) NIL

(listp (show (xlib:display-plist *dpy*))) T

(stringp (show (xlib:display-host *dpy*))) T

;(listp (show (multiple-value-list (xlib:pointer-control *dpy*)))) T
(listp (show (xlib:pointer-mapping *dpy*))) T

(multiple-value-bind (kc% b% bp bd lm gar arm) (xlib:keyboard-control *dpy*)
  (show (list kc% b% bp bd lm gar arm) :pretty t)
  (xlib:change-keyboard-control
   *dpy* :KEY-CLICK-PERCENT kc%
   :BELL-PERCENT b% :BELL-PITCH bp :BELL-DURATION bd
   :KEY 80 :AUTO-REPEAT-MODE (if (plusp (aref arm 80)) :on :off)))
NIL

(xlib:bell *dpy* 50) NIL

(let ((modifiers (show (multiple-value-list (xlib:modifier-mapping *dpy*)))))
  (apply #'xlib:set-modifier-mapping *dpy*
         (mapcan #'list '(:SHIFT :LOCK :CONTROL :MOD1 :MOD2 :MOD3 :MOD4 :MOD5)
                 modifiers)))
:SUCCESS

(show (multiple-value-list (xlib:keysym->keycodes *dpy* 65))) (38)
(show (multiple-value-list (xlib:keysym->keycodes *dpy* #xFF52))) (148 98 80) ; UP
(show (xlib:keysym 80 98 148)) #xFF52
(show (xlib:keysym "Up")) #xFF52

(let ((access (show (xlib:access-control *dpy*))))
  (assert (eq access (setf (xlib:access-control *dpy*) access)))
  t) T

(listp (show (xlib:access-hosts *dpy*) :pretty t)) T
(xlib:add-access-host *dpy* "localhost") NIL
(listp (show (xlib:access-hosts *dpy*) :pretty t)) T
(xlib:remove-access-host *dpy* "localhost") NIL
(listp (show (xlib:access-hosts *dpy*) :pretty t)) T

(xlib:display-force-output *dpy*) NIL
(xlib:display-finish-output *dpy*) NIL
(xlib:display-p (show (xlib:close-display *dpy*))) T
