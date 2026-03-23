;;; clingo-ts-mode-test-font-lock.el --- Font-lock tests for clingo-ts-mode -*- lexical-binding: t; -*-

;; Copyright © 2026 Amadé Nemes

;;; Commentary:

;; Buttercup tests for clingo-ts-mode font-lock rules.
;; Tests are organized by font-lock feature, matching the 4 levels
;; defined in `treesit-font-lock-feature-list'.

;;; Code:

(require 'buttercup)
(require 'clingo-ts-mode)

(defmacro with-fontified-buffer (ts-mode content &rest body)
  "Set up a temporary buffer with CONTENT, apply tree-sitter mode TS-MODE
font-lock, run BODY.
All four font-lock levels are activated so every feature is testable."
  (declare (indent 1))
  `(with-temp-buffer
     (insert ,content)
     (let ((treesit-font-lock-level 4))
       (funcall ,ts-mode)
       ;; clingo-ts-mode
       )
     (font-lock-ensure)
     (goto-char (point-min))
     ,@body))

(defmacro with-fontified-clingo-buffer (content &rest body)
  "Set up a temporary buffer with CONTENT, apply clingo-ts-mode
font-lock, run BODY.
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

(defun test-expect-faces-at (tree-mode content &rest face-specs)
  "Fontify CONTENT with tree-sitter mode TS-MODE and assert FACE-SPECS.
Each element of FACE-SPECS is a list (START END EXPECTED-FACE)
where START and END are buffer positions (1-indexed, inclusive)."
  (with-fontified-buffer tree-mode content
    (dolist (spec face-specs)
      (let* ((start (nth 0 spec))
             (end (nth 1 spec))
             (expected (nth 2 spec))
             (actual (test-face-at start end)))
        (expect actual :to-equal expected)))))

(defun test-clingo-expect-faces-at (content &rest face-specs)
  "Fontify CONTENT with tree-sitter mode TS-MODE and assert FACE-SPECS.
Each element of FACE-SPECS is a list (START END EXPECTED-FACE)
where START and END are buffer positions (1-indexed, inclusive)."
  (with-fontified-clingo-buffer content
    (dolist (spec face-specs)
      (let* ((start (nth 0 spec))
             (end (nth 1 spec))
             (expected (nth 2 spec))
             (actual (test-face-at start end))
	     (snippet (buffer-substring-no-properties start (min (1+ end) (point-max)))))
        (expect actual :to-equal expected)))))

(defmacro when-fontifying-it (treesit-mode description &rest tests)
  "Create a Buttercup test asserting font-lock faces in tree-sitter mode
TREESIT-MODE.
DESCRIPTION is the test name.  Each element of TESTS is
  (CODE (START END FACE) ...)
where CODE is an OCaml source string and each (START END FACE)
triple asserts that positions START through END have FACE."
  (declare (indent 1))
  `(it ,description
     (dolist (test (quote ,tests))
       (apply #'test-expect-faces-at ,treesit-mode test))))

(defmacro when-clingo-fontifying-it (description &rest tests)
  "Create a Buttercup test asserting font-lock faces in clingo-ts-mode.
DESCRIPTION is the test name.  Each element of TESTS is
  (CODE (START END FACE) ...)
where CODE is an OCaml source string and each (START END FACE)
triple asserts that positions START through END have FACE."
  `(when-fontifying-it #'clingo-ts-mode ,description ,@tests))

;; (defmacro when-clingo-fontifying-it (description &rest tests)
;;   "Create a Buttercup test asserting font-lock faces in tree-sitter mode
;; TS-MODE.
;; DESCRIPTION is the test name.  Each element of TESTS is
;;   (CODE (START END FACE) ...)
;; where CODE is an OCaml source string and each (START END FACE)
;; triple asserts that positions START through END have FACE."
;;   (declare (indent 1))
;;   `(it ,description
;;      (dolist (test (quote ,tests))
;;        (apply #'test-clingo-expect-faces-at test))))

;;; Tests

(describe "clingo-ts-mode font-lock"
  (before-all
    (unless (treesit-language-available-p 'clingo)
      (signal 'buttercup-pending "tree-sitter Clingo grammar not available")))

  ;; ---- Level 1 features ------------------------------------------------

  (describe "comment feature"
    (when-clingo-fontifying-it "fontifies regular comments"
      ("% a comment"
       (1 11 font-lock-comment-face)))

    (when-clingo-fontifying-it "fontifies block comments"
      ("%* a comment
across multiple
lines *%"
       (1 37 font-lock-comment-face)))

    (when-clingo-fontifying-it "fontifies doc comments"
      ("%*! some_predicate (A, B)

Here is `some` documentation for the predicate.
with *much* _markup_

Args:
- A: **some** description for *A*
     maybe over multiple line
- B: some description for B
*%"
       (1 3 font-lock-doc-face) ;; %*!
       (5 18 font-lock-function-call-face) ;; some_predicate
       (20 20 font-lock-bracket-face) ;; (
       (21 21  font-lock-variable-name-face) ;; A
       (22 22 font-lock-delimiter-face) ;; ,
       (24 24 font-lock-variable-name-face) ;; B
       (25 25 font-lock-bracket-face) ;; )

       (28 35 font-lock-doc-face) ;; Here is
       (36 41 font-lock-doc-markup-face) ;; `some`
       (42 80 font-lock-doc-face) ;; documentation for the predicate with
       (81 86 font-lock-doc-markup-face) ;; *much*
       (88 95 font-lock-doc-markup-face) ;; _markup_

       (98 102 font-lock-doc-markup-face) ;; Args:
       (104 104 font-lock-doc-markup-face) ;; -
       (106 106 font-lock-variable-name-face) ;; A
       (107 107 font-lock-doc-markup-face) ;; :
       (109 116 font-lock-doc-markup-face) ;; **some**
       (118 133 font-lock-doc-face) ;; description for
       (134 136 font-lock-doc-markup-face) ;; *A*
       ))
    )

  (describe "preprocessor feature"
    (when-clingo-fontifying-it
     "fontifies #minimize"
     ("#minimize {}."
      (1 9 font-lock-preprocessor-face)))

    (when-clingo-fontifying-it
     "fontifies #minimise"
     ("#minimise {}."
      (1 9 font-lock-preprocessor-face)))

    (when-clingo-fontifying-it
     "fontifies #maximize"
     ("#maximize {}."
      (1 9 font-lock-preprocessor-face)))

    (when-clingo-fontifying-it
     "fontifies #maximise"
     ("#maximise {}."
      (1 9 font-lock-preprocessor-face)))

    (when-clingo-fontifying-it
     "fontifies #edge"
     ("#edge (1,2)."
      (1 5 font-lock-preprocessor-face)))

    (when-clingo-fontifying-it
     "fontifies #heuristic"
     ("#heuristic a. [1@1,sign]"
      (1 10 font-lock-preprocessor-face)))

    (when-clingo-fontifying-it
     "fontifies #project"
     ("#project a/3."
      (1 8 font-lock-preprocessor-face)))

    (when-clingo-fontifying-it
     "fontifies #show"
     ("#show a/3."
      (1 5 font-lock-preprocessor-face)))

    (when-clingo-fontifying-it
     "fontifies #defined"
     ("#defined a/3."
      (1 8 font-lock-preprocessor-face)))

    (when-clingo-fontifying-it
     "fontifies #external"
     ("#external a."
      (1 9 font-lock-preprocessor-face)))

    (when-clingo-fontifying-it
     "fontifies #include"
     ("#include <a>."
      (1 8 font-lock-preprocessor-face)
      (11 11 font-lock-preprocessor-face)))

    (when-clingo-fontifying-it
     "fontifies #const"
     ("#const a = 3."
      (1 6 font-lock-preprocessor-face)))

    (when-clingo-fontifying-it
     "fontifies #script"
     ("#script (python) #end."
      (1 7 font-lock-preprocessor-face)
      (10 15 font-lock-preprocessor-face)
      (19 21 font-lock-preprocessor-face)))

    (when-clingo-fontifying-it
     "fontifies #theory"
     ("#theory foo {}."
      (1 7 font-lock-preprocessor-face)))

    (when-clingo-fontifying-it
     "fontifies #program"
     ("#program foo(bar)."
      (1 8 font-lock-preprocessor-face)
      (10 12 font-lock-preprocessor-face)
      (14 16 font-lock-constant-face))))

  (describe "keyword feature"
    (when-clingo-fontifying-it
     "fontifies negation"
     ("not a; not not a."
      (1 3 font-lock-keyword-face)
      (8 14 font-lock-keyword-face)))
    )
  )
