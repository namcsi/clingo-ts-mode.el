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

;;; Code:

(provide 'clingo-ts-mode)


(define-derived-mode clingo-ts-mode prog-mode "Clingo"
  "A mode for the clingo programming language."
  (when (treesit-ready-p 'clingo)
    (setq-local
      treesit-font-lock-settings
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
	  @font-lock-keyword-face
	  (script language: (identifier) @font-lock-keyword-face))

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
	'([(line_comment)
	   (block_comment)
	   (doc_comment)]
	  @font-lock-comment-face)

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
	'((string) @font-lock-string-face
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
	'((boolean_constant) @font-lock-builtin-face))

      treesit-font-lock-feature-list
      '((preprocessor comment keyword)
	(function builtin)
	(string number constant variable)
	(operator punctuation type))
    )
    (treesit-major-mode-setup)))

;;; clingo-ts-mode.el ends here
