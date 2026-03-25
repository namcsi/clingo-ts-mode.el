;;; clingo-ts-mode.el --- A tree-sitter powered major mode for clingo -*- lexical-binding:t -*-

;; Copyright (C) 2026 Amadé Nemes

;; Author: Amadé Nemes <nemesamade@gmail.com>
;; Maintainer: Amadé Nemes <nemesamade@gmail.com>
;; Created: Feb 2026
;; URL: https://github.com/namcsi/clingo-ts-mode.el
;; Version: 0.1.0
;; Keywords: languages
;; Package-Requires: ((emacs "30.2"))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:

;;; This package defines a tree-sitter powered major mode for the
;;; input language of the Potassco Answer Set Programming (ASP) system
;;; clingo.

;;; The structure of the project and test fixtures was largely
;;; inspired by neocaml: https://github.com/bbatsov/neocaml, with some
;;; code being copied almost verbatim. Thank you for your work bbatsov!

;;; Code:

(require 'treesit)

(defgroup clingo-ts-mode nil
  "Major mode for editing clingo code with tree-sitter."
  :prefix "clingo-ts-mode-"
  :group 'languages
  :link '(url-link :tag "GitHub" "https://github.com/namcsi/clingo-ts-mode.el")
  :link '(emacs-commentary-link :tag "Commentary" "clingo-ts-mode"))

(defcustom clingo-ts-mode-indent-offset 2
  "Number of spaces for each indentation step in clingo-ts-mode."
  :type 'natnum
  :safe 'natnump
  :package-version '(clingo-ts-mode . "0.1.0"))

(defconst clingo-ts-mode-version "0.1.0")

(defun clingo-ts-mode-version ()
  "Display the current package version in the minibuffer.
Fallback to value of `clingo-ts-mode-version' const when the package version is missing.
When called from other Elisp code returns the version instead of
displaying it."
  (interactive)
  (let ((pkg-version (package-get-version)))
    (if (called-interactively-p 'interactively)
        (if pkg-version
            (message "clingo-ts-mode %s (package: %s)" clingo-ts-mode-version pkg-version)
          (message "clingo-ts-mode %s" clingo-ts-mode-version))
      (or pkg-version clingo-ts-mode-version))))

(defconst clingo-ts-mode-grammar-recipe
  '(clingo "https://github.com/potassco/tree-sitter-clingo"
            "v1.0.4")
  "Tree-sitter grammar recipe for clingo.
Matches format expected by `treesit-language-source-alist'.")

(defun clingo-ts-mode-install-grammar (&optional force)
  "Install required language grammar if not already available.
With prefix argument FORCE, reinstall grammar even if it is
already installed.  This is useful after upgrading clingo to a
version that requires a newer grammar."
  (interactive "P")
  (let ((grammar (car clingo-ts-mode-grammar-recipe)))
    (when (or force (not (treesit-language-available-p grammar nil)))
      (message "Installing %s tree-sitter grammar..." grammar)
      ;; `treesit-language-source-alist' is dynamically scoped.
      ;; Binding it in this let expression allows
      ;; `treesit-install-language-grammar' to pick up the grammar recipes
      ;; without modifying what the user has configured themselves.
      (let ((treesit-language-source-alist `(,clingo-ts-mode-grammar-recipe)))
	(treesit-install-language-grammar grammar)))))

(defvar clingo-ts-mode--font-lock-settings
  (treesit-font-lock-rules
        :language 'clingo
	:feature 'preprocessor
	'(["#minimize"
	   "#minimise"
	   "#maximize"
	   "#maximise"
	   "#edge"
	   "#heuristic"
	   "#project"
	   "#show"
	   "#defined"
	   "#external"
	   "#include"
	   "#const"
	   "#script"
	   "#end"
	   "#theory"
	   "#program"]
	  @font-lock-preprocessor-face
	  (include (identifier) @font-lock-preprocessor-face)
	  (script language: (identifier) @font-lock-preprocessor-face)
	  (program name: (identifier) @font-lock-preprocessor-face))

	:language 'clingo
	:feature 'keyword
	'([(default_negation)
	   (double_default_negation)
	   (aggregate_function)
	   (theory_atom_type)
	   (const_type)
	   (theory_operator_arity)
	   (theory_operator_associativity)]
	  @font-lock-keyword-face)

	:language 'clingo
	:feature 'type
	'((theory
	   name: (identifier) @font-lock-type-face)
	  (theory_atom_definition
	    theory_term_name: (identifier) @font-lock-type-face
	    guard: (identifier) :? @font-lock-type-face)
	  (theory_term_definition
	    name: (identifier) @font-lock-type-face))

	:language 'clingo
	:feature 'function
	'((theory_atom_definition "&" @font-lock-function-name-face)
	  (theory_atom_definition
	   name: (identifier) @font-lock-function-name-face)
	  (theory_atom "&" @font-lock-function-name-face)
	  (theory_atom
	   name: (identifier) @font-lock-function-name-face))

	:language 'clingo
	:feature 'comment
	'(([(line_comment)
	    (block_comment)]
	  @font-lock-comment-face)
	  (doc_comment
	   "%*!" @font-lock-doc-face
	   predicate: (doc_predicate
		       name: (identifier) @font-lock-function-call-face)
	   "*%" @font-lock-doc-face)
	  (doc_fragment_string) @font-lock-doc-face
	  (doc_args "Args:" @font-lock-doc-markup-face)
	  (doc_arg "-" @font-lock-doc-markup-face)
	  (doc_arg ":" @font-lock-doc-markup-face)
	  [(doc_fragment_emph)
	  (doc_fragment_italic)
	  (doc_fragment_bold)
	  (doc_fragment_code)]
	  @font-lock-doc-markup-face
	  )


	:language 'clingo
	:feature 'punctuation
	'([";"
	   ","
	   "."
	   ":-"
	   ":~"
	   ":"
	   (lone_comma)]
	  @font-lock-delimiter-face
	  (disjunction "|" @font-lock-delimiter-face)
	  (weight "@" @font-lock-delimiter-face)
	  (signature "/" @font-lock-delimiter-face)
	  (theory_atom_definition "/" @font-lock-delimiter-face)
	  ["("
	   ")"
	   "{"
	   "}"
	   "["
	   "]"]
	  @font-lock-bracket-face
	  )

	:language 'clingo
	:feature 'operator
	'([".."
	   "^"
	   "?"
	   "+"
	   "-"
	   "*"
	   "\\"
	   "**"
	   "~"
	   (theory_operator)
	   (relation)
	  ]
	  @font-lock-operator-face
	  (abs "|" @font-lock-operator-face)
	  (binary_operation "/" @font-lock-operator-face)
	  (binary_operation "&" @font-lock-operator-face)
	  (unary_operation "-" @font-lock-operator-face)
	  (const "=" @font-lock-operator-face))

	:language 'clingo
	:feature 'string
	'((string "\"" @font-lock-string-face)
	  (string_fragment) @font-lock-string-face
	  (fstring) @font-lock-string-face
	  (escape_sequence) @font-lock-escape-face)

	:language 'clingo
	:feature 'number
	'((number) @font-lock-number-face)

	:language 'clingo
	:feature 'constant
	'((supremum) @font-lock-constant-face
	  (infimum) @font-lock-constant-face
	  (const name: (identifier) @font-lock-constant-face)
	  (program parameters: (parameters (identifier) @font-lock-constant-face))
	  (function name: (identifier) @font-lock-constant-face)
	  (theory_function name: (identifier) @font-lock-constant-face)
	  (external_function
	    "@" @font-lock-constant-face
	    name: (identifier) @font-lock-constant-face)
	  )

	:language 'clingo
	:feature 'variable
	'([(variable)
	   (anonymous)]
	  @font-lock-variable-name-face)

	:language 'clingo
	:feature 'function
	'(;; atom definitions
	  (rule
	    head: (literal
	      !sign
	      atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-name-face)))
	  (disjunction
	    (literal
	      !sign
	      atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-name-face)))
	  (disjunction
	    (conditional_literal
	      literal: (literal
		!sign
		atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-name-face))))
	  (head_aggregate_element
	    literal: (literal
	      !sign
	      atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-name-face)))
	  (rule
	    head: (set_aggregate
	      elements: (set_aggregate_elements
		(set_aggregate_element
		  literal: (literal
		    !sign
		    atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-name-face))))))
	  (external
	    atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-name-face))
	  ;; atom references
	  (rule
	    head: (literal
	      sign: (_)
	      atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-call-face)))
	  (disjunction
	    (literal
	      sign: (_)
	      atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-call-face)))
	  (disjunction
	    (conditional_literal
	      literal: (literal
		sign: (_)
		atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-call-face))))
	  (head_aggregate_element
	    literal: (literal
	      sign: (_)
	      atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-call-face)))
	  (rule
	    head: (set_aggregate
	      elements: (set_aggregate_elements
		(set_aggregate_element
		  literal: (literal
		    sign: (_)
		    atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-call-face))))))
	  (body_literal
	    atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-call-face))
	  (body
	    (conditional_literal
	      literal: (literal
		atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-call-face))))
	  (body_literal
	    atom: (set_aggregate
	      elements: (set_aggregate_elements
		(set_aggregate_element
		  literal: (literal
		    atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-call-face))))))
	  (condition
	    (literal
	      atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-call-face)))
	  (project_atom
	    atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-call-face))
	  (heuristic
	    atom: (symbolic_atom
		     ((classical_negation) :? (identifier)) @font-lock-function-call-face))
	  (signature
	    sign: (classical_negation) :? @font-lock-function-call-face
	    name: (identifier) @font-lock-function-call-face))

      	:language 'clingo
	:feature 'builtin
	'((boolean_constant) @font-lock-builtin-face)))

;;;###autoload
(define-derived-mode clingo-ts-mode prog-mode "Clingo"
  "A mode for the clingo programming language."

  (when-let* ((missing (not (treesit-language-available-p 'clingo)))
	      (install (y-or-n-p "Clingo tree-sitter grammar is not installed. Install them now?")))
		(clingo-ts-mode-install-grammar))

  (when (treesit-ready-p 'clingo)

    ;; Emacs 31+ uses treesit-primary-parser to identify the main parser
    ;; when multiple parsers are active.
    (let ((parser (treesit-parser-create 'clingo)))
      (when (boundp 'treesit-primary-parser)
        (setq-local treesit-primary-parser parser)))

    ;; font locking
    (setq-local treesit-font-lock-settings clingo-ts-mode--font-lock-settings)

    (setq-local treesit-font-lock-feature-list
      '((preprocessor comment keyword)
	(function builtin)
	(string number constant variable)
	(operator punctuation type)))

      ;; indentation

    (treesit-major-mode-setup)
    ;; (font-lock-ensure)
    ))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lp\\'" . clingo-ts-mode))

(provide 'clingo-ts-mode)

;;; clingo-ts-mode.el ends here
