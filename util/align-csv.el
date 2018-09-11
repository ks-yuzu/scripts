#!/usr/local/bin/emacs-25.1.91 --script

(setq load-path
      (append '("~/.emacs.d/elpa/csv-mode-1.6")
			  load-path))

(load "csv-mode")
(require 'csv-mode)
(find-file (car command-line-args-left))
(csv-align-fields t (point-min) (point-max))
(princ (buffer-string))
