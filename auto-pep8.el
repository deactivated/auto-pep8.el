;;; auto-pep8.el --- minor mode to automatically run pep8 on save

;; Copyright (c) 2012 Mike Spindel <mike@spindel.is>

;; Author: Mike Spindel <mike@spindel.is>

;; auto-pep8.el is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2, or (at your option) any later
;; version.
;;
;; It is distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License along
;; with your copy of Emacs; see the file COPYING.  If not, write to the Free
;; Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.

;;; Commentary:
;;
;; auto-pep8.el automatically runs PEP8 code style checks on save. It
;; depends on python-pep8.el.
;;
;;
;; Usage:
;;
;; (require 'auto-pep8)
;; (add-hook 'python-mode-hook (lambda () (auto-pep8-mode 1)))
;;
;;; Code:

(require 'python-pep8)

(defvar auto-pep8--close-timer nil
  "PEP8 buffer close timer")

(defvar auto-pep8--close-buffer nil
  "Currently displayed PEP8 buffer")

(defvar auto-pep8-options nil
  "Command-line parameters to use when running PEP8")

(defun auto-pep8--start-close-timer ()
  (setq auto-pep8--close-timer
        (run-at-time 3 nil 'auto-pep8--hide-buffer)))

(defun auto-pep8--stop-close-timer ()
  (when auto-pep8--close-timer
    (cancel-timer auto-pep8--close-timer)
    (setq auto-pep8--close-timer nil)))

(defun auto-pep8--buffer-error-p ()
  (save-excursion
    (goto-char (point-min))
    (re-search-forward "\\.py:[0-9]+" nil t)))

(defun auto-pep8--display-buffer (buf)
  (with-current-buffer buf
    (auto-pep8--stop-close-timer)
    (setq auto-pep8--close-buffer buf)
    (display-buffer buf)
    (auto-pep8--start-close-timer)))

(defun auto-pep8--hide-buffer ()
  (unwind-protect
      (let ((pep8-win (and auto-pep8--close-buffer
                           (get-buffer-window auto-pep8--close-buffer t))))
        (when pep8-win
          (cond ((and (boundp 'popwin:popup-window)
                      (eq popwin:popup-window pep8-win))
                 (popwin:close-popup-window))
                ((window-deletable-p pep8-win)
                 (delete-window pep8-win)))
          (bury-buffer auto-pep8--close-buffer)))
    (setq auto-pep8--close-buffer nil
          auto-pep8--close-timer nil)))

(defun auto-pep8--post-compile (buf state)
  (with-current-buffer buf
    (when (and (eq major-mode 'python-pep8-mode)
               (auto-pep8--buffer-error-p))
      (auto-pep8--display-buffer buf))))

(defun auto-pep8--pep8()
  (let ((pep-proc (get-buffer-process python-pep8-last-buffer)))
    (when pep-proc
      (interrupt-process pep-proc)))

  (when (buffer-file-name)
    (let* ((python-pep8-options (append python-pep8-options
                                        auto-pep8-options))
           (buf (pep8))
           (win (get-buffer-window buf)))
      (when (window-deletable-p win)
        (delete-window win)
        (bury-buffer buf)))))

(define-minor-mode auto-pep8-mode
  "Minor mode "
  nil " auto-pep8" nil
  (if auto-pep8-mode
      (progn
        (add-to-list 'compilation-finish-functions 'auto-pep8--post-compile)
        (add-hook 'after-save-hook 'auto-pep8--pep8 nil t))
    (remove-hook 'after-save-hook 'auto-pep8--pep8 t)))

(provide 'auto-pep8)

;;; auto-pep8.el ends here
