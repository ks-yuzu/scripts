#!/usr/local/bin/emacs-26.0.91 --script

;; make backup files and autosave files in ~/.bak
(setq make-backup-files t)
(add-to-list 'backup-directory-alist         ; backup~
       (cons "\\.*$" (expand-file-name "~/.emacs.d/backup/")))

(setq auto-save-file-name-transforms ; #autosave#
       `((".*", (expand-file-name "~/.emacs.d/autosave/") t)))


(setq load-path
      (append load-path
              '("~/.emacs.d/inits/")
              '("~/.emacs.d/elpa.bak/org-20170918")
              '("~/.emacs.d/elpa/ox-reveal-20161027.226")
              '("~/.emacs.d/elpa/htmlize-20180412.1244")
			  ))

(require 'org)
(require 'ox-reveal)
(load "setting-org-mode")
(find-file (car command-line-args-left))
(org-reveal-export-to-html)
