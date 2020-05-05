;; -*- coding: utf-8; lexical-bingding: t; -*-

;; Without this comment emacs25 adds (package-initialize) here
;; (package-initialize)

(let* ((minver "25.1"))
  (when (version< emacs-version minver)
    (error "Emacs v%s or higher is required." minver)))

(defvar best-gc-cons-threshold
  4000000
  "Best default gc threshold value. Should NOT be too big!")

;; don't GC during startup to save time
(setq gc-cons-threshold most-positive-fixnum)

(setq emacs-load-start-time (current-time))

(with-eval-after-load 'enriched-decode
  (defun enriched-decode-display-prop (start end &optional param)
    (list start end)))

;;------------------------------------------------------------------------
;; Which functionality to enable (use t or nil for true and false)
;;------------------------------------------------------------------------
(setq *is-a-mac* (eq system-type 'darwin))
(setq *win64* (eq system-type 'windows-nt))
(setq *cygwin* (eq system-type 'cygwin))
(setq *linux* (or (eq system-type 'gnu/linux) (eq system-type 'linux)) )
(setq *unix* (or *linux* (eq system-type 'usg-unix-v) (eq system-type 'berkeley-unix)) )
(setq *emacs24* (>= emacs-major-version 24))
(setq *emacs25* (>= emacs-major-version 25))
(setq *emacs26* (>= emacs-major-version 26))
(setq *no-memory* (cond
                   (*is-a-mac*
                    ;; @sec https://discussions.apple.com/thread/1753088
                    ;; "sysctl -n hw.physmem" does not work
                    (<= (string-to-number (shell-command-to-string "sysctl -n hw.memsize"))
                        (* 4 1024 1024)))
                   (*linux* nil)
                   (t nil)))

(defconst my-emacs-d (file-name-as-directory user-emacs-directory)
  "Directory of emacs.d")

(defconst my-site-lisp-dir (concat my-emacs-d "site-lisp")
  "Directory of site-lisp")

(defconst my-lisp-dir (concat my-emacs-d "lisp")
  "Directory of lisp")

;; Emacs25 does gc too frequently
(when *emacs25*
  ;;(setq garbage-collection-messages t) ; for debug
  (setq best-gc-cons-threshold (* 64 1024 1024))
  (setq gc-cons-percentage 0.5)
  (run-with-idle-timer 5 t #'garbage-collect))

(defun my-vc-merge-p ()
  (boundp 'startup-now))

(defun require-init (pkg &optional maybe-disabled)
  "Load PKG if MAYBE-DISABLED is nil or it's nil but start up in normal slowly."
  (when (or (not maybe-disabled) (not (my-vc-merge-p)))
    (load (file-truename (format "%s/%s" my-lisp-dir pkg))t t)))

(defun local-require (pkg)
  "Require PKG in site-lisp directory."
  (unless (featurep pkg)
    (load (expand-file-name
           (cond
            ((eq pkg 'go-mode-load)
             (format "%s/go-mode/%s" my-site-lisp-dir pkg))
            (t
             (format "%s/%s/%s" my-site-lisp-dir pkg pkg))))
          t t)))

;; *Message* buffer should be writable in 24.4+
(defadvice switch-to-buffer (after switch-to-buffer-after-hack activate)
  (if (string= "*Message*" (buffer-name))
      (read-only-mode -1)))

(let* ((file-name-handler-alist nil))
  (require-init 'init-autoload))