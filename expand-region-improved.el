;;; expand-region-improved.el --- Improved expand-region commands -*- lexical-binding: t -*-

;; Copyright (C) 2020-2024 Leo Gaskin

;; Author: Leo Gaskin <leo.gaskin@le0.gs>
;; Created: 26 March 2020
;; Homepage: https://github.com/leotaku/expand-region-improved.el
;; Keywords: convenience expand-region mark region
;; Package-Version: 0.1.0
;; Package-Requires: ((emacs "25.1") (expand-region "0.11.0"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package aims to provide an improvement over the sometimes
;; unpredictable expansion algorithm used by the original
;; expand-region package.

(require 'expand-region)
(require 'seq)

;;; Code:

;;;; Global variables

(defgroup expand-region-improved nil
  "Increase selected region by semantic units."
  :group 'tools)

(defcustom eri/try-expand-list
  '((er/mark-word
     er/mark-symbol
     er/mark-symbol-with-prefix
     er/mark-next-accessor)
    er/mark-method-call
    (er/mark-inside-quotes
     eri/mark-outside-quotes)
    (er/mark-inside-pairs
     er/mark-outside-pairs)
    er/mark-comment
    er/mark-url
    er/mark-email
    eri/mark-line
    eri/mark-block
    mark-page)
  "A list of functions or function groups that are tried when expanding."
  :type '(repeat (choice
                  (symbol :tag "Function" unknown)
                  (repeat :tag "Group" (symbol :tag "Function" unknown)))))

(defconst eri--direction t)
(defconst eri--future-regions :start)
(defconst eri--past-regions nil)

;;;; Improved expansions

;;;###autoload
(defun eri/maximize-region (_arg)
  (interactive "p")
  (let ((eri/try-expand-list '(mark-page)))
    (eri--expand-region)))

;;;###autoload
(defun eri/expand-region (arg)
  "Increase selected region by semantic units, improved.

With prefix ARG expands the region that many times.
If prefix argument is negative calls ‘eri/contract-region’."
  (interactive "p")
  (unless transient-mark-mode
    (transient-mark-mode))
  (eri--prepare-regions arg)
  (if (> arg 0)
      (dotimes (_ arg)
        (eri--expand-region))
    (dotimes (_ (* arg -1))
      (eri--contract-region))))

;;;###autoload
(defun eri/contract-region (arg)
  "Contract the selected region to its previous size, improved.

With prefix ARG contracts that many times.
If prefix argument is negative calls ‘eri/expand-region’."
  (interactive "p")
  (eri/expand-region (* arg -1)))

(defun eri--reset-region ()
  (unless (region-active-p)
    (setq eri--direction t)
    (setq eri--future-regions :start)
    (setq eri--past-regions nil)))

(defun eri--reset-for-mc (&rest list)
  (setq eri--future-regions :start)
  (setq eri--past-regions nil)
  (prog1 list))

(defun eri--prepare-regions (arg)
  (when (listp eri--future-regions)
    (if (> arg 0)
        (progn
          (when (not eri--direction)
            (push (car eri--future-regions) eri--past-regions)
            (setq eri--future-regions (cdr eri--future-regions)))
          (setq eri--direction t))
      (when eri--direction
        (push (car eri--past-regions) eri--future-regions)
        (setq eri--past-regions (cdr eri--past-regions)))
      (setq eri--direction nil))))

(defun eri--expand-region ()
  (cond
   ((eq eri--future-regions :start)
    (setq eri--future-regions (eri--get-all-regions))
    (if (region-active-p)
        (push (cons (point) (mark)) eri--past-regions)
      (push (cons (point) (point)) eri--past-regions))
    (eri--expand-region))
   (eri--future-regions
    (let* ((pair (car eri--future-regions))
           (this-point (car-safe pair))
           (this-mark (cdr-safe pair)))
      (setq eri--future-regions (cdr eri--future-regions))
      (push pair eri--past-regions)
      (goto-char this-point)
      (set-mark this-mark)
      (when (= this-point this-mark)
        (eri--expand-region))))))

(defun eri--contract-region ()
  (if (null eri--past-regions)
      (deactivate-mark)
    (let* ((pair (car eri--past-regions))
           (this-point (car-safe pair))
           (this-mark (cdr-safe pair)))
      (setq eri--past-regions (cdr eri--past-regions))
      (push pair eri--future-regions)
      (goto-char this-point)
      (set-mark this-mark)
      (when (= this-point this-mark)
        (deactivate-mark)))))

(defun eri--get-all-regions ()
  (let ((all (seq-uniq
              (seq-sort-by
               (lambda (pair)
                 (- (cdr pair) (car pair)))
               '<
               (seq-mapcat
                (lambda (exps)
                  (append (eri--get-regions-for exps 100)
                          (when (listp exps)
                            (eri--get-regions-for (reverse exps) 1))))
                eri/try-expand-list)))))
    all))

;; FIXME: In-region detection is pretty stupid

(defun eri--get-regions-for (exps repeat)
  (save-excursion
    (let ((exps (if (listp exps) exps (list exps)))
          (old-point (point))
          (old-mark (mark))
          (old-active mark-active)
          result current useless-iterations)
      ;; Fix mark
      (unless old-active
        (set-mark old-point)
        (setq old-mark old-point))
      ;; Run all expansions
      (cl-block 'return
        (dotimes (_ repeat)
          (dolist (exp exps)
            (condition-case err
                (funcall exp)
              (error))
            ;; Protect against useless iterations
            (if (equal current (cons (point) (mark)))
                (setq useless-iterations (1+ useless-iterations))
              (setq useless-iterations 0))
            (when (> useless-iterations 1)
              (cl-return-from 'return result))
            ;; Update region
            (setq current (cons (point) (mark)))
            (when (and (/= (point) (mark))
                       (<= (point) old-point (mark))
                       (<= (point) old-mark (mark)))
              (unless (and mark-active (= old-point (mark)))
                (push current result))))))
      ;; Reset point and mark
      (prog1 result
        (goto-char old-point)
        (set-mark old-mark)
        (unless old-active
          (deactivate-mark))))))

;;;; Easy customization

;;;###autoload
(defun eri/add-mode-expansions (mode &optional additional removed)
  "Add the ADDITIONAL expansions to `eri/try-expand-list' in
MODE, then remove the REMOVED expansions."
  (declare (indent 1))
  (if (listp mode)
      (dolist (mode mode)
        (eri/add-mode-expansions mode additional removed))
    (let ((hook (intern (concat (symbol-name mode) "-hook"))))
      (add-hook
       hook (lambda ()
              (set (make-local-variable 'eri/try-expand-list)
                   (append
                    (seq-difference eri/try-expand-list removed)
                    additional)))))))

;;;###autoload
(defmacro eri/define-pair (name char &optional test-function)
  "Define a pair of CHAR with NAME that can be marked.
This macro defines two functions that can then be used to mark
said object.

When TEST-FUNCTION is a function, immediately unmark the object
if the function returns nil after marking."
  (let ((test-function (or test-function (lambda (_) t)))
        (inside-name (intern (concat "eri/mark-inside-" (symbol-name name))))
        (outside-name (intern (concat "eri/mark-outside-" (symbol-name name)))))
    `(progn
       (defun ,outside-name ()
         (interactive)
         (when (funcall ,test-function)
           (search-backward ,char)
           (set-mark (point))
           (forward-char)
           (search-forward ,char)
           (exchange-point-and-mark)))
       (defun ,inside-name ()
         (interactive)
         (when (funcall ,test-function)
           (search-backward ,char)
           (forward-char 2)
           (set-mark (point))
           (search-forward ,char)
           (backward-char 2)
           (exchange-point-and-mark))))))

;;;; New expansions

;;;###autoload
(defun eri/mark-line ()
  "Marks one buffer line."
  (interactive)
  (goto-char (point-at-eol))
  (forward-char)
  (set-mark (point))
  (backward-char)
  (goto-char (point-at-bol)))

;;;###autoload
(defun eri/mark-block ()
  "Marks one continuous block of text."
  (interactive)
  (while (and (/= (point-at-eol) (point-at-bol))
              (/= (point-at-eol) (point-max)))
    (forward-line))
  (set-mark (point-at-bol))
  (forward-line -1)
  (while (and (/= (point-at-bol) (point-at-eol))
              (/= (point-at-bol) (point-min)))
    (forward-line -1))
  (forward-line)
  (goto-char (point-at-bol)))

(defun eri/mark-outside-quotes ()
  "Mark the current string, including the quotation marks."
  (interactive)
  (if (er--point-inside-string-p)
      (progn
        (er--move-point-forward-out-of-string)
        (set-mark (point))
        (backward-char)
        (er--move-point-backward-out-of-string))
    (forward-char)
    (if (not (er--point-inside-string-p))
        (backward-char)
      (er--move-point-forward-out-of-string)
      (set-mark (point))
      (backward-char)
      (er--move-point-backward-out-of-string))))

;;;; Setup code

(setq eri--variables '(eri--direction eri--future-regions eri--past-regions))
(dolist (var eri--variables)
  (make-variable-buffer-local var))
(add-hook 'post-command-hook 'eri--reset-region)

(with-eval-after-load 'multiple-cursors
  (dolist (var eri--variables)
    (add-to-list 'mc/cursor-specific-vars var))
  (advice-add 'mc/mark-more-like-this :before 'eri--reset-for-mc))

(eri/add-mode-expansions '(lisp-mode emacs-lisp-mode)
  '()
  '(eri/mark-line eri/mark-block))

(eri/add-mode-expansions 'LaTeX-mode
  '(LaTeX-mark-section
    er/mark-LaTeX-math
    (er/mark-LaTeX-inside-environment
     LaTeX-mark-environment)))

(eri/add-mode-expansions 'org-mode
  '(org-mark-subtree
    '(er/mark-org-element
      er/mark-org-element-parent)
    er/mark-org-code-block
    er/mark-sentence
    er/mark-paragraph))

(eri/add-mode-expansions 'clojure-mode
  '(er/mark-clj-word
    er/mark-clj-regexp-literal
    er/mark-clj-set-literal
    er/mark-clj-function-literal))

(eri/add-mode-expansions 'css-mode
  '(er/mark-css-declaration))

(eri/add-mode-expansions 'erlang-mode
  '(erlang-mark-function
    erlang-mark-clause))

(eri/add-mode-expansions 'feature-mode
  '(er/mark-feature-scenario
    er/mark-feature-step))

(eri/add-mode-expansions '(sgml-mode rhtml-mode nxhtml-mode)
  '(er/mark-html-attribute
    (er/mark-inner-tag
     er/mark-outer-tag)))

(defun eri/web-mode-element-parent ()
  (interactive)
  (web-mode-element-parent)
  (web-mode-element-select))

(defun eri/web-mode-element-parent-content ()
  (interactive)
  (web-mode-element-parent)
  (web-mode-element-select)
  (web-mode-element-content-select))

(eri/add-mode-expansions '(web-mode)
  '(web-mode-attribute-select
    web-mode-tag-select
    web-mode-block-select
    web-mode-element-select
    (eri/web-mode-element-parent
     eri/web-mode-element-parent-content)))

(eri/add-mode-expansions 'nxml-mode
  '(nxml-mark-paragraph
    er/mark-nxml-tag
    (er/mark-nxml-inside-element
     er/mark-nxml-element
     er/mark-nxml-containing-element)
    (er/mark-nxml-attribute-inner-string
     er/mark-nxml-attribute-string)
    er/mark-html-attribute)
  '(er/mark-method-call
    er/mark-symbol-with-prefix
    er/mark-symbol))

(eri/add-mode-expansions '(js-mode js2-mode js3-mode)
  '(er/mark-js-function
    er/mark-js-object-property-value
    er/mark-js-object-property
    er/mark-js-if
    (er/mark-js-inner-return
     er/mark-js-outer-return)
    er/mark-js-call))

;; (eri/add-mode-expansions 'octave-mode)
;; (eri/add-mode-expansions 'python-mode)
;; (eri/add-mode-expansions 'ruby-mode)
;; (eri/add-mode-expansions 'cc-mode)
;; (eri/add-mode-expansions 'text-mode)
;; (eri/add-mode-expansions 'cperl-mode)
;; (eri/add-mode-expansions 'sml-mode)
;; (eri/add-mode-expansions 'enh-ruby-mode)

(provide 'expand-region-improved)

;;; expand-region-improved.el ends here
