;;; clingo-ts-mode-test-font-lock.el --- Font-lock tests for clingo-ts-mode -*- lexical-binding: t; -*-

;; Copyright © 2026 Amadé Nemes

;;; Commentary:

;; Buttercup tests for clingo-ts-mode font-lock rules.
;; Tests are organized by font-lock feature, matching the 4 levels
;; defined in `treesit-font-lock-feature-list'.

;;; Code:

(require 'buttercup)
(require 'clingo-ts-mode)

(defmacro with-fontified-clingo-buffer (content &rest body)
  "Set up a temporary buffer with CONTENT, apply clingo-ts-mode font-lock, run BODY.
All four font-lock levels are activated so every feature is testable."
  (declare (indent 1))
  `(with-temp-buffer
     (insert ,content)
     (let ((treesit-font-lock-level 4))
       (clingo-ts-mode))
     (font-lock-ensure)
     (goto-char (point-min))
     ,@body))

(defun test-face-at (start end)
  "Return the face at range [START, END] in the current buffer.
If all positions in the range share the same face, return it.
Otherwise return the symbol `various-faces'."
  (let ((face (get-text-property start 'face)))
    (if (= start end)
        face
      (let ((pos (1+ start))
            (consistent t))
        (while (and consistent (<= pos end))
          (unless (equal (get-text-property pos 'face) face)
            (setq consistent nil))
          (setq pos (1+ pos)))
        (if consistent face 'various-faces)))))

(defun test-expect-faces-at (content &rest face-specs)
  "Fontify CONTENT with `neocaml-mode' and assert FACE-SPECS.
Each element of FACE-SPECS is a list (START END EXPECTED-FACE)
where START and END are buffer positions (1-indexed, inclusive)."
  (with-fontified-neocaml-buffer content
    (dolist (spec face-specs)
      (let* ((start (nth 0 spec))
             (end (nth 1 spec))
             (expected (nth 2 spec))
             (actual (neocaml-test-face-at start end)))
        (expect actual :to-equal expected)))))
