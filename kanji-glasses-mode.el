;;; kanji-glasses-mode.el --- Minor mode for studying kanji

;; Copyright (C) 2017 Correl Roush

;; Author: Correl Roush <correl@gmail.com>
;; Version: 0.1
;; Created: 2017-06-16
;; Package-Requires: ((kanji-mode "1.0") (memoize "1.0.1"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Provides a minor mode for displaying the hiragana reading alongside
;; kanji present in a buffer. This is accomplished using overlays, so
;; the contents of the buffer are not modified at all.

;; Enabling this mode will take some time on a buffer with a lot of
;; kanji present. To combat this, I've memoized the transliteration
;; method, so it at least won't look up the same thing more than once.

;; Currently relies on kanji-mode for its `km:kanji->hiragana' method
;; (which in turn relies on having kakasi (http://kakasi.namazu.org/)
;; installed) to transliterate kanji to hiragana.

;;; Code:

(require 'kanji-mode)
(require 'memoize)

(defmemoize kanji-glasses-kanji->hiragana (text)
  "Memoized function to transliterate kanji in TEXT into
hiragana."
  (km:kanji->hiragana text))

(defun kanji-glasses-set-overlay-properties ()
  "Set properties of kanji overlays."
  (put 'kanji-glasses 'evaporate t)
  (put 'kanji-glasses 'face '(bold highlight)))

(kanji-glasses-set-overlay-properties)

(defun kanji-glasses-overlay-p (overlay)
  "Return whether OVERLAY is an overlay of kanji-glasses mode."
  (eq (overlay-get overlay 'category)
      'kanji-glasses))

(defun kanji-glasses-wipe (start end)
  "Clear kanji-glasses overlays between START and END."
  (dolist (overlay (overlays-in start end))
    (when (kanji-glasses-overlay-p overlay)
      (delete-overlay overlay))))

(defun kanji-glasses-adjust (start end)
  "Apply kanji-glasses to the region defined by START and END."

  (let ((kanji-pattern "\\([\x3400-\x4DB5\x4E00-\x9FCB\xF900-\xFA6A]+\\)")
        (case-fold-search nil))
    (save-excursion
      (save-match-data
        (goto-char start)
        (while (re-search-forward kanji-pattern)
          (let ((overlay (make-overlay (match-beginning 1) (match-end 1))))
            (overlay-put overlay 'category 'kanji-glasses)
            (overlay-put overlay 'after-string
                         (propertize (concat "（" (kanji-glasses-kanji->hiragana (match-string 1)) "）")
                                     'face '(bold highlight)))))
        ))))

(defun kanji-glasses-change (start end)
  "Fontification function to be registered to `jit-lock'.
Clears and re-applies kanji-glasses overlays to the region
defined by START and END."
  (let ((start-line (save-excursion (goto-char start) (line-beginning-position)))
        (end-line (save-excursion (goto-char end) (line-end-position))))
    (kanji-glasses-wipe start-line end-line)
    (kanji-glasses-adjust start-line end-line)))

(define-minor-mode kanji-glasses-mode
  "Minor mode for studying kanji"
  :lighter " 勉強"
  (kanji-glasses-wipe (point-min) (point-max))
  (if kanji-glasses-mode
      (progn
        (jit-lock-register 'kanji-glasses-change))
    (jit-lock-unregister 'kanji-glasses-change)))

;;; kanji-glasses-mode.el ends here
