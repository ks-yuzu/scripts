#!/usr/local/bin/emacs-26.0.91 --script

;; make backup files and autosave files in ~/.bak
(setq make-backup-files t)
(add-to-list 'backup-directory-alist         ; backup~
       (cons "\\.*$" (expand-file-name "~/.emacs.d/backup/")))

(setq auto-save-file-name-transforms ; #autosave#
       `((".*", (expand-file-name "~/.emacs.d/autosave/") t)))


(setq load-path
      (append '("~/.emacs.d/inits/")
			  load-path))

(load "setting-org-mode")
(require 'org)
(find-file (car command-line-args-left))
(org-latex-export-to-pdf)
