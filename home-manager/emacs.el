;; ---------------------------------------------------------------------
;; hooks
;; ---------------------------------------------------------------------

(add-hook 'prog-mode-hook     'rainbow-delimiters-mode)
(add-hook 'after-init-hook    'electric-pair-mode)
(add-hook 'prog-mode-hook     'untabify-mode)
(add-hook 'before-save-hook   'delete-trailing-whitespace)
(add-hook 'haskell-mode-hook  'haskell-indentation-mode)
(add-hook 'haskell-mode-hook  'global-ede-mode)
(add-hook 'markdown-mode-hook 'untabify-mode)
(add-hook 'after-init-hook    'global-auto-revert-mode)
(add-hook 'after-init-hook    'global-company-mode)
(add-hook 'after-init-hook    'ido-mode)

;; ---------------------------------------------------------------------
;; keybindings
;; ---------------------------------------------------------------------

(global-set-key (kbd "M-x")   'smex)
(global-set-key (kbd "M-X")   'smex-major-mode-commands)
(global-set-key (kbd "C-x m") 'view-mode)
(global-set-key (kbd "M-;")   'comment-dwim-line)

;; ---------------------------------------------------------------------
;; customizations
;; ---------------------------------------------------------------------

;; highlight current line
(global-hl-line-mode 1)
(set-face-attribute 'hl-line nil :inherit nil :background "#000000")

(setq undo-tree-visualizer-diff 1)
(setq undo-tree-visualizer-timestamps 1)
(setq undo-tree-auto-save-history nil)

(setq typescript-indent-level 2)

;; tree undo mode
(global-undo-tree-mode)

;; show matching parens
(require 'paren)
(show-paren-mode 1)
(setq show-paren-delay 0)
(set-face-attribute 'show-paren-match nil :background "#493535")

;; cursor goes to same place from previous sessios
(save-place-mode 1)

;; read-only files open with view-mode
(setq view-read-only t)

;; highligh past 80 characters
(require 'whitespace)
(global-whitespace-mode t)
(setq whitespace-style '(face empty tabs lines-tail trailing))
(add-hook 'window-setup-hook
          (lambda ()
            (set-face-attribute 'whitespace-line nil
                                :foreground nil
                                :background "#404040")))

;; mode-line theme
(require 'spaceline-config)
(spaceline-spacemacs-theme)
(spaceline-toggle-buffer-size-off)

;; Enable ido
(setq ido-enable-flex-matching t)
(setq ido-case-fold t)

;; Use my-backup-file-name function to determine where to place backups
(setq make-backup-file-name-function 'my-backup-file-name)

(setq auto-mode-alist (append '(("\\.html$" . web-mode)) auto-mode-alist))
(setq auto-mode-alist (append '(("\\.php$" . web-mode)) auto-mode-alist))
(setq auto-mode-alist (append '(("\\.inc$" . web-mode)) auto-mode-alist))
(setq auto-mode-alist (append '(("\\.tsx$" . web-mode)) auto-mode-alist))
(setq auto-mode-alist (append '(("\\.ts$" . web-mode)) auto-mode-alist))
(defun my-web-mode-hook ()
  "Hooks for Web mode."
  (setq web-mode-code-indent-offset 2)
)
(add-hook 'web-mode-hook  'my-web-mode-hook)

(setq-default indent-tabs-mode nil)

;; Make haskell use unicode characters
(setq haskell-font-lock-symbols t)


(custom-set-variables
 '(ansi-color-faces-vector
   [default default default italic underline success warning error])
 '(ansi-color-names-vector
   ["#242424" "#e5786d" "#95e454" "#cae682" "#8ac6f2" "#333366" "#ccaa8f"
    "#f6f3e8"])
 '(custom-enabled-themes '(tango-dark)))

(custom-set-faces
 '(rainbow-delimiters-depth-1-face ((t (:foreground "dark orange"))))
 '(rainbow-delimiters-depth-2-face ((t (:foreground "deep pink"))))
 '(rainbow-delimiters-depth-3-face ((t (:foreground "chartreuse"))))
 '(rainbow-delimiters-depth-4-face ((t (:foreground "deep sky blue"))))
 '(rainbow-delimiters-depth-5-face ((t (:foreground "yellow"))))
 '(rainbow-delimiters-depth-6-face ((t (:foreground "orchid"))))
 '(rainbow-delimiters-depth-7-face ((t (:foreground "spring green"))))
 '(rainbow-delimiters-depth-8-face ((t (:foreground "sienna1"))))
 )


;; ---------------------------------------------------------------------
;; functions
;; ---------------------------------------------------------------------

;; make backup to a designated dir, mirroring the full path
(defun my-backup-file-name (fpath)
  "Return a new file path of a given file path.
  If the new path's directories does not exist, create them."
  (let* ((backupRootDir "~/.emacs.d/emacs-backup/")
         (filePath
          (replace-regexp-in-string "[A-Za-z]:" "" fpath ))
         (backupFilePath
          (replace-regexp-in-string "//" "/"
                                    (concat backupRootDir filePath "~"))))
    (make-directory
     (file-name-directory backupFilePath)
     (file-name-directory backupFilePath))
    backupFilePath)
)

;; untabify before saving
(defvar untabify-this-buffer)
(defun untabify-all ()
  "Untabify the current buffer, unless `untabify-this-buffer' is nil."
  (and untabify-this-buffer (untabify (point-min) (point-max)))
)
(define-minor-mode untabify-mode
  "Untabify buffer on save." nil " untab" nil
  (make-variable-buffer-local 'untabify-this-buffer)
  (setq untabify-this-buffer (not (derived-mode-p 'makefile-mode)))
  (add-hook 'before-save-hook #'untabify-all)
)

;; comment line rebinding
(defun comment-dwim-line (&optional arg)
  "Replacement for the comment-dwim command.
   If no region is selected and current line is not blank and we are not at the end of the line,
   then comment current line.
   Replaces default behaviour of comment-dwim, when it inserts comment at the end of the line."
  (interactive "*P")
  (comment-normalize-vars)
  (if (and (not (region-active-p)) (not (looking-at "[ \t]*$")))
      (comment-or-uncomment-region (line-beginning-position) (line-end-position))
    (comment-dwim arg)))

;; change color of haskell var starting with _
(defface haskell-underscore-face
  '((t :foreground "#ddaaaa"
       ))
  "Face for haskell vars underlined."
  :group 'my-lang-mode )
(font-lock-add-keywords 'haskell-mode
                        '(("_[a-z][a-zA-Z0-9]*" 0 'haskell-underscore-face)))
