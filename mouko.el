;;; mouko.el --- Show results of Japanese Baseball games -*- lexical-binding: t; -*-

;; Copyright (C) 2015 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-mouko
;; Version: 0.01
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))

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

;;; Code:

(eval-when-compile
  (defvar url-http-end-of-headers)
  (defvar url-http-response-status))

(require 'cl-lib)
(require 'org)
(require 'url)
(require 'json)

(defconst mouko--uri "http://botch.herokuapp.com/v0/scores/")

(defconst mouko--team
  '(("YS" . "ヤ")
    ("G"  . "巨")
    ("DB" . "De")
    ("D"  . "中")
    ("T"  . "阪")
    ("C"  . "広")

    ("F"  . "日")
    ("E"  . "楽")
    ("M"  . "ロ")
    ("L"  . "西")
    ("BF" . "オ")
    ("H"  . "ソ")))

(defsubst mouko--no-game-p (json)
  (assoc "error" json))

(defsubst mouko--team-name (team)
  (assoc-default (assoc-default 'team team) mouko--team))

(defsubst mouko--team-score (team)
  (string-to-number (assoc-default 'score team)))

(defun mouko--parse-results (results)
  (cl-loop for result across results
           for home = (assoc-default 'home result)
           for home-team = (mouko--team-name home)
           for home-score = (mouko--team-score home)
           for away = (assoc-default 'away result)
           for away-team = (mouko--team-name away)
           for away-score = (mouko--team-score away)
           collect (format "%s %d-%d %s" home-team home-score away-score away-team)))

;;;###autoload
(defun mouko (date)
  (interactive
   (list (org-read-date)))
  (let ((api-uri (concat mouko--uri (replace-regexp-in-string "-" "" date)))
        (curbuf (current-buffer)))
    (url-retrieve
     api-uri
     (lambda (_status)
       (unless (= url-http-response-status 200)
         (error "Error: got %d status" url-http-response-status))
       (let* ((res (buffer-substring-no-properties url-http-end-of-headers (point-max)))
              (json (json-read-from-string res)))
         (when (mouko--no-game-p json)
           (error "'%s' is no game" date))
         (let ((results (mouko--parse-results (assoc-default 'data json))))
           (with-current-buffer curbuf
             (setq header-line-format
                   (format "[%s] %s"
                           date (mapconcat 'identity results "|")))
             (force-mode-line-update))))))))

(provide 'mouko)

;;; mouko.el ends here
