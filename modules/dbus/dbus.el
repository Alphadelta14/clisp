;; convert dbus C headers to clisp ffi forms

(defun dbus-fix-whitespace-and-copy (beg end)
  (interactive "r")
  (narrow-to-region beg end)
  (goto-char (point-min))
  (while (re-search-forward "[ \t\n]+" (point-max) t)
    (replace-match " "))
  (goto-char (point-min))
  (insert ";; ")
  (let ((copy (buffer-substring-no-properties (point) (1- (point-max)))))
    (goto-char (point-max))
    (insert "\n") (setq beg (point))
    (insert copy) (setq end (point)))
  (widen)
  (values beg end))

(defun dbus-fix-pointers ()
  (goto-char (point-min))
  (while (re-search-forward " +\\* *" (point-max) t)
    (replace-match "* "))
  (dolist (c '(("const char*" . "c-string") ("unsigned " . "u")
               ("void*" . "c-pointer") ("void" . "nil")))
    (goto-char (point-min))
    (while (search-forward (car c) (point-max) t)
      (replace-match (cdr c)))))

(defun dbus-fix-arglist ()
  (while (re-search-forward " *\\([^,)]*\\) \\([^ ,)]+\\)[,)]" (point-max) t)
    (replace-match "(\\2 \\1) "))
  (delete-char -1)
  (insert "))"))

(defun dbus-convert-function (beg end)
  "convert a function declaration to a def-call-out"
  (interactive "r")
  (multiple-value-setq (beg end) (dbus-fix-whitespace-and-copy beg end))
  (narrow-to-region beg end)
  (dbus-fix-pointers)
  (goto-char (point-min))
  (unless (looking-at "^\\(.*\\) \\([a-z_0-9]+\\) (")
    (error "no function"))
  (replace-match "(def-call-out \\2 (:return-type \\1)\n  (:arguments ")
  (dbus-fix-arglist)
  (insert "\n")
  (widen))

(defun dbus-remove-C-comment ()
  (goto-char (point-min))
  (while (and (< (point) (point-max))
              (re-search-forward "^ *[*/]* *" (point-max) t))
    (replace-match "")
    (unless (= (point) (point-max)) (forward-char 1)))
  (goto-char (point-min))
  (while (re-search-forward " *\\*+/ *$" (point-max) t)
    (replace-match ""))
  ;(fill-paragraph)
  ;(forward-paragraph)
  (goto-char (point-max))
  (while (and (eolp) (bolp))
    (delete-char -1)))

(defun dbus-convert-comment (beg end)
  "convert a comment to lisp"
  (interactive "r")
  (narrow-to-region beg end)
  (dbus-remove-C-comment)
  (comment-region (point-min) (point-max))
  (widen))

(defun dbus-convert-typedeff (beg end)
  "convert function typedef to a def-c-type"
  (interactive "r")
  (multiple-value-setq (beg end) (dbus-fix-whitespace-and-copy beg end))
  (narrow-to-region beg end)
  (dbus-fix-pointers)
  (goto-char (point-min))
  (unless (looking-at "^typedef \\([^ ]*\\) (\\* \\([A-Za-z_0-9]+\\)) (")
    (error "no typedeff"))
  (setq beg (match-string 2))
  (replace-match "(def-c-type \\2\n  (c-function (:return-type \\1)\n              (:arguments ")
  (dbus-fix-arglist)
  (insert ")\n(def-c-type " beg "* (c-pointer " beg "))\n")
  (widen))

(defun dbus-convert-define (beg end)
  "convert #define to a def-c-const"
  (interactive "r")
  (goto-char beg)
  (let ((def-pos (search-forward "#define ")) doc
        (comment-end (line-beginning-position)))
    (narrow-to-region beg comment-end)
    (dbus-remove-C-comment)
    (widen)
    (setq doc (buffer-substring-no-properties beg (point)))
    (delete-region beg (point))
    (search-forward "#define ")
    (replace-match "(def-c-const ")
    (if (search-forward "[A-Za-z0-9_]*_STRING" (line-end-position) t)
        (insert " (:type c-string)")
        (forward-sexp))
    (just-one-space)
    (insert "; ") ; (comment-indent)
    (beginning-of-line 2)
    (insert "  (:documentation \"" doc "\"))\n")))
